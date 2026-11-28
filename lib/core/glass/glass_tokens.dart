import 'package:flutter/material.dart';

/// 液态玻璃参数集。
///
/// 数值取自上游 Compose Skill 的统一规范 v2
/// （docs/skills/liquid-glass/guides/best-practices.md），按 Flutter
/// `BackdropFilter` 的能力换算：上游 blur(2dp) 的观感约等于 sigma 12，
/// 详见 .trae/skills/liquid-glass/references/parameters.md。
@immutable
class GlassSpec {
  const GlassSpec({
    required this.blurSigma,
    required this.tint,
    required this.tintOpacity,
    required this.highlightOpacity,
    required this.borderOpacity,
    required this.shadowOpacity,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.innerShadowOpacity,
    required this.innerShadowSigma,
    required this.sheenOpacity,
  });

  /// 背景模糊强度（逻辑像素）。默认 12，超过 20 在低端机明显掉帧。
  final double blurSigma;

  /// 玻璃底色，浅色用近白、深色用近黑。
  final Color tint;

  /// 底色不透明度。上游是 15%，Flutter 没有色彩振动补偿，取 0.28 保证文字对比度。
  final double tintOpacity;

  /// 常驻高光（描边亮度）。
  final double highlightOpacity;

  /// 边缘描边不透明度。
  final double borderOpacity;

  /// 外阴影不透明度与模糊半径。
  final double shadowOpacity;
  final double shadowBlur;
  final Offset shadowOffset;

  /// 内阴影：沿内边缘向内的暗部，模拟玻璃厚度。
  final double innerShadowOpacity;
  final double innerShadowSigma;

  /// 对角光晕强度。
  final double sheenOpacity;

  static const GlassSpec light = GlassSpec(
    blurSigma: 12,
    tint: Color(0xFFFAFAFA),
    tintOpacity: 0.28,
    highlightOpacity: 0.15,
    borderOpacity: 0.32,
    shadowOpacity: 0.08,
    shadowBlur: 24,
    shadowOffset: Offset(0, 8),
    innerShadowOpacity: 0.10,
    innerShadowSigma: 5,
    sheenOpacity: 0.16,
  );

  static const GlassSpec dark = GlassSpec(
    blurSigma: 12,
    tint: Color(0xFF121212),
    tintOpacity: 0.36,
    highlightOpacity: 0.15,
    borderOpacity: 0.22,
    shadowOpacity: 0.28,
    shadowBlur: 24,
    shadowOffset: Offset(0, 8),
    innerShadowOpacity: 0.28,
    innerShadowSigma: 5,
    sheenOpacity: 0.10,
  );

  /// 按当前主题亮度取默认参数。
  static GlassSpec of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  GlassSpec copyWith({
    double? blurSigma,
    Color? tint,
    double? tintOpacity,
    double? highlightOpacity,
    double? borderOpacity,
    double? shadowOpacity,
    double? shadowBlur,
    Offset? shadowOffset,
    double? innerShadowOpacity,
    double? innerShadowSigma,
    double? sheenOpacity,
  }) {
    return GlassSpec(
      blurSigma: blurSigma ?? this.blurSigma,
      tint: tint ?? this.tint,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      highlightOpacity: highlightOpacity ?? this.highlightOpacity,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      innerShadowOpacity: innerShadowOpacity ?? this.innerShadowOpacity,
      innerShadowSigma: innerShadowSigma ?? this.innerShadowSigma,
      sheenOpacity: sheenOpacity ?? this.sheenOpacity,
    );
  }
}

/// 按压与状态动画的统一节奏（对应上游 GlassAnimationSpecs）。
class GlassMotion {
  const GlassMotion._();

  static const Duration press = Duration(milliseconds: 160);
  static const Duration release = Duration(milliseconds: 280);
  static const Duration state = Duration(milliseconds: 220);

  /// 按下时的缩放；上游是线性拉伸 4dp，这里用统一缩放更稳。
  static const double pressedScale = 0.97;

  /// 按下时高光/阴影的增量，与 [press] 进度线性相乘。
  static const double pressHighlightDelta = 0.20;
  static const double pressShadowDelta = 0.22;
  static const double pressInnerShadowDelta = 0.12;
}
