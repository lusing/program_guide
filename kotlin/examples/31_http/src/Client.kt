// 31 · HTTP 客户端：java.net.http.HttpClient + 类型化方法 + Bearer"拦截器" + Flow 轮询
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

class ApiException(val status: Int, val body: String) : Exception("HTTP $status: $body")

class ApiClient(private val port: Int) {
    private val http: HttpClient = HttpClient.newHttpClient()
    private var token: String? = null

    /** 唯一的出口：带头（拦截器位置）+ 发送 + 非 2xx 转 ApiException */
    private fun call(method: String, path: String, body: String? = null): String {
        val b = HttpRequest.newBuilder(URI.create("http://127.0.0.1:$port$path"))
        token?.let { b.header("Authorization", "Bearer $it") }
        if (body != null) b.method(method, HttpRequest.BodyPublishers.ofString(body))
        else b.method(method, HttpRequest.BodyPublishers.noBody())
        val resp = http.send(b.build(), HttpResponse.BodyHandlers.ofString())
        if (resp.statusCode() !in 200..299) throw ApiException(resp.statusCode(), resp.body())
        return resp.body()
    }

    fun login(user: String, pass: String): String {
        token = null          // 换令牌前先清掉旧头
        val r = call("POST", "/token", MiniJson.encode(mapOf("user" to user, "pass" to pass)))
        val t = MiniJson.parseFlat(r)["token"] as String
        token = t
        return t
    }

    fun users(): String = call("GET", "/users")

    fun addUser(name: String): String = call("POST", "/users", MiniJson.encode(mapOf("name" to name)))

    fun messagesSince(since: Int): List<Map<String, Any?>> = MiniJson.parseList(call("GET", "/messages?since=$since"))

    fun postMessage(text: String): String = call("POST", "/messages", MiniJson.encode(mapOf("text" to text)))

    /** 原始调用：集成测试探活未知路由等场景用 */
    fun raw(method: String, path: String, body: String? = null): String = call(method, path, body)
}

/**
 * 冷流轮询：每轮拉 since 之后的新消息逐条 emit。
 * maxPolls 是硬上限——消费端忘记取消时也不至于无限跑（防御式设计）。
 */
fun pollFlow(api: ApiClient, from: Int, maxPolls: Int, onPoll: () -> Unit = {}): Flow<String> = flow {
    var since = from
    repeat(maxPolls) {
        onPoll()
        for (m in api.messagesSince(since)) {
            emit("${m["from"]}: ${m["text"]}")
            since = (m["id"] as Long).toInt()
        }
    }
}
