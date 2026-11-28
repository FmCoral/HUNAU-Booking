package com.kyant.backdrop.catalog.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.kyant.shapes.Capsule

internal val LocalLiquidBottomTabScale =
    staticCompositionLocalOf { { 1f } }

internal val LocalSelectTab =
    staticCompositionLocalOf<(Int) -> Unit> { {} }

/**
 * 底部导航栏单个 Tab 交互项
 *
 * 当用户点击任意 Tab 标题项时，立即通知 LiquidBottomTabs 对应的 selectTab(index)，
 * 精准激发 DampedDragAnimation 产生 1.2x 按压缩放、透镜折射与高光，
 * 并以弹簧物理曲线将液态指示器平滑滑行移至目标 Tab！
 */
@Composable
fun RowScope.LiquidBottomTab(
    index: Int = 0,
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    val scale = LocalLiquidBottomTabScale.current
    val selectTab = LocalSelectTab.current

    Column(
        modifier
            .clip(Capsule())
            .clickable(
                interactionSource = null,
                indication = null,
                role = Role.Tab,
                onClick = {
                    onClick()
                    selectTab(index)
                }
            )
            .fillMaxHeight()
            .weight(1f)
            .graphicsLayer {
                val scaleValue = scale()
                scaleX = scaleValue
                scaleY = scaleValue
            },
        verticalArrangement = Arrangement.spacedBy(2f.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
        content = content
    )
}
