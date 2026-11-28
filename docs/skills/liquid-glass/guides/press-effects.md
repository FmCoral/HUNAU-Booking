# 按压效果详解

本指南详细介绍如何实现完整的按压反馈效果，包括物理动画、触摸跟踪和状态过渡。

## 核心概念

液态玻璃的按压效果通常包含以下几个层次：

1. **视觉反馈**：高光变化、颜色调整
2. **形变动画**：缩放、位移
3. **物理模拟**：弹性、阻尼、速度追踪

## 统一规范（v2）

所有交互式液态玻璃组件遵循以下按压参数规范：

| 参数 | 常驻值 | 按压值 |
|------|--------|--------|
| 高光 alpha | 0.15 | 0.15 + 0.35 * progress |
| 阴影 alpha | 0.08 | 0.08 + 0.22 * progress |
| 内阴影 radius | 4dp | 4dp + 8dp * progress |
| 内阴影 alpha | 0.1 | 0.1 + 0.3 * progress |
| 缩放 | 1.0 | 1.0 + 4dp / height（容器）或 1.15（按钮） |
| 拖拽跟随 | — | tanh(0.05 * offset / maxOffset) |
| 方向拉伸 | — | 4dp / height * 方向余弦 |

## 基础按压效果

### 使用 InteractiveHighlight

`InteractiveHighlight` 是官方提供的最简单按压效果实现：

```kotlin
@Composable
fun GlassCardWithPress(
    backdrop: Backdrop,
    onClick: () -> Unit
) {
    val animationScope = rememberCoroutineScope()
    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }

    Box(
        Modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { RoundedCornerShape(16.dp) },
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
                highlight = {
                    val p = interactiveHighlight.pressProgress
                    Highlight.Default.copy(alpha = 0.15f + 0.35f * p)
                },
                shadow = {
                    val p = interactiveHighlight.pressProgress
                    Shadow(alpha = 0.08f + 0.22f * p)
                },
                innerShadow = {
                    val p = interactiveHighlight.pressProgress
                    InnerShadow(radius = 4f.dp + 8f.dp * p, alpha = 0.1f + 0.3f * p)
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
            .padding(16.dp)
    ) {
        Text("Press Me", color = Color.White)
    }
}
```

### 关键点

1. **必须使用 `rememberCoroutineScope()`**：确保动画作用域正确
2. **`interactiveHighlight.modifier`**：绘制按压高光
3. **`interactiveHighlight.gestureModifier`**：处理触摸手势

## 高级按压效果

### 使用 DampedDragAnimation

对于需要拖拽交互的组件（如滑块、开关、底部导航），使用 `DampedDragAnimation`：

```kotlin
val animationScope = rememberCoroutineScope()

val dampedDragAnimation = remember(animationScope) {
    DampedDragAnimation(
        animationScope = animationScope,
        initialValue = 0f,              // 初始值
        valueRange = 0f..1f,           // 值范围
        visibilityThreshold = 0.001f,  // 可见阈值
        initialScale = 1f,             // 初始缩放
        pressedScale = 1.5f,           // 按下缩放
        onDragStarted = { /* 拖拽开始 */ },
        onDragStopped = { /* 拖拽结束 */ },
        onDrag = { size, dragAmount ->
            // 处理拖拽
        }
    )
}
```

### 可用的动画属性

```kotlin
// 当前值
val value: Float = dampedDragAnimation.value

// 目标值
val targetValue: Float = dampedDragAnimation.targetValue

// 进度 (0f - 1f)
val progress: Float = dampedDragAnimation.progress

// 按压进度 (0f - 1f)
val pressProgress: Float = dampedDragAnimation.pressProgress

// 缩放值
val scaleX: Float = dampedDragAnimation.scaleX
val scaleY: Float = dampedDragAnimation.scaleY

// 速度
val velocity: Float = dampedDragAnimation.velocity
```

### 弹簧动画参数

```kotlin
// 自定义弹簧参数
val pressProgressAnimationSpec = spring(
    dampingRatio = 0.5f,      // 阻尼比 (0-1，越小越弹)
    stiffness = 300f,         // 刚度，越大越快
    visibilityThreshold = 0.001f  // 可见阈值
)

// 应用到 layerBlock
layerBlock = {
    val scale = lerp(1f, 1f + 4f.dp.toPx() / size.height, dampedDragAnimation.pressProgress)
    scaleX = scale
    scaleY = scale
}
```

## 复杂按压效果

### 液态按钮的形变（v2 规范）

参考官方 LiquidButton 的复杂形变效果：

```kotlin
layerBlock = {
    val width = size.width
    val height = size.height

    val progress = interactiveHighlight.pressProgress
    val scale = lerp(1f, 1f + 4f.dp.toPx() / size.height, progress)

    val maxOffset = size.minDimension
    val initialDerivative = 0.05f
    val offset = interactiveHighlight.offset

    // 位移：使用 tanh 实现平滑的触摸跟踪
    translationX = maxOffset * tanh(initialDerivative * offset.x / maxOffset)
    translationY = maxOffset * tanh(initialDerivative * offset.y / maxOffset)

    // 方向性缩放
    val maxDragScale = 4f.dp.toPx() / size.height
    val offsetAngle = atan2(offset.y, offset.x)

    scaleX = scale + maxDragScale * abs(cos(offsetAngle) * offset.x / size.maxDimension) *
            (width / height).coerceAtMost(1f)

    scaleY = scale + maxDragScale * abs(sin(offsetAngle) * offset.y / size.maxDimension) *
            (height / width).coerceAtMost(1f)
}
```

### 图标按钮形变（42dp 圆形）

```kotlin
layerBlock = {
    val progress = interactiveHighlight.pressProgress
    val scale = lerp(1f, 1.15f, progress)  // 放大到 1.15x

    val maxOffset = size.minDimension
    translationX = maxOffset * tanh(0.05f * offset.x / maxOffset)
    translationY = maxOffset * tanh(0.05f * offset.y / maxOffset)

    val maxDragScale = 4f.dp.toPx() / size.height
    val offsetAngle = atan2(offset.y, offset.x)
    scaleX = scale + maxDragScale * abs(cos(offsetAngle) * offset.x / size.maxDimension) *
            (width / height).coerceAtMost(1f)
    scaleY = scale + maxDragScale * abs(sin(offsetAngle) * offset.y / size.maxDimension) *
            (height / width).coerceAtMost(1f)
}
```

### 底部导航的弹性指示器

```kotlin
val dampedDragAnimation = remember(animationScope) {
    DampedDragAnimation(
        animationScope = animationScope,
        initialValue = selectedTabIndex.toFloat(),
        valueRange = 0f..(tabsCount - 1).toFloat(),
        visibilityThreshold = 0.001f,
        initialScale = 1f,
        pressedScale = 78f / 56f,  // 约 1.39 倍
        onDragStopped = {
            // 速度影响形变
            val velocity = dampedDragAnimation.velocity / 10f
            scaleX /= 1f - (velocity * 0.75f).fastCoerceIn(-0.2f, 0.2f)
            scaleY *= 1f - (velocity * 0.25f).fastCoerceIn(-0.2f, 0.2f)
        },
        onDrag = { _, dragAmount ->
            // 更新值
            updateValue((targetValue + dragAmount.x / tabWidth).coerceIn(0f, tabsCount - 1f))
        }
    )
}
```

## 高光动画

### 动态高光透明度（v2 规范）

```kotlin
highlight = {
    val progress = interactiveHighlight.pressProgress
    Highlight.Default.copy(
        alpha = 0.15f + 0.35f * progress  // 按压时高光增强
    )
}
```

### 内阴影按压效果（v2 规范）

```kotlin
innerShadow = {
    val progress = dampedDragAnimation.pressProgress
    InnerShadow(
        radius = 4f.dp + 8f.dp * progress,
        alpha = 0.1f + 0.3f * progress
    )
}
```

## 性能优化

### 避免过度动画

```kotlin
// 不好的做法：每次都创建新对象
val highlight = remember {
    Highlight.Default.copy(alpha = pressProgress)
}

// 好的做法：使用 lambda 延迟计算
highlight = {
    Highlight.Default.copy(alpha = pressProgress)
}
```

### 使用正确的动画规格

```kotlin
// 按压动画：快速响应
val pressSpec = spring(0.5f, 300f, 0.001f)

// 释放动画：平滑恢复
val releaseSpec = spring(0.5f, 300f, 0.001f)

// 拖拽：高刚度
val dragSpec = spring(1f, 1000f, visibilityThreshold)
```

## 常见问题

### Q: 按压动画不流畅？

**A**: 检查是否使用了 `rememberCoroutineScope()`，避免在 `LaunchedEffect` 中重复创建动画对象。

### Q: 触摸跟踪有延迟？

**A**: 使用 `snapTo` 而不是 `animateTo` 来更新位置：

```kotlin
animationScope.launch {
    positionAnimation.snapTo(change.position)
}
```

### Q: 形变效果太夸张？

**A**: 调整系数：

```kotlin
val maxDragScale = 4f.dp.toPx() / size.height  // 降低此值
val initialDerivative = 0.05f  // 降低此值减少位移
```

## 完整示例（v2 规范）

```kotlin
@Composable
fun CompletePressableGlass(
    backdrop: Backdrop,
    onClick: () -> Unit
) {
    val animationScope = rememberCoroutineScope()
    val interactiveHighlight = remember(animationScope) {
        InteractiveHighlight(animationScope = animationScope)
    }

    Box(
        Modifier
            .drawBackdrop(
                backdrop = backdrop,
                shape = { RoundedCornerShape(24.dp) },
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
                highlight = {
                    val p = interactiveHighlight.pressProgress
                    Highlight.Default.copy(alpha = 0.15f + 0.35f * p)
                },
                shadow = {
                    val p = interactiveHighlight.pressProgress
                    Shadow(alpha = 0.08f + 0.22f * p)
                },
                innerShadow = {
                    val p = interactiveHighlight.pressProgress
                    InnerShadow(radius = 4f.dp + 8f.dp * p, alpha = 0.1f + 0.3f * p)
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
            .padding(24.dp)
    ) {
        Text("Complete Glass", color = Color.White)
    }
}
```
