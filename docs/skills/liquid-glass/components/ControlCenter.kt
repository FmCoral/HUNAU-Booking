package com.kyant.backdrop.catalog.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseIn
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.displayCutoutPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.paint
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.GraphicsLayerScope
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.rememberVectorPainter
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastCoerceAtLeast
import androidx.compose.ui.util.fastCoerceIn
import androidx.compose.ui.util.fastRoundToInt
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.catalog.utils.ProgressConverter
import com.kyant.backdrop.catalog.utils.rememberUISensor
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy
import com.kyant.backdrop.highlight.Highlight
import com.kyant.backdrop.highlight.HighlightStyle
import com.kyant.shapes.Capsule
import com.kyant.shapes.RoundedRectangle
import kotlinx.coroutines.launch

/**
 * 控制中心组件（简化容器骨架）
 *
  * ⚠️ 实验性骨架：本组件未接入 drawBackdrop，因此不会绘制任何玻璃/背景内容，
 * 仅提供拖拽展开收起、dimOverlay、BlurEffect 与布局骨架。
  * 官方完整版为 catalog destinations/ControlCenterContent.kt（444 行），
 * 它通过 drawBackdrop 的 layerBlock / onDrawSurface / effects 参数驱动
 * glassLayer（GraphicsLayerScope.() -> Unit）/ glassSurface / glassEffects，
 * 并依赖 FlightIcon、LoremIpsum 等 catalog 页面级资源 —— 需要完整控制中心效果时，
  * 请从官方 catalog 复制 ControlCenterContent 并按需裁剪，而非基于本骨架扩展。
 *
 * @param visible 是否可见
 * @param onDismiss 关闭回调
 * @param backdrop 背景源（当前骨架未使用，保留以对齐官方签名）
 * @param modifier 修饰符
 * @param content 控制中心内容
 */
@Composable
fun ControlCenter(
    visible: Boolean,
    onDismiss: () -> Unit,
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit = {}
) {
    if (!visible) return

    val isLightTheme = !isSystemInDarkTheme()
    val accentColor =
        if (isLightTheme) Color(0xFF0088FF)
        else Color(0xFF0091FF)
    val containerColor = Color.Black.copy(alpha = 0.05f)
    val dimColor = Color.Black.copy(alpha = 0.4f)

    val itemSpacing = 16f.dp
    val itemSize = 68f.dp
    val itemTwoSpanSize = itemSize * 2 + itemSpacing
    val itemShape = RoundedRectangle(itemSize / 2f)

    val innerItemSize = 56f.dp
    val innerItemShape = Capsule()
    val innerItemIconScale = 0.8f

    val inactiveItemColor = Color.White.copy(alpha = 0.2f)
    val activeItemColor = accentColor

    val animationScope = rememberCoroutineScope()
    val enterProgressAnimation = remember { Animatable(1f) }
    val safeEnterProgressAnimation = remember { Animatable(1f) }
    val progress by remember {
        derivedStateOf {
            val progress = enterProgressAnimation.value
            when {
                progress < 0f -> ProgressConverter.Default.convert(progress)
                progress <= 1f -> progress
                else -> 1f + ProgressConverter.Default.convert(progress - 1f)
            }
        }
    }
    val maxDragHeight = 1000f

    val uiSensor = rememberUISensor()
    val glassShape = { itemShape }
    val glassHighlight = {
        Highlight(
            style = HighlightStyle.Default(
                angle = uiSensor.gravityAngle,
                falloff = 2f
            )
        )
    }
    // 以下三个 block 是官方 ControlCenterContent 中传给 drawBackdrop
    // 的 layerBlock / onDrawSurface / effects 参数骨架（官方类型分别为
    // GraphicsLayerScope.() -> Unit / DrawScope.() -> Unit / BackdropEffectScope.() -> Unit）。
    // 本简化骨架未接入 drawBackdrop，故仅保留类型骨架供参考；完整实现见官方
    // catalog destinations/ControlCenterContent.kt。
    val glassLayer: GraphicsLayerScope.() -> Unit = {
        val progress = progress
        val safeProgress = safeEnterProgressAnimation.value
        // 官方此处通过 graphicsLayer 变换（scale/translationY）驱动展开动画
    }
    val glassSurface: DrawScope.() -> Unit = {
        val progress = safeEnterProgressAnimation.value
        if (progress > 0f) {
            // 官方此处绘制表面颜色
        }
    }
    val glassEffects: BackdropEffectScope.() -> Unit = {
        val progress = safeEnterProgressAnimation.value
        vibrancy()
        lens(
            24f.dp.toPx() * progress,
            48f.dp.toPx() * progress,
            depthEffect = true
        )
    }

    val spacerLayoutModifier = Modifier.layout { measurable, constraints ->
        val placeable = measurable.measure(constraints)
        val progress = progress
        val height =
            itemSpacing.roundToPx() +
                    (32f.dp.toPx() * (progress - 1f).fastCoerceAtLeast(0f)).fastRoundToInt()
        layout(constraints.minWidth, height) {
            placeable.place(0, 0)
        }
    }
    val smallSpacerLayoutModifier = Modifier.layout { measurable, constraints ->
        val placeable = measurable.measure(constraints)
        val progress = progress
        val height =
            itemSpacing.roundToPx() +
                    (16f.dp.toPx() * (progress - 1f).fastCoerceAtLeast(0f)).fastRoundToInt()
        layout(constraints.minWidth, height) {
            placeable.place(0, 0)
        }
    }

    val backdropModifier = Modifier
        .draggable(
            rememberDraggableState { delta ->
                val targetProgress = enterProgressAnimation.value + delta / maxDragHeight
                animationScope.launch {
                    launch {
                        enterProgressAnimation.snapTo(targetProgress)
                    }
                    launch {
                        safeEnterProgressAnimation.snapTo(targetProgress.fastCoerceIn(0f, 1f))
                    }
                }
            },
            Orientation.Vertical,
            onDragStopped = { velocity ->
                val targetProgress = when {
                    velocity < 0f -> 0f
                    velocity > 0f -> 1f
                    else -> if (enterProgressAnimation.value < 0.5f) 0f else 1f
                }
                animationScope.launch {
                    launch {
                        enterProgressAnimation.animateTo(
                            targetProgress,
                            if (targetProgress > 0.5f) {
                                spring(0.5f, 300f, 0.5f / maxDragHeight)
                            } else {
                                spring(1f, 300f, 0.01f)
                            },
                            velocity / maxDragHeight
                        )
                    }
                    launch {
                        safeEnterProgressAnimation.animateTo(
                            targetProgress,
                            spring(1f, 300f, 0.01f)
                        )
                    }
                }
            }
        )
        .drawWithContent {
            val progress = safeEnterProgressAnimation.value

            drawContent()
            drawRect(dimColor.copy(dimColor.alpha * progress))
        }
        .graphicsLayer {
            val progress = safeEnterProgressAnimation.value

            val blurRadius = 4f.dp.toPx() * progress
            if (blurRadius > 0f) {
                renderEffect = BlurEffect(blurRadius, blurRadius)
            }
        }

    Box(
        modifier
            .fillMaxSize()
            .then(backdropModifier)
    ) {
        Column(
            Modifier
                .padding(top = 80f.dp)
                .statusBarsPadding()
                .systemBarsPadding()
                .displayCutoutPadding()
                .fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            content()
        }
    }
}
