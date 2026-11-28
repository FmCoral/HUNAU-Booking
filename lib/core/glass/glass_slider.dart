import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'glass_tokens.dart';
import 'liquid_glass.dart';

/// 玻璃滑块：轨道内嵌在玻璃条里，按下/拖动直接用指针位置换算取值。
///
/// 传 `divisions` 时按等分离散（如 1–7 档），否则连续。
class GlassSlider extends StatelessWidget {
  const GlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.spec,
    this.activeColor,
    this.label,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final GlassSpec? spec;
  final Color? activeColor;
  final String? label;
  final String? semanticLabel;

  double get _progress {
    if (max <= min) return 0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  void _update(Offset local, double width) {
    final onChanged = this.onChanged;
    if (onChanged == null || width <= 0) return;
    final ratio = (local.dx / width).clamp(0.0, 1.0);
    final raw = min + ratio * (max - min);
    final divisions = this.divisions;
    if (divisions == null) {
      onChanged(raw);
    } else {
      final step = (max - min) / divisions;
      onChanged(min + ((raw - min) / step).round() * step);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = activeColor ?? colors.brand;
    final trackColor = colors.border.withValues(alpha: 0.65);

    return LiquidGlass(
      spec: spec,
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      semanticLabel: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppText.caption.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _update(details.localPosition, width),
                onHorizontalDragStart: (details) =>
                    _update(details.localPosition, width),
                onHorizontalDragUpdate: (details) =>
                    _update(details.localPosition, width),
                child: SizedBox(
                  height: 22,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: trackColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: active,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(
                          _progress * 2 - 1,
                          0,
                        ),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
