# Book

> 湖南农业大学校园工具：用「智慧湘农」账号登录，课表、校园卡余额与充值、宿舍电费、软件公告一屏直达。

当前版本：**1.2.2**（`versionCode 25`，arm64）

## 1. 项目概览

Book 是一个轻量 Flutter（Android）应用，面向湖南农业大学在校学生，把日常高频的校园服务收敛到两三个页面里：

- **课表**：登录后自动同步教务课表，周视图展示，左右滑动切周。
- **校园卡**：首页「我」直接看到余额；点进卡片可充值（支付宝 / 微信）。
- **宿舍电费**：可配置两个宿舍，分别查看余额并充值，校园卡支付。
- **公告**：读取 R2 上的软件公告，支持按版本定向展示，无需发版即可更新。
- **帮助与反馈**：内容直送反馈接口，附带账号与版本信息便于定位问题。

## 2. 功能清单

| 编号 | 功能 | 说明 | 状态 |
| --- | --- | --- | --- |
| F-01 | 账号登录 | 统一认证 / 融合门户登录，Cookie 持久化，支持启动静默登录 | 已完成 |
| F-02 | 首页课表 | 周视图课表，灰色底，表头固定，右侧留白 | 已完成 |
| F-03 | 课表同步 | 登录后拉取教务课表并本地缓存 | 已完成 |
| F-04 | 校园卡余额 | 「我」页展示姓名、卡号与余额，本地缓存 + 会话落盘，刷新失败自动重授权 | 已完成 |
| F-05 | 校园卡充值 | 10 / 20 / 50 元或自定义金额（1–1000 元，支持两位小数），支付宝 / 微信 | 已完成 |
| F-06 | 头像 | 带登录 Cookie 下载并缓存到本地 | 已完成 |
| F-07 | 宿舍配置 | 通用设置中选择校区 → 楼栋 → 房间，可存两个宿舍 | 已完成 |
| F-08 | 宿舍电费 | 两个宿舍余额展示，点击进入充值页可切换宿舍 | 已完成 |
| F-09 | 宿舍充值 | 10 / 20 / 50 / 100 元或自定义整数金额（1–1000 元），校园卡支付 | 已完成 |
| F-10 | 软件公告 | R2 `announcements.json`，支持全版本 / 版本区间 / 精确版本 | 已完成 |
| F-11 | 帮助与反馈 | 提交反馈、查看我的反馈 | 已完成 |
| F-12 | 检查更新 | 读取 `version.json`，进入更新说明页并可下载 APK | 已完成 |
| F-13 | 用户协议 | 关于页内置协议全文 | 已完成 |
| F-14 | 退出登录 | 清空路由、余额与宿舍缓存，回到登录首页 | 已完成 |
| F-15 | 账号隔离 | 切换账号后旧请求结果作废，不会残留上一个账号的余额与宿舍 | 已完成 |

## 3. 技术要点

- **框架**：Flutter（Android，arm64 为主），applicationId `com.fmcoral.booking`。
- **网络**：`dio` + `cookie_jar`，按域名回放 Cookie。校园卡与电费走纯 HTTP：手动跟随 302、预热会话、多页面回退，必要时回退 WebView。
- **状态**：不引入 Riverpod，使用 `ChangeNotifier` + `AuthScope`（InheritedNotifier）。
- **WebView**：`flutter_inappwebview`，仅用于登录与支付承载等必要场景。
- **本地存储**：`shared_preferences`（课表、校园卡、宿舍、头像路径）。
- **主题**：`lib/core/theme/app_tokens.dart` 统一语义色、间距、圆角与字号，页面内不硬编码色值。
- **加密**：`lib/core/utils/dkyw_crypto.dart` 对校园卡与电费支付请求签名。

## 4. 目录结构

```
HUNAU-Booking/
├── index.html                      官网单页（由仓库直接托管）
├── android/                        Android 工程
├── assets/branding/                应用图标
├── docs/
│   ├── announcements.md            软件公告 JSON 规则
│   ├── announcements.example.json  公告示例（可直接改后上传）
│   ├── CHANGELOG.md                更新日志
│   ├── release-notes/              各版本更新说明（CI 读取）
│   └── 发布与更新.md
├── lib/
│   ├── core/                       constants / network / services / theme / utils / widgets
│   └── features/
│       ├── auth/                   登录与登录态
│       ├── shell/                  底部导航壳
│       ├── timetable/              课表（模型、解析、服务、周视图）
│       ├── profile/                我（账号、校园卡、宿舍电费、设置、关于、反馈）
│       └── notice/                 软件公告（列表、详情）
├── tool/generate_icons.py
└── pubspec.yaml
```

## 5. 发布与更新

| 项目 | 地址 |
| --- | --- |
| 版本信息 | `https://apk.book.hunau.fmcoral.com/latest/version.json` |
| APK 下载 | `https://apk.book.hunau.fmcoral.com/latest/app-release.apk` |
| 软件公告 | `https://apk.book.hunau.fmcoral.com/latest/announcements.json` |
| 反馈接口 | `https://feedback.hunau.fmcoral.com/api/v1/feedback` |
| 官网 | `https://book.hunau.fmcoral.com`（由仓库根目录 `index.html` 托管） |

发布流程：

1. 修改 `pubspec.yaml` 版本号（版本号 + build，如 `1.2.2+25`）。
2. 新增 `docs/release-notes/<版本>.txt`，并在 `docs/CHANGELOG.md` 记录。
3. 单个提交 + 单个 tag `vX.Y.Z`，执行 `git push origin main vX.Y.Z`。
4. GitHub Actions 构建 arm64 APK，上传 R2 并更新 `version.json`。

详细说明见 [发布与更新](docs/发布与更新.md)。

## 6. 文档索引

| 文档 | 说明 |
| --- | --- |
| [更新日志](docs/CHANGELOG.md) | 各版本变更 |
| [公告规则](docs/announcements.md) | 公告 JSON 字段、版本定向与上传位置 |
| [发布与更新](docs/发布与更新.md) | R2、version.json、CI 流程 |

## 7. 待办

- [ ] 上传正式的 `latest/announcements.json`。
- [ ] 隐私政策页面（当前未在关于页提供，后续如有需要再补）。
