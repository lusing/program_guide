# 31 · ⭐HTTP 实战：零依赖 REST 服务端与客户端

> 对应示例：`examples/31_http/`（四个源文件：`Model.kt` + `Server.kt` + `Client.kt` + `Main.kt`）
>
> JDK 自带 HttpServer 造 REST 服务端（路由/VO/校验/全局错误映射/Bearer 认证）、
> java.net.http.HttpClient 做类型化客户端、Flow 轮询与结构化取消——
> RxJava2 手工 dispose 的时代对照，以及 MockMvc 式端到端测试的零依赖形态。

## 31.1 为什么零依赖

Spring Boot/Ktor 把本章每一步都自动化了，但"框架之下是什么"正是参考书 Messenger 后端（Spring Boot 2.0）教的分层思想本身：**路由 → 校验 → 业务 → 仓储 → 错误映射**。JDK 从 6 起自带 `com.sun.net.httpserver.HttpServer`、11 起自带 `java.net.http.HttpClient`——零外部依赖把整条链走一遍，之后用任何框架都知道它在替你做什么。

## 31.2 MiniJson：编码器 + 平坦解析器

30 行够了（完整的递归下降解析器见 24 章 ktodo）。编码走类型分派，解析只承诺**平坦对象**（字符串/整数/布尔/null，不嵌套）：

```kotlin
object MiniJson {
    fun encode(v: Any?): String = when (v) {
        null -> "null"
        is String -> "\"" + v.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
        is Boolean, is Number -> v.toString()
        is Map<*, *> -> v.entries.joinToString(",", "{", "}") { encode(it.key) + ":" + encode(it.value) }
        is Iterable<*> -> v.joinToString(",", "[", "]") { encode(it) }
        else -> encode(v.toString())
    }
    fun parseFlat(json: String): Map<String, Any?> = ...    // 按下标扫描
    fun parseList(json: String): List<Map<String, Any?>> = ...   // 平坦对象的数组
}
```

教学取舍：字符串内的转义引号不还原、不支持嵌套——**写清楚边界**比假装完整诚实。

## 31.3 REST 服务端：路由 / 仓储 / VO / 校验

一个上下文 + 手工路由表（方法 + 路径精确匹配），仓储是内存列表，响应统一 JSON：

```kotlin
// 领域模型与仓储
data class User(val id: Long, val name: String)
data class Message(val id: Long, val from: String, val text: String)

// 端点一览（本示例）
// POST /token {"user","pass"}          -> {"token":"tok-ann"} / 401
// GET  /users                          -> {"users":[...]}
// POST /users {"name"}                 -> {"id":..,"name":..} / 400(校验)
// GET  /messages?since=N  [Bearer]     -> [{"id":..,"from":..,"text":..}, ...]
// POST /messages {"text"}  [Bearer]    -> {"id":..,"from":..}
```

**VO（视图对象）思想**：响应里只放该放出去的字段——`User` 内部以后加了密码散列列，`toVo()` 映射天然挡住泄漏（参考书用 data class VO 防 JPA 实体外泄，同一招）。校验放仓储入口：

```kotlin
fun addUser(name: String): User {
    if (name.length < 2) throw AppError(400, "name too short")
    ...
}
```

## 31.4 认证：Bearer 令牌 + 客户端"拦截器"

`POST /token` 换令牌，受保护端点检查 `Authorization: Bearer <tok>`，没有就 401。客户端把"每次请求自动带头"封装进 `call()`——这就是 OkHttp Interceptor / Retrofit 的骨架思想（参考书第 5 章的 Bearer 拦截器）：

```kotlin
private fun call(method: String, path: String, body: String? = null): String {
    val b = HttpRequest.newBuilder(URI.create("http://127.0.0.1:$port$path"))
    token?.let { b.header("Authorization", "Bearer $it") }     // ← 拦截器位置
    ...
    if (resp.statusCode() !in 200..299) throw ApiException(resp.statusCode(), resp.body())
}
```

客户端方法是**类型化**的薄壳（`users()/addUser(name)/messages(since)`）——参考书 Retrofit 的"声明式接口"在无反射版的实现形态。

## 31.5 全局错误映射

Handler 外层一个 try/catch 兜底，业务码只管抛 `AppError(status, code)`：

```kotlin
try { route(exchange) }
catch (e: AppError) { send(exchange, e.status, MiniJson.encode(mapOf("error" to e.code))) }
catch (e: Exception) { send(exchange, 500, MiniJson.encode(mapOf("error" to "internal"))) }
finally { exchange.close() }
```

对应 Spring 的 `@ControllerAdvice` + `@ExceptionHandler`——异常翻译成状态码的**那张表**才是核心，注解只是它的注册语法（27 章）。

## 31.6 Flow 轮询与结构化取消

客户端拉新消息是冷流：`flow { }` 里发请求、逐条 `emit`，收集几次、何时取消全部由**消费端**决定：

```kotlin
fun pollFlow(api: ApiClient, from: Int, maxPolls: Int, onPoll: () -> Unit = {}): Flow<String> = flow {
    var since = from
    repeat(maxPolls) {
        onPoll()
        for (m in api.messagesSince(since)) { emit("${m["from"]}: ${m["text"]}"); since = (m["id"] as Long).toInt() }
    }
}

var polls = 0
runBlocking {
    pollFlow(api, from = 0, maxPolls = 10) { polls++ }   // 最多愿意轮询 10 次
        .take(3)                                          // 拿满 3 条就取消
        .collect { ... }
}
// polls == 1：第一轮就有 3 条，take(3) 触发的取消把上游轮询直接掐停
```

这就是对参考书 RxJava2 时代的最好回应：那本书第 19 章要手工建 `CompositeDisposable`、在 Activity 销毁里记得 `dispose()`（忘了就泄漏）；Flow 的取消顺着结构化并发自动传播（14 章）——**同一个问题，两代答案**。

## 31.7 端到端测试：MockMvc 思想零依赖化

测试里起真服务（`port=0` 让系统分配临时端口）、发真请求、断言响应体——参考书用 MockMvc + Hamcrest，我们用 `kotlin.test` 断言同样的东西：

```kotlin
val server = RestServer(Repo()); val port = server.start()
try {
    val api = ApiClient(port)
    api.login("ann", "pw-ann")
    assertContains(api.users(), "ann")
    val e = assertFailsWith<ApiException> { ApiClient(port).messagesSince(0) }
    assertEquals(401, e.status)
} finally { server.stop() }
```

## 本章坑位

- `HttpServer.create(..., 0)` 的 0 是 backlog 不是端口；端口 0 要在 `server.address.port` 读
- handler 结束必须 `exchange.close()`（放 finally），否则客户端挂到超时
- 端口号/线程名/时间戳都别进快照——测试用临时端口，输出只谈"已启动"
- `HttpRequest.method("POST", noBody())` 与 `POST().build()` 不等价，统一走一处封装
- 轮询流要给 `maxPolls` 上限：没有取消时别让 `flow { while(true) }` 无限跑
