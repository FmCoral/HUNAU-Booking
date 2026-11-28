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
 * 液态玻璃顶部导航栏模板
 *
 * ## 模板说明
 * 本模板演示如何使用 [LiquidTopBar] + [LiquidTitleChip] + [LiquidMenuButton] +
 * [LiquidSearchBar] + [LiquidPopupMenu] 构建一个完整的顶部导航区域，
 * 包含标题显示、三点菜单触发、搜索输入和下拉菜单弹窗。
 *
 * ## 关键特性
 * - **标题芯片**：胶囊形玻璃芯片显示当前页面标题，按压时产生方向性拉伸形变
 * - **三点菜单按钮**：圆形玻璃按钮，Canvas 绘制三个圆点，按压时均匀缩放
 * - **搜索框**：胶囊形搜索输入框，点击切换自定义键盘（readOnly 模式）
 * - **弹出菜单**：弹簧入场动画（scale 0.75→1.0, alpha 0→1, 右上角 transformOrigin）
 * - **菜单项**：按压时模糊和透镜折射从零渐增，轻微缩小 + 高光增强
 *
 * ## 依赖
 * - `backdrop` 库（`com.kyant.backdrop`）— 液态玻璃渲染核心
 * - `shapes` 库（`com.kyant.shapes`）— Capsule 胶囊形状
 *
 * ## 需要复制的 Skill 文件
 * 1. `components/LiquidTopBar.kt` — 顶部导航栏容器（导出 topBarBackdrop）
 * 2. `components/LiquidTitleChip.kt` — 标题芯片
 * 3. `components/LiquidMenuButton.kt` — 三点菜单按钮
 * 4. `components/LiquidSearchBar.kt` — 搜索输入框
 * 5. `components/LiquidPopupMenu.kt` — 弹出菜单容器 + LiquidMenuItem 菜单项
 * 6. `utils/InteractiveHighlight.kt` — 按压交互式高光（被上述组件依赖）
 *
 * ## 设置步骤
 * 1. 将上述 6 个 Skill 文件复制到你的项目
 * 2. 在 `build.gradle.kts` 中添加 backdrop 和 shapes 库依赖
 * 3. 将本模板中的 [GlassTopBarExample] 复制到你的代码
 * 4. 在你的页面中调用 `GlassTopBarExample(backdrop)` 即可运行
 *
 * ## exportedBackdrop 嵌套原理
 *
 * 玻璃组件不能直接以自身容器为背景（会导致递归绘制崩溃），
 * 需要通过 `exportedBackdrop` 将容器内容导出为独立的背景层，
 * 子组件再以该背景层作为背景来源，安全实现「玻璃上叠玻璃」。
 *
 * 嵌套层级：
 * ```
 * 页面内容 ──layerBackdrop──> pageBackdrop
 *                                          └──rememberCombinedBackdrop──> combinedBackdrop
 * 外部 backdrop ──────────────────────────────────────────────────────┘
 * │
 * ├── LiquidTopBar(backdrop = combinedBackdrop)
 * │     └── exportedBackdrop → topBarBackdrop
 * │           ├── LiquidTitleChip(backdrop = topBarBackdrop)
 * │           └── LiquidMenuButton(backdrop = topBarBackdrop)
 * │
 * ├── LiquidSearchBar(backdrop = combinedBackdrop)
 * │
 * └── LiquidPopupMenu(backdrop = combinedBackdrop)
 *       └── exportedBackdrop → menuBackdrop
 *             └── LiquidMenuItem(backdrop = menuBackdrop)
 * ```
 *
 * @see LiquidTopBar
 * @see LiquidPopupMenu
 */

import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsTopHeight
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kyant.backdrop.backdrops.LayerBackdrop
import com.kyant.backdrop.backdrops.layerBackdrop
import com.kyant.backdrop.backdrops.rememberCombinedBackdrop
import com.kyant.backdrop.backdrops.rememberLayerBackdrop
import com.kyant.backdrop.catalog.components.LiquidMenuButton
import com.kyant.backdrop.catalog.components.LiquidMenuItem
import com.kyant.backdrop.catalog.components.LiquidPopupMenu
import com.kyant.backdrop.catalog.components.LiquidSearchBar
import com.kyant.backdrop.catalog.components.LiquidTitleChip
import com.kyant.backdrop.catalog.components.LiquidTopBar

// ─────────────────────────────────────────────────────────────────────────────
// 菜单项数据
// ─────────────────────────────────────────────────────────────────────────────

/** 菜单项定义 */
data class GlassMenuItem(val label: String, val isAccent: Boolean = false)

/** 默认菜单项 */
private val DEFAULT_MENU_ITEMS = listOf(
    GlassMenuItem("设置"),
    GlassMenuItem("关于"),
    GlassMenuItem("退出", isAccent = true)
)

// ─────────────────────────────────────────────────────────────────────────────
// 完整示例：GlassTopBarExample
// ─────────────────────────────────────────────────────────────────────────────

/**
 * 液态玻璃顶部导航栏完整示例
 *
 * 集成顶部导航栏（标题 + 菜单按钮）、搜索框和弹出菜单，
 * 展示完整的 exportedBackdrop 嵌套和状态管理。
 *
 * @param backdrop 外部背景源（通常由根 Composable 传入的 LayerBackdrop）
 * @param title 当前页面标题
 */
@Composable
fun GlassTopBarExample(
    backdrop: LayerBackdrop,
    title: String = "首页"
) {
    val isDark = isSystemInDarkTheme()
    var showMenu by rememberSaveable { mutableStateOf(false) }
    var showKeyboard by rememberSaveable { mutableStateOf(false) }
    var textFieldValue by remember { mutableStateOf(TextFieldValue("")) }

    val keyboardController = LocalSoftwareKeyboardController.current

    // 页面背景层
    val pageBackdrop = rememberLayerBackdrop()
    val combinedBackdrop = rememberCombinedBackdrop(backdrop, pageBackdrop)

    Box(Modifier.fillMaxSize()) {
        // ── 页面内容（导出为 pageBackdrop）─────────────────────────────
        Box(
            Modifier
                .layerBackdrop(pageBackdrop)
                .fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            val textColor = if (isDark) Color.White.copy(alpha = 0.08f)
            else Color(0xFF1A1A2E).copy(alpha = 0.08f)
            BasicText(
                title,
                style = TextStyle(
                    color = textColor,
                    fontSize = 80.sp,
                    fontWeight = FontWeight.ExtraBold
                )
            )
        }

        // ── 顶部区域（TopBar + SearchBar）──────────────────────────────
        Column(
            Modifier
                .fillMaxWidth()
                .align(Alignment.TopStart)
        ) {
            Spacer(Modifier.windowInsetsTopHeight(WindowInsets.statusBars))
            Spacer(Modifier.height(8.dp))

            // 顶部导航栏：标题芯片 + 三点菜单按钮
            // LiquidTopBar 内部通过 exportedBackdrop 导出 topBarBackdrop 供子组件使用
            LiquidTopBar(
                backdrop = combinedBackdrop,
                isDark = isDark,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .height(56.dp)
            ) { topBarBackdrop ->
                LiquidTitleChip(
                    backdrop = topBarBackdrop,
                    title = title,
                    isDark = isDark
                )
                LiquidMenuButton(
                    backdrop = topBarBackdrop,
                    isDark = isDark,
                    onClick = { showMenu = !showMenu },
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .padding(end = 6.dp)
                )
            }

            Spacer(Modifier.height(10.dp))

            // 搜索框
            LiquidSearchBar(
                backdrop = combinedBackdrop,
                value = textFieldValue,
                onValueChange = { textFieldValue = it },
                isDark = isDark,
                onToggleKeyboard = {
                    keyboardController?.hide()
                    showKeyboard = !showKeyboard
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .height(48.dp)
            )
        }

        // ── 三点菜单弹窗 ──────────────────────────────────────────────
        if (showMenu) {
            // 点击外部关闭菜单
            Box(
                Modifier
                    .fillMaxSize()
                    .clickable(interactionSource = null, indication = null) {
                        showMenu = false
                    }
            )
            // LiquidPopupMenu 内部通过 exportedBackdrop 导出 menuBackdrop 供菜单项使用
            LiquidPopupMenu(
                backdrop = combinedBackdrop,
                isDark = isDark,
                onDismiss = { showMenu = false },
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(end = 16.dp)
                    .padding(top = 76.dp)
            ) { menuBackdrop, textColor, accentColor ->
                DEFAULT_MENU_ITEMS.forEachIndexed { idx, item ->
                    LiquidMenuItem(
                        backdrop = menuBackdrop,
                        label = item.label,
                        isAccent = false,
                        isDark = isDark,
                        textColor = textColor,
                        accentColor = accentColor,
                        onClick = { showMenu = false }
                    )
                    if (idx < DEFAULT_MENU_ITEMS.lastIndex) {
                        Spacer(Modifier.height(0.5.dp))
                    }
                }
            }
        }
    }
}
