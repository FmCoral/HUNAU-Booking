import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../models/auth_profile.dart';
import 'http_login_service.dart';

/// Android / iOS / Desktop：直接向学校 CAS 发起纯 HTTP 登录。
class NativeLoginService {
  Future<AuthProfile> login(String username, String password) async {
    final result = await HttpLoginService().login(username, password);
    final profile = result.profile;
    final uid = _findChaoxingUid(result.cookies);
    return AuthProfile(
      username: profile?.username ?? username,
      realName: profile?.realName,
      uid: uid,
      avatarUrl: uid == null ? null : AppConstants.fusionAvatarUrl(uid),
    );
  }

  /// 从登录过程中拿到的超星 Cookie 里取 UID，用于拼接头像地址。
  String? _findChaoxingUid(Map<Uri, List<Cookie>> cookies) {
    String? fallback;
    for (final entry in cookies.entries) {
      final host = entry.key.host;
      if (!host.endsWith('chaoxing.com')) continue;
      for (final cookie in entry.value) {
        if (cookie.name != 'UID' && cookie.name != '_uid') continue;
        final value = cookie.value.trim();
        if (value.isEmpty) continue;
        if (host.startsWith('passport2.')) return value;
        fallback ??= value;
      }
    }
    return fallback;
  }
}
