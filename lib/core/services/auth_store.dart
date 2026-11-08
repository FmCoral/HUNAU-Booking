import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/models/auth_profile.dart';

/// 本地保存的登录快照：凭据用于启动时静默重登，资料用于首帧立即渲染。
class SavedAuth {
  const SavedAuth({
    required this.username,
    required this.password,
    required this.profile,
  });

  final String username;
  final String password;
  final AuthProfile profile;

  bool get hasPassword => password.isNotEmpty;
}

/// 登录凭据与用户资料的本地持久化。
class AuthStore {
  static const _keyUsername = 'auth_username';
  static const _keyPassword = 'auth_password';
  static const _keyRealName = 'auth_real_name';
  static const _keyUid = 'auth_uid';
  static const _keyAvatarUrl = 'auth_avatar_url';

  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
  }

  Future<void> saveProfile(AuthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, profile.username);
    final realName = profile.realName;
    if (realName != null && realName.isNotEmpty) {
      await prefs.setString(_keyRealName, realName);
    } else {
      await prefs.remove(_keyRealName);
    }
    final uid = profile.uid;
    if (uid != null && uid.isNotEmpty) {
      await prefs.setString(_keyUid, uid);
    } else {
      await prefs.remove(_keyUid);
    }
    final avatarUrl = profile.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await prefs.setString(_keyAvatarUrl, avatarUrl);
    } else {
      await prefs.remove(_keyAvatarUrl);
    }
  }

  Future<SavedAuth?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername) ?? '';
    if (username.isEmpty) return null;
    return SavedAuth(
      username: username,
      password: prefs.getString(_keyPassword) ?? '',
      profile: AuthProfile(
        username: username,
        realName: prefs.getString(_keyRealName),
        uid: prefs.getString(_keyUid),
        avatarUrl: prefs.getString(_keyAvatarUrl),
      ),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyRealName);
    await prefs.remove(_keyUid);
    await prefs.remove(_keyAvatarUrl);
  }
}
