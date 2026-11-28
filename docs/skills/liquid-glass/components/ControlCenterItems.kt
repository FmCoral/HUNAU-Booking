package com.kyant.backdrop.catalog.components

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.draggable2D
import androidx.compose.foundation.gestures.rememberDraggable2DState
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.text.BasicText
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
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy
import com.kyant.backdrop.highlight.Highlight
import com.kyant.shapes.RoundedRectangle
import kotlinx.coroutines.launch

/**
 * 控制中心内容区
 *
 * 参考官方 ControlCenterContent 的网格布局实现。
 */
@Composable
fun ControlCenterContent(
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit = {}
) {
    val isLightTheme = !isSystemInDarkTheme()
    val accentColor =
        if (isLightTheme) Color(0xFF0088FF)
        else Color(0xFF0091FF)
    val containerColor = Color.Black.copy(alpha = 0.05f)

    val itemSpacing = 16f.dp
    val itemSize = 68f.dp
    val itemTwoSpanSize = itemSize * 2 + itemSpacing
    val itemShape = RoundedRectangle(itemSize / 2f)

    Column(
        modifier
            .padding(top = 80f.dp)
            .statusBarsPadding()
            .systemBarsPadding()
            .displayCutoutPadding()
            .fillMaxSize()
            .padding(horizontal = 16f.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(itemSpacing),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                Modifier
                    .drawBackdrop(
                        backdrop = backdrop,
                        shape = { itemShape },
                        effects = {
                            vibrancy()
                            lens(24f.dp.toPx(), 48f.dp.toPx(), depthEffect = true)
                        },
                        highlight = { Highlight.Plain },
                        layerBlock = {
                            // placeholder for future animation
                        },
                        onDrawSurface = { drawRect(containerColor) }
                    )
                    .size(itemTwoSpanSize)
                    .padding(itemSpacing)
            ) {
                content()
            }
            Box(
                Modifier
                    .drawBackdrop(
                        backdrop = backdrop,
                        shape = { itemShape },
                        effects = {
                            vibrancy()
                            lens(24f.dp.toPx(), 48f.dp.toPx(), depthEffect = true)
                        },
                        highlight = { Highlight.Plain },
                        onDrawSurface = { drawRect(containerColor) }
                    )
                    .size(itemTwoSpanSize)
            )
        }

        Spacer(modifier = Modifier.height(itemSpacing))

        Row(
            horizontalArrangement = Arrangement.spacedBy(itemSpacing, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(itemSpacing),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        Modifier
                            .drawBackdrop(
                                backdrop = backdrop,
                                shape = { itemShape },
                                effects = {
                                    vibrancy()
                                    lens(24f.dp.toPx(), 48f.dp.toPx(), depthEffect = true)
                                },
                                highlight = { Highlight.Plain },
                                onDrawSurface = { drawRect(containerColor) }
                            )
                            .size(itemSize)
                    )
                    Box(
                        Modifier
                            .drawBackdrop(
                                backdrop = backdrop,
                                shape = { itemShape },
                                effects = {
                                    vibrancy()
                                    lens(24f.dp.toPx(), 48f.dp.toPx(), depthEffect = true)
                                },
                                highlight = { Highlight.Plain },
                                onDrawSurface = { drawRect(containerColor) }
                            )
                            .size(itemSize)
                    )
                }

                Spacer(modifier = Modifier.height(itemSpacing))

                Box(
                    Modifier
                        .drawBackdrop(
                            backdrop = backdrop,
                            shape = { RoundedRectangle(24f.dp) },
                            effects = {
                                vibrancy()
                                lens(24f.dp.toPx(), 48f.dp.toPx(), depthEffect = true)
                            },
                            highlight = { Highlight.Plain }
                        )
                        .size(itemTwoSpanSize, itemSize)
                )
            }

            Row(
                horizontalArrangement = Arrangement.spacedBy(itemSpacing),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    Modifier
                        .drawBackdrop(
                            backdrop = backdrop,
                            shape = { itemShape },
                            effects = {
                                vibrancy()
                                lens(24f.dp.toPx(), 48f.dp.toPx(), depthEffect = true)
                            },
                            highlight = { Highlight.Plain },
                            onDrawSurface = { drawRect(containerColor) }
                        )
                        .size(itemSize, itemTwoSpanSize)
                )
                Box(
                    Modifier
                        .drawBackdrop(
                            backdrop = backdrop,
                            shape = { itemShape },
                            effects = {
                                vibrancy()
                                lens(24f.dp.toPx(), 48f.dp.toPx(), depthEffect = true)
                            },
                            highlight = { Highlight.Plain },
                            onDrawSurface = { drawRect(containerColor) }
                        )
                        .size(itemSize, itemTwoSpanSize)
                )
            }
        }
    }
}
