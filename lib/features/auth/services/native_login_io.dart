import '../models/auth_profile.dart';
import 'http_login_service.dart';

/// Android / iOS / Desktop：直接向学校 CAS 发起纯 HTTP 登录。
class NativeLoginService {
  Future<AuthProfile> login(String username, String password) async {
    final result = await HttpLoginService().login(username, password);
    final profile = result.profile;
    return AuthProfile(
      username: profile?.username ?? username,
      realName: profile?.realName,
    );
  }
}
