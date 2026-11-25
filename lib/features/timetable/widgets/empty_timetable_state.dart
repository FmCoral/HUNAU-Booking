import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/l10n_extension.dart';

/// 课表空状态组件
class EmptyTimetableState extends StatelessWidget {
  /// 自动同步是否开启。
  final bool autoSyncEnabled;

  /// 是否正在后台执行自动同步。仅在自动同步开启且真正同步中时显示“正在同步”及转圈；
  /// 同步完成后或关闭时退出转圈，显示暂无课表并提示点刷新按钮手动同步。
  final bool isSyncing;

  /// 自动同步失败后的重试回调；为空时不显示按钮。
  final VoidCallback? onRetry;

  const EmptyTimetableState({
    super.key,
    this.autoSyncEnabled = true,
    this.isSyncing = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showLoading = autoSyncEnabled && isSyncing;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: colors.statusBg(colors.brand),
                shape: BoxShape.circle,
              ),
              child: Icon(
                showLoading
                    ? Icons.calendar_today_outlined
                    : (autoSyncEnabled
                        ? Icons.calendar_today_outlined
                        : Icons.cloud_off_outlined),
                size: 64,
                color: colors.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              showLoading
                  ? context.l10n.timetableSyncing
                  : (onRetry != null ? '同步失败，稍后再试' : context.l10n.noLocalTimetable),
              textAlign: TextAlign.center,
              style: AppText.pageTitle.copyWith(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              showLoading
                  ? context.l10n.timetableSyncingDesc
                  : (onRetry != null
                      ? '请检查在“智慧湘农-教务系统”能否正常进入'
                      : context.l10n.tapRefreshButtonToSync),
              textAlign: TextAlign.center,
              style:
                  AppText.bodyDense.copyWith(color: colors.textMuted, height: 1.5),
            ),
            if (onRetry != null && !showLoading) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 44),
                ),
                child: const Text('重新同步'),
              ),
            ],
            if (showLoading) ...[
              const SizedBox(height: AppSpacing.xxxl),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
