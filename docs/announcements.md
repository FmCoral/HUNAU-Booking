# 软件公告规则（announcements.json）

App 内「公告」读取的是软件自己的公告，不再使用学习通通知。

## 上传位置

R2 公共桶 `apk.book.hunau.fmcoral.com`，与 `version.json` 同目录：

```
https://apk.book.hunau.fmcoral.com/latest/announcements.json
```

文件不存在（404）时 App 显示「暂无公告」，不会报错。

## 结构

```json
{
  "items": [
    {
      "id": "20261126-dorm-recharge",
      "title": "宿舍电费充值已上线",
      "content": "支持两个宿舍，点击卡片切换。",
      "publishedAt": "2026-11-26 20:00",
      "type": "feature",
      "pinned": true,
      "minVersion": "1.1.7",
      "maxVersion": "1.2.0",
      "versions": ["1.1.7", "1.1.8"],
      "link": { "text": "查看详情", "url": "https://book-hunau.fmcoral.com/" }
    }
  ]
}
```

## 字段

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `id` | 是 | 唯一标识，建议「日期-短名」，如 `20261126-dorm` |
| `title` | 是 | 标题，列表单行显示 |
| `content` | 是 | 正文，`\n` 换行；列表显示前两行摘要 |
| `publishedAt` | 是 | 发布时间字符串，按字典序倒序排列，格式建议 `YYYY-MM-DD HH:mm` |
| `type` | 否 | `notice`（默认）/ `feature` / `fix` / `warning`，只影响图标和颜色 |
| `pinned` | 否 | `true` 置顶，置顶内仍按时间倒序 |
| `minVersion` | 否 | 当前 App 版本 >= 该值才显示（含） |
| `maxVersion` | 否 | 当前 App 版本 <= 该值才显示（含） |
| `versions` | 否 | 精确版本数组，命中才显示；**非空时忽略 min/max** |
| `link` | 否 | 可选按钮：`text` 文案 + `url` 链接 |

## 版本匹配规则

优先级：`versions`（精确命中）> `minVersion` / `maxVersion`（区间）> 都不写（所有版本可见）。

版本比较按数字段逐段比较，`1.1.10 > 1.1.9`。

常见写法：

- 所有版本可见：不写任何版本字段
- 某版本及以后可见：`"minVersion": "1.1.7"`
- 某版本及以前可见：`"maxVersion": "1.1.6"`
- 仅某几个版本可见：`"versions": ["1.1.7", "1.1.8"]`
- 某区间可见：同时写 `minVersion` 和 `maxVersion`

## 其它约定

- 列表按 `pinned` → `publishedAt` 倒序展示
- 请求带时间戳参数，更新 JSON 后 App 下拉刷新即可看到，无需发版
- 删除公告直接删除对应 `items` 项；`id` 不要复用
- 示例文件见 `docs/announcements.example.json`，可直接改成正式内容上传
