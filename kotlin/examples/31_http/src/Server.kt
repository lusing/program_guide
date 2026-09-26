// 31 · 零依赖 REST 服务端：JDK HttpServer + 手工路由 + Bearer 认证 + 全局错误映射
import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.nio.charset.StandardCharsets

class RestServer(private val repo: Repo) {
    private var server: HttpServer? = null

    /** 令牌表：演示级固定令牌（真实系统：随机签发 + 过期 + 签名） */
    private val passwords = mapOf("ann" to "pw-ann", "bob" to "pw-bob")
    private val tokens = mutableMapOf<String, String>()          // token -> user

    fun start(): Int {
        val srv = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
        server = srv
        srv.createContext("/") { ex -> handle(ex) }
        srv.start()
        return srv.address.port        // 端口 0 = 系统分配，读回真实端口
    }

    fun stop() = server?.stop(0)

    // ---- 全局错误映射（= @ControllerAdvice 思想）----
    private fun handle(ex: HttpExchange) {
        try {
            route(ex)
        } catch (e: AppError) {
            send(ex, e.status, MiniJson.encode(mapOf("error" to e.code)))
        } catch (e: Exception) {
            send(ex, 500, MiniJson.encode(mapOf("error" to "internal")))
        } finally {
            ex.close()                 // 必须 finally 里关，否则客户端挂到超时
        }
    }

    private fun route(ex: HttpExchange) {
        val path = ex.requestURI.path
        val query = ex.requestURI.rawQuery ?: ""
        val body = ex.requestBody.readBytes().toString(StandardCharsets.UTF_8)
        when ("${ex.requestMethod} $path") {
            "POST /token" -> {
                val m = MiniJson.parseFlat(body)
                val user = m["user"] as? String ?: ""
                if (passwords[user] != m["pass"]) throw AppError(401, "bad credentials")
                val token = "tok-$user"
                tokens[token] = user
                send(ex, 200, MiniJson.encode(mapOf("token" to token)))
            }
            "GET /users" -> {
                auth(ex)
                send(ex, 200, MiniJson.encode(mapOf("users" to repo.users.map { it.toVo() })))
            }
            "POST /users" -> {
                val name = MiniJson.parseFlat(body)["name"] as? String ?: ""
                send(ex, 201, MiniJson.encode(repo.addUser(name).toVo()))
            }
            "GET /messages" -> {
                auth(ex)
                val since = query.substringAfter("since=", "0").toIntOrNull() ?: 0
                send(ex, 200, MiniJson.encode(repo.messagesSince(since).map { it.toVo() }))
            }
            "POST /messages" -> {
                val user = auth(ex)
                val text = MiniJson.parseFlat(body)["text"] as? String ?: ""
                send(ex, 201, MiniJson.encode(repo.addMessage(user, text).toVo()))
            }
            else -> throw AppError(404, "not found")
        }
    }

    /** Bearer 校验：返回令牌对应的用户名 */
    private fun auth(ex: HttpExchange): String {
        val header = ex.requestHeaders.getFirst("Authorization") ?: ""
        val token = header.removePrefix("Bearer ")
        return tokens[token] ?: throw AppError(401, "missing or bad token")
    }

    private fun send(ex: HttpExchange, status: Int, json: String) {
        val bytes = json.toByteArray(StandardCharsets.UTF_8)
        ex.responseHeaders.set("Content-Type", "application/json; charset=utf-8")
        ex.sendResponseHeaders(status, bytes.size.toLong())
        ex.responseBody.use { it.write(bytes) }
    }
}
