// BuildContext 只透传给认证服务用于展示验证弹窗；认证服务内部会校验 mounted。
// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/ydjwxt_auth_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/course_model.dart';
import '../parsers/ydjwxt_json_parser.dart';
import 'timetable_storage.dart';

/// 课表同步结果模型
class TimetableSyncResult {
  final bool success;
  final int courseCount;
  final String? message;

  const TimetableSyncResult({
    required this.success,
    this.courseCount = 0,
    this.message,
  });
}

/// 移动教务系统课表同步（精简版：仅抓取 20 周课程并落盘）。
class YdjwxtService {
  final _logger = AppLogger.instance;
  final _authService = YdjwxtAuthService();
  String? _token;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      validateStatus: (_) => true,
    ),
  );

  /// 学期最大周数（接口按周返回，无整学期接口）
  static const int _maxWeeks = 20;

  /// 单周请求的最大并发数，避免一次性 20 个请求打爆学校网关
  static const int _maxConcurrentFetches = 4;

  /// 单个请求的重试次数
  static const int _maxFetchAttempts = 3;

  /// 单飞互斥：同一时间仅允许一个在途同步，并发调用直接复用该 Future
  static Future<TimetableSyncResult>? _syncInProgress;

  /// 全自动同步课表。
  ///
  /// 同步是原子的：开始前把本地课表备份为 .bak，任何一步失败都会回滚，
  /// 保证旧课表不受损。
  Future<TimetableSyncResult> syncTimetable({
    required Function(String progress) onProgress,
    DateTime? firstWeekMonday,
    BuildContext? context,
  }) async {
    if (_syncInProgress != null) {
      _logger.i('⏳ Timetable sync already in progress, joining...');
      onProgress('课表同步已在进行中...');
      return await _syncInProgress!;
    }

    final future = _doSyncTimetable(
      onProgress: onProgress,
      firstWeekMonday: firstWeekMonday,
      context: context,
    );
    _syncInProgress = future;

    try {
      return await future;
    } finally {
      _syncInProgress = null;
    }
  }

  Future<TimetableSyncResult> _doSyncTimetable({
    required Function(String progress) onProgress,
    DateTime? firstWeekMonday,
    BuildContext? context,
  }) async {
    final storage = TimetableStorage();

    TimetableBackup? backup;
    try {
      backup = await TimetableBackup.capture();
    } catch (e) {
      _logger.w('⚠️ Failed to backup local timetable: $e');
    }

    try {
      _logger.i('🚀 Starting timetable sync (YDJWXT)...');

      // 1. 获取 Token
      onProgress('正在进行身份验证...');
      _token = await _authService.getToken();

      // 2. 预检：确定第一周周一（预检的第 1 周结果直接复用）
      DateTime? calculatedFirstWeekMonday = firstWeekMonday;
      Map<String, dynamic>? firstWeekRaw;

      if (calculatedFirstWeekMonday == null) {
        onProgress('正在校准学期时间...');
        firstWeekRaw = await _fetchRawWeekJson(1, context);
        calculatedFirstWeekMonday =
            YdjwxtJsonParser.extractFirstWeekMonday(firstWeekRaw);
        _logger.i('📅 Calculated firstWeekMonday: $calculatedFirstWeekMonday');
      }

      calculatedFirstWeekMonday ??= await storage.readFirstWeekMonday();
      calculatedFirstWeekMonday ??=
          TimetableStorage.guessFirstWeekMonday();

      // 3. 限流并发获取全部周数据
      onProgress('正在同步全学期课表...');
      final results = await _fetchAllWeeks(
        firstWeekRaw: firstWeekRaw,
        context: context,
      );

      final allWeeksData = <List<CourseModel>>[];
      for (final rawJson in results) {
        allWeeksData.add(YdjwxtJsonParser.parseWeekJson(rawJson));
      }

      // 4. 解析与合并
      onProgress('正在整理课程数据...');
      final mergedCourses = YdjwxtJsonParser.mergeWeeks(allWeeksData);
      _logger.i('✨ Total unique courses merged: ${mergedCourses.length}');

      if (mergedCourses.isEmpty) {
        throw Exception('未能获取到有效的课程数据，请确认本学期是否有课。');
      }

      // 5. 保存结果
      onProgress('正在保存到本地...');
      await storage.saveCourses(mergedCourses);
      await storage.saveFirstWeekMonday(calculatedFirstWeekMonday);

      if (backup != null) {
        await backup.cleanup();
      }

      final msg = '同步成功，共 ${mergedCourses.length} 门课程';
      onProgress(msg);
      _logger.i('🎉 YDJWXT sync completed.');

      return TimetableSyncResult(
        success: true,
        courseCount: mergedCourses.length,
        message: msg,
      );
    } catch (e) {
      _logger.e('❌ YDJWXT sync failed: $e');
      if (backup != null) await backup.restore();
      rethrow;
    }
  }

  /// 限流并发获取 1~20 周数据；预检已取到的第 1 周直接复用。
  Future<List<Map<String, dynamic>>> _fetchAllWeeks({
    Map<String, dynamic>? firstWeekRaw,
    BuildContext? context,
  }) async {
    final results = List<Map<String, dynamic>?>.filled(_maxWeeks, null);
    if (firstWeekRaw != null) results[0] = firstWeekRaw;

    final pendingWeeks = [
      for (var week = 1; week <= _maxWeeks; week++)
        if (results[week - 1] == null) week,
    ];
    var nextIndex = 0;

    Future<void> worker() async {
      while (nextIndex < pendingWeeks.length) {
        final index = nextIndex++;
        // 请求间轻微错峰，避免多个 worker 同时打到学校网关
        if (index > 0) {
          await Future.delayed(const Duration(milliseconds: 80));
        }
        final week = pendingWeeks[index];
        results[week - 1] = await _fetchRawWeekJson(week, context);
      }
    }

    final workerCount = pendingWeeks.length < _maxConcurrentFetches
        ? pendingWeeks.length
        : _maxConcurrentFetches;
    await Future.wait(List.generate(workerCount, (_) => worker()));

    return [for (final json in results) json!];
  }

  /// 获取单周课表原始 JSON。
  ///
  /// 对超时/连接异常和 5xx 做退避重试；401 时刷新 token 后重试。
  Future<Map<String, dynamic>> _fetchRawWeekJson(
    int week,
    BuildContext? context,
  ) async {
    final url = '${AppConstants.ydjwxtApiUrl}?week=$week&kbjcmsid=';

    for (var attempt = 1; attempt <= _maxFetchAttempts; attempt++) {
      if (_token == null) throw Exception('Token is null');

      try {
        final response = await _dio.post(
          url,
          options: Options(
            headers: {
              'token': _token,
              'User-Agent': AppConstants.ydjwxtUA,
              'Referer': 'https://ydjwxt.hunau.edu.cn/hnnydx/',
              'Accept': 'application/json, text/plain, */*',
              'Origin': 'https://ydjwxt.hunau.edu.cn',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          final rawData = response.data;
          if (rawData is Map<String, dynamic>) return rawData;
        }

        final status = response.statusCode;

        if (status == 401 && attempt < _maxFetchAttempts) {
          _logger.w('🔑 Token expired while fetching week $week, refreshing...');
          _token = await _authService.getToken(forceRefresh: true);
          continue;
        }

        if (status != null && status >= 500 && attempt < _maxFetchAttempts) {
          await Future.delayed(Duration(milliseconds: 200 * attempt));
          continue;
        }

        throw Exception('HTTP $status while fetching week $week');
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final retryable = status == null || status >= 500;
        if (!retryable || attempt == _maxFetchAttempts) rethrow;
        _logger.w('Fetch week $week failed (attempt $attempt): $e, retrying...');
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      }
    }

    throw Exception('Failed to fetch week $week after $_maxFetchAttempts attempts');
  }
}
