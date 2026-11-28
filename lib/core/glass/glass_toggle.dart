import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'glass_tokens.dart';
import 'liquid_glass.dart';

/// 玻璃开关：52×32 轨道，滑块为白色实体圆。
class GlassToggle extends StatelessWidget {
  const GlassToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.spec,
    this.activeColor,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final GlassSpec? spec;
  final Color? activeColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? context.colors.brand;
    return LiquidGlass(
      width: 52,
      height: 32,
      spec: spec,
      borderRadius: BorderRadius.circular(999),
      tint: value ? active : null,
      tintOpacity: value ? 0.9 : null,
      pressedScale: 0.94,
      padding: const EdgeInsets.all(3),
      semanticLabel: semanticLabel,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedAlign(
        duration: GlassMotion.state,
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
