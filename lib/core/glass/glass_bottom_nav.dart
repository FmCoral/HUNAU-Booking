import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'glass_tokens.dart';
import 'liquid_glass.dart';

/// 底部导航项。
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

/// 悬浮胶囊玻璃底栏，指示器为品牌色浅底。
///
/// 放在 Stack 底部或 Scaffold 的 bottomNavigationBar 位置；
/// 内容页需要预留 [margin] 对应的高度。
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.spec,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final GlassSpec? spec;
  final EdgeInsets margin;

  /// 底栏本体加默认下边距占用的高度，不含系统安全区。
  ///
  /// 可滚动页面给内容底部预留
  /// `MediaQuery.paddingOf(context).bottom + GlassBottomNav.contentInset`。
  static const double contentInset = 76;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: margin,
      child: LiquidGlass(
        spec: spec,
        borderRadius: BorderRadius.circular(999),
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(child: _GlassNavTab(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              )),
          ],
        ),
      ),
    );
  }
}

class _GlassNavTab extends StatelessWidget {
  const _GlassNavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.brandText : colors.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: GlassMotion.state,
        curve: Curves.easeOutCubic,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? colors.brand.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? (item.activeIcon ?? item.icon) : item.icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
