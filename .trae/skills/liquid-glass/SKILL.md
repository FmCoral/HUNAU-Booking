---
name: liquid-glass
description: Build liquid glass UI from lib/core/glass. Use when asked for 液态玻璃, 毛玻璃, glassmorphism, frosted bars, glass sheets, dialogs or controls. Do not use for ordinary token-styled pages.
---

# 液态玻璃（本工程 Flutter 实现）

上游 Compose「液态玻璃」Skill 的效果规范已经落到本仓库：

- 参数与视觉规范来源：`docs/skills/liquid-glass/`（Kotlin，Apache-2.0，只读参考）
- 实际可用的实现：`lib/core/glass/`（纯 Flutter，无第三方依赖）

不要从 `docs/skills/liquid-glass/` 复制 Kotlin 代码，也不要引入任何 glass/backdrop 相关 pub 包。

## 何时使用

- 用户明确要求：液态玻璃、毛玻璃、玻璃拟态、悬浮玻璃底栏、玻璃弹窗/抽屉、玻璃控件
- 需要浮在**有内容**的背景之上：图片、封面、课表网格、地图、视频封面
- 需要比普通白卡片更轻的悬浮层（底部操作条、浮动工具条、媒体控制）

不要在以下情况使用：

- 普通业务页面。常规页面继续用 `AppColors` 白底 + `border` 细边框 + 14 圆角（见 `lib/core/theme/app_theme.dart`），禁止把现有页面改成玻璃
- 玻璃后面是纯色底（`#F3F4F6`）。没有内容可模糊时它只是变白的一层，视觉收益为零

## 文件地图

| 文件 | 内容 |
| --- | --- |
| [glass_tokens.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_tokens.dart) | `GlassSpec`（参数集，light/dark）、`GlassMotion`（按压节奏） |
| [liquid_glass.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/liquid_glass.dart) | `LiquidGlass` 核心容器：模糊 + 底色 + 光晕 + 内阴影/描边 + 外阴影 + 按压缩放 |
| [glass_button.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_button.dart) | `GlassButton`（48 高胶囊）、`GlassIconButton`（圆形，默认 42） |
| [glass_card.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_card.dart) | `GlassCard`（14 圆角）、`GlassChip`（36 高标签） |
| [glass_bottom_nav.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_bottom_nav.dart) | `GlassBottomNav` + `GlassNavItem`（悬浮胶囊底栏） |
| [glass_bottom_sheet.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_bottom_sheet.dart) | `showGlassBottomSheet`、`GlassBottomSheetSurface` |
| [glass_dialog.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_dialog.dart) | `showGlassDialog` |
| [glass_search_bar.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_search_bar.dart) | `GlassSearchBar`（44 高，自带清除按钮） |
| [glass_toggle.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_toggle.dart) | `GlassToggle`（52×32） |
| [glass_slider.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass_slider.dart) | `GlassSlider`（支持 `divisions` 离散档位） |
| [glass.dart](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/lib/core/glass/glass.dart) | 统一导出，页面里 `import '../../core/glass/glass.dart';` 即可 |

## 效果链：上游 → 本工程

上游顺序是 `vibrancy → blur → lens → highlight → shadow`。Flutter 的 `BackdropFilter` 只能对已合成的下层做高斯模糊，**无法在 fragment shader 里采样 backdrop**，所以：

| 上游效果 | 本工程实现 | 差异 |
| --- | --- | --- |
| `vibrancy()` 色彩增强 | 提高底色不透明度（15% → 28%） | 没有饱和度补偿，靠底色拉对比 |
| `blur(2dp)` | `ImageFilter.blur(sigma: 12)` | 观感接近；sigma 是逻辑像素 |
| `lens()` 折射 + 色散 | 内阴影 + 顶部高光描边 + 径向光晕 | 只有“玻璃厚度”暗示，没有真实折射与色散 |
| `Highlight.Default` | `_GlassEdgePainter` 的对角高光线 + 径向 sheen | 高光跟随手指位置 |
| `Shadow` / `InnerShadow` | `BoxShadow` + `MaskFilter.blur(BlurStyle.inner)` 描边 | 内阴影用 blur 近似 |
| 按压缩放（4dp 形变） | `Transform.scale(0.97)` + 光影增强 | 不做方向性拉伸 |

要改参数只改 `GlassSpec`，不要在页面里手写 `BackdropFilter`。

## 用法

给玻璃留出有内容的背景，玻璃浮在 `Stack` 上层：

```dart
import '../../core/glass/glass.dart';

Stack(
  children: [
    Positioned.fill(child: backgroundImageOrTimetable),
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GlassBottomNav(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          GlassNavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: '课表'),
          GlassNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: '我'),
        ],
      ),
    ),
  ],
)
```

底部弹窗与对话框：

```dart
await showGlassBottomSheet<void>(
  context: context,
  builder: (sheetContext) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('选择时段', style: AppText.sectionTitle.copyWith(color: context.colors.text)),
      // 长内容用 Flexible + SingleChildScrollView
    ],
  ),
);

await showGlassDialog<void>(
  context: context,
  title: '退出登录',
  message: '将清空本地登录状态，确定继续？',
  actions: [
    TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
    TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
  ],
);
```

卡片、按钮与控件：

```dart
GlassCard(child: Text('浮在封面上的数据', style: AppText.bodyDense.copyWith(color: context.colors.text)));

GlassButton(label: '开始预约', icon: Icons.play_arrow, onTap: onStart);
GlassIconButton(icon: Icons.more_horiz, tooltip: '更多', onTap: onMore);

GlassSearchBar(hint: '搜索场馆', onChanged: (v) {});

GlassToggle(value: enabled, onChanged: (v) => setState(() => enabled = v));

GlassSlider(
  value: duration,
  min: 0.5,
  max: 3,
  divisions: 5,
  label: '时长',
  onChanged: (v) => setState(() => duration = v),
);

Wrap(
  spacing: AppSpacing.sm,
  children: [
    GlassChip(label: '全部', selected: filter == null, onTap: () => setState(() => filter = null)),
    for (final name in venues)
      GlassChip(label: name, selected: filter == name, onTap: () => setState(() => filter = name)),
  ],
);
```

统一换风格（例如更轻的模糊、品牌色底）：

```dart
LiquidGlass(
  spec: GlassSpec.of(context).copyWith(blurSigma: 8, sheenOpacity: 0.10),
  tint: context.colors.brand,
  tintOpacity: 0.18,
  borderRadius: BorderRadius.circular(20),
  padding: const EdgeInsets.all(16),
  child: child,
)
```

## 实施流程

1. 先判断是否真的需要玻璃：背景必须有内容，且该区域不是常规表单页。
2. 优先复用上表组件；只有布局特殊时才直接用 `LiquidGlass`。
3. 颜色、圆角、间距、字号一律取自 `app_tokens.dart`（`context.colors` / `AppRadius` / `AppSpacing` / `AppText`），玻璃只负责背景层。
4. 需要滚动的玻璃内层加 `RepaintBoundary`；玻璃本体已经内置。
5. 跑 `flutter analyze`，必要时写临时 widget test 渲染一次，验证后删除测试文件。
6. 不主动改造现有页面；用户点名某个页面再动。

## 硬约束

- 不新增依赖，不引入 `glassmorphism` / `backdrop_filter` 等 pub 包
- 不在 `ListView` / `GridView` 的每一项里放玻璃（每层玻璃都是一次独立的离屏模糊）
- 不嵌套 `BackdropFilter`：玻璃里再要玻璃，用 `LiquidGlass(enableBlur: false, tintOpacity: 0.45)` 叠一层半透明底即可
- 同屏玻璃层数量控制在 3 个以内（底栏 + 一张卡 + 一个浮钮已经是上限）
- 不给纯色页面加玻璃；玻璃必须后面有真实内容
- 深色模式走 `GlassSpec.dark`，由 `GlassSpec.of(context)` 自动切换，不要写死 `Color(0xFF...)`
- 动画时长用 `GlassMotion`，不要另造一套

## 性能与平台

- `blurSigma` 12 是默认平衡点；`>= 20` 在低端机掉帧明显，`>= 28` 只适合单层静态封面
- Android Impeller 下 `BackdropFilter` 走离屏渲染，低端机（Android 10 及以下、中低端 GPU）建议 `enableBlur: false` + 提高 `tintOpacity` 到 0.5 降级
- 滚动、拖动、动画中的玻璃每帧都要重算模糊；给玻璃外层的滚动容器设 `physics` 正常即可，但不要在滚动列表里复用同一块玻璃
- `showGlassBottomSheet` / `showGlassDialog` 的 `BackdropFilter` 会把遮罩层一起模糊，遮罩颜色用 0.28 黑，避免过暗

## 排查

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 玻璃看起来只是白块 | 背景没有内容，或 `tintOpacity` 过高 | 换到有图片/网格的背景上，或降到 0.2 |
| 文字发灰、对比度不足 | 玻璃后面是灰底，透出的灰拉低了文字 | 提高 `tintOpacity`，或把文字改用 `context.colors.text` 并加粗 |
| 边缘出现直角 | 圆角只给了 `borderRadius`，内容自己画了背景 | 内容不要自带不透明底色，让玻璃负责底色 |
| 一屏卡顿 | 玻璃层过多或 sigma 过大 | 降到 1–2 层，sigma 降到 8–12 |
| 弹窗后面是黑块 | `Dialog`/`BottomSheet` 自带背景色 | 用 `showGlassDialog` / `showGlassBottomSheet`，它们已把背景设为透明 |
| 底栏被系统手势条压住 | 没有安全区 | `GlassBottomNav` 已内置 `SafeArea`；自绘时自己加 |

## 参考

- [parameters.md](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/.trae/skills/liquid-glass/references/parameters.md)：上游 v2 参数表、dp→sigma 换算、调参档位
- [mapping.md](file:///d:/Users/coral/Desktop/github/HUNAU-Booking/.trae/skills/liquid-glass/references/mapping.md)：Compose→Flutter 组件与 API 映射、无法实现的效果清单
- 上游归档：`docs/skills/liquid-glass/`，参数出处 `guides/best-practices.md`，组件出处 `components/LiquidButton.kt`
