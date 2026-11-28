// For a complete navigation bar with indicator animation, state management,
// backdrop setup, and full usage example, see glass-navigation-bar.kt
//
// This file provides a minimal wrapper. For production use, prefer the
// comprehensive template which includes DampedDragAnimation, InteractiveHighlight,
// and a ready-to-run GlassNavigationBarExample.

package com.kyant.backdrop.catalog

import androidx.compose.foundation.layout.RowScope
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.catalog.components.LiquidBottomTab
import com.kyant.backdrop.catalog.components.LiquidBottomTabs

/**
 * 液态玻璃底部导航栏模板
 *
 * 本模板直接委托 [LiquidBottomTabs] 完整实现，包含官方源码的全部交互层：
 * - 玻璃容器本体（drawBackdrop + Capsule + vibrancy/blur/lens）
 * - 拖拽滑动切换（DampedDragAnimation + 面板偏移动画）
 * - 点击切换（LiquidBottomTab 的 clickable + 归位动画）
 * - 按压效果（InteractiveHighlight 光晕跟随指示器）
 * - 按压时面板效果（layerBlock 缩放、lens 渐进、highlight/shadow/innerShadow/表面色）
 * - 指示器动画（位置 + 缩放 + 速度剪切变形）
 * - 按压缩放传递（LocalLiquidBottomTabScale 1.0→1.2）
 * - 亮/暗主题适配
 *
 * 用户只需调用本组件一次，无需再实现任何交互逻辑。
 *
 * @param selectedTabIndex 当前选中索引
 * @param onTabSelected 选中回调
 * @param backdrop 背景源
 * @param tabsCount 标签数量
 * @param modifier 修饰符
 * @param content 标签内容（建议配合 [LiquidBottomTab] 使用）
 */
@Composable
fun GlassBottomBar(
    selectedTabIndex: () -> Int,
    onTabSelected: (index: Int) -> Unit,
    backdrop: Backdrop,
    tabsCount: Int,
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit
) {
    LiquidBottomTabs(
        selectedTabIndex = selectedTabIndex,
        onTabSelected = onTabSelected,
        backdrop = backdrop,
        tabsCount = tabsCount,
        modifier = modifier,
        content = content
    )
}
