# 08 · 线程、Handler 与网络请求

> 对应示例：`examples/06_handler_looper.kt`、`examples/16_network_thread.kt`、`examples/15_json_parse.kt`

## 1. 主线程模型：UI 只有一个线程

第 05 章立过铁律：只有主线程能碰 UI。这一章解释为什么，以及怎么在它周围干活。

UI 状态（控件树、布局缓存、绘制管线）完全不设防——没有锁。假允许多线程改 UI，要么给每次 `setText` 上锁把界面变成锁竞争战场，要么接受随机损坏。Android（和 WPF 的 Dispatcher、iOS 的主线程一样）选了第三条路：**UI 归且只归一个线程**，其他线程想改，发消息排队。这个线程就是**主线程（main thread / UI 线程）**。

推论同样重要：主线程必须随时待命处理输入与绘制，所以它**不能做慢活**。两套清单把线程分工说死：

| 必须在主线程 | 必须离开主线程 |
|---|---|
| 改任何控件属性、增删视图 | 网络请求 |
| Toast、对话框、菜单 | 文件与 SharedPreferences 大块读写 |
| 列表通知刷新（等价于改 UI） | 数据库操作（第 09 章） |
| `startActivity` 页面跳转 | 大图解码、大 JSON 解析 |

主线程超时的下场是 ANR（Application Not Responding）——系统弹"应用无响应"对话框，把裁决权交给用户（多数用户选关闭）：

| 场景 | 超时阈值 |
|---|---|
| 主线程处理输入事件（触摸 / 按键） | 5 秒 |
| 前台 `BroadcastReceiver.onReceive` | 10 秒 |
| 前台 Service 生命周期方法 | 20 秒 |

网络是典型慢活——一次请求以百毫秒甚至秒计。所以线程与网络必须一起讲：**网络在后台线程做，结果回主线程显示**，本章全部内容就是这条流水线。

## 2. Looper 与 Handler：主线程的消息泵

主线程为什么能"待命"？因为它启动时就被装配成一个消息循环：

```text
任意线程                                主线程
────────                                ─────────────────────────────
handler.post(r)                         Looper.loop()（死循环）
handler.postDelayed(r, 1000L)             │
          │                               ▼
          └── enqueue ──▶ MessageQueue（按触发时间排序的队列）
                                          │
                                          ▼
                              取出消息：target 指回 Handler
                              在主线程执行 r / handleMessage(msg)
```

- **Looper**：一个线程的消息泵。普通线程没有 Looper；主线程特殊——App 进程启动时系统已替它 `prepare` 并 `loop()`。任何线程也能 `Looper.prepare()` + `Looper.loop()` 自建泵，但实际开发几乎不需要手写，知道即可
- **MessageQueue**：按触发时间排序的消息队列，无消息时线程在原生层阻塞休眠（不耗 CPU）
- **Handler**：双向工具——一端把消息/任务投进队列（任意线程调用都安全），另一端在其绑定的线程上执行它们。**Handler 绑定哪个 Looper，消息就在哪个线程被处理**

`examples/06_handler_looper.kt` 是这个机制的最小演示：

```kotlin
class Example06HandlerLooper : Activity() {
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply { text = "waiting..." }
        setContentView(tv)

        handler.postDelayed({
            tv.text = "updated by main looper"
        }, 1000L)
    }
}
```

两个要点：

1. `Handler(Looper.getMainLooper())`——拿主线程的 Looper 构造。这是推荐的构造写法（无参 `Handler()` 依赖"当前线程恰是主线程"，已废弃）
2. `postDelayed(lambda, 1000L)`——lambda 被包装成一条 Message（callback 字段），触发时间定为 now + 1000ms，入队主线程 MessageQueue；一秒后主线程 Looper 取出执行 `tv.text = ...`。`setText` 发生在主线程，所以合法

把 `postDelayed` 想成"一秒后请在主线程帮我跑这段代码"——它既是定时器，也是后台线程回主线程的通道（下一节）。

Handler 还有第二副面孔：send 系（投递消息对象而非代码块），走 `handleMessage` 回调：

```kotlin
val handler = object : Handler(Looper.getMainLooper()) {
    override fun handleMessage(msg: Message) {
        when (msg.what) {
            MSG_LOADED -> tv.text = msg.obj as String
        }
    }
}
// 后台线程发消息：
handler.obtainMessage(MSG_LOADED, "done").sendToTarget()
```

新代码记住 post 系就够（lambda 直接、无需定义消息常量）；send 系用于读懂存量代码——两者最终进的是同一个队列。

## 3. 回主线程三件套：post / runOnUiThread / View.post

后台线程做完活要上屏，有三条等价的路：

```kotlin
// 1) Handler：最通用，任何地方可用
Handler(Looper.getMainLooper()).post { tv.text = "done" }

// 2) Activity.runOnUiThread：写法最短，只活在 Activity 里
runOnUiThread { tv.text = "done" }

// 3) View.post：手里只有控件也能干
tv.post { tv.text = "done" }
```

| 方式 | 前提 | 细节 |
|---|---|---|
| `Handler.post` | 无（全局可用） | 最基础；持有 handler 字段要防泄漏（见第 7 节） |
| `runOnUiThread` | 在 Activity 内 | 当前已是主线程则**立即同步执行**，否则投递 |
| `View.post` | 拿得到任意 View | View 尚未 attach 到窗口时先排队，attach 后执行 |

三个语义上都是"往主线程队列投个任务"，选最顺手的即可。但注意它们只是"单步跳回去"——一旦流程变成"后台取数 → 解析 → 再取下一条 → 再上屏"，嵌套的 post 会层层叠叠套起来（回调地狱，第 6 节的协程治这个）。

## 4. 网络请求：HttpURLConnection 与后台线程

`examples/16_network_thread.kt` 是一个标准的后台网络请求骨架：

```kotlin
class Example16NetworkThread : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Thread {
            var connection: HttpURLConnection? = null
            try {
                connection = URL("https://example.com").openConnection() as HttpURLConnection
                connection.connectTimeout = 2000
                connection.readTimeout = 2000
                val code = connection.responseCode
                Log.d("Guide", "response=$code")
            } catch (e: IOException) {
                Log.e("Guide", "network error", e)
            } finally {
                connection?.disconnect()
            }
        }.start()
    }
}
```

逐段拆：

- `Thread { ... }.start()`——匿名线程干完即焚。它刻意**只打日志不碰 UI**：IO 的结果要上屏，得配第 3 节三件套（或第 6 节协程）
- `URL(...).openConnection() as HttpURLConnection`——JDK 标准路径，Android 完整支持
- `connectTimeout / readTimeout = 2000`——连接与读取各 2 秒拿不到就抛 `SocketTimeoutException`。**超时必设**：不设的默认值在弱网下能把一个线程挂几分钟。2 秒是教学的快速失败值，生产按场景放宽
- `responseCode`——读取它会真正发出请求（HttpURLConnection 惰性连接），返回 200/404 等状态码
- `finally { connection?.disconnect() }`——无论成败释放连接，这个姿势是模板的一部分，不是装饰

要读响应体时，标准姿势是 Kotlin 的 `use {}`（块结束自动关流）：

```kotlin
val body = connection.inputStream.bufferedReader().use { it.readText() }
```

两条硬约束：

**其一，网络必须在后台线程。** 主线程碰网络，Android 3.0 起直接抛 `NetworkOnMainThreadException` 崩给你看——比等到 ANR 友好多了，一犯即纠。

**其二，Manifest 必须声明 INTERNET 权限**（详见[第 02 章](02-project-toolchain.md)）：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

忘了它的症状是请求直接 `SocketException: Permission denied`。注意 INTERNET 属于安装期权限，装 App 时即授予，**不需要**运行时申请——和[第 11 章](11-permissions-content.md)的相机/定位那类运行时权限是两个世界。另：API 28 起默认禁止 `http://` 明文流量（示例因此用 https），要开明文得显式配 networkSecurityConfig——别开。

## 5. JSON：org.json 的用法

网络拿回来的通常是 JSON 文本。`examples/15_json_parse.kt` 用平台内置的 org.json 完成构建与读取：

```kotlin
class Example15JsonParse : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val text = try {
            val obj = JSONObject()
            obj.put("name", "android")
            obj.put("level", 1)
            obj.put("tags", JSONArray().put("mobile").put("native"))
            "${obj.getString("name")}:${obj.getJSONArray("tags").length()}"
        } catch (e: JSONException) {
            e.message ?: "json error"
        }
        setContentView(TextView(this).apply { this.text = text })
    }
}
```

- `JSONObject()` 建对象，`put(key, value)` 逐项塞；`JSONArray()` 建数组，`put(item)` 追加
- 读取用 `getString / getInt / getJSONArray` 等按类型取；`getJSONArray("tags").length()` 拿数组长度
- 解析非法 JSON 抛 `JSONException`，必须捕获——**远端数据永远不可信**，这是网络代码的默认心态

解析远端字符串是同一个构造器：`JSONObject(jsonText)` 把第 4 节拿到的响应体直接喂进去即可读。org.json 零依赖、够用，但纯字符串式取值没有类型保障；模型一多，生产标配是 kotlinx.serialization（`@Serializable` 数据类 + `Json.decodeFromString`，编译期生成解析代码）或 Moshi——这是生态事实，不是对 org.json 的否定。

## 6. 现代写法：协程把回调拉平

把第 3、4、5 节串起来，传统写法长这样——两层嵌套还算体面，三层开始失控：

```kotlin
Thread {
    val body = fetchBody()                       // 后台：网络
    handler.post {
        val obj = JSONObject(body)               // 回到主线程——可解析明明不必占主线程
        val name = obj.getString("name")
        tv.text = name                           // 想再发第二个请求？再包一层 Thread + post
    }
}.start()
```

协程（coroutine）版本，用 `withContext` 切线程、`suspend` 函数表达慢操作：

```kotlin
suspend fun loadName(): String = withContext(Dispatchers.IO) {
    val body = fetchBody()                  // 在 IO 线程池执行
    JSONObject(body).getString("name")      // 解析也在 IO，不占主线程
}

// 调用处（主线程；lifecycleScope 来自 androidx.lifecycle-runtime-ktx）：
lifecycleScope.launch {
    tv.text = loadName()                    // withContext 返回后自动恢复到主线程
}
```

读懂这段只需两个概念：

- `withContext(Dispatchers.IO)`：把块内代码调度到专为阻塞 IO 准备的线程池，**执行完自动切回原来的线程**（这里是主线程）——"切出去再回来"一行搞定，没有回调
- `suspend fun`：可挂起的函数。挂起时不占线程、不阻塞 UI，等结果就绪再继续

常用调度器就三档：

| 调度器 | 用途 |
|---|---|
| `Dispatchers.Main` | 主线程，UI 专属 |
| `Dispatchers.IO` | 网络与磁盘等阻塞 IO，线程数多 |
| `Dispatchers.Default` | CPU 密集（排序、解析大 JSON），核数级线程池 |

差别一目了然：Thread + Handler 版本的"执行顺序"被回调切碎在各层嵌套里；协程版本从上到下顺序读就是执行顺序。再叠加 `lifecycleScope` 的自动取消（页面销毁，协程跟着取消，不会更新已死的 UI），Thread + Handler 在这两点上都只能靠人肉纪律。

生态事实一句话：生产代码几乎不裸写请求——OkHttp 提供连接池、拦截器、HTTP/2，Retrofit 把 HTTP 接口直接声明成 Kotlin 接口并与协程无缝集成。它们解决"怎么发请求更省心"，线程模型仍是本章这一套：IO 走后台，结果回主线程。

## 7. 常见坑

**主线程网络**：`NetworkOnMainThreadException` 当场崩，没有商量。同理磁盘、数据库、解码大图都不属于主线程——反向应用第 05 章铁律：UI 线程不碰慢活。

**忘记关流 / 断开连接**：示例 16 的 `finally { connection?.disconnect() }` 少了它，异常路径上连接悄悄泄漏，弱网机器上很快耗尽资源；读响应体的 `InputStream` 同理要 close（`use {}` 一劳永逸）。标准姿势永远是 try-finally 包住资源。

**在 IO 线程碰 UI**：阴险在**不总是当场崩溃**——可能是界面不动、内容错乱或随机崩溃，因为 UI 状态无锁。后台拿到数据后，走三件套或协程回主线程再上屏，没有例外。

**Handler 内存泄漏**：排队中的 Message 持有 Handler/lambda，后者又持有 Activity——示例 06 让 Activity 销毁后最多多活 1 秒（延迟 1000ms）；换成 60 秒的轮询，销毁的 Activity 会被消息攥在手里整分钟无法回收。修法：`onDestroy` 里 `handler.removeCallbacksAndMessages(null)` 清空队列，或直接用 `lifecycleScope` 协程（生命周期自动取消）。

**忽略结果的有效期**：后台请求返回时页面可能已经销毁（用户早退出了），此时更新控件落在死对象上。传统写法要在回调里判 `isDestroyed`；协程配 `lifecycleScope` 则天然免疫——作用域结束，续体不再执行。

## 8. 实战建议

- 主线程只做 UI：网络、磁盘、数据库、大图解码一律后台，规则简单到不需要权衡
- 新代码协程起步：`lifecycleScope.launch` + `withContext(Dispatchers.IO)`，回调地狱从根上消失；Thread/Handler 的知识用来读懂海量存量代码
- 超时必设、`IOException` 必捕、资源必关——示例 16 的 try-catch-finally 骨架直接抄进生产
- 网络库选 OkHttp/Retrofit，JSON 选 kotlinx.serialization；裸写 HttpURLConnection 的价值是让你看懂封装之下发生了什么
- UI 更新收敛到一个入口：后台逻辑只负责把数据交回主线程，改界面的代码集中一处，散落各处的 post 是维护噩梦的起点

---
上一章：[07 列表与 Adapter 模式](07-lists-adapters.md) ｜ 下一章：[09 本地数据持久化](09-data-storage.md)
