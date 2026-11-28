# 参数换算：Compose 统一规范 v2 → Flutter GlassSpec

上游参数表出处：`docs/skills/liquid-glass/guides/best-practices.md`（第 1 节）。
本工程落地在 `lib/core/glass/glass_tokens.dart` 的 `GlassSpec`。

## 对照表

| 项 | 上游（Compose / Backdrop 2.0.0） | 本工程（Flutter） | 位置 |
| --- | --- | --- | --- |
| 模糊 | `blur(2f.dp.toPx())`，RenderEffect | `ImageFilter.blur(sigma: 12)` | `GlassSpec.blurSigma` |
| 折射 | `lens(12dp, 24dp, chromaticAberration = true)` | 无（Flutter 不能采样 backdrop） | 用内阴影 + 高光描边近似 |
| 色彩增强 | `vibrancy()` | 无 | 用底色不透明度补偿 |
| 底色（浅） | `#FAFAFA` @ 15% | `#FAFAFA` @ 28% | `tint` + `tintOpacity` |
| 底色（深） | `#121212` @ 15% | `#121212` @ 36% | 同上 |
| 常驻高光 | `Highlight.Default` alpha 0.15 | 高光描边 + 径向光晕 0.16 | `highlightOpacity` / `sheenOpacity` |
| 描边 | 由 Highlight 承担 | 白色 1px，alpha 0.32（深色 0.22） | `borderOpacity` |
| 外阴影 | `Shadow(alpha = 0.08)` | `BoxShadow` alpha 0.08，blur 24，offset (0, 8) | `shadowOpacity` / `shadowBlur` / `shadowOffset` |
| 内阴影 | `InnerShadow(radius = 4dp, alpha = 0.1)` | `MaskFilter.blur(BlurStyle.inner, 5)` 描边 alpha 0.10 | `innerShadowOpacity` / `innerShadowSigma` |
| 按压高光 | `0.15 + 0.35 * progress` | `highlightOpacity + 0.20 * progress` | `GlassMotion.pressHighlightDelta` |
| 按压阴影 | `0.08 + 0.22 * progress` | `shadowOpacity + 0.22 * progress` | `GlassMotion.pressShadowDelta` |
| 按压内阴影 | `4dp + 8dp * progress`，alpha `0.1 + 0.3 * progress` | `innerShadowOpacity + 0.12 * progress` | `GlassMotion.pressInnerShadowDelta` |
| 按压缩放 | 4dp 方向性拉伸 + `tanh` 阻尼拖拽 | `Transform.scale(1 → 0.97)` | `GlassMotion.pressedScale` |
| 按压动画 | `spring(0.5, 300)` | 160ms `easeOutCubic` 按下 / 280ms 回弹 | `GlassMotion.press` / `release` |
| 状态过渡 | `spring(0.6, 250)` | 220ms `easeOutCubic` | `GlassMotion.state` |

## dp → sigma 换算

Flutter 的 `ImageFilter.blur(sigma)` 单位是逻辑像素，与 dp 同尺度，但两端的模糊实现不同：

- 上游 `blur(2dp)` 是“保留细节的轻模糊”，细节还在，只是发雾；
- Flutter 里 sigma 2 几乎看不出效果，需要更大 sigma 才能得到同样的发雾量。

经验换算：`sigma ≈ dp × 6`，再按背景细节量微调。

| 意图 | sigma | 适用 |
| --- | --- | --- |
| 轻雾（仍能看清底图轮廓） | 6–8 | 图片背景上的文字卡片 |
| 标准（默认） | 12 | 底栏、浮钮、普通玻璃卡 |
| 强雾 | 16–20 | 弹窗、抽屉，后面内容不该分散注意力 |
| 液态（大面板） | 24–28 | 单层静态封面，低端机不要用 |

## 调参档位

```dart
// 更轻
final spec = GlassSpec.of(context).copyWith(blurSigma: 8, tintOpacity: 0.22);

// 更实（后面内容很花时）
final spec = GlassSpec.of(context).copyWith(blurSigma: 16, tintOpacity: 0.40);

// 品牌色调玻璃（选中态、强调面板）
final spec = GlassSpec.of(context).copyWith(tint: context.colors.brand, tintOpacity: 0.18);
```

不要在页面里直接改 `Colors.white.withValues(...)` 这类散值；需要新风格就加一个 `GlassSpec` 预设。

## 与上游的取舍

1. **没有 vibrancy**：上游用饱和度/亮度矩阵让背后颜色更“活”。Flutter 没有等价的后处理，所以底色从 15% 提到 28%，用一点点白把对比拉回来。
2. **没有真实折射**：`lens` 依赖逐像素采样 backdrop 并做 UV 位移，`BackdropFilter` 做不到。玻璃的“厚度感”改由内阴影（暗边）+ 顶部高光（亮边）表达，这已经是视觉上最接近的近似。
3. **没有色散**：`chromaticAberration` 需要 RuntimeShader，Flutter 侧要写 fragment shader 且依然采样不到背景，收益为负，直接放弃。
4. **按压形变简化**：上游用 `tanh` 做方向性拉伸和拖拽跟随，Flutter 里手指位移与形变耦合容易抖动，统一用缩放，光影增强保留。
