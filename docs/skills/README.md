# 技能与参考库

存放后续可能用到的外部 Skill 与参考实现。这里的内容多来自其他平台（如 Android Compose），不能在本 Flutter 工程直接引用，仅作为视觉参数、交互细节与实现思路的参考。

上游参数已经落到本工程可用的实现：**项目 Skill 在 [.trae/skills/liquid-glass/SKILL.md](../../.trae/skills/liquid-glass/SKILL.md)，组件在 `lib/core/glass/`**。日常开发直接按项目 Skill 写代码，不需要读下面归档的 Kotlin。

## 项目内实现（Flutter）

| 项 | 内容 |
| --- | --- |
| Skill | [.trae/skills/liquid-glass/SKILL.md](../../.trae/skills/liquid-glass/SKILL.md)（触发词、组件清单、硬约束、排查） |
| 参考 | [references/parameters.md](../../.trae/skills/liquid-glass/references/parameters.md)（dp→sigma 换算、参数档位）、[references/mapping.md](../../.trae/skills/liquid-glass/references/mapping.md)（Compose→Flutter 映射） |
| 代码 | `lib/core/glass/`：`GlassSpec`、`LiquidGlass`、`GlassButton`、`GlassCard`、`GlassBottomNav`、`showGlassBottomSheet`、`showGlassDialog`、`GlassSearchBar`、`GlassToggle`、`GlassSlider`、`GlassChip` |
| 依赖 | 无（只用 `dart:ui` 的 `BackdropFilter` / `ImageFilter` / `MaskFilter`） |

## liquid-glass（上游 Kotlin 归档）

| 项 | 内容 |
| --- | --- |
| 来源 | https://github.com/JUEMING-006/skill-liquid-glass （`main`，归档于 2026-11-28） |
| Skill 版本 | 1.0.0 |
| 许可 | Apache-2.0，见 [LICENSE](liquid-glass/LICENSE) 与 [NOTICE](liquid-glass/NOTICE)（基于 Kyant0 的 AndroidLiquidGlass / Backdrop） |
| 技术栈 | Jetpack Compose / Compose Multiplatform，依赖 `io.github.kyant0:backdrop:2.0.0` |
| 前提 | Min SDK 21；effects 需 Android 12+（RenderEffect），`lens` 的折射/色散与 RuntimeShader 效果需 Android 13+ |

### 目录

| 路径 | 说明 |
| --- | --- |
| [SKILL.md](liquid-glass/SKILL.md) | 总入口：能力清单、依赖、效果顺序约定、组件 API 与已知限制 |
| [guides/](liquid-glass/guides/) | 快速开始、构建配置、按压效果、最佳实践、故障排查 |
| `components/` | 完整交互组件：按钮、底部导航、滑块、开关、弹窗、搜索框、顶部栏、键盘、放大镜、锁屏等 |
| `effects/` | 基础效果：模糊 `Blur`、折射 `Lens`、高光 `Highlight`、色彩振动 `Vibrancy` |
| `backdrops/` | 背景采集：画布、图层、组合背景 |
| `templates/` | 直接可复用的整页模板与应用框架 |
| `utils/` | 位图、协程、SDF Shader、涟漪等辅助实现 |

### 使用提示

- 本项目是 Flutter，Kotlin 代码不能直接搬用；需要玻璃效果时直接用 `lib/core/glass/`（见上方项目内实现），这里的归档只用于查参数与交互细节。
- 若后续要做 Android 原生液态玻璃页面，按 [quick-start](liquid-glass/guides/quick-start.md) 配置依赖即可；效果必须按 **color filter → blur → lens** 顺序应用。
- 改动效果参数前先读 [best-practices](liquid-glass/guides/best-practices.md)，避免 Android 12/13 上的兼容与性能问题。
