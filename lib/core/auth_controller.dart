import 'package:flutter/foundation.dart';

import '../features/auth/models/auth_profile.dart';
import '../features/auth/services/auth_backend.dart';
import '../features/auth/services/native_login.dart';
import 'exceptions/app_exceptions.dart';

/// 登录态：MVP 阶段仅保存在内存中。
class AuthController extends ChangeNotifier {
  AuthController({bool? web}) : _web = web ?? kIsWeb;

  final bool _web;
  final BffAuthService _bff = BffAuthService();
  final NativeLoginService _native = NativeLoginService();

  AuthProfile? _user;
  bool _isRestoring = true;
  bool _isAuthenticating = false;
  String? _errorMessage;

  AuthProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isRestoring => _isRestoring;
  bool get isAuthenticating => _isAuthenticating;
  String? get errorMessage => _errorMessage;

  /// 刷新页面时尝试恢复 BFF 会话；非 Web 平台没有可恢复的登录态。
  Future<void> restoreSession() async {
    if (!_web) {
      _isRestoring = false;
      notifyListeners();
      return;
    }
    _user = await _bff.restore();
    _isRestoring = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = _web
          ? await _bff.login(username, password)
          : await _native.login(username, password);
    } on AppException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '登录失败，请稍后重试';
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_web) {
      await _bff.logout();
    }
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}
