import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../features/auth/services/http_login_service.dart';
import '../constants/app_constants.dart';
import '../network/auth_cookies.dart';
import '../services/auth_store.dart';
import '../utils/app_logger.dart';

/// 移动教务系统（YDJWXT）Token 获取服务。
///
/// 复用登录阶段拿到的 Cookie，通过一个 1x1 的 WebView 完成超星 OAuth，
/// 再从 localStorage / sessionStorage 中提取 Token。
class YdjwxtAuthService {
  static final YdjwxtAuthService _instance = YdjwxtAuthService._internal();
  factory YdjwxtAuthService() => _instance;
  YdjwxtAuthService._internal();

  final _logger = AppLogger.instance;
  String? _cachedToken;
  DateTime? _tokenExpiry;
  Future<String>? _ongoingAuthFuture;
  int _tokenGeneration = 0;

  /// 获取移动教务系统的 Token（支持缓存与自动刷新）。
  ///
  /// [context] 用于展示「正在验证身份」的进度弹窗，同步入口必须传入。
  Future<String> getToken({bool forceRefresh = false, BuildContext? context}) async {
    if (!forceRefresh && _cachedToken != null && _isTokenValid(_cachedToken!)) {
      _logger.d('🔑 Using cached YDJWXT token');
      return _cachedToken!;
    }

    // 防止并发重复触发认证
    if (_ongoingAuthFuture != null) {
      _logger.d('🔑 Waiting for ongoing YDJWXT authentication...');
      return await _ongoingAuthFuture!;
    }

    _ongoingAuthFuture =
        _performAuth(forceRefresh: forceRefresh, context: context);
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

  Future<String> _performAuth({
    bool forceRefresh = false,
    BuildContext? context,
  }) async {
    final gen = _tokenGeneration;
    _logger.i('🔑 Acquiring YDJWXT token (forceRefresh: $forceRefresh)...');
    final token = await _authenticate(context);
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

  /// 把登录 Cookie 注入 WebView 的 Cookie 管理器。
  Future<void> _injectCookies() async {
    final manager = WebViewCookieManager();
    final injected = <String>{};
    for (final entry in AuthCookies.all.entries) {
      for (final cookie in entry.value) {
        final domain =
            (cookie.domain != null && cookie.domain!.isNotEmpty)
                ? cookie.domain!
                : entry.key.host;
        final path = cookie.path ?? '/';
        final key = '$domain|$path|${cookie.name}';
        if (!injected.add(key)) continue;
        try {
          await manager.setCookie(
            WebViewCookie(
              name: cookie.name,
              value: cookie.value,
              domain: domain,
              path: path,
            ),
          );
        } catch (e) {
          _logger.w('⚠️ Failed to inject cookie ${cookie.name}: $e');
        }
      }
    }
  }

  /// 通过 WebView 完成超星 OAuth 认证并提取 Token。
  Future<String?> _authenticate(BuildContext? context) async {
    // Cookie 不可用属于「登录失效」，需要直接抛给调用方。
    await _ensureCookies();
    await _injectCookies();

    final completer = Completer<String?>();
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setUserAgent(AppConstants.ydjwxtUA);
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) async {
          try {
            final raw = await controller.runJavaScriptReturningResult(
              "localStorage.getItem('token') || "
              "sessionStorage.getItem('token') || "
              "localStorage.getItem('access_token') || ''",
            );
            final token = raw.toString().replaceAll('"', '').trim();
            if (token.length > 20 && !completer.isCompleted) {
              completer.complete(token);
            }
          } catch (e) {
            _logger.d('⚠️ Read token from WebView failed: $e');
          }
        },
      ),
    );
    controller.loadRequest(Uri.parse(AppConstants.ydjwxtOAuthUrl));

    NavigatorState? navigator;
    var dialogClosed = false;
    if (context != null && context.mounted) {
      navigator = Navigator.of(context, rootNavigator: true);
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 14),
                      Expanded(child: Text('正在验证教务身份...')),
                    ],
                  ),
                  // 1x1 的 WebView：仅用于跑 OAuth 与执行 JS，不干扰布局
                  SizedBox(
                    width: 1,
                    height: 1,
                    child: WebViewWidget(controller: controller),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    void closeDialog() {
      if (dialogClosed) return;
      dialogClosed = true;
      final nav = navigator;
      if (nav != null && nav.mounted && nav.canPop()) {
        nav.pop();
      }
    }

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
      closeDialog();
    }
  }
}
