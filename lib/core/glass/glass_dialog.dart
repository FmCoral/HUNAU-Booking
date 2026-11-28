import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'liquid_glass.dart';

/// 液态玻璃对话框。按钮由调用方传入（建议 `TextButton`）。
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  List<Widget> actions = const [],
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (dialogContext) {
      final colors = dialogContext.colors;
      return Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: LiquidGlass(
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.sectionTitle.copyWith(color: colors.text),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: AppText.bodyDense.copyWith(color: colors.textMuted),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: AppSpacing.md),
                content,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
              ],
            ],
          ),
        ),
      );
    },
  );
}
