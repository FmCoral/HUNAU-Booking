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

package com.kyant.backdrop.catalog.utils

import androidx.activity.compose.BackHandler as AndroidxBackHandler
import androidx.compose.runtime.Composable

/**
 * 返回按钮处理器
 *
 * 封装 BackHandler 以便在 Skill 中统一使用。
 * 使用 AndroidxBackHandler 别名避免与本地函数名冲突。
 */
@Composable
fun BackHandler(
    enabled: Boolean,
    onBack: () -> Unit
) {
    AndroidxBackHandler(enabled, onBack)
}
