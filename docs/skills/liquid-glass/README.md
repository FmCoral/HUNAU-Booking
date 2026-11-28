# Android Liquid Glass Skill

基于 [Backdrop](https://github.com/Kyant0/AndroidLiquidGlass) 库的完整液态玻璃效果 Skill。

> 本 Skill 提供从基础效果到复杂交互组件的液态玻璃实现方案。
> 核心组件均完整封装官方源码的全部交互层（本体 + 滑动 + 点击 + 按压 + 按压次级效果），用户一次调用即可获得完整效果；ControlCenter 为实验性骨架、ControlCenterItems 为简化版，详见「已知限制」。

## 特性

- ✅ **基础玻璃效果**：模糊 + 折射 + 高光 + 阴影 + 内阴影
- ✅ **按压交互**：弹性动画、拖拽反馈、物理模拟、按压次级效果（shadow/innerShadow/highlight/lens 色散/表面色/指示器）
- ✅ **完整组件库**：按钮、底部导航、滑块、开关、底部弹窗、对话框、锁屏、放大镜、玻璃实验室、渐进模糊、自适应亮度（ControlCenter 为实验性骨架，见「已知限制」）
- ✅ **导航与输入组件**：顶部导航栏（LiquidTopBar + 搜索框 + 弹出菜单）、液态玻璃键盘（4 种输入模式，拼音/英文/数字符号）
- ✅ **完整应用框架模板**：一键复用的导航栏、键盘、顶部栏及整合全部组件的应用框架模板
- ✅ **工程化保障**：包含配置、依赖、性能优化、SIGSEGV 崩溃防护和常见问题排查；已修复继承自官方源码的若干缺陷（Coroutines `awaitFrame` 无限递归、Bitmap `scale` 硬编码尺寸、LiquidToggle 缺失 `import …graphics.lerp`）
- ✅ **多主题支持**：自动适配亮色/暗色主题
- ✅ **官方对齐**：核心组件（LiquidButton/LiquidBottomTabs/InteractiveHighlight/ProgressiveBlur/LockScreenGlass）与官方源码逐行一致，所有公开 API 均已文档化（ControlCenter 为实验性骨架、ControlCenterItems 为简化版，已在组件清单与「已知限制」中标注）

## 快速开始

### 安装依赖

```kotlin
dependencies {
    implementation("io.github.kyant0:backdrop:2.0.0")   // Compose Multiplatform
    // shapes 库为 backdrop 内置传递依赖；仅当直接使用 shapes 的 Shape 类时需要单独声明
    implementation("io.github.kyant0:shapes:1.2.0")      // 可选
}
```

### 基础使用

```kotlin
@Composable
fun GlassExample() {
    val backdrop = rememberLayerBackdrop()

    Box(
        Modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { RoundedCornerShape(16.dp) },
                effects = {
                    vibrancy()
                    blur(8f.dp.toPx())
                    lens(24f.dp.toPx(), 24f.dp.toPx())
                },
                highlight = { Highlight.Default },
                shadow = { Shadow.Default },
                onDrawSurface = { drawRect(Color.White.copy(alpha = 0.1f)) }
            )
            .padding(16.dp)
    ) {
        Text("Liquid Glass", color = Color.White)
    }
}
```

> **注意**：效果必须按 **color filter ⇒ blur ⇒ lens** 顺序应用。
> **平台前提**：effects 需 Android 12+ (RenderEffect)；`lens` 的 `depthEffect`/`chromaticAberration` 与 `runtimeShaderEffect` 需 Android 13+ (RuntimeShader)。
> **lens 约束**：`refractionHeight` ∈ [0, shape.minCornerRadius]、`refractionAmount` ∈ [0, size.minDimension]，且均不接受负值。

## 一键复用模板

| 模板 | 说明 |
|------|------|
| `glass-navigation-bar.kt` | 底部导航栏（含指示器动画）— 最常用 |
| `glass-keyboard.kt` | 液态玻璃键盘集成 |
| `glass-top-bar.kt` | 顶部导航栏 + 搜索 + 菜单 |
| `glass-app-framework.kt` | 完整应用框架（整合所有组件） |

每个模板文件头部 KDoc 列出了需要复制的组件文件和设置步骤。

## 目录结构

```
skill-liquid-glass/
├── SKILL.md                          # Skill 主文件（frontmatter + API 参考 + 质量门控 + FAQ）
├── README.md                         # 本文件
├── LICENSE                           # Apache 2.0
├── NOTICE                            # 第三方归属声明
├── run_all.ps1                       # 一键构建验证脚本
├── .gitignore
├── templates/                        # 一键复用模板
│   ├── basic-glass.kt                # BasicGlass / PlainGlass / HeavyBlurGlass
│   ├── interactive-glass.kt          # InteractiveGlass / ElasticGlass
│   ├── glass-bottom-bar.kt           # 底部导航栏（委托 LiquidBottomTabs 完整实现）
│   ├── glass-bottom-sheet.kt         # 底部弹窗（官方教程 exportedBackdrop 实现）
│   ├── glass-navigation-bar.kt       # 完整底部导航栏（指示器动画 + 4 标签 + backdrop 设置）
│   ├── glass-keyboard.kt             # 键盘集成（搜索框 + 键盘切换 + 文本输入）
│   ├── glass-top-bar.kt              # 顶部栏（TopBar + 搜索 + 菜单 + 弹出菜单）
│   └── glass-app-framework.kt        # 完整应用框架（整合全部组件）
├── components/                       # 完整组件（含 utils 包工具类）
│   ├── LiquidButton.kt               # 玻璃按钮 + LiquidIconButton
│   ├── LiquidBottomTabs.kt           # 玻璃底部导航（完整交互层）
│   ├── LiquidBottomTab.kt            # 单个标签项（含 LocalLiquidBottomTabScale）
│   ├── LiquidSlider.kt               # 玻璃滑块
│   ├── LiquidToggle.kt               # 玻璃开关
│   ├── LiquidBottomSheet.kt          # 玻璃底部弹窗（exportedBackdrop 防崩溃）
│   ├── LiquidDialog.kt               # 玻璃对话框
│   ├── LiquidTopBar.kt               # 顶部导航栏容器（exportedBackdrop 导出子背景）
│   ├── LiquidTitleChip.kt            # 标题玻璃芯片（tanh 阻尼按压形变）
│   ├── LiquidMenuButton.kt           # 圆形三点菜单按钮（按压缩放）
│   ├── LiquidSearchBar.kt            # 搜索输入框（BasicTextField + 清除按钮）
│   ├── LiquidPopupMenu.kt            # 弹出菜单 + LiquidMenuItem（弹簧动画）
│   ├── LiquidKeyboard.kt             # 液态玻璃键盘（4 种输入模式 + 拼音词库）
│   ├── ControlCenter.kt              # 控制中心容器（UISensor 高光）
│   ├── ControlCenterItems.kt         # 控制中心网格项
│   ├── LockScreenGlass.kt            # 锁屏玻璃
│   ├── MagnifierGlass.kt             # 放大镜玻璃
│   ├── GlassPlayground.kt            # 玻璃实验室（手势变换）
│   ├── GlassFilterChip.kt            # 玻璃筛选芯片
│   ├── AdaptiveLuminanceGlass.kt     # 自适应亮度玻璃
│   ├── ProgressiveBlur.kt            # 渐进模糊（AlphaMask shader）
│   ├── ScrollGlassContainers.kt      # 滚动/懒加载玻璃容器
│   ├── InteractiveHighlight.kt       # 交互高光（utils 包）
│   ├── DampedDragAnimation.kt        # 阻尼拖拽动画（utils 包）
│   ├── DragGestureInspector.kt       # 手势检测器（utils 包）
│   ├── UISensor.kt                   # 重力感应（utils 包）
│   └── BackHandler.kt                # 返回处理器（utils 包）
├── effects/                          # 特效封装 ⚠️ 库源码副本（依赖库时删除，见 SKILL.md「目录定位」）
│   ├── Blur.kt                       # blur()
│   ├── Lens.kt                       # lens()
│   ├── Vibrancy.kt                   # vibrancy() / colorControls() / opacity()
│   └── Highlight.kt                  # GlassHighlights 对象
├── backdrops/                        # 背景源 ⚠️ 库源码副本（依赖库时删除，见 SKILL.md「目录定位」）
│   ├── LayerBackdrop.kt              # rememberLayerBackdrop()
│   ├── CanvasBackdrop.kt             # rememberCanvasBackdrop()
│   └── CombinedBackdrop.kt           # rememberCombinedBackdrop()
├── utils/                            # 工具函数（SdfShader 依赖 Compose Resources，KMP 需启用 compose resources 插件）
│   ├── Coroutines.kt                 # awaitFrame()
│   ├── Bitmap.kt                     # ImageBitmap.scale()
│   ├── ProgressConverter.kt          # 官方指数算法
│   ├── SdfShader.kt                  # SDF 纹理着色器（AGSL）
│   ├── Ripple.kt                     # AOSP 涟漪效果（IndicationNodeFactory）
│   └── PinyinLexiconEngine.kt        # Trie Tree 拼音词典引擎
└── guides/                           # 使用指南
    ├── quick-start.md                # 快速开始
    ├── press-effects.md              # 按压效果详解
    ├── troubleshooting.md            # 常见问题排查
    ├── best-practices.md             # 最佳实践
    └── build-config.md               # 构建配置
```

## 组件列表

### 基础模板

| 组件 | 描述 | 路径 |
|------|------|------|
| BasicGlass | 基础玻璃卡片 | `templates/basic-glass.kt` |
| PlainGlass | 简洁玻璃（无高光阴影） | `templates/basic-glass.kt` |
| HeavyBlurGlass | 强模糊玻璃 | `templates/basic-glass.kt` |
| InteractiveGlass | 交互式玻璃 | `templates/interactive-glass.kt` |
| ElasticGlass | 弹性按压玻璃 | `templates/interactive-glass.kt` |
| GlassBottomBar | 底部导航（委托完整实现） | `templates/glass-bottom-bar.kt` |
| GlassBottomSheet | 底部弹窗（exportedBackdrop） | `templates/glass-bottom-sheet.kt` |
| GlassNavigationBar | 完整底部导航栏（指示器动画 + 4 标签 + backdrop 设置） | `templates/glass-navigation-bar.kt` |
| GlassKeyboard | 键盘集成（搜索框 + 键盘切换 + 文本输入） | `templates/glass-keyboard.kt` |
| GlassTopBar | 顶部栏（TopBar + 搜索 + 菜单 + 弹出菜单） | `templates/glass-top-bar.kt` |
| GlassAppFramework | 完整应用框架（整合全部组件） | `templates/glass-app-framework.kt` |

### 完整交互组件（一次调用获得全部交互层）

| 组件 | 描述 | 完整封装的交互层 | 路径 |
|------|------|-----------------|------|
| LiquidButton | 玻璃按钮 | 本体+点击+按压光晕+形变+tint | `components/LiquidButton.kt` |
| LiquidBottomTabs | 底部导航 | 本体+滑动+点击+按压+按压面板+指示器+缩放+主题 | `components/LiquidBottomTabs.kt` |
| LiquidBottomTab | 单个标签项 | 点击+按压缩放 | `components/LiquidBottomTab.kt` |
| LiquidSlider | 滑块 | 轨道+拖拽+点击跳转+按压色散+进度+LTR/RTL | `components/LiquidSlider.kt` |
| LiquidToggle | 开关 | 轨道渐变+拖拽+点击切换+按压+语义 | `components/LiquidToggle.kt` |
| LiquidBottomSheet | 底部弹窗 | 玻璃+拖拽展开/收起+exportedBackdrop+渐进显示+遮罩 | `components/LiquidBottomSheet.kt` |
| LiquidDialog | 对话框 | 玻璃+dimOverlay+BlendMode.Plus+按钮 | `components/LiquidDialog.kt` |

### 导航与输入组件

| 组件 | 描述 | 路径 |
|------|------|------|
| LiquidTopBar | 顶部导航栏容器（exportedBackdrop 导出子背景） | `components/LiquidTopBar.kt` |
| LiquidTitleChip | 标题玻璃芯片（tanh 阻尼按压形变） | `components/LiquidTitleChip.kt` |
| LiquidMenuButton | 圆形三点菜单按钮（按压缩放） | `components/LiquidMenuButton.kt` |
| LiquidSearchBar | 搜索输入框（BasicTextField + 清除按钮） | `components/LiquidSearchBar.kt` |
| LiquidPopupMenu | 弹出菜单 + LiquidMenuItem（弹簧动画） | `components/LiquidPopupMenu.kt` |
| LiquidKeyboard | 液态玻璃键盘（4 种输入模式 + 拼音词库） | `components/LiquidKeyboard.kt` |

### 复杂页面组件

| 组件 | 描述 | 路径 |
|------|------|------|
| ControlCenter | 控制中心容器（⚠️ 实验性骨架：未接入 drawBackdrop，不绘制玻璃背景；完整版参考官方 catalog `ControlCenterContent.kt`） | `components/ControlCenter.kt` |
| ControlCenterItems | 控制中心网格项（⚠️ 简化版：约 209 行，官方完整版 444 行，缺交互控件，layerBlock 为 placeholder） | `components/ControlCenterItems.kt` |
| LockScreenGlass | 锁屏玻璃（2D 拖拽 + SDF 支持，已对齐官方 LockScreenContent） | `components/LockScreenGlass.kt` |
| MagnifierGlass | 放大镜（3 层 CombinedBackdrop+色散） | `components/MagnifierGlass.kt` |
| GlassPlayground | 玻璃实验室（双指缩放/旋转/平移） | `components/GlassPlayground.kt` |
| AdaptiveLuminanceGlass | 自适应亮度（实时采样+动态效果） | `components/AdaptiveLuminanceGlass.kt` |
| ProgressiveBlur | 渐进模糊（AlphaMask shader） | `components/ProgressiveBlur.kt` |
| ScrollGlassContainer | 滚动玻璃容器 | `components/ScrollGlassContainers.kt` |
| LazyScrollGlassContainer | 懒加载玻璃列表 | `components/ScrollGlassContainers.kt` |
| GlassFilterChip | 玻璃筛选芯片 | `components/GlassFilterChip.kt` |

### 工具类

| 类 | 描述 | 路径 |
|------|------|------|
| InteractiveHighlight | 按压高亮（Shader 光晕跟随） | `components/InteractiveHighlight.kt` |
| DampedDragAnimation | 阻尼拖拽（5 路 Spring 物理+速度追踪） | `components/DampedDragAnimation.kt` |
| DragGestureInspector | 手势检测器 | `components/DragGestureInspector.kt` |
| UISensor / rememberUISensor() | 重力感应（动态高光角度） | `components/UISensor.kt` |
| BackHandler | 返回处理器 | `components/BackHandler.kt` |
| awaitFrame() | 帧等待 | `utils/Coroutines.kt` |
| ImageBitmap.scale() | 位图缩放（亮度采样） | `utils/Bitmap.kt` |
| ProgressConverter | 进度曲线（官方指数算法） | `utils/ProgressConverter.kt` |
| SdfShader / rememberSdfShader() | SDF 纹理着色器 | `utils/SdfShader.kt` |
| Ripple | AOSP 涟漪效果（IndicationNodeFactory） | `utils/Ripple.kt` |
| PinyinLexiconEngine | Trie Tree 拼音词典引擎 | `utils/PinyinLexiconEngine.kt` |

## 技术栈

- **核心库**：`io.github.kyant0:backdrop:2.0.0`（Compose Multiplatform）
- **形状库**：`io.github.kyant0:shapes:1.2.0`（backdrop 传递依赖，可选单独声明）
- **UI 框架**：Jetpack Compose / Compose Multiplatform（官方构建：Kotlin 2.4.10 + CMP 1.11.1 + AGP 9.3.0）
- **最低 SDK**：API 21（官方库实测值）
- **推荐 SDK**：API 31+（RenderEffect effects），API 33+（RuntimeShader）

## 核心概念

### Backdrop（背景源）

定义玻璃组件反射的内容来源：

```kotlin
val backdrop = rememberLayerBackdrop()                        // 捕获图层（配合 Modifier.layerBackdrop 或 exportedBackdrop）
val canvasBackdrop = rememberCanvasBackdrop { drawRect(...) } // Canvas 绘制
val combined = rememberCombinedBackdrop(backdrop1, backdrop2) // 组合
```

### Effects（效果链）

```kotlin
effects = {
    vibrancy()                    // 1. 色彩增强
    blur(8f.dp.toPx())           // 2. 模糊
    lens(24f.dp.toPx(), 24f.dp.toPx())  // 3. 折射（height ≤ shape.minCornerRadius，amount ≤ size.minDimension）
}
```

### exportedBackdrop（玻璃上叠玻璃）

玻璃组件内嵌套玻璃时**必须**使用 `exportedBackdrop`，否则 SIGSEGV 崩溃：

```kotlin
val bottomSheetBackdrop = rememberLayerBackdrop()
Column(
    Modifier.drawBackdrop(
        backdrop = backdrop,
        exportedBackdrop = bottomSheetBackdrop,
    )
) {
    Box(Modifier.drawBackdrop(backdrop = bottomSheetBackdrop))
}
```

### Highlight / Shadow

```kotlin
highlight = { Highlight.Default }      // 对角线高光
shadow = { Shadow.Default }            // 外部阴影
innerShadow = { InnerShadow() }        // 内部阴影（按压时常用）
```

## 常见问题

- **模糊不生效**：检查 `isRenderEffectSupported()`（需 Android 12+）
- **SIGSEGV 崩溃**：玻璃上叠玻璃未使用 `exportedBackdrop`
- **效果完全不生效**：未使用 `Modifier.layerBackdrop(backdrop)`
- **按压卡顿**：使用 `rememberCoroutineScope()` 正确管理动画作用域

详见 `guides/troubleshooting.md`。

## 已知限制

- **ControlCenter 为实验性骨架**：`components/ControlCenter.kt` 未接入 `drawBackdrop`，不绘制任何玻璃/背景内容，仅提供拖拽展开收起、dimOverlay、BlurEffect 与布局骨架；完整实现请参考官方 catalog 的 `ControlCenterContent.kt`。
- **ControlCenterItems 为简化版**：`components/ControlCenterItems.kt` 约 209 行（官方完整版 444 行），缺失部分交互控件，`layerBlock` 仍为 placeholder，仅供结构参考。
- **核心组件完整可用**：除上述两项外，27 个组件/工具类（按钮、底部导航、滑块、开关、底部弹窗、对话框、顶部导航栏、搜索框、弹出菜单、液态玻璃键盘、锁屏、放大镜、玻璃实验室、自适应亮度、渐进模糊、滚动容器、筛选芯片及 InteractiveHighlight/DampedDragAnimation/DragGestureInspector/UISensor/BackHandler/Ripple/PinyinLexiconEngine 等工具类）均为完整可用实现；4 个 effects、3 个 backdrops、8 个 templates 同样完整可用。
- **LiquidKeyboard 词库**：`MASTER_LEXICON` 为内置词库，可通过 `PinyinLexiconEngine` 替换为自定义词库。
- **LiquidKeyboard 平台依赖**：使用 `LocalClipboardManager`（KMP 可用）和 `LocalSoftwareKeyboardController`（仅 Android/iOS），桌面端需自行适配。

## 参考资源

- [官方文档](https://kyant.gitbook.io/backdrop)（get-started + 6 教程 + 2 API 页 + FAQ）
- [GitHub 仓库](https://github.com/Kyant0/AndroidLiquidGlass)（2.0.0 KMP 版源码在 `kmp` 分支）
- [MCP endpoint](https://kyant.gitbook.io/backdrop/~gitbook/mcp)：**GitBook 平台级 MCP**（非库自带），支持 GitBook AI 查询（`?ask=` 参数，见 SKILL.md「参考资源」）

## 开源声明

本项目基于 [AndroidLiquidGlass (Backdrop)](https://github.com/Kyant0/AndroidLiquidGlass) 构建。

### License

本项目使用 **Apache License 2.0**（见 [LICENSE](./LICENSE)）。

本项目包含来自 AndroidLiquidGlass 仓库（同样使用 Apache-2.0 许可）的代码和文档，
具体来源和归属见 [NOTICE](./NOTICE)。

> **重要**：本 Skill 中的 `backdrops/`、`effects/`、`components/`（部分）、`utils/`、`templates/glass-bottom-sheet.kt`
> 等文件直接复制或改编自 [Kyant0/AndroidLiquidGlass](https://github.com/Kyant0/AndroidLiquidGlass)（Apache-2.0），
> 使用或再分发时请保留原始版权和许可声明，并遵守 Apache-2.0 条款。

### 原始项目信息

- 项目名称：AndroidLiquidGlass (Backdrop)
- 作者：Kyant0
- 许可证：Apache License 2.0
- GitHub：https://github.com/Kyant0/AndroidLiquidGlass
- 官方文档：https://kyant.gitbook.io/backdrop
