# 17 · 网络与并发：URLSession / async-await / TaskGroup / actor

> 示例：`examples/17_networking_concurrency/main.swift`
> 实测输出见 `build/17_networking_concurrency/stdout.debug.txt`

网络请求天生是异步的。iOS 早期用 completion handler（回调地狱），现代 iOS 用
**Swift 并发**（`async`/`await`、`actor`、结构化并发）——它把异步代码写得像同步一样
顺，还能在编译期消灭一大类 data race。本章讲网络 + 并发两件事，且**完全不依赖外网**。

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

## 心智模型小结

```
结构化并发：async/await 顺序、async let 并发、TaskGroup 动态并发
actor 串行化可变状态，消灭 data race；@MainActor 把 UI 更新钉在主线程
URLSession.data(for:) 是 async 的；非 2xx 要自己判并 throw
离线可测：自定义 URLProtocol 拦截请求，返回写死响应
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

## 小结

- **离线测网络**：自定义 `URLProtocol` 拦截请求返回写死响应，让 `URLSession` 全链路可确定断言。
- `URLComponents` 拼 URL（自动编码）；`URLRequest` 配方法/头/body。
- `async`/`await` 把异步写得像同步；`URLSession` 不为 HTTP 错误码 throw，要自己判。
- **并发**：`async let`（固定个数）、`withTaskGroup`（动态个数）；只断言性质，把不确定的
  完成顺序归一化。
- **`actor`** 串行化可变状态，编译期消灭 data race；**`@MainActor`** 把 UI 更新钉在主线程，
  且 `main.swift` 顶层代码本身就是 MainActor 隔离的。
- 下一章讲**数据持久化**（UserDefaults / 文件 / Codable / Keychain）。
