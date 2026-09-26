// 32 · 客户端 API + 规则机器人 + MVP 三件套（View 契约 / Presenter 编排 / TranscriptView）
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

class ApiException(val status: Int, val body: String) : Exception("HTTP $status: $body")

/** Interactor 形态：所有网络访问集中在这里（31 章客户端的翻版） */
class ChatApi(private val port: Int) {
    private val http: HttpClient = HttpClient.newHttpClient()
    private var token: String? = null

    private fun call(method: String, path: String, body: String? = null): String {
        val b = HttpRequest.newBuilder(URI.create("http://127.0.0.1:$port$path"))
        token?.let { b.header("Authorization", "Bearer $it") }     // 拦截器位置
        if (body != null) b.method(method, HttpRequest.BodyPublishers.ofString(body))
        else b.method(method, HttpRequest.BodyPublishers.noBody())
        val resp = http.send(b.build(), HttpResponse.BodyHandlers.ofString())
        if (resp.statusCode() !in 200..299) throw ApiException(resp.statusCode(), resp.body())
        return resp.body()
    }

    fun join(user: String): String {
        val r = call("POST", "/join", MiniJson.encode(mapOf("user" to user)))
        val t = MiniJson.parseFlat(r)["token"] as String
        token = t
        return t
    }

    fun say(text: String) { call("POST", "/say", MiniJson.encode(mapOf("text" to text))) }

    fun leave() { call("POST", "/leave") }

    fun eventsSince(since: Long): List<ChatEvent> = MiniJson.parseList(call("GET", "/events?since=$since")).map(ChatEvent::of)
}

/** 规则机器人：零随机零时钟——对话可重放，快照才是回归 */
object EchoBot {
    fun replyTo(text: String): String = when {
        text.endsWith("？") -> "好问题！「${text.dropLast(1)}」的答案是：42"
        text.contains("你好") -> "你好！我是回声机器人"
        text.contains("再见") -> "再见，下次见！"
        else -> "回声: $text"
    }
}

// ---- MVP ----

/** View 契约：只管展示。Presenter 不 import 任何具体 UI 类型 */
interface ChatView {
    fun render(lines: List<String>)
    fun showError(message: String)
}

/** 终端 View：收集行——天然可断言、可快照；换 RecyclerView 时 Presenter 零改动 */
class TranscriptView : ChatView {
    val transcript = mutableListOf<String>()
    override fun render(lines: List<String>) { transcript += lines }
    override fun showError(message: String) { transcript += "[错误] $message" }
}

/** Presenter：编排 + 游标。错误路径也走 View，不直接 println */
class ChatPresenter(private val view: ChatView, private val api: ChatApi) {
    private var since = 0L

    fun onJoin(user: String) {
        api.join(user)
        refresh()
    }

    fun onSay(text: String) {
        try {
            api.say(text)
            refresh()
        } catch (e: ApiException) {
            view.showError(e.body)
        }
    }

    fun onLeave() {
        api.leave()
        refresh()
    }

    /** 拉新并渲染；游标取最后一条事件 id（比"本轮条数"更稳——见文档坑位） */
    fun refresh() {
        val fresh = api.eventsSince(since)
        if (fresh.isNotEmpty()) {
            view.render(fresh.map(::renderEvent))
            since = fresh.last().id
        }
    }
}
