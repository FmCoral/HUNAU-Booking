/*
 * Copyright (c) 2026
 *
 * This file is derived from AndroidLiquidGlass (Backdrop):
 * https://github.com/Kyant0/AndroidLiquidGlass
 * Copyright (c) Kyant0 and contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * 液态玻璃底部导航栏完整模板
 *
 * ## 模板说明
 * 本模板演示如何使用 [LiquidBottomTabs] + [LiquidBottomTab] 构建一个完整的底部导航栏，
 * 包含 4 个标签页（图标 + 文字）、指示器滑动动画、拖拽切换和按压缩放效果。
 *
 * ## 关键特性
 * - **指示器动画**：点击标签时，液态玻璃指示器使用弹簧物理（spring）平滑滑动到目标位置
 * - **拖拽切换**：支持左右拖拽滑动切换标签，松手后自动吸附到最近标签
 * - **按压形变**：按住指示器时，玻璃面板产生缩放、透镜折射渐变和光影增强
 * - **按压缩放传递**：通过 CompositionLocal 将按压缩放传递给每个标签项（1.0 → 1.2）
 * - **速度剪切变形**：松手瞬间的速度使指示器产生 X/Y 方向的非均匀拉伸
 *
 * ## 依赖
 * - `backdrop` 库（`com.kyant.backdrop`）— 液态玻璃渲染核心
 * - `shapes` 库（`com.kyant.shapes`）— Capsule 胶囊形状
 *
 * ## 需要复制的 Skill 文件
 * 1. `components/LiquidBottomTabs.kt` — 底部标签栏容器（主组件）
 * 2. `components/LiquidBottomTab.kt` — 单个标签项
 * 3. `utils/DampedDragAnimation.kt` — 拖拽动画控制器（指示器位置 + 缩放 + 速度）
 * 4. `utils/InteractiveHighlight.kt` — 按压交互式高光（光晕跟随指示器）
 * 5. `utils/DragGestureInspector.kt` — 拖拽手势检测（被 DampedDragAnimation 依赖）
 *
 * ## 设置步骤
 * 1. 将上述 5 个 Skill 文件复制到你的项目（保持 `com.kyant.backdrop.catalog` 包路径）
 * 2. 在 `build.gradle.kts` 中添加 backdrop 和 shapes 库依赖
 * 3. 将本模板中的 [GlassNavigationBar] 和 [GlassNavigationBarExample] 复制到你的代码
 * 4. 在你的页面中调用 `GlassNavigationBarExample()` 即可运行
 *
 * ## 指示器动画原理
 * [DampedDragAnimation] 管理指示器位置（`0f..(tabsCount-1).toFloat()` 的浮点值）：
 * - **点击标签** → 调用 `animateToValue(targetIndex.toFloat())` 触发弹簧动画
 * - **拖拽** → 实时更新值，松手后吸附到最近的整数索引
 * - **指示器位置** → `graphicsLayer.translationX = dampedDragAnimation.value * tabWidth`
 * - **速度变形** → 松手瞬间的速度使指示器 X/Y 方向产生非均匀缩放
 *   （`scaleX /= 1 - velocity * 0.75`，`scaleY *= 1 - velocity * 0.25`）
 * - **面板偏移** → 拖拽时整个面板产生轻微位移（`panelOffset = 4dp * sign(fraction) * EaseOut(abs(fraction))`）
 *
 * ## Backdrop 层级
 * ```
 * 页面内容 ──layerBackdrop──> pageBackdrop
 *                                          └──rememberCombinedBackdrop──> combinedBackdrop
 * 外部 backdrop ──────────────────────────────────────────────────────┘
 * LiquidBottomTabs(backdrop = combinedBackdrop)
 *   └── rememberLayerBackdrop() → tabsBackdrop（用于指示器的组合背景）
 *   └── rememberCombinedBackdrop(combinedBackdrop, tabsBackdrop) → 指示器背景
 * ```
 */

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.backdrops.LayerBackdrop
import com.kyant.backdrop.backdrops.layerBackdrop
import com.kyant.backdrop.backdrops.rememberCombinedBackdrop
import com.kyant.backdrop.backdrops.rememberLayerBackdrop
import com.kyant.backdrop.catalog.components.LiquidBottomTab
import com.kyant.backdrop.catalog.components.LiquidBottomTabs

// ─────────────────────────────────────────────────────────────────────────────
// 标签数据
// ─────────────────────────────────────────────────────────────────────────────

/** 导航标签定义 */
data class GlassNavTab(
    val title: String,
    val selectedIcon: String,
    val unselectedIcon: String
)

/** 默认标签配置 — 可替换为你的应用标签 */
private val DEFAULT_NAV_TABS = listOf(
    GlassNavTab("首页", "⊕", "⊙"),
    GlassNavTab("探索", "◉", "◈"),
    GlassNavTab("消息", "●", "◉"),
    GlassNavTab("我的", "◈", "◎")
)

// ─────────────────────────────────────────────────────────────────────────────
// 核心组件：GlassNavigationBar
// ─────────────────────────────────────────────────────────────────────────────

/**
 * 液态玻璃底部导航栏
 *
 * 可直接嵌入应用的底部导航区域。内部委托 [LiquidBottomTabs] 完成全部交互逻辑，
 * 包括指示器动画、拖拽切换、按压缩放和速度剪切变形。
 *
 * 用法：
 * ```kotlin
 * GlassNavigationBar(
 *     backdrop = combinedBackdrop,
 *     isDark = isSystemInDarkTheme(),
 *     selectedTabIndex = selectedTab,
 *     onTabSelected = { selectedTab = it }
 * )
 * ```
 *
 * @param backdrop 背景源（通常来自 rememberCombinedBackdrop）
 * @param isDark 是否深色模式
 * @param selectedTabIndex 当前选中索引
 * @param onTabSelected 选中回调
 * @param modifier 修饰符
 * @param tabs 标签配置列表（默认 4 个标签）
 */
@Composable
fun GlassNavigationBar(
    backdrop: Backdrop,
    isDark: Boolean,
    selectedTabIndex: Int,
    onTabSelected: (Int) -> Unit,
    modifier: Modifier = Modifier,
    tabs: List<GlassNavTab> = DEFAULT_NAV_TABS
) {
    val selectedColor = if (isDark) Color.White else Color(0xFF1A1A2E)
    val unselectedColor = if (isDark) Color.White.copy(alpha = 0.70f)
    else Color(0xFF1A1A2E).copy(alpha = 0.70f)

    LiquidBottomTabs(
        selectedTabIndex = { selectedTabIndex },
        onTabSelected = onTabSelected,
        backdrop = backdrop,
        tabsCount = tabs.size,
        modifier = modifier
    ) {
        tabs.forEachIndexed { index, tab ->
            LiquidBottomTab(
                onClick = { onTabSelected(index) }
            ) {
                val isSelected = selectedTabIndex == index
                val iconColor = if (isSelected) selectedColor else unselectedColor
                BasicText(
                    if (isSelected) tab.selectedIcon else tab.unselectedIcon,
                    style = TextStyle(color = iconColor, fontSize = 22.sp)
                )
                BasicText(
                    tab.title,
                    style = TextStyle(
                        color = iconColor,
                        fontSize = 10.sp,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                    )
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 完整示例：GlassNavigationBarExample
// ─────────────────────────────────────────────────────────────────────────────

/**
 * 底部导航栏完整示例
 *
 * 展示完整的 backdrop 设置流程：
 * 1. `rememberLayerBackdrop()` 创建页面背景层
 * 2. `layerBackdrop()` 修饰符将页面内容导出为背景源
 * 3. `rememberCombinedBackdrop()` 组合外部背景和页面背景
 * 4. 将组合背景传递给 [GlassNavigationBar]
 *
 * @param backdrop 外部背景源（通常由根 Composable 传入的 LayerBackdrop）
 */
@Composable
fun GlassNavigationBarExample(backdrop: LayerBackdrop) {
    val isDark = isSystemInDarkTheme()
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }

    // 页面背景层：捕获页面内容作为玻璃组件的背景来源
    val pageBackdrop = rememberLayerBackdrop()
    // 组合背景：外部 backdrop + 页面内容 backdrop
    val combinedBackdrop = rememberCombinedBackdrop(backdrop, pageBackdrop)

    val pageTitles = DEFAULT_NAV_TABS.map { it.title }
    val textColor = if (isDark) Color.White.copy(alpha = 0.08f)
    else Color(0xFF1A1A2E).copy(alpha = 0.08f)

    Box(Modifier.fillMaxSize()) {
        // ── 页面内容（导出为 pageBackdrop）─────────────────────────────
        Box(
            Modifier
                .layerBackdrop(pageBackdrop)
                .fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            BasicText(
                pageTitles.getOrElse(selectedTab) { "" },
                style = TextStyle(
                    color = textColor,
                    fontSize = 120.sp,
                    fontWeight = FontWeight.ExtraBold
                )
            )
        }

        // ── 底部导航栏 ────────────────────────────────────────────────
        Column(
            Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
        ) {
            GlassNavigationBar(
                backdrop = combinedBackdrop,
                isDark = isDark,
                selectedTabIndex = selectedTab,
                onTabSelected = { selectedTab = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .height(72.dp)
            )
            Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.navigationBars))
            Spacer(Modifier.height(10.dp))
        }
    }
}
