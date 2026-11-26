import 'package:flutter/material.dart';

import '../../../core/auth_scope.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/route_utils.dart';
import '../../timetable/services/timetable_events.dart';
import '../../timetable/services/ydjwxt_service.dart';
import '../models/electricity_model.dart';
import '../services/electricity_service.dart';
import 'dorm_config_screen.dart';

/// 设置页：目前提供教务课表同步入口。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final YdjwxtService _service = YdjwxtService();

  bool _syncing = false;
  SavedElectricityRoom? _dorm;

  @override
  void initState() {
    super.initState();
    _loadDorm();
  }

  Future<void> _loadDorm() async {
    final dorm = await ElectricityService.instance.loadSavedRoom();
    if (!mounted) return;
    setState(() => _dorm = dorm);
  }

  Future<void> _openDormConfig() async {
    await Navigator.push(
      context,
      createSlideHorizontalRoute(const DormConfigScreen()),
    );
    await _loadDorm();
  }

  Future<void> _sync() async {
    if (_syncing) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!AuthScope.of(context).isAuthenticated) {
      messenger.showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }

    setState(() => _syncing = true);

    try {
      final result = await _service.syncTimetable(onProgress: (_) {});
      // 通知课表页重新读取本地文件。
      timetableRevision.value++;
      messenger.showSnackBar(
        SnackBar(content: Text('同步成功，共 ${result.courseCount} 门课程')),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      messenger.showSnackBar(SnackBar(content: Text('同步失败：$message')));
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('通用设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.lg,
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: AppRadius.cardAll,
              border: Border.all(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _syncing ? null : _sync,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        size: 22,
                        color: _syncing ? c.textMuted : c.brandText,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          '课表同步',
                          style: AppText.body.copyWith(color: c.text),
                        ),
                      ),
                      if (_syncing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: c.textMuted,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: AppRadius.cardAll,
              border: Border.all(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openDormConfig,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt_outlined,
                        size: 22,
                        color: Color(0xFFFF9800),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '宿舍配置',
                              style: AppText.body.copyWith(color: c.text),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _dorm == null
                                  ? '未选择宿舍'
                                  : '${_dorm!.areaName} ${_dorm!.buildingName} ${_dorm!.roomName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: c.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
