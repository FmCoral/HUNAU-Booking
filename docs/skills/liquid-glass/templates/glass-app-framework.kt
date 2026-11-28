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
 * 液态玻璃完整应用框架模板
 *
 * ## 模板说明
 * 本模板集成了全部液态玻璃 UI 组件，构建一个完整的应用界面框架。
 * 包含顶部导航栏（标题 + 菜单 + 搜索）、底部导航栏（4 标签 + 指示器动画）、
 * 自定义液态玻璃键盘和弹出菜单，所有组件通过 backdrop 层级协同工作。
 *
 * ## 关键特性
 * - **顶部导航栏**：LiquidTopBar + LiquidTitleChip + LiquidMenuButton
 * - **搜索框**：LiquidSearchBar（点击切换键盘）
 * - **弹出菜单**：LiquidPopupMenu + LiquidMenuItem（弹簧入场动画）
 * - **底部导航栏**：LiquidBottomTabs + LiquidBottomTab（指示器滑动 + 拖拽 + 按压形变）
 * - **自定义键盘**：LiquidKeyboard（拼音/英文/符号四种模式）
 * - **键盘/导航栏互斥**：显示键盘时隐藏导航栏，反之亦然
 *
 * ## 依赖
 * - `backdrop` 库（`com.kyant.backdrop`）— 液态玻璃渲染核心
 * - `shapes` 库（`com.kyant.shapes`）— Capsule / RoundedCornerShape
 *
 * ## 需要复制的 Skill 文件（全部）
 * 1. `components/LiquidTopBar.kt` — 顶部导航栏容器
 * 2. `components/LiquidTitleChip.kt` — 标题芯片
 * 3. `components/LiquidMenuButton.kt` — 三点菜单按钮
 * 4. `components/LiquidSearchBar.kt` — 搜索输入框
 * 5. `components/LiquidPopupMenu.kt` — 弹出菜单 + 菜单项
 * 6. `components/LiquidBottomTabs.kt` — 底部标签栏容器
 * 7. `components/LiquidBottomTab.kt` — 单个标签项
 * 8. `components/LiquidKeyboard.kt` — 液态玻璃键盘
 * 9. `utils/InteractiveHighlight.kt` — 按压交互式高光
 * 10. `utils/DampedDragAnimation.kt` — 拖拽动画控制器
 * 11. `utils/DragGestureInspector.kt` — 拖拽手势检测
 * 12. `utils/PinyinLexiconEngine.kt` — 拼音词典引擎（可选，增强拼音匹配）
 *
 * ## 设置步骤
 * 1. 将上述 Skill 文件复制到你的项目
 * 2. 在 `build.gradle.kts` 中添加 backdrop 和 shapes 库依赖
 * 3. 将本模板中的 [GlassAppFramework] 复制到你的代码
 * 4. 在根 Composable 中创建 LayerBackdrop 并调用 `GlassAppFramework(backdrop)`
 *
 * ## 架构概览
 *
 * ### 状态管理
 * - `selectedTab: Int` — 当前选中的底部标签索引
 * - `showMenu: Boolean` — 弹出菜单是否可见
 * - `showKeyboard: Boolean` — 自定义键盘是否可见（与导航栏互斥）
 * - `textFieldValue: TextFieldValue` — 搜索框文本（含光标选区）
 *
 * ### Backdrop 层级嵌套
 * ```
 * 根 LayerBackdrop（由外部提供）
 * │
 * ├── 页面内容 ──layerBackdrop──> pageBackdrop
 * │                                          └──rememberCombinedBackdrop──> combinedBackdrop
 * └── 外部 backdrop ──────────────────────────────────────────────────────┘
 *     │
 *     ├── LiquidTopBar(backdrop = combinedBackdrop)
 *     │     └── exportedBackdrop → topBarBackdrop
 *     │           ├── LiquidTitleChip(backdrop = topBarBackdrop)
 *     │           └── LiquidMenuButton(backdrop = topBarBackdrop)
 *     │
 *     ├── LiquidSearchBar(backdrop = combinedBackdrop)
 *     │
 *     ├── LiquidPopupMenu(backdrop = combinedBackdrop)
 *     │     └── exportedBackdrop → menuBackdrop
 *     │           └── LiquidMenuItem(backdrop = menuBackdrop)
 *     │
 *     ├── LiquidKeyboard(backdrop = combinedBackdrop)    [showKeyboard 时]
 *     │
 *     └── LiquidBottomTabs(backdrop = combinedBackdrop)  [!showKeyboard 时]
 *           └── rememberLayerBackdrop() → tabsBackdrop
 *                 └── rememberCombinedBackdrop(combinedBackdrop, tabsBackdrop) → 指示器背景
 * ```
 *
 * ### 状态流
 * - 点击标签 → `onTabSelected(index)` → `selectedTab = index` → 标题芯片更新 + 页面内容切换
 * - 点击搜索框 → `onToggleKeyboard()` → `showKeyboard = !showKeyboard` → 键盘/导航栏切换
 * - 点击菜单按钮 → `showMenu = !showMenu` → 弹出菜单显示/隐藏
 * - 键盘输入 → `onKeyInput(char)` → 在光标位置插入字符 → 搜索框更新
 *
 * @param backdrop 外部背景源（通常由根 Composable 传入的 LayerBackdrop）
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
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.layout.windowInsetsTopHeight
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kyant.backdrop.backdrops.LayerBackdrop
import com.kyant.backdrop.backdrops.layerBackdrop
import com.kyant.backdrop.backdrops.rememberCombinedBackdrop
import com.kyant.backdrop.backdrops.rememberLayerBackdrop
import com.kyant.backdrop.catalog.components.LiquidBottomTab
import com.kyant.backdrop.catalog.components.LiquidBottomTabs
import com.kyant.backdrop.catalog.components.LiquidCursorMagnifier
import com.kyant.backdrop.catalog.components.LiquidKeyboard
import com.kyant.backdrop.catalog.components.LiquidMenuButton
import com.kyant.backdrop.catalog.components.LiquidMenuItem
import com.kyant.backdrop.catalog.components.LiquidPopupMenu
import com.kyant.backdrop.catalog.components.LiquidSearchBar
import com.kyant.backdrop.catalog.components.LiquidTitleChip
import com.kyant.backdrop.catalog.components.LiquidTopBar
import kotlinx.coroutines.delay

// ─────────────────────────────────────────────────────────────────────────────
// 元数据
// ─────────────────────────────────────────────────────────────────────────────

private val APP_TAB_TITLES = listOf("首页", "探索", "消息", "我的")
private val APP_TAB_ICONS_SEL = listOf("⊕", "◉", "●", "◈")
private val APP_TAB_ICONS_UNSEL = listOf("⊙", "◈", "◉", "◎")
private val APP_MENU_ITEMS = listOf("设置", "关于", "退出")

// ─────────────────────────────────────────────────────────────────────────────
// 主框架：GlassAppFramework
// ─────────────────────────────────────────────────────────────────────────────

/**
 * 液态玻璃完整应用框架
 *
 * 集成顶部导航栏、搜索框、弹出菜单、底部导航栏和自定义键盘。
 * 显示键盘时隐藏导航栏，关闭键盘时恢复导航栏。
 *
 * 用法：
 * ```kotlin
 * @Composable
 * fun App() {
 *     val backdrop = rememberLayerBackdrop()
 *     Box(Modifier.layerBackdrop(backdrop).fillMaxSize()) {
 *         // 你的背景内容（壁纸、图片等）
 *     }
 *     GlassAppFramework(backdrop)
 * }
 * ```
 *
 * @param backdrop 外部背景源（由根 Composable 传入的 LayerBackdrop）
 */
@Composable
fun GlassAppFramework(backdrop: LayerBackdrop) {
    val isDark = isSystemInDarkTheme()
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }
    var showMenu by rememberSaveable { mutableStateOf(false) }
    var showKeyboard by rememberSaveable { mutableStateOf(false) }
    var textFieldValue by remember { mutableStateOf(TextFieldValue("")) }

    // ── 光标放大镜状态 ──────────────────────────────────────────────
    var textLayoutResult by remember { mutableStateOf<TextLayoutResult?>(null) }
    var textFieldCoords by remember { mutableStateOf<LayoutCoordinates?>(null) }
    var showMagnifier by remember { mutableStateOf(false) }
    var lastText by remember { mutableStateOf("") }

    // 光标移动检测：选区变化但文本不变时，显示放大镜 1.5 秒
    LaunchedEffect(textFieldValue) {
        if (textFieldValue.text == lastText && textFieldValue.text.isNotEmpty()) {
            showMagnifier = true
            delay(1500)
            showMagnifier = false
        }
        lastText = textFieldValue.text
    }

    val keyboardController = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current

    // 页面背景层 + 组合背景
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
            val pageColor = if (isDark) Color.White.copy(alpha = 0.08f)
            else Color(0xFF1A1A2E).copy(alpha = 0.08f)
            BasicText(
                APP_TAB_TITLES.getOrElse(selectedTab) { "" },
                style = TextStyle(
                    color = pageColor,
                    fontSize = 120.sp,
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
                    title = APP_TAB_TITLES.getOrElse(selectedTab) { "" },
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

            LiquidSearchBar(
                backdrop = combinedBackdrop,
                value = textFieldValue,
                onValueChange = { textFieldValue = it },
                isDark = isDark,
                onToggleKeyboard = {
                    keyboardController?.hide()
                    showKeyboard = true
                },
                onTextLayout = { textLayoutResult = it },
                textFieldModifier = Modifier.onGloballyPositioned { textFieldCoords = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .height(48.dp)
            )
        }

        // ── 光标放大镜覆盖层（不拦截触摸事件）──────────────────────────
        LiquidCursorMagnifier(
            text = textFieldValue.text,
            cursorOffset = textFieldValue.selection.start,
            textLayoutResult = textLayoutResult,
            textFieldCoordinates = textFieldCoords,
            textStyle = TextStyle(color = if (isDark) Color.White else Color(0xFF1A1A2E), fontSize = 15.sp),
            visible = showMagnifier,
            isDark = isDark
        )

        // ── 三点菜单弹窗 ──────────────────────────────────────────────
        if (showMenu) {
            Box(
                Modifier
                    .fillMaxSize()
                    .clickable(interactionSource = null, indication = null) {
                        showMenu = false
                    }
            )
            LiquidPopupMenu(
                backdrop = combinedBackdrop,
                isDark = isDark,
                onDismiss = { showMenu = false },
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(end = 16.dp)
                    .padding(top = 76.dp)
            ) { menuBackdrop, textColor, accentColor ->
                APP_MENU_ITEMS.forEachIndexed { idx, label ->
                    LiquidMenuItem(
                        backdrop = menuBackdrop,
                        label = label,
                        isAccent = false,
                        isDark = isDark,
                        textColor = textColor,
                        accentColor = accentColor,
                        onClick = { showMenu = false }
                    )
                    if (idx < APP_MENU_ITEMS.lastIndex) {
                        Spacer(Modifier.height(0.5.dp))
                    }
                }
            }
        }

        // ── 底部区域：键盘 / 导航栏（互斥）──────────────────────────────
        if (showKeyboard) {
            // 点击外部关闭键盘
            Box(
                Modifier
                    .fillMaxSize()
                    .clickable(interactionSource = null, indication = null) {
                        showKeyboard = false
                        focusManager.clearFocus()
                    }
            )
            LiquidKeyboard(
                backdrop = combinedBackdrop,
                isDark = isDark,
                onKeyInput = { char ->
                    val pos = textFieldValue.selection.start
                    val newText = textFieldValue.text.substring(0, pos) + char + textFieldValue.text.substring(pos)
                    textFieldValue = TextFieldValue(
                        text = newText,
                        selection = TextRange(pos + char.length)
                    )
                },
                onBackspace = {
                    val pos = textFieldValue.selection.start
                    if (pos > 0) {
                        val newText = textFieldValue.text.substring(0, pos - 1) + textFieldValue.text.substring(pos)
                        textFieldValue = TextFieldValue(
                            text = newText,
                            selection = TextRange(pos - 1)
                        )
                    }
                },
                onCloseKeyboard = {
                    showKeyboard = false
                    focusManager.clearFocus()
                },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(horizontal = 12.dp)
                    .padding(bottom = 24.dp)
            )
        } else {
            // 底部导航栏
            Column(
                Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
            ) {
                val selColor = if (isDark) Color.White else Color(0xFF1A1A2E)
                val unselColor = if (isDark) Color.White.copy(alpha = 0.70f)
                else Color(0xFF1A1A2E).copy(alpha = 0.70f)

                LiquidBottomTabs(
                    selectedTabIndex = { selectedTab },
                    onTabSelected = { selectedTab = it },
                    backdrop = combinedBackdrop,
                    tabsCount = APP_TAB_TITLES.size,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                        .height(72.dp)
                ) {
                    APP_TAB_TITLES.forEachIndexed { index, title ->
                        LiquidBottomTab(
                            onClick = { selectedTab = index }
                        ) {
                            val isSelected = selectedTab == index
                            val iconColor = if (isSelected) selColor else unselColor
                            BasicText(
                                if (isSelected) APP_TAB_ICONS_SEL[index]
                                else APP_TAB_ICONS_UNSEL[index],
                                style = TextStyle(color = iconColor, fontSize = 22.sp)
                            )
                            BasicText(
                                title,
                                style = TextStyle(
                                    color = iconColor,
                                    fontSize = 10.sp,
                                    fontWeight = if (isSelected) FontWeight.SemiBold
                                    else FontWeight.Normal
                                )
                            )
                        }
                    }
                }
                Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.navigationBars))
                Spacer(Modifier.height(10.dp))
            }
        }
    }
}
