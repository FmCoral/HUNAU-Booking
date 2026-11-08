class AuthProfile {
  const AuthProfile({
    required this.username,
    this.realName,
    this.uid,
    this.avatarUrl,
  });

  final String username;
  final String? realName;

  /// 超星账号 uid，用于拼接头像地址
  final String? uid;

  /// 头像地址（photo.chaoxing.com）
  final String? avatarUrl;

  String get displayName {
    final name = realName?.trim() ?? '';
    return name.isEmpty ? username : name;
  }

  AuthProfile copyWith({String? realName, String? uid, String? avatarUrl}) {
    return AuthProfile(
      username: username,
      realName: realName ?? this.realName,
      uid: uid ?? this.uid,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
