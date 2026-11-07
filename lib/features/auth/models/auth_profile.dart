class AuthProfile {
  const AuthProfile({required this.username, this.realName});

  final String username;
  final String? realName;

  String get displayName {
    final name = realName?.trim() ?? '';
    return name.isEmpty ? username : name;
  }
}
