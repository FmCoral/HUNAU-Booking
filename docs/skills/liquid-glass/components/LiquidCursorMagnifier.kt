/*
 * Copyright (c) 2026
 *
 * * This file is derived from AndroidLiquidGlass (Backdrop):
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

package com.kyant.backdrop.catalog.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

/**
 * 液态玻璃光标放大镜
 *
 * 在文本字段交互时，于光标位置上方显示一个圆形放大镜，将光标周围的文字以 2x 缩放
 * 渲染，并叠加液态玻璃视觉效果（玻璃边框渐变、顶部高光、底部内阴影、光标指示线）。
 *
 * ## 工作原理
 * 1. 通过 [textLayoutResult.getCursorRect] 获取光标在原始文本布局中的位置
 * 2. 使用 [LayoutCoordinates.localToWindow] 将光标位置转换为窗口坐标
 * 3. 使用 [rememberTextMeasurer] 以 2x 字号重新测量文本，获取放大后的布局
 * 4. 在圆形容器内绘制放大文本，偏移使光标居中
 * 5. 叠加玻璃边框（sweepGradient 描边）、高光弧、内阴影弧
 * 6. 通过 [animateFloatAsState] 实现 200ms 淡入/淡出动画
 *
 * ## 视觉效果
 * - **半透明底色**：模拟磨砂玻璃质感
 * - **玻璃边框**：sweepGradient 描边，顶部亮、底部暗，模拟玻璃边缘折射
 * - **顶部高光弧**：白色圆弧，模拟光源反射
 * - **底部内阴影弧**：黑色半透明圆弧，增加深度感
 * - **光标指示线**：蓝色竖线，标记光标在放大视图中的位置
 *
 * ## 触摸穿透
 * 本组件不添加任何 [Modifier.pointerInput] 或 [Modifier.clickable] 修饰符，
 * 因此不会拦截触摸事件——用户可以正常操作下方的文本字段。
 *
 * ## 用法示例
 * ```kotlin
 * var textLayoutResult by remember { mutableStateOf<TextLayoutResult?>(null) }
 * var textFieldCoords by remember { mutableStateOf<LayoutCoordinates?>(null) }
 * var showMagnifier by remember { mutableStateOf(false) }
 *
 * Box {
 *     BasicTextField(
 *         value = textFieldValue,
 *         onValueChange = { textFieldValue = it },
 *         onTextLayout = { textLayoutResult = it },
 *         modifier = Modifier.onGloballyPositioned { textFieldCoords = it }
 *     )
 *
 *     LiquidCursorMagnifier(
 *         text = textFieldValue.text,
 *         cursorOffset = textFieldValue.selection.start,
 *         textLayoutResult = textLayoutResult,
 *         textFieldCoordinates = textFieldCoords,
 *         textStyle = TextStyle(fontSize = 15.sp),
 *         visible = showMagnifier
 *     )
 * }
 * ```
 *
 * @param text 当前文本内容
 * @param cursorOffset 光标在文本中的偏移量（0..text.length）
 * @param textLayoutResult 原始文本布局结果（来自 BasicTextField 的 onTextLayout）
 * @param textFieldCoordinates 文本字段的布局坐标（来自 onGloballyPositioned）
 * @param textStyle 原始文本样式（字号将被乘以 [zoomScale]）
 * @param visible 是否可见（触发淡入/淡出动画）
 * @param modifier 修饰符
 * @param magnifierDiameter 放大镜直径，默认 90dp
 * @param zoomScale 放大倍数，默认 2x
 * @param isDark 是否深色模式，影响底色和文字颜色
 */
@Composable
fun LiquidCursorMagnifier(
    text: String,
    cursorOffset: Int,
    textLayoutResult: TextLayoutResult?,
    textFieldCoordinates: LayoutCoordinates?,
    textStyle: TextStyle,
    visible: Boolean,
    modifier: Modifier = Modifier,
    magnifierDiameter: Dp = 90.dp,
    zoomScale: Float = 2f,
    isDark: Boolean = false
) {
    // ── 淡入/淡出动画 ──────────────────────────────────────────────────
    val alpha by animateFloatAsState(
        targetValue = if (visible && textLayoutResult != null && textFieldCoordinates != null) 1f else 0f,
        animationSpec = tween(durationMillis = 200),
        label = "cursor_magnifier_alpha"
    )

    // 完全透明时不渲染
    if (alpha < 0.01f) return

    val layout = textLayoutResult ?: return
    val coordinates = textFieldCoordinates ?: return

    // ── 光标位置（原始布局 → 窗口坐标）──────────────────────────────────
    val clampedOffset = cursorOffset.coerceIn(0, text.length)
    val cursorRect = layout.getCursorRect(clampedOffset)
    val cursorScreenPos = coordinates.localToWindow(
        Offset(cursorRect.left, cursorRect.top)
    )

    // ── 颜色配置 ──────────────────────────────────────────────────────
    val textColor = if (isDark) Color.White else Color(0xFF1A1A2E)
    val bgColor = if (isDark) Color(0xFF1A1A2E).copy(alpha = 0.92f)
    else Color.White.copy(alpha = 0.92f)
    val cursorColor = if (isDark) Color(0xFF6E9EFF) else Color(0xFF0088FF)

    // ── 放大文本测量 ──────────────────────────────────────────────────
    val textMeasurer = rememberTextMeasurer()
    val magnifiedStyle = remember(textStyle, zoomScale, textColor) {
        textStyle.copy(
            fontSize = (textStyle.fontSize.value * zoomScale).sp,
            color = textColor
        )
    }
    val magnifiedLayout = remember(text, magnifiedStyle) {
        textMeasurer.measure(
            text = text,
            style = magnifiedStyle,
            softWrap = false,
            maxLines = 1
        )
    }

    // 放大布局中的光标位置（用于居中偏移）
    val magnifiedCursorRect = magnifiedLayout.getCursorRect(clampedOffset)

    // ── 玻璃边框渐变颜色 ──────────────────────────────────────────────
    val rimColors = listOf(
        Color.White.copy(alpha = 0.95f),
        Color.White.copy(alpha = 0.30f),
        Color.Black.copy(alpha = 0.12f),
        Color.White.copy(alpha = 0.55f),
        Color.White.copy(alpha = 0.95f)
    )

    // 注意：像素值在 offset{} 和 drawBehind{} 的 Density 作用域内计算
    Box(
        modifier
            .offset {
                // 放大镜位置：光标正上方，水平居中
                val magnifierPx = magnifierDiameter.toPx()
                val verticalGap = 22.dp.toPx()
                val x = cursorScreenPos.x - magnifierPx / 2f
                val y = cursorScreenPos.y - magnifierPx - verticalGap
                IntOffset(x.roundToInt(), y.roundToInt())
            }
            .size(magnifierDiameter)
            .graphicsLayer { this.alpha = alpha }
            .clip(CircleShape)
            .drawBehind {
                val radius = size.minDimension / 2f
                val halfSize = size.width / 2f
                val rimWidth = 2.dp.toPx()

                // 1. 半透明底色（磨砂玻璃质感）
                drawCircle(bgColor)

                // 2. 放大文本（偏移使光标居中于放大镜）
                val textDrawX = halfSize - magnifiedCursorRect.left
                val textDrawY = halfSize - magnifiedCursorRect.top
                drawText(
                    textLayoutResult = magnifiedLayout,
                    topLeft = Offset(textDrawX, textDrawY)
                )

                // 3. 光标指示线（居中竖线）
                val cursorLineHalfHeight = (12f * zoomScale).dp.toPx()
                drawLine(
                    color = cursorColor,
                    start = Offset(halfSize, halfSize - cursorLineHalfHeight),
                    end = Offset(halfSize, halfSize + cursorLineHalfHeight),
                    strokeWidth = 1.5.dp.toPx(),
                    cap = StrokeCap.Round
                )

                // 4. 玻璃边框（sweepGradient 描边：顶部亮 → 底部暗 → 顶部亮）
                drawCircle(
                    brush = Brush.sweepGradient(rimColors),
                    radius = radius - rimWidth / 2f,
                    style = Stroke(width = rimWidth)
                )

                // 5. 顶部高光弧（模拟光源反射）
                drawArc(
                    color = Color.White.copy(alpha = 0.65f),
                    startAngle = 210f,
                    sweepAngle = 75f,
                    useCenter = false,
                    topLeft = Offset(rimWidth, rimWidth),
                    size = Size(size.width - rimWidth * 2, size.height - rimWidth * 2),
                    style = Stroke(width = 1.5.dp.toPx(), cap = StrokeCap.Round)
                )

                // 6. 底部内阴影弧（增加深度感）
                drawArc(
                    color = Color.Black.copy(alpha = 0.18f),
                    startAngle = 15f,
                    sweepAngle = 150f,
                    useCenter = false,
                    topLeft = Offset(rimWidth * 2, rimWidth * 2),
                    size = Size(size.width - rimWidth * 4, size.height - rimWidth * 4),
                    style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round)
                )
            }
    )
}
