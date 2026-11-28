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
package com.kyant.backdrop.effects

import androidx.annotation.FloatRange
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.TileMode
import com.kyant.backdrop.BackdropEffectScope
import com.kyant.backdrop.isRenderEffectSupported

/**
 * 模糊效果扩展函数
 *
 * @param radius 模糊半径（像素）
 * @param edgeTreatment 边缘处理模式，默认 Clamp
 */
fun BackdropEffectScope.blur(
    @FloatRange(from = 0.0) radius: Float,
    edgeTreatment: TileMode = TileMode.Clamp
) {
    if (!isRenderEffectSupported()) return
    if (radius <= 0f) return

    if (edgeTreatment != TileMode.Clamp || renderEffect != null) {
        if (radius > padding) {
            padding = radius
        }
    }

    renderEffect =
        BlurEffect(
            renderEffect,
            radius,
            radius,
            edgeTreatment
        )
}
