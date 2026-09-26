// 32 · 聊天服务端：事件存储 + join/say/leave/events 四端点 + Bearer + 全局错误映射
import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.nio.charset.StandardCharsets

class ChatServer {
    private var server: HttpServer? = null

    /** 事件存储：内存列表 + 单调递增 id（since 游标的确定性根基） */
    val events = mutableListOf<ChatEvent>()
    private var nextId = 4L     // 前 3 条 Said 的 id 是 1..3

    init {
        events += ChatEvent.Said(1, "bob", "你好")
        events += ChatEvent.Said(2, "cat", "在吗")
        events += ChatEvent.Said(3, "bob", "终端聊天室上线")
    }

    private val tokens = mutableMapOf<String, String>()      // token -> user

    fun start(): Int {
        val srv = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
        server = srv
        srv.createContext("/") { ex -> handle(ex) }
        srv.start()
        return srv.address.port
    }

    fun stop() = server?.stop(0)

    private fun handle(ex: HttpExchange) {
        try {
            route(ex)
        } catch (e: AppError) {
            send(ex, e.status, MiniJson.encode(mapOf("error" to e.code)))
        } catch (e: Exception) {
            send(ex, 500, MiniJson.encode(mapOf("error" to "internal")))
        } finally {
            ex.close()
        }
    }

    private fun route(ex: HttpExchange) {
        val path = ex.requestURI.path
        val query = ex.requestURI.rawQuery ?: ""
        val body = ex.requestBody.readBytes().toString(StandardCharsets.UTF_8)
        when ("${ex.requestMethod} $path") {
            "POST /join" -> {
                val user = MiniJson.parseFlat(body)["user"] as? String ?: ""
                if (user.isBlank()) throw AppError(400, "user blank")
                val token = "tok-$user"
                tokens[token] = user
                events += ChatEvent.Joined(nextId++, user)
                send(ex, 200, MiniJson.encode(mapOf("token" to token)))
            }
            "POST /say" -> {
                val user = auth(ex)
                val text = MiniJson.parseFlat(body)["text"] as? String ?: ""
                if (text.isBlank()) throw AppError(400, "text blank")
                val e = ChatEvent.Said(nextId++, user, text.trim())
                events += e
                send(ex, 201, MiniJson.encode(mapOf("id" to e.id)))
            }
            "POST /leave" -> {
                val user = auth(ex)
                events += ChatEvent.Left(nextId++, user)
                send(ex, 200, MiniJson.encode(mapOf("ok" to true)))
            }
            "GET /events" -> {
                auth(ex)
                val since = query.substringAfter("since=", "0").toLongOrNull() ?: 0L
                send(ex, 200, MiniJson.encode(events.filter { it.id > since }.map { it.toVo() }))
            }
            else -> throw AppError(404, "not found")
        }
    }

    private fun auth(ex: HttpExchange): String {
        val token = (ex.requestHeaders.getFirst("Authorization") ?: "").removePrefix("Bearer ")
        return tokens[token] ?: throw AppError(401, "missing or bad token")
    }

    private fun send(ex: HttpExchange, status: Int, json: String) {
        val bytes = json.toByteArray(StandardCharsets.UTF_8)
        ex.responseHeaders.set("Content-Type", "application/json; charset=utf-8")
        ex.sendResponseHeaders(status, bytes.size.toLong())
        ex.responseBody.use { it.write(bytes) }
    }
}
