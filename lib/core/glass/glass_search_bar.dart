import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'glass_tokens.dart';
import 'liquid_glass.dart';

/// 玻璃搜索框：44 高胶囊，内嵌无边框 [TextField]。
///
/// 传入 `controller` 时由调用方负责释放，不传则内部自建。
class GlassSearchBar extends StatefulWidget {
  const GlassSearchBar({
    super.key,
    this.controller,
    this.hint = '搜索',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.spec,
    this.trailing,
    this.textInputAction = TextInputAction.search,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final GlassSpec? spec;
  final Widget? trailing;
  final TextInputAction textInputAction;

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar> {
  TextEditingController? _owned;

  TextEditingController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _owned = TextEditingController();
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LiquidGlass(
      spec: widget.spec,
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: colors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: widget.autofocus,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: widget.textInputAction,
                cursorColor: colors.brand,
                style: AppText.bodyDense.copyWith(color: colors.text),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: widget.hint,
                  hintStyle:
                      AppText.bodyDense.copyWith(color: colors.textMuted),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final hasText = value.text.isNotEmpty;
                if (!hasText && widget.trailing == null) {
                  return const SizedBox.shrink();
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasText)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _controller.clear();
                          widget.onChanged?.call('');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.cancel,
                            size: 18,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    if (widget.trailing != null) widget.trailing!,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
