# 17 · 网络与并发：URLSession / async-await / TaskGroup / actor

> 示例：`examples/17_networking_concurrency/main.swift`
> 实测输出见 `build/17_networking_concurrency/stdout.debug.txt`

网络请求天生是异步的。iOS 早期用 completion handler（回调地狱），现代 iOS 用
**Swift 并发**（`async`/`await`、`actor`、结构化并发）——它把异步代码写得像同步一样
顺，还能在编译期消灭一大类 data race。

本章讲三件事，且**完全不依赖外网**：并发（`async`/`await`、`TaskGroup`、`actor`、`@MainActor`）、
**网络缓存**（`URLCache` 这个仓库和 `requestCachePolicy` 这六条规则各自怎么工作——它们是两条独立的
通路，混在一起想必然想不清），以及 **`WKWebView`**（UIKit 世界里唯一活在另一个进程里的控件，
JS↔Swift 每一次传值都是一次跨进程序列化）。缓存的读取用 `127.0.0.1:1` 这个必然拒绝连接的保留端口
来把「有没有打网络」变成一个确定的错误码；`WKWebView` 则用一个**必须在任何 `await` 之前建好**的实例
——为什么必须这样，见本章的「诚实边界」。

## 离线怎么测网络：自定义 URLProtocol

真实网络不确定（延迟、失败、内容变），无法做逐字节断言。本教程的办法：注册一个
**自定义 `URLProtocol`** 拦截所有请求，返回**写死**的响应。于是「发请求 → 拿数据 →
解码」这条真实 `URLSession` 全链路能离线、确定地跑：

```swift
final class StubProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }   // 拦截一切
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let path = request.url?.path ?? "/"
        let (status, body): (Int, String) = path == "/notfound"
            ? (404, #"{"error":"missing"}"#)
            : (200, #"{"ok":true,"items":[1,2,3]}"#)
        let resp = HTTPURLResponse(url: request.url!, statusCode: status,
                                   httpVersion: "HTTP/1.1",
                                   headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [StubProtocol.self]     // 关键：让 stub 接管所有请求
let session = URLSession(configuration: config)
```

`URLProtocol` 是 `URLSession` 的可插拔传输层。生产里你也能用它做缓存、Mock、抓包。
测试时把它换成 stub，就得到一个**确定**的网络。

## 1) URL / URLComponents：别手拼字符串

拼 URL 用 `URLComponents`，它负责百分号编码：

```swift
var comps = URLComponents()
comps.scheme = "https"; comps.host = "api.example.com"; comps.path = "/search"
comps.queryItems = [
    URLQueryItem(name: "q", value: "swift ios"),   // 含空格
    URLQueryItem(name: "page", value: "2"),
]
comps.url!.absoluteString
// https://api.example.com/search?q=swift%20ios&page=2
```

```
-- URL / URLComponents：拼查询参数 --
  拼出的 URL = https://api.example.com/search?q=swift%20ios&page=2
  ok   URLComponents 自动百分号编码空格，拼出规范 URL
  ok   两个查询参数
```

空格自动变成 `%20`。**永远别用字符串拼 URL**——漏编码特殊字符是经典 bug（也是注入风险）。

## 2) URLRequest：方法 / 头 / body

```swift
var req = URLRequest(url: url)
req.httpMethod = "POST"
req.setValue("application/json", forHTTPHeaderField: "Content-Type")
req.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
req.httpBody = #"{"k":1}"#.data(using: .utf8)
```

```
-- URLRequest：配置请求 --
  ok   httpMethod 设为 POST
  ok   自定义请求头可读回
  ok   Authorization 头已设置
  ok   httpBody 已附带
```

## 3) async/await + URLSession：像同步一样写异步

`URLSession.data(for:)` 是 `async` 的。配上 `Codable` 解码，一个网络层函数长这样：

```swift
enum ApiError: Error { case badStatus(Int) }

func fetchPayload(from url: URL, session: URLSession) async throws -> Payload {
    let (data, resp) = try await session.data(for: URLRequest(url: url))
    guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        throw ApiError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1)
    }
    return try JSONDecoder().decode(Payload.self, from: data)
}
```

```
-- async/await：发请求 → 解码 --
  解码结果 = ok:true items:[1, 2, 3]
  ok   URLSession 全链路：拿到 stub 响应并 Codable 解码成功
```

`await` 处会**挂起**当前任务、让出线程，等网络回来再从这行继续。没有回调嵌套，
错误用 `try`/`throw` 统一处理——这就是 async/await 相对 completion handler 的巨大改善。

## 4) 错误处理：非 2xx 要自己判

> **重要**：`URLSession` 只在**传输层**失败（无网络、DNS、超时）时 throw。HTTP 的
> `404`/`500` 在它看来是「请求成功了，服务器这么答的」，**不 throw**。你必须自己检查
> `statusCode`。

```swift
do {
    _ = try await fetchPayload(from: notFoundURL, session: session)
} catch ApiError.badStatus(let code) {
    // code == 404
}
```

```
-- 错误处理：404 被翻译成 Swift 错误 --
  捕获到 badStatus(404)
  ok   非 2xx 响应被网络层判成 ApiError.badStatus(404)
```

## 5) 顺序 await vs async let：并发

- **顺序**：`let a = await f(); let b = await g()` —— `f` 完再 `g`，耗时相加。
- **并发**：`async let a = f(); async let b = g(); … await a + b` —— `f`、`g` 同时跑。

```swift
let s1 = await delayed(1); let s2 = await delayed(2)        // 顺序，~40ms
async let c1 = delayed(10); async let c2 = delayed(20)       // 并发，~20ms
let concSum = await c1 + c2
```

```
-- 顺序 await vs async let：并发 --
  ok   顺序 await 拿到两个结果
  ok   async let 并发执行，结果相加为 30
  并发耗时 < 顺序耗时 : true
  ok   async let 并发比顺序 await 更快（性质，不依赖具体毫秒）
```

注意断言只判**性质**（`concElapsed < seqElapsed`），不打印具体毫秒——具体耗时是环境
相关的，本教程一律不断言。`async let` 的取值处才写 `await`（`await c1`），声明处不写。

## 6) withTaskGroup：动态数量的并发

`async let` 适合**固定个数**的并发。个数由数据决定时，用 `withTaskGroup`：

```swift
let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
    for i in 1...5 { group.addTask { await delayed(i) } }
    var collected: [Int] = []
    for await r in group { collected.append(r) }     // 谁先完成先收谁
    return collected.sorted()
}
```

```
-- withTaskGroup：把一批任务并发跑完 --
  TaskGroup 收集到 = [1, 2, 3, 4, 5]
  ok   5 个子任务全部完成并收集齐（完成顺序不定，排序后确定）
```

`for await r in group` 按**完成顺序**产出结果（不是添加顺序），所以示例里 `sorted()`
后再断言——完成顺序是不确定的，排序后才是确定值。这正是「只断言性质、把不确定的
顺序归一化」的做法。

## 7) actor：编译期消灭 data race

多个任务同时改一个 `class` 的可变属性 = **data race**（未定义行为，可能丢更新、可能崩）。
`actor` 把可变状态**串行化**：同一时刻只有一个任务能进入 actor 执行，访问它的隔离状态
必须 `await`：

```swift
actor Counter {
    private var n = 0
    func increment() { n += 1 }
    func value() -> Int { n }
}
let counter = Counter()
await withTaskGroup(of: Void.self) { group in
    for _ in 0..<100 { group.addTask { await counter.increment() } }
}
let finalCount = await counter.value()      // 100
```

```
-- actor：并发安全的状态 --
  100 个并发 increment 后 = 100
  ok   actor 串行化访问：100 个并发自增无一丢失（普通 class 会 data race）
```

100 个并发 `increment`，最终正好 100，一个不丢。换成普通 `class`，这个结果会**小于**
100（并发的 `n += 1` 互相覆盖）。actor 让「并发安全」变成编译器帮你保证的事，而不是
你手动加锁。

## 8) @MainActor：UI 更新钉在主线程

所有 UIKit / SwiftUI 的界面更新都必须在**主线程**。`@MainActor` 是一个特殊的 actor，
标在类型或方法上，保证它的代码在主线程执行：

```swift
@MainActor
final class UIState {
    var text = ""
    var ranOnMain = false
    func update(_ s: String) {
        text = s
        ranOnMain = Thread.isMainThread      // @MainActor 保证 true
    }
}
let ui = UIState()
ui.update("已加载")
```

```
-- @MainActor：UI 更新回到主线程 --
  ok   @MainActor 方法更新了状态
  ok   @MainActor 保证在主线程执行（UI 更新安全）
```

> **关键事实**：`main.swift` 的**顶层代码本身就是 `@MainActor` 隔离的**。所以上面调用
> `@MainActor` 的 `ui.update(...)` **不需要 `await`**（同一 actor，同步调用）。这也解释了
> 为什么 SwiftUI 的 `body`、UIKit 的各种回调天然在主线程——它们都在主 actor 上。
> 从**别的** actor 调 `@MainActor` 方法时才需要 `await`（跨 actor 边界，会跳到主线程）。

网络请求的典型模式：在后台 actor 上拉数据、解码，最后 `await MainActor.run { … }` 或调
`@MainActor` 方法把结果交给 UI。Swift 并发让这个「后台算、主线程更新」的模式写得非常干净。

## 9) URLCache：容量、六个缓存策略、三种 session 配置的出厂值

「有没有缓存」在 iOS 里其实是**两个东西**叠在一起，把它们分开是这一节的全部目的：

- **`URLCache`** 是一个**仓库**：内存一段 + 磁盘一段，键是 canonical request，值是 `CachedURLResponse`。
- **`requestCachePolicy`** 是一次加载的**取用规则**：允不允许打网络、允不允许吃旧的。

仓库和规则各有各的出厂值，先把它们量出来：

```swift
let sharedCache = URLCache.shared                       // 进程级单例
let ownCache = URLCache(memoryCapacity: 100_000, diskCapacity: 200_000, diskPath: nil)
let dcfg = URLSessionConfiguration.default
let efc  = URLSessionConfiguration.ephemeral
let bgc  = URLSessionConfiguration.background(withIdentifier: "…")
```

```
-- URLCache：容量、六个缓存策略、三种 session 配置的出厂值 --
  两次取 URLCache.shared 是同一个对象=true
  共享缓存出厂 memoryCapacity=512000 diskCapacity=10000000
  自建实例 memoryCapacity=100000 diskCapacity=200000 与共享同一个对象=false
  ok   自建 URLCache 的容量就是你给的那两个数
  ok   URLCache.shared 是进程级单例——session 不写 urlCache 时用的就是它
  共享缓存那两个「当前占用」读得到，但值随这台模拟器之前跑过什么变——所以本示例只在**自建**实例上断言占用，不在共享实例上断言
  六个 requestCachePolicy 的 raw 值：useProtocolCachePolicy=0 reloadIgnoringLocalCacheData=1 returnCacheDataElseLoad=2 returnCacheDataDontLoad=3 reloadIgnoringLocalAndRemoteCacheData=4 reloadRevalidatingCacheData=5
  URLRequest() 出厂 cachePolicy=0（就是 useProtocolCachePolicy）
  ok   URLRequest 不改策略时默认就是「按协议说的办」
  三参数构造之后 cachePolicy=3 timeoutInterval=5.0
  default 配置：requestCachePolicy=0 urlCache 就是共享那个=true timeoutForRequest=60.0 timeoutForResource=604800.0 内存/磁盘容量=512000/10000000
  default 配置：httpShouldUsePipelining=false shouldUseExtendedBackgroundIdleMode=false httpShouldSetCookies=true cookieAcceptPolicy raw=2
  ok   default 配置出厂就带 512000/10000000 那个共享缓存，策略是 useProtocol
  ephemeral 配置：urlCache 有值=true 与共享同一个对象=false 内存容量=512000 cookieStorage 有值=true
  background 配置：urlCache 有值=false sessionSendsLaunchEvents=true requestCachePolicy=0
  ok   background 配置出厂 urlCache=nil：后台会话的缓存归那个独立的后台 daemon 管，不归你手里的 URLCache
  缓存存放位置三档 URLCache.StoragePolicy：allowed=0 allowedInMemoryOnly=1 notAllowed=2
```

逐条读：

- **共享缓存的出厂容量是写死的 512000 / 10000000**（内存 512 KB、磁盘 10 MB）。很多人以为
  `URLCache.shared` 是「系统给的一个大缓存」，其实它内存段就 512 KB——一张稍大的图片就把它挤出去了。
- **`URLCache.shared === URLCache.shared` 是同一个对象**，而 `URLSessionConfiguration.default` 出厂就
  拿着它（上面那行 `urlCache 就是共享那个=true`）。于是「你在某个 `default` 配置上改 `urlCache`」
  这件事影响的范围比你想的大：每一个新取的 `default` 出厂都指向同一个实例。
- **`ephemeral` 的 `urlCache` 并不是 `nil`**：它自带一个实例（`内存容量=512000`），只是不落你这台设备的
  磁盘缓存目录。想真正关掉缓存要显式写 `cfg.urlCache = nil`——本示例第 3~8 节那个 session 就是这么关的。
- **`background` 配置的 `urlCache` 出厂才是 `nil`**：后台会话由系统那个独立的 daemon 进程跑，缓存归它管，
  你手里的 `URLCache` 对象碰不到它。
- **六个 `requestCachePolicy` 的 raw 值是 0..5，但排布反直觉**：两个「reload」是 1 和 4，
  两个「只吃缓存的变体」是 2 和 3，`reloadRevalidatingCacheData` 那个最冷门的占 5。把它们配成对来记
  才不容易写错；靠数字大小猜语义一定猜错。
- `URLRequest(url:)` 单参构造出厂 `cachePolicy=0`（就是 `useProtocolCachePolicy`）；要改策略得用三参构造。
- 「存不存」另有三档：`URLCache.StoragePolicy` 的 `allowed=0` / `allowedInMemoryOnly=1` / `notAllowed=2`。
  Swift 里只能写 `notAllowed`——那个老名字 `forbidden` 在头文件里已被标成 unavailable。

> `currentMemoryUsage` / `currentDiskUsage` 在**共享**实例上是环境相关的（这台模拟器之前跑过什么都会留
> 痕迹），所以本示例只在自建实例上断言占用数字，共享实例只读不断言。

## 10) 缓存的写入侧：谁决定这条响应进不进 URLCache

写入这一侧的开关**不在响应头里**，在 `URLProtocol` 交给 loading system 的那个参数上：

```swift
client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: CacheStub.storagePolicy)
//                                          ^ 就是这个参数；Foundation 不看 resp 里写了什么头
```

本示例把 `cacheStoragePolicy` 和响应头都做成可配的 `CacheStub`，跑五格：

```
-- 缓存的写入侧：谁决定这条响应进不进 URLCache --
  协议传 .allowed：拿到=net1 stub 被调=1 存完 URLCache 查得到=true 内存占用=4 磁盘占用=0
  协议传 .allowedInMemoryOnly：拿到=net1 stub 被调=1 存完 URLCache 查得到=true 内存占用=4 磁盘占用=0
  协议传 .notAllowed：拿到=net1 stub 被调=1 存完 URLCache 查得到=false 内存占用=0 磁盘占用=0
  协议传 .allowed + 响应头 no-store：拿到=net1 stub 被调=1 存完 URLCache 查得到=true 内存占用=4 磁盘占用=0
  协议传 .allowed + 响应头 max-age=600：拿到=net1 stub 被调=1 存完 URLCache 查得到=true 内存占用=4 磁盘占用=0
  ok   三档 StoragePolicy 里只有 notAllowed 真的不落缓存
  ok   响应头写 no-store 也照样存了：这条路上没人解析 Cache-Control，能不能存全由协议传的那个参数说了算
  ok   allowed 与 allowedInMemoryOnly 在「查得到」这件事上没区别（区别在落不落磁盘，小对象本来就留在内存）
  同一段 body「net1」= 4 字节，上面报的内存占用正是 4——它数的是 CachedURLResponse 的 data 长度
```

三个必须记住的结论：

1. **只有 `notAllowed` 真的不落缓存**。`allowed` 和 `allowedInMemoryOnly` 在这里都「查得到」，区别只在
   会不会写磁盘——一个 4 字节的小对象本来就留在内存段里，两档的磁盘占用都是 0。
2. **响应头 `Cache-Control: no-store` 完全不影响写入**。解析 HTTP 缓存语义的是**内置的 HTTP 协议实现**；
   你的 stub 造出来的响应，Foundation 只认你亲手传的那个 `cacheStoragePolicy`。这条对写 mock 特别重要：
   在 stub 路径上 `no-store` 是个装饰。
3. **`currentMemoryUsage` 数的是 `CachedURLResponse.data` 的字节数**（body 是 `net1` 就是 4），不含响应头
   ——别拿它当「缓存占了多少空间」的度量。

## 11) 缓存的读取侧：六个策略的实测矩阵

读取这一侧才决定缓存到底省不省流量。要离线、确定地测它，难点是「怎么证明这次到底有没有打网络」。
本示例的技巧是**把目标地址指向 `http://127.0.0.1:1`**：1 号是保留端口，模拟器里不会有任何服务监听它，
于是「打了网络」被翻译成一个固定错误码 `-1004`（`cannotConnectToHost`），全程不出机器。

```swift
let probeURL = URL(string: "http://127.0.0.1:1/probe")!
func readProbe(_ policy: URLRequest.CachePolicy, seeded: Bool, fresh: Bool) async -> String {
    let c = URLCache(memoryCapacity: 100_000, diskCapacity: 200_000, diskPath: nil)
    if seeded {                                  // 先手动往仓库里塞一条
        var h = ["Content-Type": "text/plain"]
        if fresh { h["Cache-Control"] = "max-age=600" }   // 塞不塞新鲜度，就是矩阵的两个轴
        …
        c.storeCachedResponse(CachedURLResponse(response: r, data: Data(body.utf8),
                                                userInfo: nil, storagePolicy: .allowed),
                              for: URLRequest(url: probeURL))
    }
    let cfg = URLSessionConfiguration.default
    cfg.urlCache = c
    cfg.requestCachePolicy = policy
    …
}
```

```
-- 缓存的读取侧：requestCachePolicy 六格矩阵（目标 127.0.0.1:1，离线且确定）--
  A useProtocolCachePolicy + 缓存里有一条 max-age=600 的：吃到缓存 12 字节 内容=cached-fresh 状态码=200
  B useProtocolCachePolicy + 缓存里那条没有任何新鲜度头：打网络（必然失败）domain=NSURLErrorDomain code=-1004
  C useProtocolCachePolicy + 缓存是空的：打网络（必然失败）domain=NSURLErrorDomain code=-1004
  D returnCacheDataDontLoad + 有缓存：吃到缓存 12 字节 内容=cached-fresh 状态码=200
  E returnCacheDataDontLoad + 没缓存：打网络（必然失败）domain=NSURLErrorDomain code=-1008
  F returnCacheDataElseLoad + 有缓存但不新鲜：吃到缓存 14 字节 内容=cached-nofresh 状态码=200
  G reloadIgnoringLocalCacheData + 有缓存且新鲜：打网络（必然失败）domain=NSURLErrorDomain code=-1004
  H reloadIgnoringLocalAndRemoteCacheData + 有缓存且新鲜：打网络（必然失败）domain=NSURLErrorDomain code=-1004
  I reloadRevalidatingCacheData + 有缓存且新鲜：打网络（必然失败）domain=NSURLErrorDomain code=-1004
  ok   A 吃到缓存、B/C 打网络：只有响应自己声明了新鲜度，useProtocolCachePolicy 才真的免掉一次网络
  ok   dontLoad 有缓存就给你、没缓存报 -1008 resourceUnavailable（不是文档常被引用的那个 -2000 cannotLoadFromNetwork）
  ok   elseLoad 连过期都照给：它「只要有缓存就不打网络」，不看新鲜度
  ok   三个 reload 全都必打网络，哪怕缓存里那条还新鲜
  相关错误码：cannotConnectToHost=-1004 resourceUnavailable=-1008 cannotLoadFromNetwork=-2000 cannotFindHost=-1003 cannotOpenFile=-3001
  第十节那个 stub 场景为什么第二次仍打网络：注册自定义 URLProtocol 等于把内置 HTTP 协议栈整个换掉，
  而「查缓存」这一步正是内置协议栈做的——写入还在（第 10 节证明了），读取没了。
  同一 URL 连打两次（策略 useProtocol、响应 max-age=600、缓存实例是自己 new 的）：
    第一次=net1 第二次=net2 stub 累计被调=2 而缓存里查得到=true
  ok   写了却没读：stub 顶掉内置协议栈之后，连 max-age=600 的响应也会每次重跑——这是 mock 层最常见的「缓存行为测不到」
```

这张矩阵就是「网络缓存策略」四个字的全部真相：

| 格子 | 策略 | 仓库里有什么 | 结果 | 说明 |
| --- | --- | --- | --- | --- |
| A | `useProtocolCachePolicy` | 有 `max-age=600` | **吃到缓存** | 九格里唯一真的省掉一次网络的一格 |
| B | `useProtocolCachePolicy` | 有，但没有任何新鲜度头 | 打网络 `-1004` | 手动塞进去的条目没有 `Cache-Control`/`Expires` 就**视为已过期** |
| C | `useProtocolCachePolicy` | 空 | 打网络 `-1004` | 正常 |
| D | `returnCacheDataDontLoad` | 有 | 吃到缓存 | 「只准吃缓存」 |
| E | `returnCacheDataDontLoad` | 空 | `-1008 resourceUnavailable` | 见下面的错误码更正 |
| F | `returnCacheDataElseLoad` | 有，但不新鲜 | 吃到缓存 | **不看新鲜度**，有就给 |
| G | `reloadIgnoringLocalCacheData` | 有且新鲜 | 打网络 `-1004` | 无视本地缓存 |
| H | `reloadIgnoringLocalAndRemoteCacheData` | 有且新鲜 | 打网络 `-1004` | 连中间代理的缓存也要绕 |
| I | `reloadRevalidatingCacheData` | 有且新鲜 | 打网络 `-1004` | 语义就是「先跟服务器校验」，当然要打网络 |

- **`useProtocolCachePolicy` 只在响应自己声明了新鲜度时才免掉网络**（A vs B 的差别就一个响应头）。
  这解释了一件常见困惑：「我明明设了 `urlCache`，怎么还是每次都重新下载」——因为服务端没给
  `Cache-Control`/`Expires`/`Last-Modified`，条目一进仓库就算过期。
- **`returnCacheDataDontLoad` 查不到缓存时给的是 `-1008`（`resourceUnavailable`），不是很多地方写的
  `-2000 cannotLoadFromNetwork`**。上面那行错误码表里两个数都在，差了一个数量级。这是**实测更正**：
  写「有缓存就用、没有就告诉用户离线」的兜底逻辑时，判 `-1008`，或者干脆只判
  `(error as NSError).domain == "NSURLErrorDomain"` 再走兜底分支。
- **`elseLoad` 与 `useProtocol` 的分工**：前者是「别打网络，过期也给我」，后者是「过期就算了，去网上拿」。
  下拉刷新想「先立刻显示旧内容、再后台更新」就是 `elseLoad` + 一次 `reloadIgnoringLocalCacheData` 的组合。
- **自定义 `URLProtocol` 会把缓存的「读」这条路一起顶掉**。上面最后四行是直接证据：策略是默认的
  `useProtocolCachePolicy`、响应带着 `max-age=600`、缓存实例是自己 new 的、第一次加载也确实写进去了
  （`缓存里查得到=true`）——可第二次加载仍然进了 stub（`stub 累计被调=2`，body 从 `net1` 变成 `net2`）。
  原因是**「先查缓存」这一步由内置 HTTP 协议实现做**；你注册 `protocolClasses` 等于把整个内置实现换成
  自己的，于是写入还在（那是协议自己传的参数），读取没了。想在 mock 环境下测缓存行为，要么放行真实
  协议，要么在自己的 stub 里实现读取分支——这是 mock 层最常见的一个「测不到」。

## 12) WKWebView：UIWebView 的现代替代

`UIWebView` 早就废弃了（App Store 也会拒带它的包），今天只剩 `WKWebView`。它和 `UIWebView` 的根本区别是
**它活在另一个进程里**（`com.apple.WebKit.WebContent`），于是 JS 与 Swift 之间每一次传值都是一次跨进程
序列化——能不能传、传不过来时报什么，只有真跑一遍才知道。

```
-- WKWebView：接着用预备阶段那个实例（新实例在 await 之后起不动）--
  出厂配置：allowsInlineMediaPlayback=false javaScriptCanOpenWindowsAutomatically=false defaultWebpagePreferences.allowsContentJavaScript=true
  预备阶段那次加载留下的状态：title=预热页 isLoading=false estimatedProgress=1.0 canGoBack=false canGoForward=false
  第二次 loadHTMLString：到齐=true didStart 累计=2 didFinish 累计=2 didFail 累计=0
  标题同步到 warmView.title=true 值=页面标题
  JS 发了 6 条 postMessage，Swift 侧收到 5 条（等满=true）：bridge/__NSCFNumber bridge/__NSCFString second/__NSArrayI bridge/__NSFrozenDictionaryM bridge/Optional<AnyObject>
  ok   headless 进程里 WKWebView 真跑完了第二次导航：didStart→didFinish，没有 didFail
  ok   6 条 postMessage 只有 5 条到：JS 的 function 对象没法跨进程序列化，被**静默丢掉**（不报错、也不回调）
  ok   undefined 那条真的到了，但 m.body 是 nil——按 Any 强解包就是崩
  反向（Swift→JS）：值=Optional(2)
  读 DOM：值=Optional(1)
  读 document.title：值=Optional(页面标题)
  引用不存在的变量：值=nil 错误=WKErrorDomain#4
  返回 Symbol（Swift 侧收不了的类型）：值=nil 错误=WKErrorDomain#5
  返回 Promise：值=nil 错误=WKErrorDomain#5
  WKError 码表：javaScriptExceptionOccurred=4 javaScriptResultTypeIsUnsupported=5 webContentProcessTerminated=2
  注入脚本之前 userScripts 数=0；加一条之后=1 injectionTime raw=0（0=atDocumentStart 1=atDocumentEnd）forMainFrameOnly=true
  同一个实例再加载一次（这次带着注入脚本）：值=Optional(7)
  removeScriptMessageHandler 摘掉两个名字之后，userScripts 数还是=1（消息通道与注入脚本是两本账）
  数据仓：WKWebsiteDataStore.default() 类型=WKWebsiteDataStore nonPersistent 类型=WKWebsiteDataStore
  它能清的数据种类共 14 种，含 LocalStorage、Cookies、MemoryCache
  ok   WKWebView 的存储是「按种类清理」的模型：LocalStorage/Cookie/缓存各自一个类型名，removeData(ofTypes:) 决定清哪些
```

这一节里值得抄进笔记的六件事：

- **不需要窗口**：`loadHTMLString` → `didStartProvisionalNavigation` → `didFinishNavigation` 在 headless
  进程里全程跑通，`wv.title` 也会同步过来（它比 `didFinish` **晚一拍**，所以示例用有界抽送等到它，
  而不是在 `didFinish` 里当场读）。
- **JS→Swift 走 `window.webkit.messageHandlers.<名字>.postMessage(...)`**，Swift 侧是
  `WKUserContentController.add(_:name:)` + `WKScriptMessageHandler`。名字是字符串，一个 controller 可以
  注册多个名字，所以 `m.name` 要拿来分派。
- **`function` 传不过去，而且是静默丢**：JS 里连着发 6 条，Swift 只收到 5 条，**没有回调、也没有报错**。
- **`undefined` 会到，但 `m.body` 是 `nil`**（上面那行末尾的 `bridge/Optional<AnyObject>`）。按 `Any`
  强解包就是崩，所以 handler 的第一件事是 `guard let body = m.body else { return }`。
- **Swift→JS 用 `evaluateJavaScript(_:completionHandler:)`**（这个 API 有个 `async` 版，但在 `main.swift`
  的顶层写 `await wv.evaluateJavaScript("…")` 会被重载解析挑到带默认参数的同步版，编译器还会提醒你别这么写）。
  返回值只有 Swift 侧收得下的类型：数字、字符串、DOM 计数都正常；引用不存在的变量给 `WKErrorDomain#4`
  （`javaScriptExceptionOccurred`），`Symbol` 和 `Promise` 给 `#5`（`javaScriptResultTypeIsUnsupported`）。
  想要 Promise 的结果，得在 JS 里 `.then(...)` 之后 `postMessage` 回来，而不是指望 `evaluateJavaScript` 等它。
- **`WKUserScript` 是「每次文档开始时注入」**：`injectionTime` 两档 `0=atDocumentStart / 1=atDocumentEnd`，
  `forMainFrameOnly` 决定要不要连子 frame 一起注。它记的是「脚本」这本账；
  `removeScriptMessageHandler(forName:)` 管的是「消息通道」那本账——上面那行 `userScripts 数还是=1`
  说明两本账各记各的。
- **清理数据是按种类来的**：`WKWebsiteDataStore.allWebsiteDataTypes()` 给 14 个类型名
  （`WKWebsiteDataTypeLocalStorage`、`…Cookies`、`…MemoryCache`、…），`removeData(ofTypes:modifiedSince:)`
  里点哪些清哪些。想「只登出不清缓存」或反过来，就是在这里挑类型，而不是一个 `clearAll()`。

## 本章的诚实边界

`WKWebView` 的实例活在另一个进程中，于是它有一个**只在 headless 命令行进程里才会撞上**的限制，本示例的
处理办法是「**在任何顶层 `await` 之前，把唯一的那个 WebView 建好并加载一次**」——就是第 2 节之后那行
`预备：预热 WebView（didFinish=1 标题同步到=true）`。这句话的证据来自一个独立探针进程（示例里不跑它：
它不崩、不报错，只是永远等不到回调，留在示例里就是一次无声挂起）：

```swift
// 探针要点：1) 任何 await 之前建实例并加载 → 2) 跑一次纯计算的顶层 await →
// 3) 复用同一个实例再加载 → 4) await 之后新建实例（共享 WKProcessPool）→ 5) await 之后新建实例（默认池）
let (v1, p1) = makeView(sharePool: true)
line(load(v1, p1, "预热页"))                        // 这一步必须在任何 await 之前
let n = await withTaskGroup(of: Int.self) { … }     // 只是纯计算，完全不碰网络
line(load(v1, p1, "复用页"))                         // 同一个实例：还能用
let (v2, p2) = makeView(sharePool: true)
line(load(v2, p2, "共享池新实例"))                   // await 之后新建：起不动
```

实测输出（原文收录；第 3 步那个 `title=` 空是标题那一拍还没同步到，导航本身已经完成了）：

```
== 1) 任何 await 之前：建实例 + 加载 ==
   等到导航完成=true didStart=1 didFinish=1 didFail=0 title=预热页
== 2) 跑一次纯计算的顶层 await（不碰网络）==
   await 回来了 n=6
== 3) await 之后：复用同一个实例再加载 ==
   等到导航完成=true didStart=2 didFinish=2 didFail=0 title=
   同一个实例跑 JS：值=Optional(2)
== 4) await 之后：新建实例（共享第 1 步那个 WKProcessPool）==
   等到导航完成=false didStart=0 didFinish=0 didFail=0 title=
== 5) await 之后：新建实例（默认进程池）==
   等到导航完成=false didStart=0 didFinish=0 didFail=0 title=
== 6) 对照：await 之前就把第 4/5 步那两个实例建好、加载过，再 await 之后第二次加载 ==
   （第 3 步就是这个情形，结论：只有「在任何 await 之前已经加载成功过的这个实例」还能继续用）
END
```

结论三条：

1. 触发条件是**顶层代码挂起过一次主线程**，与有没有网络、`TaskGroup` 里做了什么无关——第 2 步只是纯计算。
2. 只有「在任何 `await` 之前已经加载成功过的**这个实例**」之后还能继续用；同池新建的（第 4 步）和默认池
   新建的（第 5 步）都是 `didStart=0 didFinish=0 didFail=0`——**连失败回调都不来**。
3. **共享 `WKProcessPool` 救不了它**（第 4 步就是为此设计的对照组）。

所以结论不是「WKWebView 在 headless 里不能用」（第 1、3 步都能用），而是「**它的实例必须在主线程第一次
挂起之前起起来**」。真 App 里不会遇到这件事：`UIApplicationMain` 之后主线程本来就在跑 runloop，WebView
也是在 `viewDidLoad` 里建的。会撞上它的是命令行工具、SwiftPM 可执行文件、无 UI 的自动化脚本。

第二条边界是上面已经说过一次的：**注册自定义 `URLProtocol` 会连缓存的读取一起顶掉**（第 11 节最后四行）。
它是第 01 章「谁替你做了什么」这条主线在网络层的又一次现身——`URLProtocol` 是可插拔传输层，你换掉它，
就把它顺带承担的缓存读取一起换了。

## 心智模型小结

```
结构化并发：async/await 顺序、async let 并发、TaskGroup 动态并发
actor 串行化可变状态，消灭 data race；@MainActor 把 UI 更新钉在主线程
URLSession.data(for:) 是 async 的；非 2xx 要自己判并 throw
离线可测：自定义 URLProtocol 拦截请求，返回写死响应
缓存两条路：写入看协议传的 StoragePolicy，读取看 requestCachePolicy 那六个格子
WKWebView 活在另一个进程里：JS→Swift 传不了 function（静默丢），Swift→JS 收不了 Symbol/Promise（#5 结果类型不支持）
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 手拼 URL 偶尔失败 | 特殊字符没编码；用 `URLComponents` + `queryItems` |
| 服务器返 404 却没进 catch | `URLSession` 只对传输层错误 throw；HTTP 状态码要自己判 |
| 多个任务改一个 class，结果偏小 | data race；改用 `actor` |
| UI 更新崩溃/不刷新 | 不在主线程；用 `@MainActor` 或 `MainActor.run` |
| `async let` 声明处写了 `await` | `await` 只在**取值**处（`await c1`），声明处不写 |
| TaskGroup 结果顺序不稳 | 按完成顺序产出；需要确定顺序就自己排序 |
| 顶层代码调 `@MainActor` 方法提示多余的 `await` | 顶层已是 MainActor 隔离，同 actor 调用不需要 `await` |
| `Thread.isMainThread` 在 async 上下文报警 | 该 API 在异步上下文不可用；把检查放进 `@MainActor` 方法里 |
| 设了 `urlCache` 却每次都重下 | 响应没有 `Cache-Control`/`Expires`，条目一进仓库就算过期（矩阵 B 格） |
| 离线兜底时判 `-2000` 判不到 | `returnCacheDataDontLoad` 空缓存实际给 `-1008 resourceUnavailable` |
| mock 里加了 `Cache-Control: no-store` 却仍进缓存 | stub 路径没人解析响应头；只有 `cacheStoragePolicy` 那个参数说话 |
| 注册了自定义 `URLProtocol` 后缓存「只写不读」 | 查缓存是内置 HTTP 协议实现的活儿，被你整个换掉了 |
| 拿 `currentMemoryUsage` 当缓存总占用 | 它只数 `CachedURLResponse.data` 的字节，不含响应头，也不含磁盘段 |
| JS 发了 6 条消息 Swift 只收到 5 条 | `function` 不能跨进程序列化，被**静默丢掉**（没有回调、没有错误） |
| `m.body as! String` 崩 | `undefined` 会送到但 `body` 是 `nil`；先 `guard let body = m.body` |
| `evaluateJavaScript` 等 Promise 拿到 `#5` | 结果类型不支持；在 JS 里 `.then()` 之后 `postMessage` 回来 |
| `await` 之后新建的 `WKWebView` 永远不回调 | 顶层挂起过主线程后 WebContent 进程起不动；实例要在第一个 `await` 之前建好并预热 |

## 小结

- **离线测网络**：自定义 `URLProtocol` 拦截请求返回写死响应，让 `URLSession` 全链路可确定断言。
- `URLComponents` 拼 URL（自动编码）；`URLRequest` 配方法/头/body。
- `async`/`await` 把异步写得像同步；`URLSession` 不为 HTTP 错误码 throw，要自己判。
- **并发**：`async let`（固定个数）、`withTaskGroup`（动态个数）；只断言性质，把不确定的
  完成顺序归一化。
- **`actor`** 串行化可变状态，编译期消灭 data race；**`@MainActor`** 把 UI 更新钉在主线程，
  且 `main.swift` 顶层代码本身就是 MainActor 隔离的。
- **缓存是两条路**：写入由 `URLProtocol` 传的 `cacheStoragePolicy` 决定（`no-store` 响应头在这条路上
  不生效），读取由 `requestCachePolicy` 那六个格子决定，而「只有响应自己声明了新鲜度，
  `useProtocolCachePolicy` 才真的免掉一次网络」。自定义 `URLProtocol` 会把读取那条路一起顶掉。
- **`WKWebView`** 在另一个进程里：JS→Swift 的 `function` 静默丢、`undefined` 给 `nil` body；
  Swift→JS 收不了 `Symbol`/`Promise`（`WKErrorDomain#5`）；数据清理是「按种类」的模型。
- 下一章讲**数据持久化**（UserDefaults / 文件 / Codable / Keychain）。

---

上一章：[16 手势、触摸与响应链](16-gestures-responder.md) · 下一章：[18 数据持久化](18-persistence.md)
