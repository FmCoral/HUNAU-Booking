import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/auth/models/auth_profile.dart';
import '../features/auth/services/auth_backend.dart';
import '../features/auth/services/native_login.dart';
import 'exceptions/app_exceptions.dart';
import 'services/auth_store.dart';

/// 登录态管理：本地保存凭据与资料，重启后先渲染资料再静默重登。
class AuthController extends ChangeNotifier {
  AuthController({bool? web}) : _web = web ?? kIsWeb;

  final bool _web;
  final BffAuthService _bff = BffAuthService();
  final NativeLoginService _native = NativeLoginService();
  final AuthStore _store = AuthStore();

  AuthProfile? _user;
  bool _isRestoring = true;
  bool _isAuthenticating = false;
  String? _errorMessage;

  AuthProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isRestoring => _isRestoring;
  bool get isAuthenticating => _isAuthenticating;
  String? get errorMessage => _errorMessage;

  /// Web 恢复 BFF 会话；原生端读本地快照，先用缓存资料渲染，再静默重登刷新。
  Future<void> restoreSession() async {
    if (_web) {
      _user = await _bff.restore();
      _isRestoring = false;
      notifyListeners();
      return;
    }

    final saved = await _store.load();
    if (saved != null) {
      _user = saved.profile;
    }
    _isRestoring = false;
    notifyListeners();

    if (saved != null && saved.hasPassword) {
      unawaited(_silentLogin(saved));
    }
  }

  /// 启动静默重登：失败只保留本地登录态，不把用户踢回登录页。
  Future<void> _silentLogin(SavedAuth saved) async {
    try {
      final profile = await _native.login(saved.username, saved.password);
      _user = profile;
      _errorMessage = null;
      notifyListeners();
      await _store.saveProfile(profile);
    } catch (_) {
      // 网络异常或服务端短暂不可用时保持已登录状态。
    }
  }

  Future<void> login(String username, String password) async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = _web
          ? await _bff.login(username, password)
          : await _native.login(username, password);
      _user = profile;
      if (!_web) {
        await _store.saveCredentials(username: username, password: password);
      }
      await _store.saveProfile(profile);
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
    await _store.clear();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}
