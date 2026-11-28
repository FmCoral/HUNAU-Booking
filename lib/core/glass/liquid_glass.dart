import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'glass_tokens.dart';

/// 液态玻璃容器。
///
/// 渲染顺序与上游一致：模糊背景 → 底色 → 对角光晕 → 内阴影与描边 → 外阴影；
/// 可点时叠加按压缩放与光影增强。
///
/// 注意：Flutter 的 [BackdropFilter] 只能模糊，无法像 Backdrop 库那样做真实折射，
/// 折射感由描边、内阴影与光晕近似，参数含义见 docs/skills/liquid-glass/。
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.spec,
    this.tint,
    this.tintOpacity,
    this.onTap,
    this.onLongPress,
    this.pressedScale = GlassMotion.pressedScale,
    this.enableBlur = true,
    this.followPointer = true,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final Widget child;

  /// 圆角；胶囊用 `BorderRadius.circular(height / 2)`。
  final BorderRadius borderRadius;

  /// 覆盖默认参数，一般按主题取 `GlassSpec.of(context)`。
  final GlassSpec? spec;

  /// 覆盖底色（例如选中态的强调色）。
  final Color? tint;
  final double? tintOpacity;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final double pressedScale;

  /// 关闭模糊后只剩半透明底色，用于玻璃叠玻璃或低端机降级。
  final bool enableBlur;

  /// 光晕是否跟随手指位置。
  final bool followPointer;

  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: GlassMotion.press,
    reverseDuration: GlassMotion.release,
  );
  Offset? _pointer;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec ?? GlassSpec.of(context);
    return AnimatedBuilder(
      animation: _press,
      builder: (context, _) {
        final p = Curves.easeOutCubic.transform(_press.value);
        return Transform.scale(
          scale: 1 - (1 - widget.pressedScale) * p,
          child: _buildGlass(context, spec, p),
        );
      },
    );
  }

  Widget _buildGlass(BuildContext context, GlassSpec spec, double p) {
    final radius = widget.borderRadius;
    final tint = widget.tint ?? spec.tint;
    final tintOpacity = widget.tintOpacity ?? spec.tintOpacity;

    Widget body = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: tint.withValues(alpha: tintOpacity),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  _buildSheen(spec, p, constraints.biggest),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GlassEdgePainter(
                radius: radius,
                borderOpacity: spec.borderOpacity,
                highlightOpacity: spec.highlightOpacity,
                innerShadowOpacity: spec.innerShadowOpacity,
                innerShadowSigma: spec.innerShadowSigma,
                progress: p,
              ),
            ),
          ),
        ),
        Padding(padding: widget.padding, child: widget.child),
      ],
    );

    if (widget.enableBlur) {
      body = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: spec.blurSigma,
          sigmaY: spec.blurSigma,
        ),
        child: body,
      );
    }

    Widget glass = ClipRRect(borderRadius: radius, child: body);
    if (_interactive) {
      glass = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleDown,
        onTapUp: (_) => _handleRelease(),
        onTapCancel: _handleRelease,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _handleRelease();
                widget.onLongPress!();
              },
        child: glass,
      );
    }

    if (widget.semanticLabel != null) {
      glass = Semantics(
        label: widget.semanticLabel,
        button: _interactive,
        child: glass,
      );
    }

    return RepaintBoundary(
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: spec.shadowOpacity + GlassMotion.pressShadowDelta * p,
              ),
              blurRadius: spec.shadowBlur,
              offset: spec.shadowOffset,
            ),
          ],
        ),
        child: glass,
      ),
    );
  }

  Widget _buildSheen(GlassSpec spec, double p, Size size) {
    final anchor = widget.followPointer && _pointer != null
        ? _pointer!
        : Offset(size.width * 0.28, -size.height * 0.15);
    final center = Alignment(
      size.width == 0 ? -0.5 : (anchor.dx / size.width) * 2 - 1,
      size.height == 0 ? -1 : (anchor.dy / size.height) * 2 - 1,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: 1.1,
          colors: [
            Colors.white.withValues(
              alpha: spec.sheenOpacity +
                  GlassMotion.pressHighlightDelta * p * 0.5,
            ),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  void _handleDown(TapDownDetails details) {
    _pointer = details.localPosition;
    _press.forward();
  }

  void _handleRelease() {
    _pointer = null;
    _press.reverse();
  }
}

/// 内阴影 + 高光描边。上游是独立的效果层，这里用一次 CustomPaint 近似。
class _GlassEdgePainter extends CustomPainter {
  const _GlassEdgePainter({
    required this.radius,
    required this.borderOpacity,
    required this.highlightOpacity,
    required this.innerShadowOpacity,
    required this.innerShadowSigma,
    required this.progress,
  });

  final BorderRadius radius;
  final double borderOpacity;
  final double highlightOpacity;
  final double innerShadowOpacity;
  final double innerShadowSigma;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rrect = radius.toRRect(Offset.zero & size).deflate(0.5);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.black.withValues(
        alpha: (innerShadowOpacity + GlassMotion.pressInnerShadowDelta * progress)
            .clamp(0.0, 1.0),
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, innerShadowSigma);
    canvas.drawRRect(rrect, inner);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(
        alpha:
            (borderOpacity + GlassMotion.pressHighlightDelta * progress * 0.6)
                .clamp(0.0, 1.0),
      );
    canvas.drawRRect(rrect, border);

    if (highlightOpacity > 0) {
      final topGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.1, 0),
          Offset(size.width * 0.9, size.height * 0.6),
          [
            Colors.white.withValues(alpha: highlightOpacity),
            Colors.white.withValues(alpha: 0),
          ],
        );
      canvas.drawRRect(rrect, topGlow);
    }
  }

  @override
  bool shouldRepaint(_GlassEdgePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.radius != radius ||
      oldDelegate.borderOpacity != borderOpacity ||
      oldDelegate.highlightOpacity != highlightOpacity ||
      oldDelegate.innerShadowOpacity != innerShadowOpacity ||
      oldDelegate.innerShadowSigma != innerShadowSigma;
}
