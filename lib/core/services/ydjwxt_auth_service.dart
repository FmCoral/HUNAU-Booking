import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../features/auth/services/http_login_service.dart';
import '../constants/app_constants.dart';
import '../network/auth_cookies.dart';
import '../services/auth_store.dart';
import '../utils/app_logger.dart';

/// 移动教务系统（YDJWXT）Token 获取服务。
///
/// 复用登录阶段拿到的 Cookie，通过 Headless WebView 完成超星 OAuth，
/// 并在页面请求头 / localStorage 中提取 Token。
class YdjwxtAuthService {
  static final YdjwxtAuthService _instance = YdjwxtAuthService._internal();
  factory YdjwxtAuthService() => _instance;
  YdjwxtAuthService._internal();

  final _logger = AppLogger.instance;
  String? _cachedToken;
  DateTime? _tokenExpiry;
  Future<String>? _ongoingAuthFuture;
  int _tokenGeneration = 0;

  /// 需要注入 Cookie 的目标站点。
  static const List<String> _cookieTargets = [
    'https://auth.chaoxing.com',
    'https://passport2.chaoxing.com',
    'https://passport2-api.chaoxing.com',
    'https://notice.chaoxing.com',
    'https://sso.hunau.edu.cn',
    'https://portal.hunau.edu.cn',
    'https://ydjwxt.hunau.edu.cn',
  ];

  /// 获取移动教务系统的 Token（支持缓存与自动刷新）。
  Future<String> getToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedToken != null && _isTokenValid(_cachedToken!)) {
      _logger.d('🔑 Using cached YDJWXT token');
      return _cachedToken!;
    }

    // 防止并发重复触发认证
    if (_ongoingAuthFuture != null) {
      _logger.d('🔑 Waiting for ongoing YDJWXT authentication...');
      return await _ongoingAuthFuture!;
    }

    _ongoingAuthFuture = _performAuth(forceRefresh: forceRefresh);
    try {
      return await _ongoingAuthFuture!;
    } finally {
      _ongoingAuthFuture = null;
    }
  }

  /// 清除缓存的 Token
  void clearToken() {
    _tokenGeneration++;
    _cachedToken = null;
    _tokenExpiry = null;
    _ongoingAuthFuture = null;
  }

  Future<String> _performAuth({bool forceRefresh = false}) async {
    final gen = _tokenGeneration;
    _logger.i('🔑 Acquiring YDJWXT token (forceRefresh: $forceRefresh)...');
    final token = await _authenticate();
    if (token == null || token.isEmpty) {
      throw Exception('身份验证失败，未能获取移动教务系统 Token。请确保已登录。');
    }

    if (gen != _tokenGeneration) {
      _logger.w('🔑 YDJWXT auth completed after clearToken, discarding token');
      return '';
    }

    _cachedToken = token;
    _tokenExpiry =
        _extractTokenExpiry(token) ?? DateTime.now().add(const Duration(hours: 3));
    _logger.i('✅ YDJWXT token acquired, expires at: $_tokenExpiry');
    return token;
  }

  /// 检查 Token 是否仍在有效期内（预留 5 分钟缓冲）
  bool _isTokenValid(String token) {
    if (_tokenExpiry != null) {
      return DateTime.now()
          .isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)));
    }
    return true;
  }

  /// 从 JWT Token 的 Payload 中解析过期时间
  DateTime? _extractTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is int) {
        if (exp > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(exp);
        }
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      _logger.d('⚠️ Could not parse token exp: $e');
    }
    return null;
  }

  /// 准备 Cookie：优先使用本次登录的内存 Cookie，否则用本地凭据重新登录。
  Future<void> _ensureCookies() async {
    if (AuthCookies.all.isNotEmpty) return;

    final saved = await AuthStore().load();
    if (saved == null || saved.password.isEmpty) {
      throw Exception('登录状态已失效，请重新登录');
    }

    try {
      final result =
          await HttpLoginService().login(saved.username, saved.password);
      AuthCookies.save(result.cookies);
    } catch (e) {
      _logger.e('❌ Re-login for YDJWXT cookies failed: $e');
      throw Exception('登录状态已失效，请重新登录');
    }
  }

  /// Cookie 是否适用于目标站点。
  bool _cookieMatches(io.Cookie cookie, Uri origin, Uri target) {
    final domain = cookie.domain;
    if (domain != null && domain.isNotEmpty) {
      final d = domain.startsWith('.') ? domain.substring(1) : domain;
      return target.host == d || target.host.endsWith('.$d');
    }
    return origin.host == target.host;
  }

  /// 把登录 Cookie 注入 WebView 的 Cookie 管理器。
  Future<void> _injectCookies() async {
    final manager = CookieManager();
    for (final target in _cookieTargets) {
      final uri = Uri.parse(target);
      // 同名 Cookie 以最后写入的为准，避免重复注入。
      final byName = <String, io.Cookie>{};
      for (final entry in AuthCookies.all.entries) {
        for (final cookie in entry.value) {
          if (!_cookieMatches(cookie, entry.key, uri)) continue;
          byName[cookie.name] = cookie;
        }
      }
      for (final cookie in byName.values) {
        try {
          await manager.setCookie(
            url: WebUri(target),
            name: cookie.name,
            value: cookie.value,
            domain: cookie.domain,
            path: cookie.path ?? '/',
            isSecure: uri.scheme == 'https',
          );
        } catch (e) {
          _logger.w('⚠️ Failed to inject cookie ${cookie.name}: $e');
        }
      }
    }
  }

  /// 通过 Headless WebView 完成超星 OAuth 认证并提取 Token。
  Future<String?> _authenticate() async {
    // Cookie 不可用属于「登录失效」，需要直接抛给调用方。
    await _ensureCookies();
    await _injectCookies();

    final completer = Completer<String?>();
    final controller = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(AppConstants.ydjwxtOAuthUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        userAgent: AppConstants.ydjwxtUA,
        useShouldInterceptRequest: true,
        cacheEnabled: false,
        cacheMode: CacheMode.LOAD_NO_CACHE,
        clearSessionCache: true,
      ),
      onLoadStop: (controller, url) async {
        try {
          final raw = await controller.evaluateJavascript(source: '''
            (function() {
              return localStorage.getItem('token') ||
                     sessionStorage.getItem('token') ||
                     localStorage.getItem('access_token') || '';
            })()
          ''');
          final token = (raw ?? '').toString().replaceAll('"', '').trim();
          if (token.length > 20 && !completer.isCompleted) {
            _logger.i('✅ Token captured from storage at $url');
            completer.complete(token);
          }
        } catch (e) {
          _logger.d('⚠️ Read token from WebView failed: $e');
        }
      },
      shouldInterceptRequest: (controller, request) async {
        final headers = request.headers;
        if (headers != null) {
          for (final key in const ['token', 'Token', 'authorization', 'Authorization']) {
            final raw = headers[key];
            if (raw == null || raw.isEmpty || raw.length <= 20) continue;
            if (raw.startsWith('Basic')) break;
            final token =
                raw.startsWith('Bearer ') ? raw.substring(7) : raw;
            if (token.length > 20 && !completer.isCompleted) {
              _logger.i('✅ Token captured from request header');
              completer.complete(token);
            }
            break;
          }
        }
        return null;
      },
    );

    await controller.run();

    final timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('移动教务系统身份验证超时'));
      }
    });

    try {
      return await completer.future;
    } catch (e) {
      _logger.e('Authentication error: $e');
      rethrow;
    } finally {
      timeoutTimer.cancel();
      await controller.dispose();
    }
  }
}
