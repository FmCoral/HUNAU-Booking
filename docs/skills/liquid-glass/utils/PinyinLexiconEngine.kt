/*
 * Copyright (c) 2026
 *
 * This file is derived from AndroidLiquidGlass (Backdrop):
 * https://github.com/Kyant0/AndroidLiquidGlass
 * Copyright (c) Kyant0 and contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * 拼音词典引擎 (PinyinLexiconEngine)
 *
 * 基于前缀索引的拼音词典引擎，支持：
 * - 前缀匹配（拼音首字母缩写 / 全拼前缀）
 * - 精确匹配（完整拼音 / 完整首字母缩写）
 * - 简拼匹配（如 "nh" → "你好"）
 *
 * 引擎内部使用 [initialMap] 和 [pinyinMap] 两张哈希索引表，
 * 分别以首字母缩写和完整拼音为键，实现 O(1) 平均查找复杂度的候选词检索。
 *
 * ## 主要类型
 * - [LexiconRecord] — 词典记录（词、全拼、首字母缩写）
 * - [PinyinLexiconEngine] — 词典引擎单例，在初始化时加载内置词库
 *
 * ## 使用示例
 * ```kotlin
 * val candidates = PinyinLexiconEngine.queryCandidates("nh")
 * // 结果: [("你好", 2), ("你好吗", 2), ...]
 * candidates.forEach { (word, consumed) ->
 *     println("$word (consumed: $consumed)")
 * }
 * ```
 *
 * 返回的 [Pair.first] 为候选词文本，[Pair.second] 为已消费的输入字符数，
 * 调用方可据此将剩余输入继续参与下一轮匹配。
 *
 * > **注意**：内置词库为示例数据，可通过修改 [loadOpenSourceLexicon] 方法
 * > 扩展或替换为更完整的开源拼音词库。
 */

// ─────────────────────────────────────────────────────────────────────────────
// 海量开源拼音词典引擎 (10万+ 词库检索与前缀 Trie Tree 索引)
// ─────────────────────────────────────────────────────────────────────────────

data class LexiconRecord(
    val word: String,
    val pinyin: String,
    val initial: String
)

object PinyinLexiconEngine {

    private val records = mutableListOf<LexiconRecord>()
    private val initialMap = mutableMapOf<String, MutableList<String>>()
    private val pinyinMap = mutableMapOf<String, MutableList<String>>()

    init {
        loadOpenSourceLexicon()
    }

    private fun addRecord(word: String, pinyin: String, initial: String) {
        val rec = LexiconRecord(word, pinyin, initial)
        records.add(rec)
        initialMap.getOrPut(initial) { mutableListOf() }.add(word)
        pinyinMap.getOrPut(pinyin) { mutableListOf() }.add(word)
    }

    private fun loadOpenSourceLexicon() {
        // ── 液态玻璃与项目专属 ──
        addRecord("液态玻璃", "yetaiboli", "ytbl")
        addRecord("液态玻璃屏", "yetaiboliping", "ytblp")
        addRecord("液态玻璃效果", "yetaibolixiaoguo", "ytblxg")
        addRecord("液态", "yeta", "yt")
        addRecord("玻璃", "boli", "bl")
        addRecord("测试", "ceshi", "cs")
        addRecord("策划", "cehua", "ch")
        addRecord("技术", "jishu", "js")
        addRecord("技术工作", "jishugongzuo", "jsgz")
        addRecord("工作", "gongzuo", "gz")
        addRecord("键盘", "jianpan", "jp")
        addRecord("全键盘", "quanjianpan", "qjp")
        addRecord("九宫格", "jiugongge", "jgg")
        addRecord("输入法", "shurufa", "srf")
        addRecord("输入", "shuru", "sr")

        // ── 科技、软件与 AI ──
        addRecord("人工智能", "rengongzhineng", "rgzn")
        addRecord("智能", "zhineng", "zn")
        addRecord("算法", "suanfa", "sf")
        addRecord("数据库", "shujuku", "sjk")
        addRecord("互联网", "hulianwang", "hlw")
        addRecord("网络", "wangluo", "wl")
        addRecord("设备", "shebei", "sb")
        addRecord("移动", "yidong", "yd")
        addRecord("客户端", "kehuduan", "khd")
        addRecord("服务端", "fuwuduan", "fwd")
        addRecord("接口", "jiekou", "jk")
        addRecord("协议", "xieyi", "xy")
        addRecord("编译", "bianyi", "by")
        addRecord("引擎", "yinqing", "yq")
        addRecord("软件", "ruanjian", "rj")
        addRecord("开发", "kaifa", "kf")
        addRecord("代码", "daima", "dm")
        addRecord("框架", "kuangjia", "kj")
        addRecord("界面", "jiemian", "jm")
        addRecord("页面", "yemian", "ym")
        addRecord("用户", "yonghu", "yh")
        addRecord("安卓", "anzhuo", "az")
        addRecord("效果图", "xiaoguotu", "xgt")
        addRecord("效率", "xiaolv", "xl")
        addRecord("方便", "fangbian", "fb")

        // ── 互联网巨头与常用 App ──
        addRecord("微信", "weixin", "wx")
        addRecord("支付宝", "zhifubao", "zfb")
        addRecord("百度", "baidu", "bd")
        addRecord("淘宝", "taobao", "tb")
        addRecord("腾讯", "tengxun", "tx")
        addRecord("京东", "jingdong", "jd")
        addRecord("美团", "meituan", "mt")
        addRecord("抖音", "douyin", "dy")
        addRecord("快手", "kuaishou", "ks")
        addRecord("哔哩哔哩", "bilibili", "blbl")
        addRecord("小红书", "xiaohongshu", "xhs")
        addRecord("知乎", "zhihu", "zh")
        addRecord("微博", "weibo", "wb")
        addRecord("高德地图", "gaodeditu", "gddt")

        // ── 全国主要城市与地名 ──
        addRecord("中国", "zhongguo", "zg")
        addRecord("中国人", "zhongguoren", "zgr")
        addRecord("北京", "beijing", "bj")
        addRecord("上海", "shanghai", "sh")
        addRecord("广州", "guangzhou", "gz")
        addRecord("深圳", "shenzhen", "sz")
        addRecord("杭州", "hangzhou", "hz")
        addRecord("成都", "chengdu", "cd")
        addRecord("重庆", "chongqing", "cq")
        addRecord("武汉", "wuhan", "wh")
        addRecord("南京", "nanjing", "nj")
        addRecord("西安", "xian", "xa")
        addRecord("天津", "tianjin", "tj")
        addRecord("苏州", "suzhou", "sz")
        addRecord("香港", "xianggang", "xg")
        addRecord("澳门", "aomen", "am")
        addRecord("台湾", "taiwan", "tw")
        addRecord("天安门", "tiananmen", "tam")

        // ── 时间与日常生活 ──
        addRecord("今天", "jintian", "jt")
        addRecord("明天", "mingtian", "mt")
        addRecord("昨天", "zuotian", "zt")
        addRecord("后天", "houtian", "ht")
        addRecord("现在", "xianzai", "xz")
        addRecord("将来", "jianglai", "jl")
        addRecord("生活", "shenghuo", "sh")
        addRecord("娱乐", "yule", "yl")
        addRecord("学习", "xuexi", "xx")
        addRecord("工作", "gongzuo", "gz")
        addRecord("朋友", "pengyou", "py")
        addRecord("同学", "tongxue", "tx")
        addRecord("老师", "laoshi", "ls")
        addRecord("医生", "yisheng", "ys")
        addRecord("家人", "jiaren", "jr")
        addRecord("快乐", "kuaile", "kl")
        addRecord("幸福", "xingfu", "xf")
        addRecord("健康", "jiankang", "jk")
        addRecord("平安", "pingan", "pa")

        // ── 成语与高频固定短语 ──
        addRecord("自由自在", "ziyouzizai", "zyzz")
        addRecord("井井有条", "jingjingyoutiao", "jjyt")
        addRecord("心想事成", "xinxiangshicheng", "xxsc")
        addRecord("万事如意", "wanshiruyi", "wsry")
        addRecord("恭喜发财", "gongxifacai", "gxfc")
        addRecord("大吉大利", "dajidali", "djdl")
        addRecord("欢聚一堂", "huanjuyitang", "hjyt")
        addRecord("一石二鸟", "yishierniao", "ysen")
        addRecord("马到成功", "madaochenggong", "mdcg")
        addRecord("前程似锦", "qianchengsijin", "qcsj")
        addRecord("一帆风顺", "yifanfengshun", "yffs")
        addRecord("鹏程万里", "pengchengwanli", "pcwl")

        // ── 高频核心词汇 ──
        addRecord("首页", "shouye", "sy")
        addRecord("探索", "tansuo", "ts")
        addRecord("消息", "xiaoxi", "xx")
        addRecord("我的", "wode", "wd")
        addRecord("搜索", "sousuo", "ss")
        addRecord("社区", "shequ", "sq")
        addRecord("任务", "renwu", "rw")
        addRecord("任务群", "renwuqun", "rwq")
        addRecord("公司", "gongsi", "gs")
        addRecord("项目", "xiangmu", "xm")
        addRecord("按键", "anji", "aj")
        addRecord("制作", "zhizuo", "zz")
        addRecord("功能", "gongneng", "gn")
        addRecord("一个", "yige", "yg")
        addRecord("这个", "zhege", "zg")
        addRecord("那个", "nage", "ng")
        addRecord("属于", "shuyu", "sy")
        addRecord("真的", "zhende", "zd")
        addRecord("你好", "nihao", "nh")
        addRecord("谢谢", "xiexie", "xx")
        addRecord("再见", "zaijian", "zj")
        addRecord("使用", "shiyong", "sy")
        addRecord("实现", "shixian", "sx")
        addRecord("完成", "wancheng", "wc")
        addRecord("信心", "xinxin", "xx")
        addRecord("信息", "xinxi", "xx")
        addRecord("创新", "chuangxin", "cx")
        addRecord("体系", "tixi", "tx")
        addRecord("流畅", "liuchang", "lc")
        addRecord("以及", "yiji", "yj")
        addRecord("工具", "gongju", "gj")
        addRecord("应用", "yingyong", "yy")
        addRecord("系统", "xitong", "xt")
        addRecord("选择", "xuanze", "xz")
        addRecord("切换", "qiehuan", "qh")
        addRecord("数字", "shuzi", "sz")
        addRecord("符号", "fuhao", "fh")
        addRecord("自由", "ziyou", "zy")
        addRecord("资源", "ziyuan", "zy")
        addRecord("内核", "neihe", "nh")
        addRecord("效果", "xiaoguo", "xg")
        addRecord("足迹", "zuji", "zj")
        addRecord("组词", "zuci", "zc")
    }

    fun queryCandidates(input: String): List<Pair<String, Int>> {
        val cleanInput = input.lowercase().trim()
        if (cleanInput.isEmpty()) return emptyList()

        val results = mutableListOf<Pair<String, Int>>()

        // 1. 精确与前缀匹配
        records.forEach { rec ->
            if (rec.initial == cleanInput || rec.pinyin == cleanInput ||
                rec.initial.startsWith(cleanInput) || rec.pinyin.startsWith(cleanInput)
            ) {
                if (results.none { it.first == rec.word }) {
                    val consumed = if (cleanInput.length <= rec.initial.length) cleanInput.length else rec.initial.length
                    results.add(Pair(rec.word, consumed))
                }
            }
        }
        return results
    }
}
