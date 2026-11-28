import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'glass_tokens.dart';
import 'liquid_glass.dart';

/// 玻璃卡片：14 圆角 + 16 内边距，与 `AppRadius.card` 对齐。
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.radius = AppRadius.card,
    this.spec,
    this.tint,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final GlassSpec? spec;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      spec: spec,
      tint: tint,
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      padding: padding,
      child: child,
    );
  }
}

/// 玻璃标签：36 高的胶囊，选中态叠品牌色。
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.spec,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final GlassSpec? spec;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = selected ? colors.brandText : colors.textMuted;
    return LiquidGlass(
      spec: spec,
      tint: selected ? colors.brand : null,
      tintOpacity: selected ? 0.16 : null,
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 36,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: AppSpacing.xs + 2),
            ],
            Text(
              label,
              style: AppText.caption.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
