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
 * 液态玻璃光标放大镜模板
 *
 * ## 模板说明
 * 本模板演示如何将 [LiquidCursorMagnifier] 集成到文本输入场景中。
 * 当用户移动光标（选区变化但文本不变）时，在光标上方显示一个圆形放大镜，
 * 以 2x 缩放渲染光标周围的文字，并叠加液态玻璃视觉效果。
 *
 * ## 关键特性
 * - **光标移动检测**：通过比较 `TextFieldValue` 的 text 和 selection 变化，
 *   区分"文本输入"和"光标移动"两种场景
 * - **自动隐藏**：光标移动后显示放大镜 1.5 秒，然后自动淡出
 * - **触摸穿透**：放大镜不拦截触摸事件，用户可正常操作文本字段
 * - **坐标捕获**：通过 `onGloballyPositioned` 获取文本字段的布局坐标，
 *   用于将光标位置转换为窗口坐标
 *
 * ## 依赖
 * - 标准 Compose Multiplatform API（无额外库依赖）
 * - [LiquidCursorMagnifier] 组件本身不依赖 backdrop / shapes 库，
 *   仅使用 `rememberTextMeasurer` + `drawText` + 自定义 `drawBehind` 绘制
 *
 * ## 需要复制的 Skill 文件
 * 1. `components/LiquidCursorMagnifier.kt` — 光标放大镜组件
 *
 * ## 设置步骤
 * 1. 将 `LiquidCursorMagnifier.kt` 复制到你的项目（保持 `com.kyant.backdrop.catalog` 包路径）
 * 2. 在 `build.gradle.kts` 中添加 backdrop 和 shapes 库依赖
 * 3. 将本模板中的 [GlassCursorMagnifierExample] 复制到你的代码
 * 4. 在你的页面中调用 `GlassCursorMagnifierExample()` 即可运行
 *
 * ## 核心交互流程
 * ```
 * 用户点击/拖拽文本字段 → TextFieldValue.selection 变化（text 不变）
 *     → LaunchedEffect 检测到光标移动
 *     → showMagnifier = true
 *     → LiquidCursorMagnifier 淡入显示（200ms）
 *     → 1.5 秒后 showMagnifier = false
 *     → LiquidCursorMagnifier 淡出隐藏（200ms）
 * ```
 */

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kyant.backdrop.catalog.components.LiquidCursorMagnifier
import kotlinx.coroutines.delay

// ─────────────────────────────────────────────────────────────────────────────
// 完整示例：GlassCursorMagnifierExample
// ─────────────────────────────────────────────────────────────────────────────

/**
 * 液态玻璃光标放大镜最小示例
 *
 * 展示光标放大镜的完整集成流程：
 * 1. BasicTextField 捕获文本布局结果和布局坐标
 * 2. LaunchedEffect 检测光标移动（选区变化但文本不变）
 * 3. LiquidCursorMagnifier 在光标上方显示放大视图
 *
 * 用法：
 * ```kotlin
 * @Composable
 * fun App() {
 *     GlassCursorMagnifierExample()
 * }
 * ```
 */
@Composable
fun GlassCursorMagnifierExample() {
    val isDark = isSystemInDarkTheme()
    var textFieldValue by remember { mutableStateOf(TextFieldValue("在此输入文字来测试光标放大镜")) }

    // ── 光标放大镜状态 ──────────────────────────────────────────────
    var textLayoutResult by remember { mutableStateOf<TextLayoutResult?>(null) }
    var textFieldCoords by remember { mutableStateOf<LayoutCoordinates?>(null) }
    var showMagnifier by remember { mutableStateOf(false) }
    var lastText by remember { mutableStateOf(textFieldValue.text) }

    // 光标移动检测：选区变化但文本不变时，显示放大镜 1.5 秒
    LaunchedEffect(textFieldValue) {
        if (textFieldValue.text == lastText && textFieldValue.text.isNotEmpty()) {
            showMagnifier = true
            delay(1500)
            showMagnifier = false
        }
        lastText = textFieldValue.text
    }

    val textColor = if (isDark) Color.White else Color(0xFF1A1A2E)
    val hintColor = if (isDark) Color.White.copy(alpha = 0.4f) else Color(0xFF1A1A2E).copy(alpha = 0.4f)

    Box(
        Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // ── 提示文字 ────────────────────────────────────────────────
        BasicText(
            "点击下方文本框并移动光标，\n放大镜将在光标上方显示",
            style = TextStyle(
                color = hintColor,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium
            )
        )

        // ── 文本输入框 ──────────────────────────────────────────────
        BasicTextField(
            value = textFieldValue,
            onValueChange = { textFieldValue = it },
            onTextLayout = { textLayoutResult = it },
            modifier = Modifier
                .align(Alignment.Center)
                .fillMaxWidth()
                .onGloballyPositioned { textFieldCoords = it },
            textStyle = TextStyle(
                color = textColor,
                fontSize = 16.sp,
                fontWeight = FontWeight.Normal
            ),
            singleLine = true
        )

        // ── 光标放大镜覆盖层（不拦截触摸事件）──────────────────────────
        LiquidCursorMagnifier(
            text = textFieldValue.text,
            cursorOffset = textFieldValue.selection.start,
            textLayoutResult = textLayoutResult,
            textFieldCoordinates = textFieldCoords,
            textStyle = TextStyle(
                color = textColor,
                fontSize = 16.sp
            ),
            visible = showMagnifier,
            isDark = isDark
        )
    }
}
