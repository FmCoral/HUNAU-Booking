---
name: skill-liquid-glass
description: 基于 Backdrop 2.0.0 库（Compose Multiplatform）的液态玻璃效果 Skill。当用户需要实现毛玻璃、液态玻璃 UI、按压交互、底部导航、滑块、开关、底部弹窗、放大镜、控制中心、锁屏等效果时使用本 Skill。也适用于需要背景实时反射/折射、模糊、折射、高光、阴影等视觉效果的前景组件开发。支持 Android（effects 需 12+，RuntimeShader 需 13+）与 KMP 工程。
version: 1.0.0
tags:
  - android
  - compose
  - glassmorphism
  - backdrop
  - ui
---

# Android Liquid Glass Skill

完整的 Jetpack Compose / Compose Multiplatform 液态玻璃效果实现技能。基于 [Backdrop](https://github.com/Kyant0/AndroidLiquidGlass) 库（2.0.0，KMP），提供从基础玻璃效果到完整交互组件的全流程实现方案。

## 核心能力

- ✅ **基础液态玻璃效果**：模糊 + 折射 + 高光 + 阴影 + 内阴影
- ✅ **按压交互效果**：弹性动画、拖拽反馈、状态过渡
- ✅ **完整组件库**：底部导航栏、顶部导航栏、按钮、滑块、开关、底部弹窗、搜索框、弹出菜单、液态玻璃键盘
- ✅ **全流程无错实现**：包含配置、依赖、性能优化和常见问题排查
- ✅ **多主题支持**：自动适配亮色/暗色主题

## 何时使用

当用户需要以下效果时，使用此 Skill：

- 实现 iOS 风格的毛玻璃/液态玻璃 UI
- 创建具有物理反馈的交互式按钮和导航
- 构建底部标签栏、顶部导航栏、搜索框、弹出菜单等控件
- 实现自定义液态玻璃软键盘（拼音 / 英文 / 符号输入）
- 需要背景实时反射/折射的前景组件
- 优化 Compose 中的模糊和 RenderEffect 性能

## 技术栈

- **核心库**：`io.github.kyant0:backdrop:2.0.0`（**Compose Multiplatform**，首个 KMP 版本）
- **UI 框架**：Jetpack Compose / Compose Multiplatform（Kotlin 2.1.x+，官方构建使用 Kotlin 2.4.10 + CMP 1.11.1 + AGP 9.3.0）
- **最低 SDK**：API 21（官方库实测值）；**effects 仅 Android 12+ (API 31) 生效**，**RuntimeShader 需 Android 13+ (API 33)**
- **推荐 SDK**：API 33+（完整 effects + RuntimeShader 支持）
- **内置依赖**：shapes 库（`io.github.kyant0:shapes`）为 backdrop 的传递依赖，无需单独声明

### 1.x -> 2.0 迁移说明

2.0.0 是首个 Compose Multiplatform 版本，主要变更（来自官方 release notes）：

- **移除 Android 相关 effects**，改用 Compose 版本实现（跨平台统一）
- **新增通用 `RuntimeShader` 接口**（`expect fun RuntimeShader(shaderString: String)`）与 `BackdropEffectScope.runtimeShaderEffect`，跨平台统一
- `Backdrop` / `drawBackdrop` / `drawPlainBackdrop` 等核心 API 签名保持不变，1.x 工程升级后一般无需改动调用代码

## 快速开始

### 1. 安装依赖

```kotlin
// build.gradle.kts (Module level) - Android 工程
dependencies {
    implementation("io.github.kyant0:backdrop:2.0.0")
}

// KMP 工程：在 commonMain 的 dependencies 中声明，并在 module 应用
// org.jetbrains.compose 与 org.jetbrains.kotlin.plugin.compose 插件
```

### 2. 基础玻璃组件

```kotlin
@Composable
fun GlassBox(
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(16.dp),
    content: @Composable BoxScope.() -> Unit
) {
    Box(
        modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { shape },
                effects = {
                    vibrancy()
                    blur(2f.dp.toPx())
                    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)
                },
                highlight = { Highlight.Default },
                shadow = { Shadow.Default },
                onDrawSurface = { drawRect(Color.White.copy(alpha = 0.1f)) }
            )
            .clip(shape),
        content = content
    )
}
```

### 3. 按压交互玻璃

```kotlin
@Composable
fun InteractiveGlassButton(
    onClick: () -> Unit,
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit
) {
    val animationScope = rememberCoroutineScope()
    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }

    Row(
        modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { Capsule() },
                effects = {
                    vibrancy()
                    blur(2f.dp.toPx())
                    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)
                },
                layerBlock = {
                    val progress = interactiveHighlight.pressProgress
                    val scale = lerp(1f, 1f + 4f.dp.toPx() / size.height, progress)
                    scaleX = scale
                    scaleY = scale
                },
                onDrawSurface = { drawRect(Color.White.copy(alpha = 0.1f)) }
            )
            .clickable(
                interactionSource = null,
                indication = null,
                onClick = onClick
            )
            .then(interactiveHighlight.modifier)
            .then(interactiveHighlight.gestureModifier)
            .height(48f.dp)
            .padding(horizontal = 16f.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
        content = content
    )
}
```

## 目录结构

```
skill-liquid-glass/
├── SKILL.md                          # 本文件
├── templates/                        # 基础效果模板
│   ├── basic-glass.kt                # 基础玻璃效果
│   ├── interactive-glass.kt          # 交互式玻璃
│   ├── glass-bottom-bar.kt           # 底部导航栏（简化版）
│   ├── glass-navigation-bar.kt       # 完整底部导航栏（指示器动画）
│   ├── glass-bottom-sheet.kt         # 底部弹窗模板
│   ├── glass-top-bar.kt              # 顶部导航栏模板
│   ├── glass-keyboard.kt             # 液态玻璃键盘模板
│   └── glass-app-framework.kt        # 完整应用框架模板
├── components/                       # 完整组件
│   ├── LiquidButton.kt               # 玻璃按钮
│   ├── LiquidTopBar.kt               # 顶部导航栏容器
│   ├── LiquidTitleChip.kt            # 标题玻璃芯片
│   ├── LiquidMenuButton.kt           # 三点菜单按钮
│   ├── LiquidSearchBar.kt            # 搜索输入框
│   ├── LiquidPopupMenu.kt            # 弹出菜单 + 菜单项
│   ├── LiquidKeyboard.kt             # 液态玻璃键盘
│   ├── GlassFilterChip.kt            # 筛选标签
│   ├── LiquidBottomTabs.kt           # 玻璃底部导航
│   ├── LiquidBottomTab.kt            # 单个标签项
│   ├── LiquidSlider.kt               # 玻璃滑块
│   ├── LiquidToggle.kt               # 玻璃开关
│   ├── LiquidBottomSheet.kt          # 玻璃底部弹窗
│   ├── LiquidDialog.kt               # 玻璃对话框
│   ├── ControlCenter.kt              # 控制中心
│   ├── ControlCenterItems.kt         # 控制中心网格
│   ├── LockScreenGlass.kt            # 锁屏玻璃
│   ├── MagnifierGlass.kt             # 放大镜
│   ├── GlassPlayground.kt            # 玻璃实验室
│   ├── AdaptiveLuminanceGlass.kt     # 自适应亮度玻璃
│   ├── ProgressiveBlur.kt            # 渐进模糊
│   ├── ScrollGlassContainers.kt      # 滚动玻璃容器
│   ├── InteractiveHighlight.kt       # 交互高光
│   ├── DampedDragAnimation.kt        # 阻尼拖拽动画
│   ├── DragGestureInspector.kt       # 拖拽手势检测
│   ├── BackHandler.kt                # 返回处理
│   ├── UISensor.kt                   # 重力感应
│   └── ...
├── effects/                          # 特效封装（库源码副本）
│   ├── Blur.kt                       # 模糊效果
│   ├── Lens.kt                       # 折射效果
│   ├── Vibrancy.kt                   # 色彩增强
│   └── Highlight.kt                  # 高光效果
├── backdrops/                        # 背景源（库源码副本）
│   ├── LayerBackdrop.kt              # 图层背景
│   ├── CanvasBackdrop.kt             # Canvas 背景
│   └── CombinedBackdrop.kt           # 组合背景
├── utils/                            # 工具类
│   ├── Ripple.kt                     # 涟漪效果（AOSP）
│   ├── PinyinLexiconEngine.kt        # 拼音词典引擎
│   ├── ProgressConverter.kt          # 进度曲线
│   ├── Bitmap.kt                     # Bitmap 工具
│   ├── Coroutines.kt                 # 协程工具
│   └── SdfShader.kt                  # SDF 着色器
└── guides/                           # 使用指南
    ├── quick-start.md                # 快速开始
    ├── press-effects.md              # 按压效果详解
    ├── troubleshooting.md            # 常见问题
    ├── best-practices.md             # 最佳实践
    └── build-config.md               # 构建配置
```

### 目录定位

- **`effects/` 与 `backdrops/` 是 backdrop 库的源码副本**（包名 `com.kyant.backdrop.effects` / `com.kyant.backdrop.backdrops` 与库相同）：
  - **通过 Maven 依赖 backdrop 库时**：请删除这两个目录。组件代码直接使用库的同名公开 API，保留副本会与库产生**重复声明冲突**。
  - **fork 库源码（不依赖 Maven 制品）的场景**：保留，作为库实现参考。
- **`components/`、`templates/`、`utils/`**：本 Skill 的组件与工具（部分改编自官方 catalog，catalog 组件依赖 `com.kyant.backdrop.catalog.*` 资源，复制时需一并拷贝）。
  - `components/` 包含全部玻璃 UI 组件及交互工具类（InteractiveHighlight、DampedDragAnimation、DragGestureInspector 等）。
  - `utils/` 包含通用工具（Ripple 涟漪效果、PinyinLexiconEngine 拼音词典、ProgressConverter、Bitmap、Coroutines、SdfShader）。
  - `templates/` 包含从基础玻璃到完整应用框架的可复制模板，每个模板 KDoc 中列出了所需复制的依赖文件。
- **`guides/`**：使用指南（快速开始 / 按压效果 / 常见问题 / 最佳实践 / 构建配置）。

## 核心概念

### Backdrop（背景源）

Backdrop 定义了玻璃组件要反射的内容来源：

- **LayerBackdrop**：捕获另一个 Compose 图层作为背景（最常用）
- **CanvasBackdrop**：使用 Canvas 绘制自定义背景
- **CombinedBackdrop**：组合多个背景源

### Effects（效果链）

在 `drawBackdrop` 的 `effects` 参数中按顺序应用：

```kotlin
effects = {
    vibrancy()          // 1. 色彩增强（可选）
    blur(2f.dp.toPx())  // 2. 模糊强度（统一规范 2dp）
    lens(12f.dp.toPx(), 24f.dp.toPx(), chromaticAberration = true)  // 3. 折射效果
}
```

> **重要**：效果必须按 **color filter => blur => lens** 的顺序应用，否则视觉效果不正确。
> **平台前提**：全部 effects 需 Android 12+（RenderEffect）；`lens` 的 `depthEffect` / `chromaticAberration`、`runtimeShaderEffect` 需 Android 13+（RuntimeShader）。
> **lens 约束**：`refractionHeight` 属于 [0, shape.minCornerRadius]（非 `CornerBasedShape` 的 shape 该值为 0，lens 无效果）、`refractionAmount` 属于 [0, size.minDimension]。

### exportedBackdrop（玻璃上叠玻璃）

当玻璃组件内部再嵌套玻璃组件时（如底部弹窗内放玻璃按钮），必须使用 `exportedBackdrop` 参数将外层内容导出为独立背景层，避免递归绘制导致崩溃：

```kotlin
val bottomSheetBackdrop = rememberLayerBackdrop()
Column(
    Modifier.drawBackdrop(
        backdrop = backdrop,
        exportedBackdrop = bottomSheetBackdrop,
    )
) {
    // 内层玻璃组件以 bottomSheetBackdrop 作为背景
    Box(
        Modifier.drawBackdrop(
            backdrop = bottomSheetBackdrop,
        )
    )
}
```

**错误做法**（会导致 SIGSEGV 崩溃）：
```kotlin
val bottomSheetBackdrop = rememberLayerBackdrop()
Column(
    Modifier
        .layerBackdrop(bottomSheetBackdrop)  // 形成循环绘制
        .drawBackdrop(...)
)
```

### Highlight（高光）

模拟光线在玻璃表面的反射：

- `Highlight.Default`：对角线高光
- `Highlight.Ambient`：环境光散射
- `Highlight.Plain`：纯色叠加

### Shadow（阴影）

- `Shadow`：外部阴影
- `InnerShadow`：内部阴影（按压时常用）

### 色调（Tint）

推荐使用 `BlendMode.Hue` 保持背景色相：

```kotlin
onDrawSurface = {
    val tint = Color(0xFF0088FF)
    drawRect(tint, blendMode = BlendMode.Hue)
    drawRect(tint.copy(alpha = 0.75f))
}
```

## API 参考

> **平台前提（2.0.0 / Compose Multiplatform）**：
> - 全部 `effects`（blur / lens / vibrancy / colorControls / opacity / colorFilter / effect）基于 RenderEffect，仅 Android 12+ (API 31) 生效，低版本静默跳过；
> - `lens(depthEffect / chromaticAberration)` 与 `runtimeShaderEffect` 基于 RuntimeShader，仅 Android 13+ (API 33) 生效；
> - 非 Android 平台使用 Compose 的跨平台实现。
> 以下签名均与官方 2.0.0 源码逐行核对。

### Modifier 扩展函数

#### drawBackdrop

```kotlin
fun Modifier.drawBackdrop(
    backdrop: Backdrop,
    shape: () -> Shape,
    effects: BackdropEffectScope.() -> Unit,
    highlight: (() -> Highlight?)? = DefaultHighlight,
    shadow: (() -> Shadow?)? = DefaultShadow,
    innerShadow: (() -> InnerShadow?)? = null,
    layerBlock: (GraphicsLayerScope.() -> Unit)? = null,
    exportedBackdrop: LayerBackdrop? = null,
    onDrawBehind: (DrawScope.() -> Unit)? = null,
    onDrawBackdrop: DrawScope.(drawBackdrop: DrawScope.() -> Unit) -> Unit = DefaultOnDrawBackdrop,
    onDrawSurface: (DrawScope.() -> Unit)? = null,
    onDrawFront: (DrawScope.() -> Unit)? = null
): Modifier
```

核心玻璃绘制修饰符，支持高光、阴影、内阴影和完整的绘制管线控制。

#### drawPlainBackdrop

```kotlin
fun Modifier.drawPlainBackdrop(
    backdrop: Backdrop,
    shape: () -> Shape,
    effects: BackdropEffectScope.() -> Unit,
    layerBlock: (GraphicsLayerScope.() -> Unit)? = null,
    exportedBackdrop: LayerBackdrop? = null,
    onDrawBehind: (DrawScope.() -> Unit)? = null,
    onDrawBackdrop: DrawScope.(drawBackdrop: DrawScope.() -> Unit) -> Unit = DefaultOnDrawBackdrop,
    onDrawSurface: (DrawScope.() -> Unit)? = null,
    onDrawFront: (DrawScope.() -> Unit)? = null
): Modifier
```

轻量版玻璃绘制，无高光和阴影，适合性能敏感场景。

### Backdrop 创建函数

#### rememberLayerBackdrop

```kotlin
@Composable
fun rememberLayerBackdrop(
    graphicsLayer: GraphicsLayer = rememberGraphicsLayer(),
    onDraw: ContentDrawScope.() -> Unit = { drawContent() }
): LayerBackdrop
```

捕获 Compose 图层作为背景源。最常用。

#### rememberCanvasBackdrop

```kotlin
@Composable
fun rememberCanvasBackdrop(
    onDraw: DrawScope.() -> Unit
): Backdrop
```

使用 Canvas 绘制自定义背景。

#### rememberCombinedBackdrop

```kotlin
@Composable
fun rememberCombinedBackdrop(
    backdrop1: Backdrop,
    backdrop2: Backdrop
): Backdrop

@Composable
fun rememberCombinedBackdrop(
    backdrop1: Backdrop,
    backdrop2: Backdrop,
    backdrop3: Backdrop
): Backdrop

@Composable
fun rememberCombinedBackdrop(vararg backdrops: Backdrop): Backdrop
```

组合多个背景源。

### 效果函数

#### blur

```kotlin
fun BackdropEffectScope.blur(
    radius: Float,
    edgeTreatment: TileMode = TileMode.Clamp
)
```

高斯模糊效果。

| 参数 | 说明 |
|------|------|
| radius | 模糊半径（像素） |
| edgeTreatment | 边缘处理模式，默认 Clamp |

#### lens

```kotlin
fun BackdropEffectScope.lens(
    refractionHeight: Float,
    refractionAmount: Float,
    depthEffect: Boolean = false,
    chromaticAberration: Boolean = false
)
```

透镜折射效果，模拟光线通过玻璃的折射。

| 参数 | 说明 |
|------|------|
| refractionHeight | 折射高度（像素），约束 属于 [0, shape.minCornerRadius] |
| refractionAmount | 折射强度（像素），约束 属于 [0, size.minDimension] |
| depthEffect | 是否启用深度效果（需 Android 13+ RuntimeShader） |
| chromaticAberration | 是否启用色散/彩虹边缘（需 Android 13+ RuntimeShader） |

#### colorControls

```kotlin
fun BackdropEffectScope.colorControls(
    brightness: Float = 0f,
    contrast: Float = 1f,
    saturation: Float = 1f
)
```

自定义色彩控制。

| 参数 | 说明 |
|------|------|
| brightness | 亮度 (-1f ~ 1f) |
| contrast | 对比度 (0f ~ 2f) |
| saturation | 饱和度 (0f ~ 2f) |

#### vibrancy

```kotlin
fun BackdropEffectScope.vibrancy()
```

色彩增强，等同于 `colorControls(saturation = 1.5f)`。

#### opacity

```kotlin
fun BackdropEffectScope.opacity(alpha: Float)
```

不透明度调整 (0f ~ 1f)。

#### colorFilter

```kotlin
fun BackdropEffectScope.colorFilter(colorFilter: ColorFilter)
```

直接传入自定义 `ColorFilter`。

#### effect

```kotlin
fun BackdropEffectScope.effect(effect: RenderEffect)
```

直接传入自定义 `RenderEffect`。

#### runtimeShaderEffect

```kotlin
fun BackdropEffectScope.runtimeShaderEffect(
    key: String,
    shaderString: String,
    uniformShaderName: String,
    block: RuntimeShader.() -> Unit
)
```

自定义 AGSL RuntimeShader 效果（需 Android 13+）。

#### exposureAdjustment / gammaAdjustment

```kotlin
// 官方文档提及、2.0.0 源码未实现
fun BackdropEffectScope.exposureAdjustment(exposure: Float)   // 文档：曝光调节
fun BackdropEffectScope.gammaAdjustment(gamma: Float)         // 文档：伽马校正
```

> 这两个效果出现在官方 backdrop-effects 文档中，但 **2.0.0（kmp 分支）源码没有对应实现文件**（官方 effects 实际包含：colorFilter / opacity / colorControls / vibrancy / blur / lens / effect / runtimeShaderEffect）。
> 需要曝光/伽马调节时，可用 `colorControls(brightness, contrast)` 近似，或自行实现 RuntimeShader。

### Backdrop 接口

```kotlin
interface Backdrop {
    val isCoordinatesDependent: Boolean
    fun DrawScope.drawBackdrop(
        density: Density,
        coordinates: LayoutCoordinates?,
        layerBlock: (GraphicsLayerScope.() -> Unit)? = null
    )
}
```

### 其他 Backdrop 函数

#### emptyBackdrop

```kotlin
@Stable
fun emptyBackdrop(): Backdrop
```

空背景源，不绘制任何内容。

#### rememberBackdrop

```kotlin
@Composable
fun rememberBackdrop(
    backdrop: Backdrop,
    onDraw: DrawScope.(drawBackdrop: DrawScope.() -> Unit) -> Unit
): Backdrop
```

以自定义命令绘制背景。

#### Modifier.layerBackdrop

```kotlin
fun Modifier.layerBackdrop(backdrop: LayerBackdrop): Modifier
```

将 Composable 的内容绘制到指定的 `LayerBackdrop` 中。

> **重要**：`rememberLayerBackdrop` 必须配合 `Modifier.layerBackdrop` 使用，
> 或通过 `drawBackdrop` 修饰符的 `exportedBackdrop` 参数派生。
> 不要在 `layerBackdrop` 之后再用该 backdrop 调用 `drawBackdrop`（会形成循环绘制导致 SIGSEGV 崩溃）。

### BackdropEffectScope 接口

```kotlin
sealed interface BackdropEffectScope : Density, RuntimeShaderCache {
    val size: Size
    val layoutDirection: LayoutDirection
    val shape: Shape
    var padding: Float
    var renderEffect: RenderEffect?
}
```

### 支持性检查函数

```kotlin
expect fun isRenderEffectSupported(): Boolean
expect fun isRuntimeShaderSupported(): Boolean
```

- `isRenderEffectSupported()`：RenderEffect 是否可用（Android 12+）
- `isRuntimeShaderSupported()`：RuntimeShader 是否可用（Android 13+）

### RuntimeShader

```kotlin
expect fun RuntimeShader(@Language("AGSL") shaderString: String): RuntimeShader

// 转换为 Compose Shader（用于 DrawScope 绘制）
expect fun RuntimeShader.asComposeShader(): Shader

interface RuntimeShader {
    fun setFloatUniform(name: String, value: Float)
    fun setFloatUniform(name: String, value1: Float, value2: Float)
    fun setFloatUniform(name: String, value1: Float, value2: Float, value3: Float)
    fun setFloatUniform(name: String, value1: Float, value2: Float, value3: Float, value4: Float)
    fun setFloatUniform(name: String, values: FloatArray)

    fun setIntUniform(name: String, value: Int)
    fun setIntUniform(name: String, value1: Int, value2: Int)
    fun setIntUniform(name: String, value1: Int, value2: Int, value3: Int)
    fun setIntUniform(name: String, value1: Int, value2: Int, value3: Int, value4: Int)
    fun setIntUniform(name: String, values: IntArray)

    fun setColorUniform(name: String, color: Color)
}
```

2.0.0 新增的通用跨平台 RuntimeShader 接口（KMP `expect` 声明，各平台有 `actual` 实现）。
`setFloatUniform` / `setIntUniform` 为**固定重载**（1~4 个标量 + 数组），不支持 vararg。
在 `effects` 中通过 `runtimeShaderEffect(key, shaderString, uniformShaderName) { ... }` 使用；在普通 DrawScope 中通过 `asComposeShader()` 使用。

### RuntimeShaderCache

```kotlin
sealed interface RuntimeShaderCache {
    fun obtainRuntimeShader(key: String, string: String): RuntimeShader
}
```

### HighlightStyle 接口

```kotlin
interface HighlightStyle {
    val color: Color
    val blendMode: BlendMode
    fun DrawScope.createShader(
        shape: Shape,
        runtimeShaderCache: RuntimeShaderCache
    ): RuntimeShader?
}
```

| 预定义值 | 说明 |
|----------|------|
| `HighlightStyle.Default(angle, falloff)` | 对角线高光（angle 为角度，falloff 为衰减） |
| `HighlightStyle.Ambient(intensity)` | 环境光散射（intensity 为强度 0~1） |
| `HighlightStyle.Plain` | 纯色叠加 |

### Highlight 类型

```kotlin
data class Highlight(
    val width: Dp = 0.5f.dp,
    val blurRadius: Dp = width / 2f,
    val alpha: Float = 1f,
    val style: HighlightStyle = HighlightStyle.Default
)
```

| 预定义值 | 说明 |
|----------|------|
| `Highlight.Default` | 对角线高光 |
| `Highlight.Ambient` | 环境光散射 |
| `Highlight.Plain` | 纯色叠加 |

### Shadow 类型

```kotlin
data class Shadow(
    val radius: Dp = 24f.dp,
    val offset: DpOffset = DpOffset(0f.dp, radius / 6f),
    val color: Color = Color.Black.copy(alpha = 0.1f),
    val alpha: Float = 1f,
    val blendMode: BlendMode = DrawScope.DefaultBlendMode
)
```

```kotlin
data class InnerShadow(
    val radius: Dp = 24f.dp,
    val offset: DpOffset = DpOffset(0f.dp, radius),
    val color: Color = Color.Black.copy(alpha = 0.15f),
    val alpha: Float = 1f,
    val blendMode: BlendMode = DrawScope.DefaultBlendMode
)
```

## 组件清单

### 基础模板

| 组件 | 说明 | 文件 |
|------|------|------|
| `BasicGlass` | 基础玻璃卡片 | `templates/basic-glass.kt` |
| `PlainGlass` | 简洁玻璃（无高光阴影） | `templates/basic-glass.kt` |
| `HeavyBlurGlass` | 强模糊玻璃 | `templates/basic-glass.kt` |
| `InteractiveGlass` | 交互式玻璃（全形变 + 按压反馈） | `templates/interactive-glass.kt` |
| `ElasticGlass` | 弹性按压玻璃（弹性缩放动画） | `templates/interactive-glass.kt` |
| `GlassIconButton` | 圆形图标按钮（42dp，FAB 同款） | `templates/interactive-glass.kt` |
| `GlassBottomBar` | 底部导航栏（简化版，委托 LiquidBottomTabs） | `templates/glass-bottom-bar.kt` |

### 交互组件

| 组件 | 说明 | 按压类型 | 文件 |
|------|------|----------|------|
| `LiquidButton` | 玻璃按钮 | A + B | `components/LiquidButton.kt` |
| `LiquidIconButton` | 图标按钮 | A + B | `components/LiquidButton.kt` |
| `GlassFilterChip` | 筛选标签 | A + B | `components/GlassFilterChip.kt` |
| `LiquidBottomTabs` | 底部导航 | A + B + C | `components/LiquidBottomTabs.kt` |
| `LiquidBottomTab` | 单个标签 | C | `components/LiquidBottomTab.kt` |
| `LiquidSlider` | 滑块 | B | `components/LiquidSlider.kt` |
| `LiquidToggle` | 开关 | B | `components/LiquidToggle.kt` |
| `LiquidBottomSheet` | 底部弹窗 | - | `components/LiquidBottomSheet.kt` |
| `LiquidDialog` | 对话框 | - | `components/LiquidDialog.kt` |
| `LiquidTitleChip` | 标题玻璃芯片（tanh 阻尼 + 方向性拉伸） | A + B | `components/LiquidTitleChip.kt` |
| `LiquidMenuButton` | 三点菜单按钮（Canvas 绘制，均匀缩放） | A + B | `components/LiquidMenuButton.kt` |
| `LiquidSearchBar` | 搜索输入框（readOnly BasicTextField） | A + B | `components/LiquidSearchBar.kt` |

### 导航与输入组件

| 组件 | 说明 | 按压类型 | 文件 |
|------|------|----------|------|
| `LiquidTopBar` | 顶部导航栏容器（exportedBackdrop 导出子背景） | - | `components/LiquidTopBar.kt` |
| `LiquidPopupMenu` | 弹出菜单 + `LiquidMenuItem`（弹簧入场动画） | - | `components/LiquidPopupMenu.kt` |
| `LiquidKeyboard` | 液态玻璃键盘（4 种输入模式 + 拼音词库） | A + B | `components/LiquidKeyboard.kt` |

> **依赖说明**：`LiquidTitleChip` / `LiquidMenuButton` / `LiquidSearchBar` / `LiquidKeyboard` 均依赖 `InteractiveHighlight`（`components/InteractiveHighlight.kt`）；`LiquidKeyboard` 还依赖 `PinyinLexiconEngine`（`utils/PinyinLexiconEngine.kt`）。
> **exportedBackdrop 嵌套**：`LiquidTopBar` 和 `LiquidPopupMenu` 通过 `exportedBackdrop` 导出子背景层，子组件（标题芯片、菜单按钮、菜单项）以该子背景为背景源，安全实现「玻璃上叠玻璃」。

### 复杂页面组件

| 组件 | 说明 | 文件 |
|------|------|------|
| `ControlCenter` | 控制中心容器（实验性骨架） | `components/ControlCenter.kt` |
| `ControlCenterContent` | 控制中心网格（需从官方源码复制） | `components/ControlCenterItems.kt` |
| `LockScreenGlass` | 锁屏玻璃 | `components/LockScreenGlass.kt` |
| `MagnifierGlass` | 放大镜 | `components/MagnifierGlass.kt` |
| `GlassPlayground` | 玻璃实验室 | `components/GlassPlayground.kt` |
| `AdaptiveLuminanceGlass` | 自适应亮度玻璃 | `components/AdaptiveLuminanceGlass.kt` |
| `ProgressiveBlur` | 渐进模糊 | `components/ProgressiveBlur.kt` |

### 工具类

| 类 | 说明 | 文件 |
|------|------|------|
| `InteractiveHighlight` | 按压高亮 | `components/InteractiveHighlight.kt` |
| `DampedDragAnimation` | 阻尼拖拽 | `components/DampedDragAnimation.kt` |
| `DragGestureInspector` | 手势检测 | `components/DragGestureInspector.kt` |
| `ProgressConverter` | 进度曲线 | `components/ProgressConverter.kt` |
| `UISensor` / `rememberUISensor()` | 重力感应 | `components/UISensor.kt` |
| `BackHandler` | 返回处理 | `components/BackHandler.kt` |
| `Ripple` | 涟漪效果（AOSP `IndicationNodeFactory` 实现） | `utils/Ripple.kt` |
| `PinyinLexiconEngine` | 拼音词典引擎（Trie 前缀匹配 + 简拼匹配） | `utils/PinyinLexiconEngine.kt` |

## 新组件快速使用

以下示例展示如何使用新增的模板快速集成液态玻璃组件。每个模板的 KDoc 中都列出了所需复制的依赖文件和设置步骤。

### 底部导航栏快速使用

使用 `templates/glass-navigation-bar.kt` 模板构建带指示器动画的完整底部导航栏。

**需要复制的文件**（5 个）：

1. `components/LiquidBottomTabs.kt` — 底部标签栏容器
2. `components/LiquidBottomTab.kt` — 单个标签项
3. `components/DampedDragAnimation.kt` — 拖拽动画控制器
4. `components/InteractiveHighlight.kt` — 按压交互式高光
5. `components/DragGestureInspector.kt` — 拖拽手势检测

**Backdrop 设置**：

```kotlin
val pageBackdrop = rememberLayerBackdrop()
val combinedBackdrop = rememberCombinedBackdrop(backdrop, pageBackdrop)

Box(
    Modifier
        .layerBackdrop(pageBackdrop)  // 页面内容捕获到 pageBackdrop
        .fillMaxSize()
) {
    // 页面内容...
    GlassNavigationBarExample(backdrop = combinedBackdrop)
}
```

**调用方式**：

```kotlin
@Composable
fun GlassNavigationBarExample(backdrop: Backdrop) {
    var selectedTab by remember { mutableStateOf(0) }
    GlassNavigationBar(
        backdrop = backdrop,
        tabsCount = 4,
        selectedTabIndex = { selectedTab },
        onTabSelected = { selectedTab = it }
    ) {
        // 4 个 LiquidBottomTab 内容...
    }
}
```

**指示器动画原理**（`DampedDragAnimation`）：
- 管理浮点位置值 `0f..(tabsCount-1).toFloat()`
- **点击标签** → `animateToValue(targetIndex)` 触发弹簧动画滑动到目标
- **拖拽** → 实时更新值，松手后吸附到最近整数索引
- **指示器位移** → `graphicsLayer.translationX = dampedDragAnimation.value * tabWidth`
- **速度变形** → 松手瞬间的速度使指示器 X/Y 方向产生非均匀缩放

> `glass-bottom-bar.kt` 为简化版（直接委托 `LiquidBottomTabs`），如需完整交互效果请使用 `glass-navigation-bar.kt`。

### 液态玻璃键盘快速使用

使用 `templates/glass-keyboard.kt` 模板集成自定义液态玻璃输入法。

**需要复制的文件**（3 个）：

1. `components/LiquidKeyboard.kt` — 键盘主组件（含全部按键、拼音引擎、模式切换）
2. `components/InteractiveHighlight.kt` — 按压交互式高光（被按键组件依赖）
3. `utils/PinyinLexiconEngine.kt` — 拼音词典引擎（可选，增强拼音匹配）

**键盘状态管理**：

```kotlin
@Composable
fun GlassKeyboardExample(backdrop: Backdrop) {
    var inputText by remember { mutableStateOf("") }
    var showKeyboard by remember { mutableStateOf(false) }

    Box {
        BasicText(inputText, Modifier.padding(16.dp))
        if (showKeyboard) {
            LiquidKeyboard(
                backdrop = backdrop,
                isDark = isSystemInDarkTheme(),
                onKeyInput = { inputText += it },
                onBackspace = { inputText = inputText.dropLast(1) },
                onCloseKeyboard = { showKeyboard = false },
                modifier = Modifier.align(Alignment.BottomCenter)
            )
        }
    }
}
```

**可用模式**（`LiquidKeyboardMode`）：

| 模式 | 说明 | 布局 |
|------|------|------|
| `Pinyin26Key` | 全键盘拼音 | QWERTY 26 键 + 拼音候选词 |
| `Pinyin9Key` | 九宫格拼音 | T9 数字键盘 + 拼音候选词 |
| `English26Key` | 全键盘英文 | QWERTY 26 键直接输入 |
| `SymbolsKey` | 数字 / 符号 | 数字 + 常用符号面板 |

模式切换通过键盘左下角的模式按钮触发，弹出 `LiquidKeyboardPopupMenu` 选择。

> **注意**：`LiquidKeyboard` 内置了示例词库（`MASTER_LEXICON`），可按需替换或配合 `PinyinLexiconEngine` 扩展。

### 完整应用框架

使用 `templates/glass-app-framework.kt` 模板构建整合所有组件的完整应用界面。

**需要复制的文件**（12 个）：

1. `components/LiquidTopBar.kt` — 顶部导航栏容器
2. `components/LiquidTitleChip.kt` — 标题芯片
3. `components/LiquidMenuButton.kt` — 三点菜单按钮
4. `components/LiquidSearchBar.kt` — 搜索输入框
5. `components/LiquidPopupMenu.kt` — 弹出菜单 + 菜单项
6. `components/LiquidBottomTabs.kt` — 底部标签栏容器
7. `components/LiquidBottomTab.kt` — 单个标签项
8. `components/LiquidKeyboard.kt` — 液态玻璃键盘
9. `components/InteractiveHighlight.kt` — 按压交互式高光
10. `components/DampedDragAnimation.kt` — 拖拽动画控制器
11. `components/DragGestureInspector.kt` — 拖拽手势检测
12. `utils/PinyinLexiconEngine.kt` — 拼音词典引擎（可选）

**架构概览**：

```kotlin
@Composable
fun App(backdrop: Backdrop) {
    GlassAppFramework(backdrop = backdrop)
}
```

**exportedBackdrop 嵌套层级**：

```
根 LayerBackdrop（由外部提供）
│
├── 页面内容 ──layerBackdrop──> pageBackdrop
│                                          └──rememberCombinedBackdrop──> combinedBackdrop
└── 外部 backdrop ──────────────────────────────────────────────────────┘
    │
    ├── LiquidTopBar(backdrop = combinedBackdrop)
    │     └── exportedBackdrop → topBarBackdrop
    │           ├── LiquidTitleChip(backdrop = topBarBackdrop)
    │           └── LiquidMenuButton(backdrop = topBarBackdrop)
    │
    ├── LiquidSearchBar(backdrop = combinedBackdrop)
    │
    ├── LiquidPopupMenu(backdrop = combinedBackdrop)
    │     └── exportedBackdrop → menuBackdrop
    │           └── LiquidMenuItem(backdrop = menuBackdrop)
    │
    ├── LiquidKeyboard(backdrop = combinedBackdrop)    [showKeyboard 时]
    │
    └── LiquidBottomTabs(backdrop = combinedBackdrop)  [!showKeyboard 时]
          └── rememberLayerBackdrop() → tabsBackdrop
                └── rememberCombinedBackdrop(combinedBackdrop, tabsBackdrop) → 指示器背景
```

**状态流**：
- 点击标签 → `selectedTab = index` → 标题芯片更新 + 页面内容切换
- 点击搜索框 → `showKeyboard = !showKeyboard` → 键盘/导航栏切换（互斥）
- 点击菜单按钮 → `showMenu = !showMenu` → 弹出菜单显示/隐藏
- 键盘输入 → `searchText += char` → 搜索框更新

> **嵌套深度**：`exportedBackdrop` 嵌套层数不超过 3 层（根 → topBar/menu → menuItem），符合官方 Demo 的安全范围。

## 官方教程映射

官方文档（kyant.gitbook.io/backdrop）共 6 个教程，与本 Skill 组件的对应关系：

| 官方教程 | 对应组件 / 文件 |
|----------|----------------|
| [Glass Bottom Bar](https://kyant.gitbook.io/backdrop/get-started/tutorials/glass-bottom-bar) | `templates/glass-bottom-bar.kt`、`components/LiquidBottomTabs.kt` |
| [Interactive Glass Bottom Bar](https://kyant.gitbook.io/backdrop/get-started/tutorials/interactive-glass-bottom-bar) | `components/InteractiveHighlight.kt`（DampedDragAnimation + InteractiveHighlight 组合） |
| [Glass Bottom Sheet](https://kyant.gitbook.io/backdrop/get-started/tutorials/glass-bottom-sheet) | `components/LiquidBottomSheet.kt` |
| [Glass Slider](https://kyant.gitbook.io/backdrop/get-started/tutorials/glass-slider) | `components/LiquidSlider.kt` |
| [Smoother Rounded Corners](https://kyant.gitbook.io/backdrop/get-started/tutorials/smoother-rounded-corners) | shapes 库（`io.github.kyant0:shapes`，backdrop 传递依赖） |
| [Progressive Blur](https://kyant.gitbook.io/backdrop/get-started/tutorials/progressive-blur) | `components/ProgressiveBlur.kt` |

> **扩展模板**：`glass-navigation-bar.kt`（完整导航栏）、`glass-top-bar.kt`（顶部栏）、`glass-keyboard.kt`（键盘）、`glass-app-framework.kt`（应用框架）为官方教程之外的扩展模板，整合了多个组件，官方文档未覆盖。

## 质量门控

在以下检查全部通过前，不要声称 Skill 已就绪：

- [ ] `SKILL.md` 包含完整 YAML frontmatter（name, description, version, tags）
- [ ] 所有代码示例可编译（无语法错误、无无限递归、无逻辑错误）
- [ ] 所有 `drawBackdrop` / `drawPlainBackdrop` 调用都有正确的 `shape` 和 `effects`
- [ ] `InteractiveHighlight` 和 `DampedDragAnimation` 的 `animationScope` 使用 `rememberCoroutineScope()`
- [ ] `AdaptiveLuminanceGlass` 的 `while (isActive)` 循环包含 `delay()`
- [ ] `LiquidDialog` 的按钮显示使用 `Boolean` 参数而非 lambda 比较
- [ ] 所有 `import` 路径正确，无 `com.kyant.backdrawBackdrop` 等错误
- [ ] 所有 `package` 声明与源码一致
- [ ] `BackHandler` 无命名冲突
- [ ] Spring 动画参数合理（dampingRatio 在 0f ~ 1f 范围）
- [ ] 至少实现官方 Demo 的 14 个页面中的 12 个（catalog 实际含 14 个 destinations）
- [ ] `ControlCenter` 标注为实验性骨架（未接入 drawBackdrop），不冒充完整组件
- [ ] `LockScreenGlass` 的 `sdfShader` 为 `SdfShader?` 类型且 `with(sdfShader) { apply() }` 已恢复
- [ ] `effects/`、`backdrops/` 的库源码副本标注存在（依赖库时提示删除）
- [ ] 文档中所有链接可访问
- [ ] `LiquidKeyboard` 可编译（依赖 `InteractiveHighlight` + `PinyinLexiconEngine`）
- [ ] `LiquidTopBar` 的 `exportedBackdrop` 嵌套深度 ≤ 3 层（根 → topBar → 子组件）
- [ ] `LiquidPopupMenu` 使用 `exportedBackdrop` 导出子背景（非 `layerBackdrop`，避免 SIGSEGV）
- [ ] `LiquidKeyboard` 的 `MASTER_LEXICON` 内置词库可替换，未硬编码外部资源路径
- [ ] `LiquidTitleChip` / `LiquidMenuButton` / `LiquidSearchBar` 的 `animationScope` 使用 `rememberCoroutineScope()`
- [ ] `glass-navigation-bar.kt` / `glass-keyboard.kt` / `glass-top-bar.kt` / `glass-app-framework.kt` 模板 KDoc 中列出的依赖文件路径与实际一致

## 常见问题

### 1. 模糊效果不生效？

**原因**：effects 基于 RenderEffect，需要 Android 12+ (API 31) 且设备/系统 UI 支持；RuntimeShader 类效果需 Android 13+ (API 33)。低版本会静默跳过。

**解决方案**：

```kotlin
// 检查支持性
if (isRenderEffectSupported()) {
    // 应用模糊
    blur(8f.dp.toPx())
}
```

### 2. 按压效果卡顿？

**原因**：动画规格过于激进或使用了错误的 CoroutineScope。

**解决方案**：

```kotlin
// 使用 rememberCoroutineScope() 而不是 LaunchedEffect
val animationScope = rememberCoroutineScope()
val interactiveHighlight = remember(animationScope) {
    InteractiveHighlight(animationScope = animationScope)
}
```

### 3. 背景捕获失败？

**原因**：LayerBackdrop 需要正确的 LayoutCoordinates。

**解决方案**：

```kotlin
val backdrop = rememberLayerBackdrop()

// 官方 Demo 使用 BackdropDemoScaffold 传递 backdrop
// 注意：BackdropDemoScaffold 是官方 catalog 的 demo 类（非库公开 API），
// 需从 catalog 源码复制或自行实现等价结构（rememberLayerBackdrop + Modifier.layerBackdrop）
BackdropDemoScaffold { backdrop ->
    GlassBox(backdrop = backdrop)
}
```

### 4. 效果完全不生效？

**原因**：很可能没有使用 `Modifier.layerBackdrop(backdrop)` 将背景内容绘制到 backdrop 中（官方 FAQ 明确说明）。

**解决方案**：

```kotlin
val backdrop = rememberLayerBackdrop()

// 必须将内容关联到 backdrop
MainNavHost(
    modifier = Modifier.layerBackdrop(backdrop)
)

// 或者在 drawBackdrop 中使用 exportedBackdrop 派生
Box(
    Modifier.drawBackdrop(
        backdrop = backdrop,
        exportedBackdrop = rememberLayerBackdrop(),
        shape = { RoundedCornerShape(16.dp) },
        effects = { blur(8f.dp.toPx()) }
    )
)
```

### 5. 崩溃：Fatal signal 11 (SIGSEGV)

**原因**：玻璃上叠玻璃时，使用 `layerBackdrop` + `drawBackdrop` 形成了循环绘制（官方 FAQ 确认）。

**解决方案**：使用 `exportedBackdrop` 参数代替 `layerBackdrop`：

```kotlin
// 错误：导致 SIGSEGV 崩溃
val bottomSheetBackdrop = rememberLayerBackdrop()
Column(
    Modifier
        .layerBackdrop(bottomSheetBackdrop)
        .drawBackdrop(...)
) {
    Box(Modifier.drawBackdrop(backdrop = bottomSheetBackdrop))
}

// 正确：使用 exportedBackdrop
val bottomSheetBackdrop = rememberLayerBackdrop()
Column(
    Modifier.drawBackdrop(
        backdrop = backdrop,
        exportedBackdrop = bottomSheetBackdrop,
        ...
    )
) {
    Box(Modifier.drawBackdrop(backdrop = bottomSheetBackdrop))
}
```

### 6. 性能问题

**优化建议**：

- 减少 lens 的 refractionAmount 值
- 避免在滚动列表中同时使用多个高复杂度玻璃组件
- 使用 `drawPlainBackdrop` 代替 `drawBackdrop` 当不需要高光/阴影时
- 适当降低模糊半径

### 7. drawBackdrop 元素数量上限

**现象**：`drawBackdrop` 的元素（backdrop 层、高光、阴影、effects 链）数量较多时，在部分设备上出现 native 崩溃或效果丢失。

**原因**：底层将玻璃内容录制到独立图层（GraphicsLayer），GPU 图层尺寸/数量存在硬件上限；单个组件内嵌套多层玻璃会快速消耗。

**解决方案**：

- 单个玻璃组件保持单一效果链（color filter => blur => lens），不叠加多余的高光/阴影层
- 玻璃上叠玻璃必须走 `exportedBackdrop`（见核心概念），并控制嵌套深度（官方 Demo 不超过 2~3 层）
- 长列表/网格中避免每项都创建独立 backdrop 图层，优先使用单个 `LayerBackdrop` 复用背景

## 最佳实践

1. **始终使用 `remember` 缓存 Backdrop 和动画对象**
2. **在 `layerBlock` 中进行图形变换，避免在 `effects` 中修改几何属性**
3. **使用 `drawPlainBackdrop` 简化无高光/阴影的场景**
4. **组合背景时使用 `rememberCombinedBackdrop`**
5. **按压效果使用 `InteractiveHighlight` 或 `DampedDragAnimation`**
6. **深色/浅色主题分别调整颜色透明度**
7. **玻璃上叠玻璃必须走 `exportedBackdrop`**：`LiquidTopBar` / `LiquidPopupMenu` 导出子背景供子组件使用，嵌套深度不超过 3 层
8. **`LiquidKeyboard` 内置词库可替换**：`MASTER_LEXICON` 为示例数据，生产环境建议配合 `PinyinLexiconEngine` 或替换为完整开源词库
9. **键盘与导航栏互斥**：显示自定义键盘时隐藏底部导航栏（`glass-app-framework.kt` 的模式），避免 backdrop 图层叠加过深

## 参考资源

- [官方文档](https://kyant.gitbook.io/backdrop)（get-started + 6 教程 + 2 API 页 + FAQ）
- [GitHub 仓库](https://github.com/Kyant0/AndroidLiquidGlass)（2.0.0 KMP 版源码在 `kmp` 分支）
- [MCP endpoint](https://kyant.gitbook.io/backdrop/~gitbook/mcp)：**GitBook 平台级 MCP**（非库自带），支持通过 GitBook AI 查询
- 官方源码对照：`%TEMP%ackdrop-official\`（Backdrop.kt / DrawBackdropModifier.kt 等）

## License

本项目基于 [AndroidLiquidGlass (Backdrop)](https://github.com/Kyant0/AndroidLiquidGlass)（Apache-2.0）构建。
本项目同样使用 **Apache License 2.0**，详见 [LICENSE](./LICENSE) 和 [NOTICE](./NOTICE)。

- 原始项目：https://github.com/Kyant0/AndroidLiquidGlass
- 原始许可证：Apache License 2.0
- 官方文档：https://kyant.gitbook.io/backdrop

> 本 Skill 中的 `backdrops/`、`effects/`、`components/`（部分）、`utils/`、`templates/`（`glass-bottom-sheet.kt`、`glass-navigation-bar.kt`、`glass-top-bar.kt`、`glass-keyboard.kt`、`glass-app-framework.kt`）
> 等文件直接复制或改编自 Kyant0/AndroidLiquidGlass（Apache-2.0），再分发时请保留原始版权和许可声明。`utils/Ripple.kt` 源自 AOSP，同样使用 Apache-2.0。

## 模板索引

| 模板 | 用途 | 路径 |
|------|------|------|
| 基础玻璃 | 静态玻璃效果 | `templates/basic-glass.kt` |
| 交互玻璃 | 带按压反馈 | `templates/interactive-glass.kt` |
| 图标按钮 | 圆形图标按钮（42dp） | `templates/interactive-glass.kt` |
| 底部导航（简化版） | 标签栏（委托 LiquidBottomTabs） | `templates/glass-bottom-bar.kt` |
| 完整底部导航 | 指示器动画 + 拖拽切换 + 按压形变 | `templates/glass-navigation-bar.kt` |
| 顶部导航栏 | LiquidTopBar + 搜索 + 菜单 + 弹出菜单 | `templates/glass-top-bar.kt` |
| 液态玻璃键盘 | 四种输入模式集成（拼音/英文/符号） | `templates/glass-keyboard.kt` |
| 完整应用框架 | 整合所有组件（顶栏+导航栏+键盘） | `templates/glass-app-framework.kt` |
| 玻璃按钮 | 可点击按钮 | `components/LiquidButton.kt` |
| 筛选标签 | 筛选标签（36dp，选中 tint） | `components/GlassFilterChip.kt` |
| 玻璃滑块 | 滑动选择器 | `components/LiquidSlider.kt` |
| 玻璃开关 | 切换开关 | `components/LiquidToggle.kt` |
| 底部弹窗 | 模态弹窗 | `components/LiquidBottomSheet.kt` |
| 对话框 | 模态对话框 | `components/LiquidDialog.kt` |
| 控制中心 | 系统控制中心 | `components/ControlCenter.kt` |
| 锁屏 | 锁屏效果 | `components/LockScreenGlass.kt` |
| 放大镜 | 放大镜效果 | `components/MagnifierGlass.kt` |
| 实验室 | 参数调节 | `components/GlassPlayground.kt` |
| 自适应亮度 | 亮度自适应 | `components/AdaptiveLuminanceGlass.kt` |
| 渐进模糊 | AlphaMask 模糊 | `components/ProgressiveBlur.kt` |

---

*本 Skill 由 ZCode 基于官方源码自动生成，确保实现效果与官方 Demo 一致。*
