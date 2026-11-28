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
 * 液态玻璃软键盘集成模板
 *
 * ## 模板说明
 * 本模板演示如何将 [LiquidKeyboard] 集成到应用中，实现自定义液态玻璃输入法。
 * 包含键盘状态管理（显示/隐藏）、文本输入处理、退格删除、剪贴板复制/粘贴，
 * 以及点击键盘外部区域关闭键盘的交互。
 *
 * ## 关键特性
 * - **四种输入模式**：全键盘拼音、九宫格拼音、全键盘英文、数字/符号
 * - **模式切换**：键盘内置模式切换弹窗（LiquidKeyboardPopupMenu）
 * - **拼音输入**：支持全拼、简拼、T9 九宫格拼音（内置示例词库）
 * - **长按退格**：长按退格键连续快速删除（每 70ms 回删一次）
 *
 * ## 依赖
 * - `backdrop` 库（`com.kyant.backdrop`）— 液态玻璃渲染核心
 * - `shapes` 库（`com.kyant.shapes`）— Capsule / RoundedCornerShape
 *
 * ## 需要复制的 Skill 文件
 * 1. `components/LiquidKeyboard.kt` — 键盘主组件（含全部按键、拼音引擎、模式切换）
 * 2. `utils/InteractiveHighlight.kt` — 按压交互式高光（被按键组件依赖）
 * 3. `utils/PinyinLexiconEngine.kt` — 拼音词典引擎（可选，用于增强拼音匹配）
 *
 * ## 设置步骤
 * 1. 将上述 Skill 文件复制到你的项目（保持 `com.kyant.backdrop.catalog` 包路径）
 * 2. 在 `build.gradle.kts` 中添加 backdrop 和 shapes 库依赖
 * 3. 将本模板中的 [GlassKeyboardExample] 复制到你的代码
 * 4. 在你的页面中调用 `GlassKeyboardExample(backdrop)` 即可运行
 *
 * ## 键盘模式（LiquidKeyboardMode）
 * | 模式 | 说明 | 布局 |
 * |---|---|---|
 * | `Pinyin26Key` | 全键盘拼音 | QWERTY 26 键 + 拼音候选词 |
 * | `Pinyin9Key` | 九宫格拼音 | T9 数字键盘 + 拼音候选词 |
 * | `English26Key` | 全键盘英文 | QWERTY 26 键直接输入 |
 * | `SymbolsKey` | 数字 / 符号 | 数字 + 常用符号面板 |
 *
 * 模式切换通过键盘左下角的模式按钮触发，弹出 LiquidKeyboardPopupMenu 选择。
 *
 * ## Backdrop 层级
 * ```
 * 页面内容 ──layerBackdrop──> pageBackdrop
 *                                          └──rememberCombinedBackdrop──> combinedBackdrop
 * 外部 backdrop ──────────────────────────────────────────────────────┘
 * LiquidKeyboard(backdrop = combinedBackdrop)
 * ```
 */

import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
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
import com.kyant.backdrop.catalog.components.LiquidCursorMagnifier
import com.kyant.backdrop.catalog.components.LiquidKeyboard
import kotlinx.coroutines.delay

// ─────────────────────────────────────────────────────────────────────────────
// 完整示例：GlassKeyboardExample
// ─────────────────────────────────────────────────────────────────────────────

/**
 * 液态玻璃键盘集成示例
 *
 * 展示完整的键盘集成流程：
 * 1. 搜索框启用系统交互（长按复制/粘贴、光标定位、粘贴）
 * 2. 获焦时抑制系统键盘，仅使用自定义液态玻璃键盘
 * 3. 键盘输入回调更新文本
 * 4. 点击键盘外部区域关闭键盘
 *
 * @param backdrop 外部背景源（通常由根 Composable 传入的 LayerBackdrop）
 */
@Composable
fun GlassKeyboardExample(backdrop: LayerBackdrop) {
    val isDark = isSystemInDarkTheme()
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

    // 页面背景层
    val pageBackdrop = rememberLayerBackdrop()
    val combinedBackdrop = rememberCombinedBackdrop(backdrop, pageBackdrop)

    val textColor = if (isDark) Color.White else Color(0xFF1A1A2E)
    val placeholderColor = if (isDark) Color.White.copy(alpha = 0.40f)
    else Color(0xFF1A1A2E).copy(alpha = 0.40f)
    val surfaceColor = if (isDark) Color(0xFF0D0D1A).copy(alpha = 0.35f)
    else Color(0xFFFFFFFF).copy(alpha = 0.35f)

    Box(Modifier.fillMaxSize()) {
        // ── 页面内容（导出为 pageBackdrop）─────────────────────────────
        Box(
            Modifier
                .layerBackdrop(pageBackdrop)
                .fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            BasicText(
                if (textFieldValue.text.isEmpty()) "点击下方搜索框开始输入" else "输入内容：${textFieldValue.text}",
                style = TextStyle(
                    color = textColor.copy(alpha = 0.5f),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
            )
        }

        // ── 顶部搜索框 ────────────────────────────────────────────────
        Column(
            Modifier
                .align(Alignment.TopStart)
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // 简易搜索框（启用系统交互 + 获焦时抑制系统键盘）
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .clickable(interactionSource = null, indication = null) {
                        keyboardController?.hide()
                        showKeyboard = true
                    },
                contentAlignment = Alignment.CenterStart
            ) {
                if (textFieldValue.text.isEmpty()) {
                    BasicText(
                        "搜索…",
                        style = TextStyle(color = placeholderColor, fontSize = 15.sp)
                    )
                }
                BasicTextField(
                    value = textFieldValue,
                    onValueChange = { textFieldValue = it },
                    enabled = true,
                    readOnly = false,
                    onTextLayout = { textLayoutResult = it },
                    modifier = Modifier
                        .fillMaxWidth()
                        .onGloballyPositioned { textFieldCoords = it }
                        .onFocusChanged { focusState ->
                            if (focusState.isFocused) {
                                keyboardController?.hide()
                                showKeyboard = true
                            }
                        },
                    textStyle = TextStyle(color = textColor, fontSize = 15.sp),
                    singleLine = true
                )
            }
        }

        // ── 光标放大镜覆盖层（不拦截触摸事件）──────────────────────────
        LiquidCursorMagnifier(
            text = textFieldValue.text,
            cursorOffset = textFieldValue.selection.start,
            textLayoutResult = textLayoutResult,
            textFieldCoordinates = textFieldCoords,
            textStyle = TextStyle(color = textColor, fontSize = 15.sp),
            visible = showMagnifier,
            isDark = isDark
        )

        // ── 键盘区域 ──────────────────────────────────────────────────
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
        }
    }
}
