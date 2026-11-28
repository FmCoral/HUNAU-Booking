package com.kyant.backdrop.catalog.components

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.draggable2D
import androidx.compose.foundation.gestures.rememberDraggable2DState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.kyant.backdrop.backdrops.layerBackdrop
import com.kyant.backdrop.backdrops.rememberCombinedBackdrop
import com.kyant.backdrop.backdrops.rememberLayerBackdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.shadow.InnerShadow
import com.kyant.shapes.Capsule
import com.kyant.shapes.RoundedRectangle

/**
 * 放大镜玻璃效果
 *
 * 参考官方 MagnifierContent 实现，包含：
 * - 2D 拖拽跟随
 * - 背景内容捕获
 * - 色散折射效果
 * - 内阴影
 *
 * @param backdrop 背景源
 * @param modifier 修饰符
 * @param size 放大镜尺寸
 * @param content 背景内容（可捕获）
 */
@Composable
fun MagnifierGlass(
    backdrop: com.kyant.backdrop.Backdrop,
    modifier: Modifier = Modifier,
    size: androidx.compose.ui.unit.DpSize = androidx.compose.ui.unit.DpSize(128.dp, 96.dp),
    content: @Composable () -> Unit
) {
    val contentBackdrop = rememberLayerBackdrop()
    val cursorBackdrop = rememberLayerBackdrop()
    var offset by remember { mutableStateOf(Offset.Zero) }

    Box(modifier) {
        // 背景内容层
        Box(
            Modifier
                .layerBackdrop(contentBackdrop)
                .padding(24f.dp)
                .clip(RoundedRectangle(32f.dp))
                .background(Color.White.copy(alpha = 0.9f))
                .padding(24f.dp)
        ) {
            content()
        }

        // 光标指示器
        Box(
            Modifier
                .graphicsLayer {
                    val offset = offset
                    translationX = offset.x
                    translationY = offset.y
                }
                .draggable2D(rememberDraggable2DState { delta -> offset += delta })
                .layerBackdrop(cursorBackdrop)
                .background(Color(0xFF0088FF), Capsule())
                .size(4f.dp, 24.dp)
        )

        // 放大镜玻璃
        Box(
            Modifier
                .graphicsLayer {
                    val offset = offset
                    translationX = offset.x
                    translationY = offset.y - 80f.dp.toPx()
                }
                .drawBackdrop(
                    backdrop = rememberCombinedBackdrop(backdrop, contentBackdrop, cursorBackdrop),
                    shape = { Capsule() },
                    effects = {
                        lens(
                            8f.dp.toPx(),
                            24f.dp.toPx(),
                            depthEffect = true,
                            chromaticAberration = true
                        )
                    },
                    innerShadow = { InnerShadow(radius = 16f.dp) },
                    onDrawBackdrop = { drawBackdrop ->
                        withTransform(
                            {
                                scale(1.5f, 1.5f)
                                translate(top = with(this@drawBackdrop) { -80f.dp.toPx() })
                            },
                            drawBackdrop
                        )
                    }
                )
                .size(size.width, size.height)
        )
    }
}
