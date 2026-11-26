import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/auth_cookies.dart';
import '../../../core/utils/app_logger.dart';
import '../models/message_model.dart';

/// 超星通知公告服务，接口与牛×5 一致。
class NoticeService {
  NoticeService._();

  static final NoticeService instance = NoticeService._();

  final _logger = AppLogger.instance;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  String _cookieHeader(Uri uri) {
    final values = <String>[];
    final seen = <String>{};
    for (final entry in AuthCookies.all.entries) {
      for (final cookie in entry.value) {
        final domain = cookie.domain;
        final matched = domain == null || domain.isEmpty
            ? entry.key.host == uri.host
            : uri.host == domain.replaceFirst(RegExp(r'^\.'), '') ||
                uri.host.endsWith(
                  domain.startsWith('.') ? domain : '.$domain',
                );
        if (!matched) continue;
        if (!seen.add(cookie.name)) continue;
        values.add('${cookie.name}=${cookie.value}');
      }
    }
    return values.join('; ');
  }

  Options _options(Uri uri) {
    return Options(
      contentType: Headers.formUrlEncodedContentType,
      headers: {
        'User-Agent': AppConstants.campusCardUA,
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://notice.chaoxing.com/pc/notice/myNotice',
        'Cookie': _cookieHeader(uri),
      },
    );
  }

  /// 获取通知列表，[lastValue] 为分页标记，第一页传空。
  Future<NoticeResult> fetchMessageList({String? lastValue}) async {
    final uri = Uri.parse(AppConstants.chaoxingNoticeListUrl);
    try {
      final response = await _dio.post<Object?>(
        uri.toString(),
        data: {
          'type': 2,
          'notice_type': '',
          'lastValue': lastValue ?? '',
          'sort': '',
          'folderUUID': '',
          'kw': '',
          'startTime': '',
          'endTime': '',
          'gKw': '',
          'gName': '',
          'year': DateTime.now().year,
          'tag': '',
          'fidsCode': '',
          'queryFolderNoticePrevYear': 0,
          'filterSenderPuids': '',
          'filterTags': '',
        },
        options: _options(uri),
      );

      if (response.statusCode != 200) {
        throw Exception('获取通知列表失败: HTTP ${response.statusCode}');
      }

      final data = response.data;
      if (data is! Map) {
        return NoticeResult(messages: const [], hasMore: false);
      }

      final notices = data['notices'];
      if (notices is! Map) {
        final errorMsg = data['errorMsg']?.toString();
        if (errorMsg != null && errorMsg.isNotEmpty) {
          throw Exception('公告接口返回错误: $errorMsg');
        }
        return NoticeResult(messages: const [], hasMore: false);
      }

      final list = notices['list'];
      if (list is! List || list.isEmpty) {
        return NoticeResult(messages: const [], hasMore: false);
      }

      final nextLastValue = notices['lastGetId']?.toString();
      final messages = list
          .whereType<Map>()
          .map((e) => MessageModel.fromChaoxingJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      return NoticeResult(
        messages: messages,
        nextLastValue: nextLastValue,
        hasMore: nextLastValue != null && nextLastValue.isNotEmpty,
      );
    } catch (e) {
      _logger.e('Fetch notices failed: $e');
      rethrow;
    }
  }

  /// 获取通知详情。
  Future<Map<String, dynamic>> fetchNoticeDetail(String uuid) async {
    final uri = Uri.parse(
      '${AppConstants.chaoxingNoticeBaseUrl}/pc/notice/$uuid/getNoticeDetail?sendTag=0',
    );
    final response = await _dio.get<Object?>(
      uri.toString(),
      options: Options(
        headers: {
          'User-Agent': AppConstants.campusCardUA,
          'Referer': 'https://notice.chaoxing.com/pc/notice/myNotice',
          'Cookie': _cookieHeader(uri),
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('获取通知详情失败: HTTP ${response.statusCode}');
    }
    final data = response.data;
    if (data is! Map || data['status'] != true) {
      throw Exception('公告详情加载失败');
    }
    final msg = data['msg'];
    if (msg is! Map) throw Exception('公告详情为空');
    return Map<String, dynamic>.from(msg);
  }

  /// 标记通知为已读。
  Future<void> setNoticeRead(String noticeId) async {
    final uri = Uri.parse(
      '${AppConstants.chaoxingNoticeBaseUrl}/mobile/notice/setNoticeRead?noticeId=$noticeId',
    );
    try {
      await _dio.get<Object?>(
        uri.toString(),
        options: Options(
          headers: {
            'User-Agent': AppConstants.campusCardUA,
            'Cookie': _cookieHeader(uri),
          },
        ),
      );
    } catch (e) {
      _logger.w('Mark notice read failed: $e');
    }
  }
}
