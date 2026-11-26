/// 软件公告模型，数据来自 R2 的 announcements.json。
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
    this.type = 'notice',
    this.pinned = false,
    this.linkText,
    this.linkUrl,
    this.minVersion,
    this.maxVersion,
    this.versions = const [],
  });

  final String id;
  final String title;
  final String content;
  final String publishedAt;
  final String type;
  final bool pinned;
  final String? linkText;
  final String? linkUrl;

  /// 仅对 >= minVersion 生效；为空表示不限
  final String? minVersion;

  /// 仅对 <= maxVersion 生效；为空表示不限
  final String? maxVersion;

  /// 精确匹配的版本列表；非空时优先于 min/max
  final List<String> versions;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final link = json['link'];
    return Announcement(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      publishedAt: (json['publishedAt'] ?? '').toString(),
      type: (json['type'] ?? 'notice').toString(),
      pinned: json['pinned'] == true,
      linkText: link is Map ? link['text']?.toString() : null,
      linkUrl: link is Map ? link['url']?.toString() : null,
      minVersion: json['minVersion']?.toString(),
      maxVersion: json['maxVersion']?.toString(),
      versions: json['versions'] is List
          ? (json['versions'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  /// 当前版本是否可见。
  bool matchesVersion(String current) {
    if (versions.isNotEmpty) {
      return versions.contains(current);
    }
    if (minVersion != null &&
        minVersion!.isNotEmpty &&
        compareVersion(current, minVersion!) < 0) {
      return false;
    }
    if (maxVersion != null &&
        maxVersion!.isNotEmpty &&
        compareVersion(current, maxVersion!) > 0) {
      return false;
    }
    return true;
  }

  static int compareVersion(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va > vb ? 1 : -1;
    }
    return 0;
  }
}
