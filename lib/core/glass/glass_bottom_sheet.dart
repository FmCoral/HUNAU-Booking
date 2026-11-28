import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'glass_tokens.dart';
import 'liquid_glass.dart';

/// 打开液态玻璃底部弹窗。
///
/// 弹窗内容高度自适应，最多占屏幕 [maxHeightFactor]；
/// 需要滚动的长内容由调用方在 `builder` 里用 `Flexible` + `SingleChildScrollView`。
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightFactor = 0.88,
  bool dismissible = true,
  GlassSpec? spec,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    elevation: 0,
    isDismissible: dismissible,
    enableDrag: dismissible,
    builder: (sheetContext) {
      final padding = MediaQuery.viewInsetsOf(sheetContext);
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * maxHeightFactor;
      return Padding(
        padding: EdgeInsets.only(bottom: padding.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: GlassBottomSheetSurface(
            spec: spec,
            child: SizedBox(
              width: double.infinity,
              child: builder(sheetContext),
            ),
          ),
        ),
      );
    },
  );
}

/// 底部弹窗的玻璃底板：顶部 20 圆角 + 拖拽把手。
class GlassBottomSheetSurface extends StatelessWidget {
  const GlassBottomSheetSurface({
    super.key,
    required this.child,
    this.spec,
    this.showHandle = true,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 20),
  });

  final Widget child;
  final GlassSpec? spec;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LiquidGlass(
      spec: spec,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
