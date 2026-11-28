# 最佳实践

本指南汇总了使用 Backdrop 液态玻璃库的最佳实践，帮助你构建高性能、可维护的玻璃 UI。

## 1. 统一参数规范（v2）

所有液态玻璃组件遵循以下统一参数规范：

| 参数 | 值 | 说明 |
|------|-----|------|
| blur | 2dp | 低模糊保留内容细节 |
| lens | 12dp, 24dp, chromaticAberration=true | 中等折射 + 色散 |
| 底色 | 15% 中性雾感 | 浅色 FAFAFA / 深色 121212 |
| 常驻高光 | 0.15 | Highlight.Default.alpha |
| 常驻阴影 | 0.08 | Shadow.alpha |
| 常驻内阴影 | 4dp, 0.1 | InnerShadow(radius, alpha) |
| 按压高光 | 0.15 + 0.35 * progress | 线性增强 |
| 按压阴影 | 0.08 + 0.22 * progress | 线性增强 |
| 按压内阴影 | 4dp + 8dp * progress, 0.1 + 0.3 * progress | 线性增强 |

### 适用范围

- `InteractiveGlass` — 交互式容器
- `ElasticGlass` — 弹性按压容器
- `GlassIconButton` — 圆形图标按钮（42dp）
- `LiquidButton` — 胶囊按钮（48dp）
- `GlassFilterChip` — 筛选标签（36dp）
- `LiquidBottomTabs` — 底部导航栏
- `LiquidDialog` — 对话框按钮

## 2. 架构设计

### 分层结构

```
Screen
├── BackgroundLayer (背景内容)
│   └── Image, Gradient, etc.
├── GlassLayer (玻璃前景)
│   ├── GlassCard
│   ├── GlassButton
│   └── GlassBottomBar
└── ForegroundLayer (最前景)
    └── Text, Icon, etc.
```

### 示例代码

```kotlin
@Composable
fun GlassScreen() {
    val backdrop = rememberLayerBackdrop()

    Box(modifier = Modifier.fillMaxSize()) {
        // 1. 背景层
        BackgroundContent()

        // 2. 玻璃层
        GlassForeground(backdrop = backdrop)

        // 3. 最前景层（文字、图标等）
        ForegroundContent()
    }
}
```

## 3. Backdrop 管理

### 正确创建和传递

```kotlin
// ✅ 在合适的层级创建
@Composable
fun GlassScreen() {
    val backdrop = rememberLayerBackdrop()

    Column {
        GlassCard(backdrop)
        GlassButton(backdrop)
    }
}

// ❌ 避免在组件内部创建
@Composable
fun BadGlassCard() {
    val backdrop = rememberLayerBackdrop()  // 每次调用都创建新实例
    // ...
}
```

### 组合多个 Backdrop

```kotlin
@Composable
fun ComplexGlass(backdrop: Backdrop) {
    val layerBackdrop = rememberLayerBackdrop()
    val canvasBackdrop = rememberCanvasBackdrop {
        drawRect(Color.Blue)
    }

    val combined = rememberCombinedBackdrop(
        backdrop,
        layerBackdrop,
        canvasBackdrop
    )

    GlassBox(combined)
}
```

## 4. 效果链优化

### 合理的顺序

```kotlin
effects = {
    vibrancy()                    // 1. 先增强色彩
    blur(2f.dp.toPx())           // 2. 再模糊（统一规范）
    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)  // 3. 最后折射
}
```

### 避免过度效果

```kotlin
// ❌ 过多的效果
effects = {
    vibrancy()
    blur(20f.dp.toPx())
    lens(32f.dp.toPx(), 32f.dp.toPx())
    // 自定义效果...
    // 更多效果...
}

// ✅ 精简的效果（统一规范）
effects = {
    vibrancy()
    blur(2f.dp.toPx())
    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)
}
```

## 5. 按压效果最佳实践

### 使用正确的动画对象

```kotlin
// ✅ 正确：在 Composable 作用域创建
@Composable
fun GlassButton() {
    val animationScope = rememberCoroutineScope()
    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }
    // ...
}

// ❌ 错误：在函数参数或局部变量中创建
@Composable
fun BadGlassButton() {
    val interactiveHighlight = InteractiveHighlight(animationScope = coroutineScope)
    // 每次重组都会创建新实例
}
```

### 统一的动画规格

```kotlin
object GlassAnimationSpecs {
    val Press = spring(0.5f, 300f, 0.001f)
    val Release = spring(0.5f, 300f, 0.001f)
    val Drag = spring(1f, 1000f, 0.001f)
    val Scale = spring(0.6f, 250f, 0.001f)
}

// 使用
animationScope.launch {
    pressProgressAnimation.animateTo(1f, GlassAnimationSpecs.Press)
}
```

### 液态按钮形变（LiquidButton 规范）

```kotlin
layerBlock = {
    val progress = interactiveHighlight.pressProgress
    val scale = lerp(1f, 1f + 4f.dp.toPx() / size.height, progress)

    // tanh 平滑拖拽跟随
    val maxOffset = size.minDimension
    translationX = maxOffset * tanh(0.05f * offset.x / maxOffset)
    translationY = maxOffset * tanh(0.05f * offset.y / maxOffset)

    // 方向性拉伸
    val maxDragScale = 4f.dp.toPx() / size.height
    val offsetAngle = atan2(offset.y, offset.x)
    scaleX = scale + maxDragScale * abs(cos(offsetAngle) * offset.x / size.maxDimension) *
            (width / height).coerceAtMost(1f)
    scaleY = scale + maxDragScale * abs(sin(offsetAngle) * offset.y / size.maxDimension) *
            (height / width).coerceAtMost(1f)
}
```

## 6. 主题适配

### 统一主题管理

```kotlin
object GlassTheme {
    val light = GlassColors(
        backgroundColor = Color(0xFFFAFAFA).copy(alpha = 0.15f),
        accentColor = Color(0xFF0088FF),
        highlightColor = Color.White.copy(alpha = 0.5f)
    )

    val dark = GlassColors(
        backgroundColor = Color(0xFF121212).copy(alpha = 0.15f),
        accentColor = Color(0xFF0091FF),
        highlightColor = Color.White.copy(alpha = 0.3f)
    )
}

data class GlassColors(
    val backgroundColor: Color,
    val accentColor: Color,
    val highlightColor: Color
)

@Composable
fun rememberGlassColors(): GlassColors {
    return if (isSystemInDarkTheme()) GlassTheme.dark else GlassTheme.light
}
```

### 使用示例

```kotlin
@Composable
fun ThemedGlassCard(backdrop: Backdrop) {
    val colors = rememberGlassColors()

    Box(
        Modifier.drawBackdrop(
            backdrop = backdrop,
            shape = { RoundedCornerShape(16.dp) },
            effects = {
                vibrancy()
                blur(2f.dp.toPx())
                lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)
            },
            onDrawSurface = { drawRect(colors.backgroundColor) }
        )
    )
}
```

## 7. 可访问性

### 语义属性

```kotlin
Modifier
    .semantics {
        role = Role.Button
        contentDescription = "Glass button"
        stateDescription = if (isPressed) "Pressed" else "Not pressed"
    }
    .clickable(
        interactionSource = null,
        indication = null,
        onClick = onClick
    )
```

### 焦点指示器

```kotlin
Modifier
    .drawBackdrop(...)
    .focusable()
    .focusTarget()
```

## 8. 测试

### UI 测试

```kotlin
@get:Rule
val composeTestRule = createComposeRule()

@Test
fun glassButton_test() {
    composeTestRule.setContent {
        GlassButton(
            onClick = {},
            // 测试环境没有真实图层背景：用官方 emptyBackdrop()（非 Composable，可直接调用）；
            // 需要真实绘制内容时用 rememberCanvasBackdrop { ... }（须在 Composable 内调用）
            backdrop = emptyBackdrop()
        ) {
            Text("Test")
        }
    }

    composeTestRule
        .onNodeWithText("Test")
        .assertIsDisplayed()
        .performClick()
}
```

### 快照测试

```kotlin
@Composable
fun GlassButtonSnapshot() {
    MaterialTheme {
        Surface {
            GlassButton(
                onClick = {},
                // 快照测试同样没有真实图层背景，使用 emptyBackdrop()
                backdrop = emptyBackdrop()
            ) {
                Text("Snapshot")
            }
        }
    }
}
```

## 9. 性能监控

### 自定义性能指标

```kotlin
@Composable
fun GlassWithMetrics(backdrop: Backdrop) {
    var frameTime by remember { mutableStateOf(0L) }

    LaunchedEffect(Unit) {
        while (isActive) {   // 协程取消后立即退出，避免泄漏
            val start = System.nanoTime()
            awaitFrame()
            frameTime = System.nanoTime() - start
        }
    }

    Box(modifier = Modifier
        .drawBackdrop(
            backdrop = backdrop,
            // ...
        )
        .onGloballyPositioned { coordinates ->
            if (frameTime > 16_000_000) {  // 60fps = 16.6ms
                Log.w("Performance", "Frame time: ${frameTime / 1_000_000}ms")
            }
        }
    )
}
```

## 10. 代码组织

### 按功能拆分

```
com/kyant/backdrop/
├── components/          # UI 组件
│   ├── LiquidButton.kt
│   ├── LiquidSlider.kt
│   ├── LiquidToggle.kt
│   └── GlassFilterChip.kt
├── effects/             # 效果封装
│   ├── Blur.kt
│   ├── Lens.kt
│   └── Vibrancy.kt
├── backdrops/           # 背景源
│   ├── LayerBackdrop.kt
│   └── CanvasBackdrop.kt
├── highlight/           # 高光
│   └── Highlight.kt
└── shadow/              # 阴影
    └── Shadow.kt
```

### 统一导入

```kotlin
// 在文件顶部统一导入
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy
import com.kyant.backdrop.highlight.Highlight
import com.kyant.backdrop.shadow.Shadow
```

## 11. 文档和注释

### 组件文档

```kotlin
/**
 * 液态玻璃按钮
 *
 * 参考官方 LiquidButton 实现，包含完整的按压反馈和形变动画。
 *
 * @param onClick 点击回调
 * @param backdrop 背景源
 * @param modifier 修饰符
 * @param isInteractive 是否启用交互效果（默认 true）
 * @param tint 色调叠加（可选）
 * @param surfaceColor 表面颜色（可选）
 * @param content 按钮内容
 */
@Composable
fun LiquidButton(
    onClick: () -> Unit,
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    isInteractive: Boolean = true,
    tint: Color = Color.Unspecified,
    surfaceColor: Color = Color.Unspecified,
    content: @Composable RowScope.() -> Unit
) { ... }
```

### 复杂逻辑注释

```kotlin
// 使用 tanh 实现平滑的触摸跟踪
// tanh 的特性：在小位移时线性，大位移时趋于饱和
// 这模拟了真实物理中的阻尼效果
translationX = maxOffset * tanh(initialDerivative * offset.x / maxOffset)
```

## 总结

遵循这些最佳实践可以帮助你：

- ✅ 构建高性能的玻璃 UI
- ✅ 避免常见的性能和内存问题
- ✅ 保持代码的可维护性
- ✅ 确保在不同设备上的一致体验
