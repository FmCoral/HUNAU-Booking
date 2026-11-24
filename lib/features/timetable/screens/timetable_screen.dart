import 'package:flutter/material.dart';

import '../../../core/auth_scope.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/course_model.dart';
import '../services/timetable_storage.dart';
import '../services/ydjwxt_service.dart';
import '../widgets/empty_timetable_state.dart';
import '../widgets/weekly_calendar_view.dart';

/// 课表首页：展示周视图课表，右上角刷新按钮手动同步教务课表。
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
  String _progress = '';

  @override
  void initState() {
    super.initState();
    _loadLocal();
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
    if (_syncing) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!AuthScope.of(context).isAuthenticated) {
      messenger.showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }

    setState(() {
      _syncing = true;
      _progress = '正在同步课表...';
    });

    try {
      final result = await _service.syncTimetable(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
        firstWeekMonday: _firstWeekMonday,
        context: context,
      );

      final courses = await _storage.readCourses();
      final monday = await _storage.readFirstWeekMonday();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _firstWeekMonday = monday;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('同步成功，共 ${result.courseCount} 门课程')),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      messenger.showSnackBar(
        SnackBar(content: Text('同步失败：$message')),
      );
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
      appBar: AppBar(
        title: const Text('课表'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              tooltip: '同步课表',
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_syncing)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(colors.brand),
            ),
          if (_syncing)
            Container(
              width: double.infinity,
              color: colors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.page,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                _progress.isEmpty ? '正在同步课表...' : _progress,
                style: AppText.caption.copyWith(color: colors.textMuted),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : hasTimetable
                    ? WeeklyCalendarView(
                        courses: _courses,
                        firstWeekMonday: _firstWeekMonday!,
                        showEndTime: false,
                      )
                    : EmptyTimetableState(isSyncing: _syncing),
          ),
        ],
      ),
    );
  }
}
