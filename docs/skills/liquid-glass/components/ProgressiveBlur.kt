package com.kyant.backdrop.catalog.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.runtimeShaderEffect

/**
 * 渐进模糊玻璃
 *
 * 参考官方 ProgressiveBlurContent 实现，包含：
 * - drawPlainBackdrop
 * - runtimeShaderEffect("AlphaMask")
 * - smoothstep alpha mask
 * - tint gradient
 *
 * @param backdrop 背景源
 * @param modifier 修饰符
 * @param tintColor 着色颜色
 * @param content 内容
 */
@Composable
fun ProgressiveBlurGlass(
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    tintColor: Color = Color.White,
    content: @Composable () -> Unit = {}
) {
    val isLightTheme = !isSystemInDarkTheme()
    val finalTintColor = if (isLightTheme) Color.White else Color(0xFF808080)

    Box(
        modifier
            .drawPlainBackdrop(
                backdrop = backdrop,
                shape = { RectangleShape },
                effects = {
                    blur(4f.dp.toPx())
                    runtimeShaderEffect(
                        "AlphaMask",
                        """
    uniform shader content;
    
    uniform float2 size;
    layout(color) uniform half4 tint;
    uniform float tintIntensity;
    
    half4 main(float2 coord) {
        float blurAlpha = smoothstep(size.y, size.y * 0.5, coord.y);
        float tintAlpha = smoothstep(size.y, size.y * 0.5, coord.y);
        return mix(content.eval(coord) * blurAlpha, tint * tintAlpha, tintIntensity);
    }""",
                        "content"
                    ) {
                        setFloatUniform("size", size.width, size.height)
                        setColorUniform("tint", finalTintColor)
                        setFloatUniform("tintIntensity", 0.8f)
                    }
                }
            )
            .height(128f.dp)
            .fillMaxWidth(),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}
