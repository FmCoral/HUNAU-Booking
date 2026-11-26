import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/announcement.dart';

/// 软件公告服务：读取 R2 上的 announcements.json，按当前版本过滤。
class AnnouncementService {
  AnnouncementService._();

  static final AnnouncementService instance = AnnouncementService._();

  final _logger = AppLogger.instance;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  Future<List<Announcement>> fetch() async {
    String currentVersion = '';
    try {
      currentVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}

    final response = await _dio.get<Object?>(
      AppConstants.announcementsUrl,
      queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
      options: Options(
        headers: {'Cache-Control': 'no-cache'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) {
      throw Exception('公告加载失败 (${response.statusCode})');
    }

    final data = response.data;
    final list = data is Map ? data['items'] : null;
    if (list is! List) return const [];

    final items = list
        .whereType<Map>()
        .map((e) => Announcement.fromJson(Map<String, dynamic>.from(e)))
        .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
        .where((item) => item.matchesVersion(currentVersion))
        .toList();

    items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });

    _logger.i('Loaded ${items.length} announcements for v$currentVersion');
    return items;
  }
}
