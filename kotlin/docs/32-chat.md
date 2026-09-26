# 32 · ⭐实战：终端聊天室（sealed 事件 + MVP 分层 + 规则机器人）

> 对应示例：`examples/32_chat/`（`Model.kt` + `Server.kt` + `Chat.kt` + `Main.kt`）
>
> 把 08（密封事件穷尽 when）、15/31（HTTP + Flow 游标拉新）、16（错误路径）、20（表驱动测试）
> 拧成一个项目：MVP 三件套契约、确定性规则机器人、剧本化对话、快照即回放。

## 32.1 MVP 三件套：View / Presenter / Interactor

参考书（实例精解第 5-6 章）的 Messenger 用 MVP 把"界面"与"逻辑"钉在契约两侧——本例的终端版：

```kotlin
interface ChatView {                       // View 契约：只管展示， dumb
    fun render(lines: List<String>)
    fun showError(message: String)
}

class TranscriptView : ChatView {          // 终端实现 = 收集行（天然可断言、可快照）
    val transcript = mutableListOf<String>()
    override fun render(lines: List<String>) { transcript += lines }
    override fun showError(message: String) { transcript += "[错误] $message" }
}

class ChatPresenter(private val view: ChatView, private val api: ChatApi) { ... }
```

分层的回报是**可测试性**：`TranscriptView` 收集渲染结果，测试直接对着"剧本对话的字幕"断言——UI 换成 Android RecyclerView 时 Presenter 一行不改（参考书的适配器只动 View 层）。业务访问集中在 Interactor 形态的 `ChatApi` 里（31 章客户端的翻版）。

## 32.2 sealed 事件模型：穷尽渲染

聊天室的领域事件是三态密封类（08 章 ADT）：

```kotlin
sealed class ChatEvent {
    data class Joined(val user: String) : ChatEvent()
    data class Said(val id: Long, val from: String, val text: String) : ChatEvent()
    data class Left(val user: String) : ChatEvent()
}

fun renderEvent(e: ChatEvent): String = when (e) {      // 无 else——加第四种事件编译器逼你改这
    is ChatEvent.Joined -> "*** ${e.user} 进入聊天室"
    is ChatEvent.Said   -> "[${e.from}] ${e.text}"
    is ChatEvent.Left   -> "*** ${e.user} 离开"
}
```

线上传输是 JSON，客户端用**工厂函数**把平坦 Map 还原成密封层级——`type` 字段对不上就是错误输入，穷尽性在边界收口。

## 32.3 聊天服务端

31 章同款骨架（JDK HttpServer + 手工路由 + Bearer + 全局错误映射），端点四个：

```text
POST /join  {"user"}            -> {"token":"tok-ann"}（并广播 Joined）
POST /say   {"text"}  [Bearer]  -> {"id":6}（并广播 Said；空文本 400）
POST /leave           [Bearer]  -> {"ok":true}（并广播 Left）
GET  /events?since=N  [Bearer]  -> [ {...}, ... ]（游标拉新，31 章轮询姿势）
```

事件存内存列表、id 单调递增——`since` 游标语义与服务端顺序完全确定。

## 32.4 规则机器人：表驱动剧本

不接 AI、不碰随机——确定性机器人让整个会话可快照（20 章"可复现"的坚持）：

```kotlin
object EchoBot {
    fun replyTo(text: String): String = when {
        text.endsWith("？")      -> "好问题！「${text.dropLast(1)}」的答案是：42"
        text.contains("你好")    -> "你好！我是回声机器人"
        text.contains("再见")    -> "再见，下次见！"
        else                     -> "回声: $text"
    }
}
```

它是第二个登录用户（`bot`），对 `ann` 的每条消息回复一次——**双客户端同服务端**，正是参考书"仿 QQ"业务流（登录→取联系人→收发消息）的终端内核。

## 32.5 Presenter 编排：游标 + 错误路径

```kotlin
class ChatPresenter(private val view: ChatView, private val api: ChatApi) {
    private var since = 0
    fun onJoin(user: String, pass: String) { api.join(user, pass); refresh() }
    fun onSay(text: String) {
        try { api.say(text); refresh() }
        catch (e: ApiException) { view.showError(e.body) }    // 错误也走 View——别 printStackTrace
    }
    fun refresh() = view.render(api.eventsSince(since).map(::renderEvent).also {
        since += it.size   // hmm 游标推进见下
    })
}
```

游标推进的坑：`since += it.size` 只在"事件只增不漏"时成立——正确姿势是**取最后一条事件的 id**（`since = last.id`）。本项目事件严格递增，两种写法等价，但生产代码用 id 游标（31 章轮询流的写法）。

## 32.6 剧本对话（快照 = 回放）

`Main` 是编剧：ann 加入读历史 → 两条消息 → bot 加入并逐条回复 → ann 说再见 → bot 回应 → ann 离开 → 打印完整字幕。每一步都是确定性的，`expected.txt` 就是这场对话的**逐字回放**——任何一层（服务端路由/渲染/机器人规则/游标）改坏一个字，快照立刻红。

## 本章坑位

- MVP 的 Presenter 别 import 任何 UI 类型（本例 Presenter 只认 `ChatView` 接口）——耦合一进来分层就白搭
- `since += 本轮条数` 只在无漏序时等价于 id 游标；稳妥写法永远取最后事件 id
- 渲染 when 不写 else——密封类加事件时让编译器逼你补分支
- 机器人禁止随机与时间——快照测试的对话必须可重放
- 错误路径也要进 View（`showError`），别在 Presenter 里直接 println
