import '../models/auth_profile.dart';

/// 非 Web 平台不会使用 BFF。
class BffAuthService {
  Future<AuthProfile> login(String username, String password) {
    throw UnsupportedError('BFF 登录仅在 Web 平台可用');
  }

  Future<AuthProfile?> restore() async => null;

  Future<void> logout() async {}
}
