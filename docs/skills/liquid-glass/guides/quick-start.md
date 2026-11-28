# 快速开始指南

本指南将引导你从零开始创建一个完整的液态玻璃应用。

## 前提条件

- Android Studio 或 IntelliJ IDEA（支持 Kotlin Multiplatform 插件）
- Kotlin 2.1.0+（官方构建使用 2.4.10）
- Compose Multiplatform 1.8+（官方构建使用 1.11.1）；Android-only 工程需 Jetpack Compose 1.5+ 对应版本
- Min SDK 21，Target/Compile SDK 37（对齐官方）
- 效果运行时前提：effects 需 Android 12+ (API 31)（RenderEffect），RuntimeShader 类效果需 Android 13+ (API 33)

## 第一步：项目配置

### 1.1 添加依赖

在你的**模块级** `build.gradle.kts` 中添加：

```kotlin
dependencies {
    // Backdrop 核心库（2.0.0，Compose Multiplatform）
    implementation("io.github.kyant0:backdrop:2.0.0")

    // shapes 库（backdrop 传递依赖；直接使用 com.kyant.shapes 的 Shape 时声明）
    implementation("io.github.kyant0:shapes:1.2.0")

    // Compose 相关（如果尚未添加）
    implementation(platform("androidx.compose:compose-bom:2025.09.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
}
```

> KMP 工程请把上述依赖放入 `commonMain`，并应用 `org.jetbrains.compose` 插件（详见 `guides/build-config.md` 方案 B）。

### 1.2 启用 Compose

在模块级 `build.gradle.kts` 中：

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")  // Kotlin 2.x 起取代 composeOptions
}

android {
    compileSdk = 37

    defaultConfig {
        minSdk = 21
        targetSdk = 37
    }

    buildFeatures {
        compose = true
    }
}
```

## 第二步：创建玻璃容器

在你的 `MainActivity` 或根 Composable 中创建玻璃容器：

```kotlin
@Composable
fun GlassApp() {
    // 创建图层背景
    val backdrop = rememberLayerBackdrop()

    // 背景内容（会被玻璃反射）
    Box(modifier = Modifier.fillMaxSize()) {
        // 你的背景 UI
        BackgroundContent()

        // 玻璃前景
        GlassForeground(backdrop = backdrop)
    }
}

@Composable
fun BackgroundContent() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                        Color(0xFFf093fb)
                    )
                )
            )
    ) {
        // 背景内容，例如图片、渐变、动画等
    }
}

@Composable
fun GlassForeground(backdrop: LayerBackdrop) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // 玻璃卡片
        GlassCard(backdrop = backdrop)

        // 玻璃按钮
        GlassButton(backdrop = backdrop)

        // 玻璃导航栏
        GlassBottomBar(backdrop = backdrop)
    }
}
```

## 第三步：实现基础玻璃卡片

```kotlin
@Composable
fun GlassCard(
    backdrop: LayerBackdrop,
    modifier: Modifier = Modifier
) {
    Box(
        modifier
            .fillMaxWidth()
            .height(120.dp)
            .drawBackdrop(
                backdrop = backdrop,
                shape = { RoundedCornerShape(24.dp) },
                effects = {
                    vibrancy()
                    blur(12f.dp.toPx())
                    lens(24f.dp.toPx(), 24f.dp.toPx())
                },
                highlight = { Highlight.Default },
                shadow = {
                    Shadow(
                        radius = 24.dp,
                        color = Color.Black.copy(alpha = 0.1f)
                    )
                },
                onDrawSurface = {
                    drawRect(Color.White.copy(alpha = 0.1f))
                }
            )
            .padding(16.dp)
    ) {
        Text(
            text = "Liquid Glass",
            style = MaterialTheme.typography.headlineMedium,
            color = Color.White
        )
    }
}
```

## 第四步：添加按压效果

```kotlin
@Composable
fun PressableGlassCard(
    backdrop: LayerBackdrop,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val animationScope = rememberCoroutineScope()
    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }

    Box(
        modifier
            .fillMaxWidth()
            .height(120.dp)
            .drawBackdrop(
                backdrop = backdrop,
                shape = { RoundedCornerShape(24.dp) },
                effects = {
                    vibrancy()
                    blur(12f.dp.toPx())
                    lens(24f.dp.toPx(), 24f.dp.toPx())
                },
                layerBlock = {
                    // 按压时的缩放动画
                    val progress = interactiveHighlight.pressProgress
                    val scale = lerp(1f, 0.95f, progress)
                    scaleX = scale
                    scaleY = scale
                },
                highlight = {
                    Highlight.Default.copy(
                        alpha = 1f - interactiveHighlight.pressProgress * 0.5f
                    )
                },
                onDrawSurface = {
                    drawRect(Color.White.copy(alpha = 0.1f))
                }
            )
            .clickable(
                interactionSource = null,
                indication = null,
                onClick = onClick
            )
            .then(interactiveHighlight.modifier)
            .then(interactiveHighlight.gestureModifier)
            .padding(16.dp)
    ) {
        Text(
            text = "Tap Me",
            style = MaterialTheme.typography.headlineMedium,
            color = Color.White
        )
    }
}
```

## 第五步：完整的底部导航栏

```kotlin
@Composable
fun GlassBottomBar(
    backdrop: LayerBackdrop,
    modifier: Modifier = Modifier
) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("Home", "Search", "Profile")

    LiquidBottomTabs(
        selectedTabIndex = { selectedTab },
        onTabSelected = { selectedTab = it },
        backdrop = backdrop,
        tabsCount = tabs.size,
        modifier = modifier
    ) {
        tabs.forEachIndexed { index, title ->
            Icon(
                imageVector = when (index) {
                    0 -> Icons.Default.Home
                    1 -> Icons.Default.Search
                    else -> Icons.Default.Person
                },
                contentDescription = title,
                tint = if (index == selectedTab) {
                    Color(0xFF0088FF)
                } else {
                    Color.White.copy(alpha = 0.6f)
                }
            )
        }
    }
}
```

## 验证效果

运行应用后，你应该能看到：

1. ✅ 玻璃卡片能反射背景内容
2. ✅ 模糊效果自然
3. ✅ 有高光反射
4. ✅ 点击时有缩放反馈
5. ✅ 底部导航栏流畅切换

## 下一步

- 查看 `components/` 目录获取完整组件
- 阅读 `guides/press-effects.md` 了解按压效果详解
- 参考 `guides/troubleshooting.md` 解决常见问题
