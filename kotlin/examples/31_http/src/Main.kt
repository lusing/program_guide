// 31 · HTTP 实战主线：起服务 → 登录换令牌 → REST 增查 → 错误演示 → Flow 轮询与结构化取消
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.runBlocking

fun main() {
    println("== 31.1 起服务（零依赖，端口系统分配不进快照）==")
    val server = RestServer(Repo())
    val port = server.start()
    println("服务端已启动: 127.0.0.1:<临时端口>，端点: /token /users /messages")
    try {
        println("== 31.2 登录换令牌（无令牌访问受保护端点 401）==")
        val bare = ApiClient(port)
        try { bare.messagesSince(0) } catch (e: ApiException) { println("无令牌: HTTP ${e.status} ${e.body}") }
        val api = ApiClient(port)
        val token = api.login("ann", "pw-ann")
        println("登录成功: token=$token（此后每次请求自动带 Authorization 头——拦截器位置）")

        println("== 31.3 REST 增与查 ==")
        println("GET /users  -> ${api.users()}")
        println("POST /users -> ${api.addUser("cat")}")
        api.postMessage("第一条来自客户端的消息")
        println("POST /messages -> 4 号消息入库")

        println("== 31.4 校验与错误映射 ==")
        try { api.addUser("x") } catch (e: ApiException) { println("名字太短: HTTP ${e.status} ${e.body}") }
        try { api.addUser("ann") } catch (e: ApiException) { println("名字重复: HTTP ${e.status} ${e.body}") }
        try { bare.users(); check(false) } catch (e: ApiException) { println("用户列表也要令牌: HTTP ${e.status} ${e.body}") }
        println("AppError(status, code) 在全局映射器统一翻译——@ControllerAdvice 的零依赖形态")

        println("== 31.5 Flow 轮询与结构化取消 ==")
        var polls = 0
        val seen = mutableListOf<String>()
        runBlocking {
            pollFlow(api, from = 0, maxPolls = 10) { polls++ }
                .take(3)                       // 拿满 3 条就取消上游
                .collect { seen.add(it) }
        }
        println("take(3) 收到 ${seen.size} 条，上游实际只轮询 $polls 轮（第一轮就有 3 条，取消掐停了后续）")
        seen.forEach { println("  $it") }
        println("RxJava2 时代对照: 手工 CompositeDisposable + Activity 销毁记得 dispose；Flow 沿结构化并发自动传播")

        println("== 31.6 增量轮询（since 游标）==")
        val seen2 = mutableListOf<String>()
        runBlocking {
            pollFlow(api, from = 3, maxPolls = 3).collect { seen2.add(it) }
        }
        println("since=3 只拉新消息: ${seen2.size} 条 -> ${seen2.singleOrNull() ?: seen2}")
    } finally {
        server.stop()
        println("服务端已停止")
    }
}
