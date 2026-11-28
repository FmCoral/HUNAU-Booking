# Compose → Flutter 映射

上游归档在 `docs/skills/liquid-glass/`，是 Kotlin / Compose Multiplatform 代码，**只读，不能编译进本工程**。
下表是“上游哪个文件、对应本工程哪个实现”。

## 组件映射

| 上游文件 | 上游 API | 本工程 | 差异 |
| --- | --- | --- | --- |
| `templates/basic-glass.kt` | `drawBackdrop` + effects | `LiquidGlass` | 效果链被压成一次合成 |
| `components/LiquidButton.kt` | `LiquidButton` / `LiquidIconButton` | `GlassButton` / `GlassIconButton` | 去掉方向性拉伸 |
| `components/GlassFilterChip.kt` | `GlassFilterChip` | `GlassChip` | 选中态叠品牌色 |
| `components/LiquidBottomTabs.kt` | `LiquidBottomTabs` | `GlassBottomNav` | 指示器用品牌色浅底，不做弹簧动画 |
| `components/LiquidBottomSheet.kt` | `LiquidBottomSheet` | `showGlassBottomSheet` / `GlassBottomSheetSurface` | 用 `showModalBottomSheet` 承载 |
| `components/LiquidDialog.kt` | `LiquidDialog` | `showGlassDialog` | 用 `showDialog` 承载 |
| `components/LiquidSearchBar.kt` | `LiquidSearchBar` | `GlassSearchBar` | 内嵌无边框 `TextField` |
| `components/LiquidSlider.kt` | `LiquidSlider` | `GlassSlider` | 自绘轨道与滑块，不依赖 Material `Slider` |
| `components/LiquidToggle.kt` | `LiquidToggle` | `GlassToggle` | 白色实体滑块 |
| `components/LiquidTitleChip.kt` | 标题玻璃芯片 | `GlassChip` | 同款胶囊 |
| `components/LiquidTopBar.kt` | `LiquidTopBar` | 未实现 | 本工程顶栏是 `AppBar` 风格，暂不需要 |
| `components/MagnifierGlass.kt` | 放大镜 | 未实现 | 需要 shader 采样 backdrop，Flutter 无法实现 |
| `components/LiquidKeyboard.kt` | 液态玻璃键盘 | 不实现 | 业务无关，且依赖大量私有资源 |
| `components/ControlCenter.kt` 等 | 控制中心 / 锁屏 | 不实现 | 演示性质 |

## API 映射

| 上游概念 | Flutter 对应 | 说明 |
| --- | --- | --- |
| `Backdrop` / `rememberLayerBackdrop()` | 无 | Flutter 的 `BackdropFilter` 直接模糊“已经画在下面的合成层”，不需要显式背景源 |
| `fixedBackgroundBackdrop` | 无 | 同上；如需固定背景，把背景放到玻璃所在 `Stack` 的底层即可 |
| `drawBackdrop(effects = { ... })` | `BackdropFilter(filter: ImageFilter.blur(...))` | 只保留模糊 |
| `vibrancy()` | 无 | 用 `tintOpacity` 补偿 |
| `blur(dp)` | `ImageFilter.blur(sigmaX, sigmaY)` | `sigma ≈ dp × 6`，见 [parameters.md](parameters.md) |
| `lens(...)` | 无 | 用内阴影 + 高光描边近似 |
| `Highlight.Default` | 对角高光描边 + 径向光晕 | 光晕中心跟随手指 |
| `Shadow` / `InnerShadow` | `BoxShadow` / `MaskFilter.blur(BlurStyle.inner)` | 内阴影是近似 |
| `exportedBackdrop`（玻璃叠玻璃） | `LiquidGlass(enableBlur: false)` + 提高 `tintOpacity` | Flutter 嵌套 `BackdropFilter` 会重复离屏、代价高 |
| `onDrawSurface = { drawRect(...) }` | `ColoredBox` + `RadialGradient` | 底色与光晕都是普通绘制 |
| `layerBlock`（形变） | `Transform.scale` | 不做拉伸与拖拽跟随 |
| `clickable(interactionSource = null, indication = null)` | `GestureDetector`（`LiquidGlass.onTap`） | 无系统水波纹，保持玻璃干净 |
| `rememberCoroutineScope` + `animateTo` | `AnimationController` + `AnimatedBuilder` | `StatefulWidget` 内管理 |
| `spring(0.5f, 300f, 0.001f)` | `GlassMotion.press` / `release` + `Curves.easeOutCubic` | 手感按 Flutter 曲线校准 |
| `remember { InteractiveHighlight(...) }` | `_LiquidGlassState._press` + `_pointer` | 进度与指针位置 |
| `absoluteOffset` / `dragOffset` | 未实现 | 无拖拽形变 |

## 不能照搬的效果

| 效果 | 原因 | 替代 |
| --- | --- | --- |
| 真实折射（UV 位移采样） | `BackdropFilter` 不暴露 backdrop 纹理；fragment shader 也拿不到下层内容 | 内阴影 + 高光描边的厚度暗示 |
| 色散（RGB 分离） | 同上的采样问题 | 放弃 |
| `RuntimeShader` 自定义效果 | 同上 | 放弃 |
| 放大镜 | 需要采样背景并做缩放变换 | 用 `ImageFilter.matrix` + `BackdropFilter` 的近似方案（缩放模糊），不做为默认组件 |
| 重力感应 / 陀螺仪视差（`UISensor.kt`） | 需要传感器依赖，本工程未引入 | 不实现；需要时单独评估 `sensors_plus` |

## 阅读上游的顺序

1. `SKILL.md` 的“核心概念”与“API 参考”两节，理解 Backdrop / effects / highlight / shadow 的关系。
2. `guides/best-practices.md` 第 1 节拿统一参数，第 5 节看按压缩放与动画规格。
3. `components/LiquidButton.kt` 看最完整的交互实现（`layerBlock` + 三段光影）。
4. `components/LiquidBottomTabs.kt` 看指示器与标签动画。
5. `effects/Blur.kt`、`effects/Lens.kt` 看效果顺序为什么必须是 color filter → blur → lens。

## 迁移到 Flutter 时的坑

- Compose 的 `dp` 是密度无关像素，Flutter 的逻辑像素同尺度，但阴影、模糊的观感不同，必须重新调，不能按 1:1 照抄。
- 上游玻璃是“捕获图层再绘制”，Flutter 是“模糊已合成的下层”。因此 Flutter 侧玻璃**必须有内容在下面**，否则只是一层半透明白。
- Compose 里 `Shadow` 与 `InnerShadow` 是 effect 链的一部分，Flutter 里外阴影走 `BoxDecoration.boxShadow`（在内容下层），内阴影走 `CustomPainter`（在内容上层），层级不同。
- 上游 `InteractiveHighlight` 用协程 + spring 驱动进度；Flutter 里用 `AnimationController`，不要在 `build` 里创建控制器。
