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

package com.kyant.backdrop.catalog.templates

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.backdrops.rememberLayerBackdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy

/**
 * 玻璃底部弹窗
 *
 * 参考官方教程 Glass Bottom Sheet 实现。
 *
 * 重要：必须使用 `exportedBackdrop` 参数，将弹窗内容导出为独立背景层，
 * 内层玻璃组件再以该背景层作为背景来源，
 * 从而安全实现「玻璃上叠玻璃」，避免递归绘制导致的 SIGSEGV 崩溃
 * （Fatal signal 11 (SIGSEGV), code 2 (SEGV_ACCERR)）。
 *
 * 错误做法（会导致崩溃）：
 * ```
 * val bottomSheetBackdrop = rememberLayerBackdrop()
 * Column(
 *     Modifier
 *         .layerBackdrop(bottomSheetBackdrop)  // 错误：形成循环绘制
 *         .drawBackdrop(...)
 * ) {
 *     Box(Modifier.drawBackdrop(backdrop = bottomSheetBackdrop))
 * }
 * ```
 *
 * @param backdrop 背景源
 */
@Composable
fun BoxScope.GlassBottomSheet(backdrop: Backdrop) {
    // 将弹窗内容导出为独立背景层，供内层玻璃组件使用
    val bottomSheetBackdrop = rememberLayerBackdrop()
    Column(
        Modifier
            .safeContentPadding()
            .drawBackdrop(
                backdrop = backdrop,
                shape = { RoundedCornerShape(44f.dp) },
                effects = {
                    vibrancy()
                    blur(4f.dp.toPx())
                    lens(24f.dp.toPx(), 48f.dp.toPx(), true)
                },
                exportedBackdrop = bottomSheetBackdrop,
                onDrawSurface = { drawRect(Color.White.copy(alpha = 0.5f)) }
            )
            .fillMaxWidth()
            .align(Alignment.BottomCenter)
    ) {
        Spacer(Modifier.height(256f.dp))
        // glass button
        Box(
            Modifier
                .padding(16f.dp)
                .drawBackdrop(
                    backdrop = bottomSheetBackdrop,
                    shape = { CircleShape },
                    shadow = null,
                    effects = {
                        vibrancy()
                        blur(4f.dp.toPx())
                        lens(16f.dp.toPx(), 32f.dp.toPx())
                    },
                    onDrawSurface = { drawRect(Color.White.copy(alpha = 0.5f)) }
                )
                .height(56f.dp)
                .fillMaxWidth()
        )
    }
}
