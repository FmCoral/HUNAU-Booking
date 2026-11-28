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

/*
 * WARNING: Library source copy
 * 库源码副本
 *
 * This file is a copy of the backdrop library (io.github.kyant0:backdrop:2.0.0) source,
 * sharing the same package name (com.kyant.backdrop.effects / com.kyant.backdrop.backdrops).
 * - If you depend on the backdrop library via Maven: DELETE this directory.
 *   The component code directly uses the library's identical public APIs, and keeping
 *   this copy would cause duplicate declaration conflicts with the library.
 * - Keep this directory only if you fork the library source (no Maven dependency).
 */
package com.kyant.backdrop.backdrops

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.GraphicsLayerScope
import androidx.compose.ui.graphics.drawscope.ContentDrawScope
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.unit.Density
import com.kyant.backdrop.Backdrop

/**
 * Canvas 背景源
 *
 * 使用 Canvas 绘制自定义背景，不依赖任何布局坐标。
 * 适合静态背景或程序化生成的背景。
 *
 * @param onDraw 自定义绘制逻辑
 */
@Composable
fun rememberCanvasBackdrop(
    onDraw: DrawScope.() -> Unit
): Backdrop {
    return remember(onDraw) {
        CanvasBackdrop(onDraw)
    }
}

@Immutable
private class CanvasBackdrop(
    val onDraw: DrawScope.() -> Unit
) : Backdrop {

    override val isCoordinatesDependent: Boolean = false

    override fun DrawScope.drawBackdrop(
        density: Density,
        coordinates: LayoutCoordinates?,
        layerBlock: (GraphicsLayerScope.() -> Unit)?
    ) {
        onDraw()
    }
}
