import '../models/auth_profile.dart';

/// Web 平台不会直接连接学校服务器，登录统一走 BFF。
class NativeLoginService {
  Future<AuthProfile> login(String username, String password) {
    throw UnsupportedError('纯 HTTP 登录仅在非 Web 平台可用');
  }
}
