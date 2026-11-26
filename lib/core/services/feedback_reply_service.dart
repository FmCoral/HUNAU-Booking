import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class FeedbackItem {
  final String id;
  final String content;
  final String createdAt;
  final String reply;
  final String repliedAt;

  const FeedbackItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.reply,
    required this.repliedAt,
  });

  bool get isReplied => reply.isNotEmpty;
}

/// 反馈查询：仅在本地确认提交过反馈后，按学号拉取自己的反馈与回复。
class FeedbackReplyService {
  FeedbackReplyService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      sendTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  static String _submittedKey(String username) =>
      'feedback_submitted_$username';
  static String _seenKey(String username) => 'feedback_reply_seen_$username';

  static Future<void> markSubmitted(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_submittedKey(username), true);
    } catch (_) {}
  }

  static Future<bool> hasSubmitted(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_submittedKey(username)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<FeedbackItem>?> fetchAll(String username) async {
    try {
      final response = await _dio.post(
        AppConstants.feedbackMyEndpoint,
        data: {'username': username},
      );
      return _parseItems(response.data);
    } catch (_) {
      return null;
    }
  }

  static Future<List<FeedbackItem>> fetchNewReplies(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_submittedKey(username)) ?? false)) return [];

      final lastSeen = prefs.getString(_seenKey(username)) ?? '';
      final response = await _dio.post(
        AppConstants.feedbackMyEndpoint,
        data: {'username': username},
      );
      final items = _parseItems(response.data);
      final fresh = items
          .where((item) => item.isReplied && item.repliedAt.compareTo(lastSeen) > 0)
          .toList();
      if (fresh.isNotEmpty) {
        await markSeen(username, fresh.first.repliedAt);
      }
      return fresh;
    } catch (_) {
      return [];
    }
  }

  static Future<void> markSeen(String username, String repliedAt) async {
    if (repliedAt.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(_seenKey(username)) ?? '';
      if (repliedAt.compareTo(lastSeen) > 0) {
        await prefs.setString(_seenKey(username), repliedAt);
      }
    } catch (_) {}
  }

  static List<FeedbackItem> _parseItems(dynamic data) {
    final list = data is Map ? data['items'] : null;
    if (list is! List) return const [];

    final items = <FeedbackItem>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      items.add(
        FeedbackItem(
          id: (raw['id'] ?? '').toString(),
          content: (raw['content'] ?? '').toString(),
          createdAt: (raw['createdAt'] ?? '').toString(),
          reply: (raw['reply'] ?? '').toString(),
          repliedAt: (raw['repliedAt'] ?? '').toString(),
        ),
      );
    }
    return items;
  }
}
