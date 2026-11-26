import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth_scope.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/course_model.dart';
import '../services/timetable_events.dart';
import '../services/timetable_storage.dart';
import '../services/ydjwxt_service.dart';
import '../widgets/empty_timetable_state.dart';
import '../widgets/weekly_calendar_view.dart';

/// 课表首页：展示周视图课表。
///
/// 登录后若本地暂无课表则自动同步一次；同步失败时在空状态提供「重新同步」按钮。
/// 手动同步入口在「我的 → 设置 → 课表同步」。
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TimetableStorage _storage = TimetableStorage();
  final YdjwxtService _service = YdjwxtService();

  List<CourseModel> _courses = const [];
  DateTime? _firstWeekMonday;
  bool _loading = true;
  bool _syncing = false;
  bool _syncFailed = false;
  String _progress = '';

  @override
  void initState() {
    super.initState();
    timetableRevision.addListener(_loadLocal);
    // 首帧之后再读登录态，initState 里不能查 InheritedWidget。
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    timetableRevision.removeListener(_loadLocal);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadLocal();
    if (!mounted) return;
    // 仅在新登录且本地无课表时自动同步，避免每次启动都请求教务系统。
    if (_courses.isEmpty && _firstWeekMonday == null) {
      unawaited(_sync());
    }
  }

  Future<void> _loadLocal() async {
    final courses = await _storage.readCourses();
    final monday = await _storage.readFirstWeekMonday();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _firstWeekMonday = monday;
      _loading = false;
    });
  }

  Future<void> _sync() async {
    if (_syncing || !mounted) return;
    if (!AuthScope.of(context).isAuthenticated) return;

    setState(() {
      _syncing = true;
      _syncFailed = false;
      _progress = '正在同步课表...';
    });

    try {
      await _service.syncTimetable(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
      );
      timetableRevision.value++;
      await _loadLocal();
    } catch (_) {
      if (!mounted) return;
      // 失败信息由空状态文案承载，不再额外弹 SnackBar 重复提示。
      setState(() => _syncFailed = true);
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
          _progress = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasTimetable = _courses.isNotEmpty && _firstWeekMonday != null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_syncing) ...[
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.brand),
              ),
              Container(
                width: double.infinity,
                color: colors.bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  _progress.isEmpty ? '正在同步课表...' : _progress,
                  style: AppText.caption.copyWith(color: colors.textMuted),
                ),
              ),
            ],
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : hasTimetable
                      ? WeeklyCalendarView(
                          courses: _courses,
                          firstWeekMonday: _firstWeekMonday!,
                          showEndTime: false,
                        )
                      : EmptyTimetableState(
                          isSyncing: _syncing,
                          onRetry:
                              _syncFailed && !_syncing ? () => _sync() : null,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
