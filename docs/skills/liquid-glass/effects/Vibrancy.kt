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

import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.ColorMatrixColorFilter
import com.kyant.backdrop.BackdropEffectScope
import com.kyant.backdrop.internal.ColorFilterEffect
import com.kyant.backdrop.isRenderEffectSupported

/**
 * 色彩增强效果
 *
 * 增强背景的色彩饱和度和对比度，使玻璃效果更加生动。
 *
 * @param saturation 饱和度，默认 1.5f
 */
fun BackdropEffectScope.vibrancy(
    saturation: Float = 1.5f
) {
    colorFilter(vibrancyColorFilter(saturation))
}

/**
 * 自定义色彩控制
 *
 * @param brightness 亮度 (-1f 到 1f)
 * @param contrast 对比度 (0f 到 2f)
 * @param saturation 饱和度 (0f 到 2f)
 */
fun BackdropEffectScope.colorControls(
    brightness: Float = 0f,
    contrast: Float = 1f,
    saturation: Float = 1f
) {
    if (brightness == 0f && contrast == 1f && saturation == 1f) {
        return
    }

    colorFilter(colorControlsColorFilter(brightness, contrast, saturation))
}

/**
 * 不透明度效果
 *
 * @param alpha 透明度 (0f 到 1f)
 */
fun BackdropEffectScope.opacity(alpha: Float) {
    val colorMatrix = ColorMatrix(
        floatArrayOf(
            1f, 0f, 0f, 0f, 0f,
            0f, 1f, 0f, 0f, 0f,
            0f, 0f, 1f, 0f, 0f,
            0f, 0f, 0f, alpha, 0f
        )
    )
    colorFilter(ColorMatrixColorFilter(colorMatrix))
}

private val VibrantColorFilter = colorControlsColorFilter(saturation = 1.5f)

private fun vibrancyColorFilter(saturation: Float): ColorFilter {
    return colorControlsColorFilter(saturation = saturation)
}

private fun colorControlsColorFilter(
    brightness: Float = 0f,
    contrast: Float = 1f,
    saturation: Float = 1f
): ColorFilter {
    val invSat = 1f - saturation
    val r = 0.213f * invSat
    val g = 0.715f * invSat
    val b = 0.072f * invSat

    val c = contrast
    val t = (0.5f - c * 0.5f + brightness) * 255f
    val s = saturation

    val cr = c * r
    val cg = c * g
    val cb = c * b
    val cs = c * s

    val colorMatrix = ColorMatrix(
        floatArrayOf(
            cr + cs, cg, cb, 0f, t,
            cr, cg + cs, cb, 0f, t,
            cr, cg, cb + cs, 0f, t,
            0f, 0f, 0f, 1f, 0f
        )
    )
    return ColorMatrixColorFilter(colorMatrix)
}
