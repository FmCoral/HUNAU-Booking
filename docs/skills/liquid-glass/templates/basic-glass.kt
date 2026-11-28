package com.kyant.backdrop.catalog

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.dp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy
import com.kyant.backdrop.highlight.Highlight
import com.kyant.backdrop.shadow.InnerShadow
import com.kyant.backdrop.shadow.Shadow

/**
 * 基础玻璃效果模板（v2 — 统一规范）
 *
 * 提供标准液态玻璃容器，包含低模糊 + 强折射 + 色差 + 常驻光影。
 *
 * ## 统一规范
 * | 参数 | 值 |
 * |---|---|
 * | blur | 2dp（低模糊保留内容细节） |
 * | lens | 12dp, 24dp, chromaticAberration=true |
 * | 底色 | 15% 中性雾感（浅色 FAFAFA / 深色 121212） |
 * | 高光 | 0.15 | 阴影 | 0.08 | 内阴影 | 4dp, 0.1 |
 */
@Composable
fun BasicGlass(
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(16.dp),
    blurRadius: Float = 2f.dp.toPx(),
    lensRefraction: Float = 12f.dp.toPx(),
    lensDistortion: Float = 24f.dp.toPx(),
    backgroundColor: Color = if (!isSystemInDarkTheme()) Color(0xFFFAFAFA).copy(alpha = 0.15f)
        else Color(0xFF121212).copy(alpha = 0.15f),
    content: @Composable () -> Unit
) {
    Box(
        modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { shape },
                effects = {
                    vibrancy()
                    blur(blurRadius)
                    lens(lensRefraction, lensDistortion, chromaticAberration = true)
                },
                highlight = { Highlight.Default.copy(alpha = 0.15f) },
                shadow = { Shadow(alpha = 0.08f) },
                innerShadow = { InnerShadow(radius = 4f.dp, alpha = 0.1f) },
                onDrawSurface = { drawRect(backgroundColor) }
            )
            .padding(16.dp),
        content = content
    )
}

/**
 * 无高光简洁玻璃（v2 — 统一规范）
 */
@Composable
fun PlainGlass(
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(16.dp),
    blurRadius: Float = 2f.dp.toPx(),
    backgroundColor: Color = if (!isSystemInDarkTheme()) Color(0xFFFAFAFA).copy(alpha = 0.15f)
        else Color(0xFF121212).copy(alpha = 0.15f),
    content: @Composable () -> Unit
) {
    Box(
        modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { shape },
                effects = {
                    blur(blurRadius)
                    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)
                },
                highlight = null, shadow = null, innerShadow = null,
                onDrawSurface = { drawRect(backgroundColor) }
            )
            .padding(16.dp),
        content = content
    )
}

/**
 * 强模糊玻璃（v2 — 统一规范，适合大卡片，保留旧版 20dp 模糊风格）
 */
@Composable
fun HeavyBlurGlass(
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(24.dp),
    backgroundColor: Color = if (!isSystemInDarkTheme()) Color(0xFFFAFAFA).copy(alpha = 0.2f)
        else Color(0xFF121212).copy(alpha = 0.2f),
    content: @Composable () -> Unit
) {
    Box(
        modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { shape },
                effects = {
                    vibrancy()
                    blur(20f.dp.toPx())
                    lens(32f.dp.toPx(), 32f.dp.toPx(), chromaticAberration = true)
                },
                highlight = { Highlight.Default.copy(alpha = 0.15f) },
                shadow = { Shadow(radius = 32.dp, color = Color.Black.copy(alpha = 0.15f)) },
                innerShadow = { InnerShadow(radius = 4f.dp, alpha = 0.1f) },
                onDrawSurface = { drawRect(backgroundColor) }
            )
            .padding(24.dp),
        content = content
    )
}
