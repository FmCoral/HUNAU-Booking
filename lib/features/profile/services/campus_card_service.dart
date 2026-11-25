import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/auth_cookies.dart';
import '../../../core/utils/dkyw_crypto.dart';

/// 校园卡信息（姓名、卡号、余额）。
class CampusCardInfo {
  const CampusCardInfo({
    required this.name,
    required this.idserial,
    required this.balance,
  });

  final String name;
  final String idserial;
  final String balance;

  Map<String, dynamic> toJson() => {
        'name': name,
        'idserial': idserial,
        'balance': balance,
      };

  factory CampusCardInfo.fromJson(Map<String, dynamic> json) => CampusCardInfo(
        name: (json['name'] ?? '').toString(),
        idserial: (json['idserial'] ?? '').toString(),
        balance: (json['balance'] ?? '0.00').toString(),
      );
}

/// 微信充值订单（含微信 H5 支付地址）。
class WeChatRechargeOrder {
  const WeChatRechargeOrder({
    required this.partnerjourno,
    required this.mwebUrl,
    required this.returnurl,
  });

  final String partnerjourno;
  final String mwebUrl;
  final String returnurl;
}

/// 校园卡余额查询与充值。
///
/// 与牛×5 一致的纯 HTTP 链路：
/// `auth.chaoxing.com` 授权 → 302 → `fin-serv` openHomePage（携带 openid）
/// → `cardpay/openCardPay` 页面内 `<p class="bdb">姓名：学号 余额：x.xx元</p>`。
/// 登录得到的 Cookie 从 [AuthCookies] 复用，按域名回放。
/// 充值接口 `cardpay/openCardPay` 系列需要动态 AES 加解密，见 [DkywCrypto]。
class CampusCardService {
  CampusCardService._();

  static final CampusCardService instance = CampusCardService._();

  static const String _storageKey = 'cached_campus_card_info';
  static const String _finServBase = 'https://fin-serv.hunau.edu.cn';
  static const String _cardPayPath = '/cardpay/openCardPay';
  static const String _homePath = '/homeCX/openHomePage';

  CampusCardInfo? _cached;
  CampusCardInfo? get cached => _cached;

  String? _openid;
  String? get openid => _openid;

  _CardSession? _session;

  /// 读取上次成功获取的余额，用于首帧直接展示。
  Future<CampusCardInfo?> loadCached() async {
    if (_cached != null) return _cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      if (data is Map) {
        _cached = CampusCardInfo.fromJson(Map<String, dynamic>.from(data));
        return _cached;
      }
    } catch (_) {
      // 缓存损坏时按无缓存处理。
    }
    return null;
  }

  /// 退出登录时清空，避免下一个账号看到上一个人的余额。
  Future<void> clearSession() async {
    _cached = null;
    _openid = null;
    _session = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // 忽略清理失败
    }
  }

  /// 拉取最新余额。失败抛出可直接展示的中文原因。
  Future<CampusCardInfo> refresh() async {
    final session = _CardSession();
    for (final entry in AuthCookies.all.entries) {
      session.seed(entry.key, entry.value);
    }

    final openid = await session.authorize();
    if (openid == null) {
      throw Exception('校园卡授权失败，请重新登录后再试');
    }

    _session = session;
    _openid = openid;

    final html = (await session.get(
      '$_finServBase$_cardPayPath?openid=$openid&displayflag=1&id=28',
      referer: '$_finServBase$_homePath?openid=$openid&usertype=2',
    ))
        .data ??
        '';

    final info = _parse(html);
    if (info == null) {
      throw Exception('未能解析校园卡余额，请稍后重试');
    }

    _cached = info;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(info.toJson()));
    } catch (_) {
      // 持久化失败不影响本次展示
    }
    return info;
  }

  /// 确保充值环境可用：已有会话先预热 openCardPay，否则重新授权。
  Future<String?> ensureCardPayAuthenticated({bool force = false}) async {
    if (force || _openid == null || _session == null || _cached == null) {
      await refresh();
    }

    final openid = _openid;
    final session = _session;
    if (openid == null || session == null) return null;

    try {
      await session.get(
        '$_finServBase$_cardPayPath?openid=$openid&displayflag=1&id=28',
        referer: '$_finServBase$_homePath?openid=$openid&usertype=2',
      );
    } catch (_) {
      // 预热失败不阻断，后续 POST 会带同样 Cookie。
    }
    return openid;
  }

  /// 提交充值请求，获取支付宝跳转表单。
  Future<String> getAlipayForm(double amount) async {
    await ensureCardPayAuthenticated();
    final info = _cached;
    if (info == null) throw Exception('未获取到校园卡信息');

    final amountStr =
        amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toStringAsFixed(2);

    try {
      await _postCardPay(
        '$_finServBase/myaccount/userlastbind',
        {
          'payinfo': {'cardpayWay': '4'},
          'idserial': info.idserial,
        },
      );
    } catch (_) {
      // 记录支付方式失败不影响下单
    }

    final data = await _postCardPay(
      '$_finServBase/alipay/transferFromAlipay2Card',
      {
        'txamt': amountStr,
        'payWay': '4',
        'openid': _openid,
        'idserial': info.idserial,
      },
    );

    if (data is Map && (data['success'] == true || data['success'] == 'true')) {
      final result = data['resultData'];
      if (result is Map && result['htmlpost'] != null) {
        return result['htmlpost'].toString();
      }
    }
    if (data is Map) {
      final msg = data['message'] ?? data['msg'];
      if (msg != null) throw Exception(msg.toString());
    }
    throw Exception('获取支付宝支付表单失败，请稍后重试');
  }

  /// 提交微信充值请求，获取微信 H5 支付地址。
  Future<WeChatRechargeOrder> createWeChatOrder(double amount) async {
    await ensureCardPayAuthenticated();
    final info = _cached;
    if (info == null) throw Exception('未获取到校园卡信息');

    final amountStr =
        amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toStringAsFixed(2);

    try {
      await _postCardPay(
        '$_finServBase/myaccount/userlastbind',
        {
          'payinfo': {'cardpayWay': '1'},
          'idserial': info.idserial,
        },
      );
    } catch (_) {
      // 记录支付方式失败不影响下单
    }

    final data = await _postCardPay(
      '$_finServBase/wxpay/transferFromWx2Card',
      {
        'txamt': amountStr,
        'payWay': '1',
        'openid': _openid,
        'idserial': info.idserial,
        'tradetype': 'WAP',
      },
    );

    if (data is Map && (data['success'] == true || data['success'] == 'true')) {
      final result = data['resultData'];
      if (result is Map && result['mweb_url'] != null) {
        var returnurl = result['returnurl']?.toString() ?? '';
        if (returnurl.contains('%')) {
          try {
            returnurl = Uri.decodeComponent(returnurl);
          } catch (_) {}
        }
        if (returnurl.startsWith('http://')) {
          returnurl = returnurl.replaceFirst('http://', 'https://');
        }
        return WeChatRechargeOrder(
          partnerjourno: result['partnerjourno']?.toString() ?? '',
          mwebUrl: result['mweb_url'].toString(),
          returnurl: returnurl,
        );
      }
    }
    if (data is Map) {
      final msg = data['message'] ?? data['msg'];
      if (msg != null) throw Exception(msg.toString());
    }
    throw Exception('创建微信充值订单失败，请稍后重试');
  }

  /// 从微信 H5 支付页中提取 `weixin://wap/pay?...` 唤醒链接。
  Future<String?> getWeChatDeepLink(String mwebUrl) async {
    final session = _session ?? _CardSession();
    try {
      final response = await session.get(
        mwebUrl,
        referer: '$_finServBase/',
        accept:
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      );
      final html = response.data ?? '';
      final match =
          RegExp(r'''(weixin://wap/pay\?[^"'\s<>\)]+)''').firstMatch(html);
      if (match != null) {
        return match.group(1)!.replaceAll('&amp;', '&');
      }
    } catch (_) {
      // 提取失败时退回内置 WebView 打开 mweb_url
    }
    return null;
  }

  /// 发送带 DKYW 动态 AES 加解密的充值 POST 请求。
  Future<dynamic> _postCardPay(
    String url,
    Map<String, dynamic> payload, {
    bool isRetry = false,
  }) async {
    if (_openid == null || _session == null) {
      await ensureCardPayAuthenticated(force: isRetry);
    }
    final openid = _openid;
    final session = _session;
    if (openid == null || session == null) throw Exception('未授权，请重新登录后再试');

    final response = await session.post(
      '$url?openid=$openid&connect_redirect=1',
      data: {'datajson': DkywCrypto.encryptPayload(payload)},
      referer: '$_finServBase$_cardPayPath?openid=$openid&displayflag=1&id=28',
    );

    final data = DkywCrypto.decryptServerResponse(response.data);

    if (!isRetry && _looksExpired(data)) {
      _openid = null;
      _session = null;
      await ensureCardPayAuthenticated(force: true);
      return _postCardPay(url, payload, isRetry: true);
    }

    return data;
  }

  bool _looksExpired(dynamic data) {
    if (data is Map) {
      final msg = (data['message'] ?? data['msg'] ?? '').toString();
      return msg.contains('openid无效') ||
          msg.contains('页面丢失') ||
          msg.contains('未登录') ||
          msg.contains('会话过期') ||
          msg.contains('资源受限');
    }
    if (data is String) {
      return data.contains('cas/login') ||
          data.contains('errorPage') ||
          data.contains('资源受限') ||
          data.contains('页面丢失');
    }
    return false;
  }

  CampusCardInfo? _parse(String html) {
    // 标准结构：<p class="bdb">张三：202440800000 余额：21.00元</p>
    final infoText = RegExp(r'<p class="bdb">(.*?)</p>', dotAll: true)
        .firstMatch(html)
        ?.group(1);
    if (infoText != null && infoText.isNotEmpty) {
      final match =
          RegExp(r'([^：:\s<>]+)[：:]([0-9]+).*?余额[：:]([0-9.]+)')
              .firstMatch(infoText);
      if (match != null) {
        return CampusCardInfo(
          name: match.group(1)!.trim(),
          idserial: match.group(2)!.trim(),
          balance: match.group(3)!.trim(),
        );
      }
    }

    // 兜底：扫描表单域与「余额」文本
    final name = RegExp(r'id="username"\s+value="([^"]+)"')
        .firstMatch(html)
        ?.group(1) ??
        RegExp(r'name="username"\s+value="([^"]+)"').firstMatch(html)?.group(1);
    final idserial = RegExp(r'id="idserial"\s+value="([^"]+)"')
        .firstMatch(html)
        ?.group(1) ??
        RegExp(r'name="idserial"\s+value="([^"]+)"').firstMatch(html)?.group(1);
    final balance = RegExp(r'余额(?:<[^>]*>|[：:\s])*([0-9]+\.[0-9]+)')
            .firstMatch(html)
            ?.group(1) ??
        RegExp(r'([0-9]+\.[0-9]+)\s*元').firstMatch(html)?.group(1);
    if (name != null && idserial != null && balance != null) {
      return CampusCardInfo(
        name: name.trim(),
        idserial: idserial.trim(),
        balance: balance,
      );
    }
    return null;
  }
}

/// 单次查询用的会话：手动跟随 302，按域名回放与接收 Cookie。
class _CardSession {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: false,
      responseType: ResponseType.plain,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  final Map<String, Cookie> _cookies = <String, Cookie>{};

  void seed(Uri origin, List<Cookie> cookies) {
    for (final cookie in cookies) {
      _store(origin, cookie);
    }
  }

  void _store(Uri origin, Cookie cookie) {
    final domain = (cookie.domain?.replaceFirst(RegExp(r'^\.'), '') ??
            origin.host)
        .toLowerCase();
    final path = cookie.path ?? '/';
    _cookies['$domain|$path|${cookie.name}'] = Cookie(cookie.name, cookie.value)
      ..domain = domain
      ..path = path;
  }

  String? _cookieHeader(Uri uri) {
    final host = uri.host.toLowerCase();
    final values = <String>[];
    for (final cookie in _cookies.values) {
      final domain = cookie.domain ?? host;
      final domainMatches = host == domain || host.endsWith('.$domain');
      final path = cookie.path ?? '/';
      if (domainMatches && uri.path.startsWith(path)) {
        values.add('${cookie.name}=${cookie.value}');
      }
    }
    return values.isEmpty ? null : values.join('; ');
  }

  void _absorbCookies(Response response, Uri uri) {
    final setCookies =
        response.headers[HttpHeaders.setCookieHeader] ?? const <String>[];
    for (final header in setCookies) {
      try {
        _store(uri, Cookie.fromSetCookieValue(header));
      } catch (_) {
        // 个别 Set-Cookie 格式异常时跳过
      }
    }
  }

  Future<Response<String>> get(
    String url, {
    String? referer,
    String? accept,
  }) async {
    final uri = Uri.parse(url);
    final cookieHeader = _cookieHeader(uri);
    final response = await _dio.getUri<String>(
      uri,
      options: Options(
        headers: {
          'User-Agent': AppConstants.campusCardUA,
          'Accept': accept ??
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9',
          'Referer': ?referer,
          'Cookie': ?cookieHeader,
        },
      ),
    );
    _absorbCookies(response, uri);
    return response;
  }

  Future<Response<String>> post(
    String url, {
    Object? data,
    String? referer,
  }) async {
    final uri = Uri.parse(url);
    final cookieHeader = _cookieHeader(uri);
    final response = await _dio.postUri<String>(
      uri,
      data: data,
      options: Options(
        contentType: Headers.jsonContentType,
        headers: {
          'User-Agent': AppConstants.campusCardUA,
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'Accept-Language': 'zh-CN,zh;q=0.9',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': ?referer,
          'Cookie': ?cookieHeader,
        },
      ),
    );
    _absorbCookies(response, uri);
    return response;
  }

  /// 走超星授权链，返回 openid；落到 errorPage、资源受限或超时返回 null。
  ///
  /// 与牛×5 一致：即使 Location 里已经带了 openid，也要继续 GET 一次
  /// `openHomePage`，否则 fin-serv 的会话 Cookie 没建立，
  /// 后续 openCardPay 会落到 errorPage（表现为刷新失败）。
  Future<String?> authorize() async {
    var url = AppConstants.campusCardUrl;
    String? referer;

    for (var step = 0; step < 12; step++) {
      final response = await get(url, referer: referer);
      final status = response.statusCode ?? 0;
      final location =
          response.headers.value(HttpHeaders.locationHeader) ?? '';

      if (status >= 300 && status < 400 && location.isNotEmpty) {
        final next = Uri.parse(url).resolve(location).toString();
        if (next.contains('errorPage')) return null;
        referer = url;
        url = next;
        continue;
      }

      final body = response.data ?? '';
      if (body.contains('资源受限') || body.contains('页面丢失')) return null;

      final fromBody =
          RegExp(r'openHomePage\?openid=([A-Za-z0-9]+)').firstMatch(body) ??
              RegExp(r'''openid["'=:\s]+([A-Fa-f0-9]{16,})''').firstMatch(body);
      if (fromBody != null) return fromBody.group(1);

      final openid = Uri.parse(url).queryParameters['openid'];
      if (openid != null && openid.isNotEmpty) return openid;

      return null;
    }
    return null;
  }
}
