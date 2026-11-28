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

package com.kyant.backdrop.catalog.components

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.draggable2D
import androidx.compose.foundation.gestures.rememberDraggable2DState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.catalog.utils.SdfShader
import com.kyant.backdrop.drawPlainBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.colorControls
import com.kyant.shapes.Rectangle

/**
 * 锁屏玻璃效果
 *
 * 参考官方 LockScreenContent 实现（catalog destinations/LockScreenContent.kt），包含：
 * - drawPlainBackdrop
 * - 2D 拖拽跟随
 * - SDF 纹理支持（需自行提供 [SdfShader]，如 rememberSdfShader(Res.drawable.clock_sdf)）
 * - aspectRatio 自适应（有 SDF 时取 SDF 宽高比）
 *
 * 注意：SDF 纹理依赖 Compose Resources（org.jetbrains.compose.resources），
 * KMP 工程需启用 compose resources 插件；Android-only 工程传入 null 退化为普通玻璃。
 *
 * @param backdrop 背景源
 * @param modifier 修饰符
 * @param sdfShader SDF 着色器（可选，null 时退化为无纹理玻璃）
 * @param content 内容
 */
@Composable
fun LockScreenGlass(
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    sdfShader: SdfShader? = null,
    content: @Composable () -> Unit = {}
) {
    var offset by remember { mutableStateOf(Offset.Zero) }

    Column(
        modifier
            .background(Color.Black.copy(alpha = 0.3f))
            .fillMaxWidth()
    ) {
        Box(
            Modifier
                .weight(1f)
                .fillMaxWidth(),
            contentAlignment = Alignment.Center
        ) {
            Box(
                Modifier
                    .padding(horizontal = 48f.dp)
                    .graphicsLayer {
                        val offset = offset
                        translationX = offset.x
                        translationY = offset.y
                    }
                    .draggable2D(rememberDraggable2DState { delta -> offset += delta })
                    .drawPlainBackdrop(
                        backdrop = backdrop,
                        shape = { Rectangle },
                        effects = {
                            colorControls(brightness = -0.1f, contrast = 0.75f, saturation = 1.5f)
                            blur(2f.dp.toPx())
                            if (sdfShader != null) {
                                with(sdfShader) { apply() }
                            }
                        },
                        onDrawBackdrop = { drawBackdrop ->
                            drawBackdrop()
                            drawRect(Color.White.copy(alpha = 0.25f))
                        }
                    )
                    .widthIn(max = 400f.dp)
                    .aspectRatio(
                        if (sdfShader != null) {
                            sdfShader.width.toFloat() / sdfShader.height.toFloat()
                        } else {
                            1f
                        }
                    )
                    .fillMaxWidth()
            ) {
                content()
            }
        }
        Box(Modifier.weight(1f))
    }
}
