package com.kyant.backdrop.catalog

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastCoerceAtMost
import androidx.compose.ui.util.lerp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.catalog.utils.InteractiveHighlight
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy
import com.kyant.backdrop.highlight.Highlight
import com.kyant.backdrop.shadow.InnerShadow
import com.kyant.backdrop.shadow.Shadow
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.tanh

/**
 * 交互式玻璃效果模板（v2 — 统一规范）
 *
 * 包含完整的按压反馈、缩放动画和触摸跟踪效果。
 * 与 FAB / 底部导航栏 / 对话框统一参数规范。
 *
 * ## 统一规范
 *
 * | 参数 | 值 |
 * |---|---|
 * | blur | 2dp（低模糊保留内容细节） |
 * | lens | 12dp, 24dp, chromaticAberration=true |
 * | 底色 | 15% 中性雾感（浅色 FAFAFA / 深色 121212） |
 * | 常驻高光 | 0.15 |
 * | 常驻阴影 | 0.08 |
 * | 常驻内阴影 | 4dp, 0.1 |
 * | 按压高光 | 0.15 + 0.35 * progress |
 * | 按压阴影 | 0.08 + 0.22 * progress |
 * | 按压内阴影 | 4dp + 8dp * progress, 0.1 + 0.3 * progress |
 *
 * @param backdrop 背景源
 * @param onClick 点击回调
 * @param modifier 修饰符
 * @param shape 玻璃形状
 * @param isInteractive 是否启用交互效果
 * @param backgroundColor 表面颜色（默认 15% 中性雾感）
 * @param content 内容
 */
@Composable
fun InteractiveGlass(
    backdrop: Backdrop,
    onClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(16.dp),
    isInteractive: Boolean = true,
    backgroundColor: Color = if (!isSystemInDarkTheme()) Color(0xFFFAFAFA).copy(alpha = 0.15f)
        else Color(0xFF121212).copy(alpha = 0.15f),
    content: @Composable () -> Unit
) {
    val animationScope = rememberCoroutineScope()
    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }
    Box(
        modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { shape },
                effects = {
                    vibrancy()
                    blur(2f.dp.toPx())
                    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)
                },
                layerBlock = if (isInteractive) {
                    {
                        val width = size.width
                        val height = size.height
                        val progress = interactiveHighlight.pressProgress
                        val scale = lerp(1f, 1f + 4f.dp.toPx() / size.height, progress)
                        val maxOffset = size.minDimension
                        val initialDerivative = 0.05f
                        val offset = interactiveHighlight.offset
                        translationX = maxOffset * tanh(initialDerivative * offset.x / maxOffset)
                        translationY = maxOffset * tanh(initialDerivative * offset.y / maxOffset)
                        val maxDragScale = 4f.dp.toPx() / size.height
                        val offsetAngle = atan2(offset.y, offset.x)
                        scaleX = scale +
                            maxDragScale * abs(cos(offsetAngle) * offset.x / size.maxDimension) *
                            (width / height).fastCoerceAtMost(1f)
                        scaleY = scale +
                            maxDragScale * abs(sin(offsetAngle) * offset.y / size.maxDimension) *
                            (height / width).fastCoerceAtMost(1f)
                    }
                } else {
                    null
                },
                highlight = {
                    val progress = interactiveHighlight.pressProgress
                    Highlight.Default.copy(alpha = 0.15f + 0.35f * progress)
                },
                shadow = {
                    val progress = interactiveHighlight.pressProgress
                    Shadow(alpha = 0.08f + 0.22f * progress)
                },
                innerShadow = {
                    val progress = interactiveHighlight.pressProgress
                    InnerShadow(
                        radius = 4f.dp + 8f.dp * progress,
                        alpha = 0.1f + 0.3f * progress
                    )
                },
                onDrawSurface = { drawRect(backgroundColor) }
            )
            .then(
                if (isInteractive && onClick != null) {
                    Modifier.clickable(
                        interactionSource = null,
                        indication = null,
                        onClick = onClick
                    )
                } else {
                    Modifier
                }
            )
            .then(
                if (isInteractive) {
                    Modifier
                        .then(interactiveHighlight.modifier)
                        .then(interactiveHighlight.gestureModifier)
                } else {
                    Modifier
                }
            )
            .padding(16.dp),
        content = content
    )
}

/**
 * 带弹性动画的按压玻璃（v2 — 统一规范）
 */
@Composable
fun ElasticGlass(
    backdrop: Backdrop,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(16.dp),
    pressedScale: Float = 0.95f,
    content: @Composable () -> Unit
) {
    val animationScope = rememberCoroutineScope()
    var isPressed by remember { mutableStateOf(false) }
    val bgColor = if (!isSystemInDarkTheme()) Color(0xFFFAFAFA).copy(alpha = 0.15f)
        else Color(0xFF121212).copy(alpha = 0.15f)
    val scaleX = remember { Animatable(1f) }
    val scaleY = remember { Animatable(1f) }
    LaunchedEffect(isPressed) {
        val target = if (isPressed) pressedScale else 1f
        scaleX.animateTo(target, spring(0.5f, 300f, 0.001f))
        scaleY.animateTo(target, spring(0.5f, 300f, 0.001f))
    }
    Box(
        modifier
            .graphicsLayer { scaleX = scaleX.value; scaleY = scaleY.value }
            .drawBackdrop(
                backdrop = backdrop, shape = { shape },
                effects = {
                    vibrancy()
                    blur(2f.dp.toPx())
                    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)
                },
                highlight = { Highlight.Default.copy(alpha = if (isPressed) 0.5f else 0.15f) },
                shadow = { Shadow(alpha = 0.08f) },
                innerShadow = {
                    InnerShadow(
                        radius = if (isPressed) 12f.dp else 4f.dp,
                        alpha = if (isPressed) 0.4f else 0.1f
                    )
                },
                onDrawSurface = { drawRect(bgColor) }
            )
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                    }
                )
            }
            .clickable(interactionSource = null, indication = null, onClick = onClick)
            .padding(16.dp),
        content = content
    )
}

/**
 * 液态玻璃圆形图标按钮（与 FAB 同款规范）。
 * 42dp 圆形玻璃按钮，按压时完整 LiquidButton 形变
 * （tanh 拖拽跟随 + 方向拉伸）+ 放大 + 光影增强。
 */
@Composable
fun GlassIconButton(
    backdrop: Backdrop,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    backgroundColor: Color = if (!isSystemInDarkTheme()) Color(0xFFFAFAFA).copy(alpha = 0.15f)
        else Color(0xFF121212).copy(alpha = 0.15f),
    icon: @Composable () -> Unit,
) {
    val animationScope = rememberCoroutineScope()
    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }
    Box(
        modifier = modifier
            .size(42.dp)
            .drawBackdrop(
                backdrop = backdrop, shape = { CircleShape },
                effects = {
                    vibrancy()
                    blur(2f.dp.toPx())
                    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)
                },
                highlight = {
                    val p = interactiveHighlight.pressProgress
                    Highlight.Default.copy(alpha = 0.15f + 0.35f * p)
                },
                shadow = {
                    val p = interactiveHighlight.pressProgress
                    Shadow(alpha = 0.08f + 0.22f * p)
                },
                innerShadow = {
                    val p = interactiveHighlight.pressProgress
                    InnerShadow(radius = 4f.dp + 8f.dp * p, alpha = 0.1f + 0.3f * p)
                },
                layerBlock = {
                    val w = size.width; val h = size.height
                    val p = interactiveHighlight.pressProgress
                    val scale = lerp(1f, 1.15f, p)
                    val maxOff = size.minDimension; val initDeriv = 0.05f; val off = interactiveHighlight.offset
                    translationX = maxOff * tanh(initDeriv * off.x / maxOff)
                    translationY = maxOff * tanh(initDeriv * off.y / maxOff)
                    val maxDrag = 4f.dp.toPx() / h; val angle = atan2(off.y, off.x)
                    scaleX = scale + maxDrag * abs(cos(angle) * off.x / size.maxDimension) * (w / h).fastCoerceAtMost(1f)
                    scaleY = scale + maxDrag * abs(sin(angle) * off.y / size.maxDimension) * (h / w).fastCoerceAtMost(1f)
                },
                onDrawSurface = { drawRect(backgroundColor.copy(alpha = if (enabled) 1f else 0.5f)) }
            )
            .then(interactiveHighlight.modifier)
            .then(interactiveHighlight.gestureModifier)
            .clickable(interactionSource = null, indication = null, enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        icon()
    }
}
