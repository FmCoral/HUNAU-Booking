import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'glass_tokens.dart';
import 'liquid_glass.dart';

/// 液态玻璃按钮：默认 48 高的胶囊，带按压缩放。
///
/// 只用于浮在内容/图片之上的场景。常规表单与主操作仍用
/// `ElevatedButton` / `OutlinedButton`（见 app_theme.dart）。
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.spec,
    this.height = 48,
    this.pill = true,
    this.expand = false,
    this.foreground,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final GlassSpec? spec;
  final double height;
  final bool pill;
  final bool expand;
  final Color? foreground;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? context.colors.text;
    return LiquidGlass(
      spec: spec,
      borderRadius: BorderRadius.circular(pill ? height / 2 : AppRadius.control),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyDense.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 圆形玻璃图标按钮，默认 42（与上游 GlassIconButton 一致）。
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconSize,
    this.tooltip,
    this.spec,
    this.foreground,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double? iconSize;
  final String? tooltip;
  final GlassSpec? spec;
  final Color? foreground;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final button = LiquidGlass(
      width: size,
      height: size,
      spec: spec,
      borderRadius: BorderRadius.circular(size / 2),
      onTap: onTap,
      pressedScale: 0.92,
      semanticLabel: semanticLabel,
      child: Center(
        child: Icon(
          icon,
          size: iconSize ?? size * 0.44,
          color: foreground ?? context.colors.text,
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
