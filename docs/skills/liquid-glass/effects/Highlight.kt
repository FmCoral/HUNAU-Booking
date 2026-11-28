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

import androidx.compose.runtime.Composable
import com.kyant.backdrop.BackdropEffectScope
import com.kyant.backdrop.highlight.Highlight
import com.kyant.backdrop.highlight.HighlightStyle

/**
 * 高光效果扩展函数
 *
 * @param highlight 高光配置
 */
fun BackdropEffectScope.highlight(
    highlight: Highlight
) {
    // 高光通过 drawBackdrop 的 highlight 参数应用
    // 这里仅为类型别名，实际使用请参考 drawBackdrop API
}

/**
 * 预定义高光样式
 */
object GlassHighlights {
    /**
     * 默认对角线高光
     */
    val Default = Highlight.Default

    /**
     * 环境光散射
     */
    val Ambient = Highlight.Ambient

    /**
     * 纯色叠加（无渐变）
     */
    val Plain = Highlight.Plain

    /**
     * 强高光（适合亮色主题）
     */
    val Strong = Highlight(
        width = 1f.dp,
        blurRadius = 0.5f.dp,
        alpha = 0.8f,
        style = HighlightStyle.Default(falloff = 2f)
    )

    /**
     * 弱高光（适合暗色主题）
     */
    val Weak = Highlight(
        width = 0.5f.dp,
        blurRadius = 0.25f.dp,
        alpha = 0.3f,
        style = HighlightStyle.Default(falloff = 0.5f)
    )
}
