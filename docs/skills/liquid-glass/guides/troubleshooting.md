# 常见问题排查

本指南帮助你解决使用 Backdrop 液态玻璃库时的常见问题。

## 问题 1：模糊效果不生效

### 症状
`blur()` 调用后没有模糊效果，玻璃仍然清晰。

### 原因
- RenderEffect 需要 API 31+ (Android 12.0)
- 某些设备不支持硬件加速的模糊

### 解决方案

```kotlin
// 1. 检查 RenderEffect 支持
import com.kyant.backdrop.isRenderEffectSupported

if (isRenderEffectSupported()) {
    // 应用模糊
    blur(8f.dp.toPx())
}

// 2. 在 build.gradle.kts 中确保 minSdk 设置正确
android {
    defaultConfig {
        minSdk = 21  // Backdrop 2.0.0 最低要求（编译期）
    }
}
// 注意：effects 在 Android 12+ 运行时才生效（RenderEffect），
// 运行时仍需用 isRenderEffectSupported() 检查

// 3. 启用硬件加速（通常在 Application 中已默认开启）
<application
    android:hardwareAccelerated="true"
    ...>
```

### 降级方案

```kotlin
@Composable
fun GlassWithFallback(backdrop: Backdrop) {
    if (isRenderEffectSupported()) {
        // 完整玻璃效果
        GlassWithBlur(backdrop)
    } else {
        // 降级为半透明效果
        GlassFallback(backdrop)
    }
}

@Composable
fun GlassFallback(backdrop: Backdrop) {
    Box(
        Modifier
            .background(Color.White.copy(alpha = 0.2f))
            .padding(16.dp)
    ) {
        Text("Glass effect not supported", color = Color.White)
    }
}
```

## 问题 2：按压效果卡顿

### 症状
点击时动画掉帧、延迟或不流畅。

### 原因
- 在 `LaunchedEffect` 中创建动画对象，导致频繁重建
- 使用了错误的动画规格
- 同时运行过多动画

### 解决方案

```kotlin
// ❌ 错误做法
@Composable
fun BadGlass() {
    LaunchedEffect(Unit) {
        // 每次重组都会重新创建
        val animation = Animatable(0f)
    }
}

// ✅ 正确做法
@Composable
fun GoodGlass() {
    val animationScope = rememberCoroutineScope()

    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }

    // 动画对象只创建一次
}
```

### 优化动画规格

```kotlin
// 使用更快的弹簧参数
val pressSpec = spring(0.5f, 300f, 0.001f)

// 避免过高的 stiffness（会导致抖动）
// 推荐范围：200f - 500f
```

### 减少不必要的重组

```kotlin
// 使用 derivedStateOf 缓存计算结果
val progress by remember {
    derivedStateOf {
        complexCalculation()
    }
}
```

## 问题 3：背景捕获失败

### 症状
玻璃组件显示空白或黑色，没有反射背景内容。

### 原因
- LayerBackdrop 的 LayoutCoordinates 未正确传递
- 背景和玻璃不在同一个图层树中

### 解决方案

```kotlin
// ✅ 正确的结构
@Composable
fun GlassApp() {
    val backdrop = rememberLayerBackdrop()

    Box(Modifier.fillMaxSize()) {
        // 背景层
        BackgroundContent()

        // 前景玻璃层（必须在背景之后）
        ForegroundGlass(backdrop)
    }
}

// ❌ 错误的结构
@Composable
fun BadGlassApp() {
    // 背景和玻璃分离，无法捕获
    BackgroundContent()
    ForegroundGlass()
}
```

### 使用 BackdropDemoScaffold

```kotlin
@Composable
fun GlassScreen() {
    BackdropDemoScaffold { backdrop ->
        // 这里 backdrop 已经正确配置
        GlassBox(backdrop = backdrop)
    }
}
```

> ⚠️ **`BackdropDemoScaffold` 是官方 catalog 的 demo 类（非库公开 API）**，
> 定义在 catalog 包（`com.kyant.backdrop.catalog`），需要从官方源码复制或自行实现等价结构：
> `rememberLayerBackdrop()` + `Modifier.layerBackdrop(backdrop)` 包裹内容 + `BoxScope` 传参。

### 手动传递 LayerBackdrop

```kotlin
@Composable
fun ManualBackdrop() {
    val backdrop = rememberLayerBackdrop()

    // 在某些情况下需要手动设置 coordinates
    BackHandler(enabled = true) {
        // 确保 backdrop 在使用前已定位
    }

    GlassBox(backdrop = backdrop)
}
```

## 问题 4：性能问题

### 症状
- 滚动列表时掉帧
- 多个玻璃组件时卡顿
- 内存占用过高

### 诊断

```kotlin
// 开启 Compose 性能追踪（Kotlin 2.x 使用 compose 插件，无需配置 compiler 版本）
plugins {
    id("org.jetbrains.kotlin.plugin.compose")
}

// 使用 Android Studio Profiler 或 Perfetto 分析帧耗时
```

### 优化方案

#### 1. 减少模糊半径

```kotlin
// ❌ 过大的模糊
blur(32f.dp.toPx())

// ✅ 适当的模糊
blur(8f.dp.toPx())
blur(12f.dp.toPx())
```

#### 2. 简化效果链

```kotlin
// ❌ 过多效果
effects = {
    vibrancy()
    blur(12f.dp.toPx())
    lens(24f.dp.toPx(), 24f.dp.toPx())
    // 额外的自定义效果...
}

// ✅ 精简效果
effects = {
    blur(8f.dp.toPx())
    lens(16f.dp.toPx(), 16f.dp.toPx())
}
```

#### 3. 使用 drawPlainBackdrop

```kotlin
// 当不需要高光和阴影时，使用更轻量的 drawPlainBackdrop
Modifier.drawPlainBackdrop(
    backdrop = backdrop,
    shape = { shape },
    effects = {
        blur(8f.dp.toPx())
        lens(16f.dp.toPx(), 16f.dp.toPx())
    }
)
```

#### 4. 避免在滚动项中同时使用多个玻璃

```kotlin
// ❌ 不好的做法
LazyColumn {
    items(items) { item ->
        GlassCard(backdrop)  // 每个 item 都是玻璃
    }
}

// ✅ 好的做法
LazyColumn {
    items(items) { item ->
        PlainCard(item)  // 使用简单的卡片
    }
}

// 只在必要的地方使用玻璃
Box {
    LazyColumn { /* 普通内容 */ }
    FloatingGlassButton(backdrop)  // 单个玻璃按钮
}
```

#### 5. 缓存 Backdrop

```kotlin
// ✅ 正确缓存
val backdrop = rememberLayerBackdrop()

// ❌ 每次重组都创建新的
val backdrop = rememberLayerBackdrop()  // 如果没有 key，会被缓存
// 但如果有参数变化，记得使用 key
val backdrop = remember(key1 = someParam) {
    rememberLayerBackdrop()
}
```

## 问题 5：主题适配问题

### 症状
- 亮色模式下玻璃效果过暗
- 暗色模式下高光过于刺眼

### 解决方案

```kotlin
@Composable
fun AdaptiveGlass(backdrop: Backdrop) {
    val isLightTheme = !isSystemInDarkTheme()

    val backgroundColor = if (isLightTheme) {
        Color.White.copy(alpha = 0.4f)  // 亮色模式更透明
    } else {
        Color.Black.copy(alpha = 0.2f)  // 暗色模式更深
    }

    val accentColor = if (isLightTheme) {
        Color(0xFF0088FF)
    } else {
        Color(0xFF0091FF)
    }

    Box(
        Modifier.drawBackdrop(
            backdrop = backdrop,
            shape = { RoundedCornerShape(16.dp) },
            effects = {
                blur(8f.dp.toPx())
                lens(16f.dp.toPx(), 16f.dp.toPx())
            },
            onDrawSurface = { drawRect(backgroundColor) }
        )
    )
}
```

## 问题 6：内存泄漏

### 症状
- 页面销毁后动画仍在运行
- Compose 节点未正确释放

### 解决方案

```kotlin
// ✅ 使用 rememberCoroutineScope 自动管理生命周期
@Composable
fun SafeGlass() {
    val animationScope = rememberCoroutineScope()

    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }

    // 当 Composable 销毁时，animationScope 会自动取消
}

// ❌ 避免使用 GlobalScope
GlobalScope.launch {
    // 这会导致内存泄漏
}
```

## 问题 7：drawBackdrop 元素数量过多导致 native 崩溃

### 症状
- 玻璃组件嵌套多层后偶发 `Fatal signal 11 (SIGSEGV)` 或效果整体丢失
- 长列表/网格中每个 item 都是玻璃组件时掉帧甚至崩溃

### 原因
`drawBackdrop` 会将玻璃内容录制到独立图层（GraphicsLayer），GPU 图层的尺寸与数量存在硬件上限；每层玻璃都会复制一份背景采样，元素过多会耗尽 GPU 资源。

### 解决方案

```kotlin
// 1. 玻璃上叠玻璃必须使用 exportedBackdrop（见 SKILL.md「核心概念」），
//    并控制嵌套深度（官方 Demo 不超过 2~3 层）
// 2. 长列表/网格中避免每项独立 backdrop，改为单一 LayerBackdrop 复用背景：
Box(Modifier.layerBackdrop(sharedBackdrop)) {
    LazyColumn {
        items(items) { item -> PlainCard(item) }   // 普通卡片
    }
    FloatingGlassButton(sharedBackdrop)            // 单个玻璃组件复用背景
}
// 3. 精简效果链：单组件保持 color filter ⇒ blur ⇒ lens 一条链
```

## 调试技巧

### 1. 启用布局检查

```kotlin
// Kotlin 2.x 使用 org.jetbrains.kotlin.plugin.compose 插件，无需 composeOptions
// 布局检查直接在 Android Studio 的 Layout Inspector 中进行
```

### 2. 检查 RenderEffect 支持

```kotlin
@Composable
fun CheckSupport() {
    val supported = isRenderEffectSupported()
    Log.d("Glass", "RenderEffect supported: $supported")
}
```

### 3. 可视化 Backdrop 内容

```kotlin
// ❌ 错误做法：Backdrop.drawBackdrop(density, coordinates, layerBlock) 需要
// 有效的 LayoutCoordinates（依赖图层树中的位置），传 null 无法绘制任何内容
@Composable
fun DebugBackdropWrong(backdrop: Backdrop) {
    Canvas(modifier = Modifier.fillMaxSize()) {
        with(backdrop) {
            drawBackdrop(density = this, coordinates = null, layerBlock = null)
        }
    }
}

// ✅ 正确做法 1：通过 drawBackdrop 修饰符直接可视化（背景内容会反射到玻璃上）
@Composable
fun DebugBackdrop(backdrop: Backdrop, content: @Composable () -> Unit) {
    Box(
        Modifier
            .fillMaxSize()
            .drawBackdrop(
                backdrop = backdrop,
                shape = { Rectangle },   // 用矩形占满整个区域即可完整显示背景
                effects = { blur(2f.dp.toPx()) },
                onDrawSurface = { drawRect(Color.White.copy(alpha = 0.05f)) }
            )
    ) { content() }
}

// ✅ 正确做法 2：不依赖图层坐标的调试用背景（CanvasBackdrop）
val debugBackdrop = rememberCanvasBackdrop {
    drawRect(Color(0xFF667eea))
    drawCircle(Color(0xFFf093fb), radius = size.minDimension / 3f)
}
```

## 获取帮助

如果以上方案无法解决你的问题：

1. 查看官方文档：https://kyant.gitbook.io/backdrop
2. 访问 GitHub Issues：https://github.com/Kyant0/AndroidLiquidGlass/issues
3. 参考官方示例：https://github.com/Kyant0/AndroidLiquidGlass（`kmp` 分支，catalog 示例在 `catalog/` 目录）
