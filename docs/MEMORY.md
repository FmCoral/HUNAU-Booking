# 项目记忆 · Book

> 本文件用于跨对话交接。重开对话时先读这里，再读 [README](../README.md)、[开发方案](开发方案.md) 与 [开发进度](进度.md)。

## 1. 项目身份

- 项目名：Book（校园场馆预约，独立 App，与 Hunau App 完全分离）
- 本地仓库：`D:\Users\coral\Desktop\github\HUNAU-Booking`（开发草稿目录为 `D:\Users\coral\Desktop\booking`）
- 远端仓库：`https://github.com/FmCoral/HUNAU-Booking.git`
- Flutter 包名：`booking`
- Android applicationId：`com.fmcoral.booking`
- 桌面显示名称：`Book`
- 工程状态：Flutter 脚手架已初始化（仅 Android 平台），业务代码未开始
- 原文档曾放在 `d:\Users\coral\Desktop\hunau\venue-booking-app`，已迁移到本项目，旧目录已删除

## 2. 已确认需求

- 登录后展示功能列表，当前仅「场馆预约」。
- 场馆类型列表（乒乓球馆、羽毛球馆等）。
- 选中某类运动后，展示**同一类运动**的场地 × 时段矩阵，不跨运动类型汇总。
- 矩阵页自动拉取全部场地与时段状态，表格展示，可直接预约（操作形式暂定）。
- 导航栏提供「超前预定」入口。
- 超前预定：**单个未来日期 + 多个时间段**，不支持一次配置多个日期。
- 到该日期开放时刻自动执行，逐段返回结果，成功后进入支付。

## 3. 业务规则（用户纠正过的版本，务必遵守）

- 可预约窗口 = **当日 08:00 至次日 08:00**，窗口内可预约今日与明日。
- 例：1 号 08:00 – 2 号 08:00 可预约 1、2 号；3 号不可预约。
- 不存在零点分段，不要再写「00:00 – 08:00」。
- 超前预定目标必须是窗口外日期，执行时刻 = 目标日期前一日 08:00。
- 窗口外日期无已预约信息，必须让用户选择冲突处理策略并确认失败风险。

## 4. 技术决策

- 技术栈：Flutter，复用现有 Hunau App 的登录与 Cookie 模块（拷贝裁剪，不直接引用）。
- 提交策略：优先纯 HTTP 秒杀；接口若含动态签名，回退 WebView 注入。
- 时间同步：对轻量接口采样 5 次取中位数，误差目标 ≤ 50ms；定时用单调时钟。
- 准点时序：08:00 前 10s 校验登录、前 5s 预热连接、前 2s 校准并定时、提前 150ms 发首包。
- 支付：WebView 打开支付页，带订单倒计时与状态轮询。

## 5. 已完成

- [x] README（需求/规则/流程/待确认项）
- [x] docs/开发方案.md（架构、页面、模块、算法、数据模型、接口占位、里程碑）
- [x] Flutter 工程脚手架：`flutter create --platforms=android --org=com.fmcoral --project-name=booking --no-pub`
- [x] 更新域名常量：`lib/core/constants/app_constants.dart`
- [x] docs/发布与更新.md（域名、R2、version.json、GitHub Actions 方案）
- [x] 应用名改为 Book，Android label 与 MaterialApp title 同步
- [x] 图标：`tool/generate_icons.py` 生成圆角图标，输出 5 档 mipmap 与 assets/branding
- [x] Git 仓库初始化并关联 `FmCoral/HUNAU-Booking`

## 6. 发布与更新（已创建资源）

- 域名：`apk.book.hunau.fmcoral.com`
- 用途：APK 分发 + `latest/version.json`
- R2 桶：已创建，绑定上述域名
- 路径规范：`latest/version.json`、`latest/app-release.apk`、`v{version}/app_v{version}.apk`
- Cloudflare：R2 公共桶 + 自定义域名 + 缓存规则（version.json 1 分钟，APK 5 分钟）
- GitHub 仓库：`FmCoral/HUNAU-Booking`，构建发布流水线待补

## 7. 待办

1. `flutter pub get` + 补齐依赖（dio、cookie_jar、dio_cookie_manager、flutter_inappwebview、flutter_secure_storage、shared_preferences、intl）。
2. 移植登录模块（`HttpLoginService`、`AuthProvider` cookie 读取、`AppCookieManager`）。
3. 抓包确认接口：场馆类型、场地列表、时段矩阵、提交预约、订单、支付。
4. 实现场馆类型页与矩阵页。
5. 实现当场预约与支付。
6. 实现超前预定（单日期 + 多时段 + 冲突策略）与计划列表。
7. 实现时间同步与准点调度。
8. 用户创建 R2 桶与 GitHub 仓库后，接入更新检测与自动发布。

## 8. 待确认项

- 矩阵页时段粒度（整点 / 30 分钟 / 服务端原始粒度）。
- 当场预约操作形式（点格子弹窗 / 多选批量 / 长按快捷）。
- 超前预定可选的目标日期范围。
- 冲突策略最终选项（C-1 全有或全无、C-2 尽力而为、C-3 自动替补、C-4 备选清单、C-5 只保首段）。
- 服务端是否支持一次提交多个时段。
- 服务端是否支持取消订单（影响 C-1）。
- 窗口外日期能否提前获取场地/时段 id。
- 计划的后台执行方式（前台驻留 / 精确闹钟 / 前台服务）。
- 支付页是否允许外部浏览器打开。
- F-09「场馆概览」是否本期实现。

## 9. 开发环境

- Flutter：`D:\dev\flutter`
- Android SDK：`D:\dev\android-sdk`
- JDK 17：`D:\dev\jdk17`
- 构建前环境变量：`JAVA_HOME=D:\dev\jdk17`、`ANDROID_HOME=D:\dev\android-sdk`

## 10. 可复用参考（Hunau App）

| 能力 | 文件 |
| --- | --- |
| CAS/超星登录 | `d:\Users\coral\Desktop\hunau\lib\features\auth\services\http_login_service.dart` |
| 登录态读取 | `d:\Users\coral\Desktop\hunau\lib\features\auth\providers\auth_provider.dart` |
| Cookie 持久化 | `d:\Users\coral\Desktop\hunau\lib\core\network\cookie_manager.dart` |
| WebView 容器 | `d:\Users\coral\Desktop\hunau\lib\features\workspace\screens\webview_detail_screen.dart` |
| 版本更新（参考模式） | `d:\Users\coral\Desktop\hunau\lib\core\services\update_service.dart` |
| 场馆预约地址 | `d:\Users\coral\Desktop\hunau\lib\core\constants\app_constants.dart` |

## 11. 硬性约束

- 不跨运动类型汇总矩阵。
- 超前预定的一个计划只对应一个日期，但可有多个时间段。
- 可预约窗口只按 08:00–次日 08:00 表述。
- 接口未抓包确认前，不进入准点抢约编码。
- 不修改用户本地代理配置；如需抓包代理，先征求用户同意。
- 不做多账号并发、不绕过验证码、不高频刷单。
