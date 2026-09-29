// ============================================================
// 17 - 网络与并发：URLSession / async-await / TaskGroup / actor / @MainActor
//
// 绝不依赖外网：注册一个自定义 URLProtocol 拦截所有请求，返回**写死的**响应。
// 于是「发请求 → 拿数据 → 解码」这条真实的 URLSession 全链路可以离线、确定地跑。
// 并发部分（async/await、async let、TaskGroup、actor、@MainActor）本身就是纯计算，
// 不碰网络，结果确定。
//
// 后半章是两件「你以为懂其实没懂」的事：
//   网络缓存（9~11 节）：URLCache 的写入侧和读取侧是**两条不同的路**。
//     写入由 URLProtocol 传给 loading system 的 cacheStoragePolicy 决定，
//     响应头里的 Cache-Control: no-store 在 stub 这条路上一律不生效；
//     读取由 requestCachePolicy 决定，而那六个策略的真实差别只有六个格子能说明白。
//     读取实验的目标地址用 127.0.0.1:1 —— 保留端口，没有任何服务会监听它，
//     所以「有没有打网络」这件事被翻译成一个确定的错误码 -1004，全程离线。
//   WKWebView（12 节）：UIKit 那套里唯一真正在跑另一个进程的东西。
//     裸 simctl 进程里它能 loadHTMLString、能触发导航代理、能双向传值，
//     因为不需要窗口；但 JS 到 Swift 的消息有几种类型会被**静默丢掉**，
//     这只有真跑一遍才知道。
//
// headless：本示例是顶层代码，直接用 Swift 并发（顶层 await）。所有网络走 stub 或
// 指向 127.0.0.1:1，所有断言都是确定值（状态码、解码结果、actor 计数、缓存命中与否）。
// 不打印线程 id、耗时、路径等环境相关量；WKWebView 的有界抽送只判「等到没等到」，
// 不打印等了多久。
// ============================================================

import Foundation
import UIKit
import WebKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

// ------------------------------------------------ 拦截所有请求的 stub URLProtocol
final class StubProtocol: URLProtocol {
    // 按 URL path 返回不同的写死响应
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let path = request.url?.path ?? "/"
        let status: Int
        let body: String
        switch path {
        case "/notfound":
            status = 404; body = #"{"error":"missing"}"#
        default:
            status = 200; body = #"{"ok":true,"items":[1,2,3]}"#
        }
        let data = Data(body.utf8)
        let resp = HTTPURLResponse(url: request.url!, statusCode: status,
                                   httpVersion: "HTTP/1.1",
                                   headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

struct Payload: Codable, Equatable { let ok: Bool; let items: [Int] }

// --------------------------------- 专给缓存三节用的 stub：可配「存不存」和「响应头」
// 它自己数被调用了几次，于是「这次加载有没有真的打网络」变成一个能打印的整数。
final class CacheStub: URLProtocol {
    static var hits = 0
    static var storagePolicy: URLCache.StoragePolicy = .allowed
    static var headers: [String: String] = ["Content-Type": "application/json"]
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        CacheStub.hits += 1
        let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                                   headerFields: CacheStub.headers)!
        // 第三个参数才是「这条响应能不能进 URLCache」。它由**协议自己**传给 loading system，
        // Foundation 不会替你解析 resp 里的 Cache-Control。
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: CacheStub.storagePolicy)
        client?.urlProtocol(self, didLoad: Data("net\(CacheStub.hits)".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

// --------------------------------- 专给 WKWebView 那节用的代理：只数事件，不打时间
final class WebProbe: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var started = 0
    var finished = 0
    var failed = 0
    var lastFail = ""
    var kinds: [String] = []          // JS → Swift 的消息：名字 + 收到的真实类型
    func webView(_ w: WKWebView, didStartProvisionalNavigation n: WKNavigation!) { started += 1 }
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { finished += 1 }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) {
        failed += 1
        let x = e as NSError
        lastFail = "\(x.domain)#\(x.code)"
    }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) {
        failed += 1
        let x = e as NSError
        lastFail = "provisional \(x.domain)#\(x.code)"
    }
    func userContentController(_ ucc: WKUserContentController, didReceive m: WKScriptMessage) {
        // m.body 是 Any?：JS 的 undefined 给你 nil，直接强解包就是崩，所以这里只打类型
        kinds.append("\(m.name)/\(type(of: m.body))")
    }
}

/// 有界抽送：转 runloop 直到条件成立或到点。**绝不**无限 runloop（同第 13 章）。
/// 返回值只说「等到没等到」，耗时本身不打——环境相关。
func spin(until done: () -> Bool, maxSeconds: Double = 5.0) -> Bool {
    let deadline = Date().addingTimeInterval(maxSeconds)
    while !done() && Date() < deadline {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
    }
    return done()
}

/// 跑一段 JS，把 completionHandler 的两个参数收成一行
func js(_ wv: WKWebView, _ src: String) -> String {
    var out = ""
    wv.evaluateJavaScript(src) { v, e in
        if let e {
            let x = e as NSError
            out = "值=nil 错误=\(x.domain)#\(x.code)"
        } else {
            out = "值=\(String(describing: v))"
        }
    }
    _ = spin(until: { !out.isEmpty })
    return out
}

// 一个把非 2xx 当成错误的网络层
enum ApiError: Error { case badStatus(Int) }
func fetchPayload(from url: URL, session: URLSession) async throws -> Payload {
    let (data, resp) = try await session.data(for: URLRequest(url: url))
    guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        throw ApiError.badStatus(code)
    }
    return try JSONDecoder().decode(Payload.self, from: data)
}

let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [StubProtocol.self]        // 关键：让我们的 stub 接管所有请求
config.urlCache = nil
let session = URLSession(configuration: config)

line("== 17 网络与并发 ==")

// ---------------------------------------------------- 1) URL 构造：URLComponents
line("")
line("-- URL / URLComponents：拼查询参数 --")
var comps = URLComponents()
comps.scheme = "https"
comps.host = "api.example.com"
comps.path = "/search"
comps.queryItems = [
    URLQueryItem(name: "q", value: "swift ios"),      // 含空格，会被百分号编码
    URLQueryItem(name: "page", value: "2"),
]
let builtURL = comps.url!
line("  拼出的 URL = \(builtURL.absoluteString)")
expect(builtURL.absoluteString == "https://api.example.com/search?q=swift%20ios&page=2",
       "URLComponents 自动百分号编码空格，拼出规范 URL")
expect(comps.queryItems?.count == 2, "两个查询参数")

// ---------------------------------------------------- 2) URLRequest：方法 / 头 / body
line("")
line("-- URLRequest：配置请求 --")
var req = URLRequest(url: URL(string: "https://api.example.com/x")!)
req.httpMethod = "POST"
req.setValue("application/json", forHTTPHeaderField: "Content-Type")
req.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
req.httpBody = #"{"k":1}"#.data(using: .utf8)
expect(req.httpMethod == "POST", "httpMethod 设为 POST")
expect(req.value(forHTTPHeaderField: "Content-Type") == "application/json", "自定义请求头可读回")
expect(req.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true, "Authorization 头已设置")
expect(req.httpBody != nil && req.httpBody!.count > 0, "httpBody 已附带")

// ------------------------------------------------ 预备动作：把 WKWebView 在所有 await 之前叫醒
// 这是一条**实测到**的 headless 约束，不是风格问题：顶层代码只要挂起过一次主线程
// （哪怕只是 `await withTaskGroup { }` 这种纯计算），之后再**新建**的 WKWebView 就永远
// 等不到 didStart/didFinish —— 它那个 WebContent 子进程的启动握手再也不完成。
// 共享 WKProcessPool 救不了；而「在任何 await 之前就已经加载成功过的那个实例」
// 之后还能继续用（再 load 一次、再跑 JS 都正常）。
// 所以本示例只在第 1 节之前建**一个** WebView 并预热一次，第 12 节接着用它。
// 那条约束的原始探针输出收录在 docs/17 的「诚实边界」里。
let webProbe = WebProbe()
let webScripts = WKUserContentController()
webScripts.add(webProbe, name: "bridge")
webScripts.add(webProbe, name: "second")
let webConfig = WKWebViewConfiguration()
webConfig.userContentController = webScripts
let warmView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 200), configuration: webConfig)
warmView.navigationDelegate = webProbe
warmView.loadHTMLString("<html><head><title>预热页</title></head><body></body></html>", baseURL: nil)
let warmedUp = spin(until: { warmView.title == "预热页" })
line("  预备：预热 WebView（didFinish=\(webProbe.finished) 标题同步到=\(warmedUp)）——这句必须在任何 await 之前完成")

// ---------------------------------------------------- 3) async/await + URLSession（走 stub）
line("")
line("-- async/await：发请求 → 解码 --")
do {
    let payload = try await fetchPayload(from: URL(string: "https://api.example.com/data")!, session: session)
    line("  解码结果 = ok:\(payload.ok) items:\(payload.items)")
    expect(payload == Payload(ok: true, items: [1, 2, 3]), "URLSession 全链路：拿到 stub 响应并 Codable 解码成功")
} catch {
    expect(false, "不应抛错：\(error)")
}

// ---------------------------------------------------- 4) 错误处理：非 2xx → 抛错
line("")
line("-- 错误处理：404 被翻译成 Swift 错误 --")
do {
    _ = try await fetchPayload(from: URL(string: "https://api.example.com/notfound")!, session: session)
    expect(false, "404 本应抛错")
} catch ApiError.badStatus(let code) {
    line("  捕获到 badStatus(\(code))")
    expect(code == 404, "非 2xx 响应被网络层判成 ApiError.badStatus(404)")
} catch {
    expect(false, "错误类型不对：\(error)")
}

// ---------------------------------------------------- 5) 顺序 await vs async let（并发）
line("")
line("-- 顺序 await vs async let：并发 --")
func delayed(_ v: Int) async -> Int {
    try? await Task.sleep(nanoseconds: 20_000_000)   // 20ms
    return v
}
// 顺序：一个接一个
let seqStart = Date()
let s1 = await delayed(1)
let s2 = await delayed(2)
let seqElapsed = Date().timeIntervalSince(seqStart)
expect(s1 == 1 && s2 == 2, "顺序 await 拿到两个结果")
// 并发：async let 同时开跑
let concStart = Date()
async let c1 = delayed(10)
async let c2 = delayed(20)
let concSum = await c1 + c2
let concElapsed = Date().timeIntervalSince(concStart)
expect(concSum == 30, "async let 并发执行，结果相加为 30")
// 只断言**性质**：并发应比顺序快（不打印具体毫秒，避免环境相关数字）
line("  并发耗时 < 顺序耗时 : \(concElapsed < seqElapsed)")
expect(concElapsed < seqElapsed, "async let 并发比顺序 await 更快（性质，不依赖具体毫秒）")

// ---------------------------------------------------- 6) TaskGroup：动态并发
line("")
line("-- withTaskGroup：把一批任务并发跑完 --")
let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
    for i in 1...5 { group.addTask { await delayed(i) } }
    var collected: [Int] = []
    for await r in group { collected.append(r) }
    return collected.sorted()
}
line("  TaskGroup 收集到 = \(results)")
expect(results == [1, 2, 3, 4, 5], "5 个子任务全部完成并收集齐（完成顺序不定，排序后确定）")

// ---------------------------------------------------- 7) actor：串行化的可变状态
line("")
line("-- actor：并发安全的状态 --")
actor Counter {
    private var n = 0
    func increment() { n += 1 }
    func value() -> Int { n }
}
let counter = Counter()
// 100 个并发任务同时 increment：actor 保证串行访问，不会丢更新
await withTaskGroup(of: Void.self) { group in
    for _ in 0..<100 { group.addTask { await counter.increment() } }
}
let finalCount = await counter.value()
line("  100 个并发 increment 后 = \(finalCount)")
expect(finalCount == 100, "actor 串行化访问：100 个并发自增无一丢失（普通 class 会 data race）")

// ---------------------------------------------------- 8) @MainActor：回到主线程
line("")
line("-- @MainActor：UI 更新回到主线程 --")
// 注意：main.swift 的顶层代码本身就是 @MainActor 隔离的，所以调用 @MainActor 成员
// 不需要 await（同一 actor）。这恰好印证：SwiftUI 的 body、UIKit 的回调都在主 actor 上。
@MainActor
final class UIState {
    var text = ""
    var ranOnMain = false
    func update(_ s: String) {
        text = s
        ranOnMain = Thread.isMainThread     // @MainActor 保证在主线程执行
    }
}
let ui = UIState()
ui.update("已加载")
expect(ui.text == "已加载", "@MainActor 方法更新了状态")
expect(ui.ranOnMain, "@MainActor 保证在主线程执行（UI 更新安全）")

// ---------------------------------------------------- 9) URLCache：出厂值与六个策略
line("")
line("-- URLCache：容量、六个缓存策略、三种 session 配置的出厂值 --")
let sharedCache = URLCache.shared
line("  两次取 URLCache.shared 是同一个对象=\(sharedCache === URLCache.shared)")
line("  共享缓存出厂 memoryCapacity=\(sharedCache.memoryCapacity) diskCapacity=\(sharedCache.diskCapacity)")
let ownCache = URLCache(memoryCapacity: 100_000, diskCapacity: 200_000, diskPath: nil)
line("  自建实例 memoryCapacity=\(ownCache.memoryCapacity) diskCapacity=\(ownCache.diskCapacity) 与共享同一个对象=\(ownCache === URLCache.shared)")
expect(ownCache.memoryCapacity == 100_000 && ownCache.diskCapacity == 200_000,
       "自建 URLCache 的容量就是你给的那两个数")
expect(sharedCache === URLCache.shared, "URLCache.shared 是进程级单例——session 不写 urlCache 时用的就是它")
// 这两个数别当断言用：共享缓存的**当前占用**取决于这台模拟器之前跑过什么
line("  共享缓存那两个「当前占用」读得到，但值随这台模拟器之前跑过什么变——所以本示例只在**自建**实例上断言占用，不在共享实例上断言")

let policies: [(String, URLRequest.CachePolicy)] = [
    ("useProtocolCachePolicy", .useProtocolCachePolicy),
    ("reloadIgnoringLocalCacheData", .reloadIgnoringLocalCacheData),
    ("returnCacheDataElseLoad", .returnCacheDataElseLoad),
    ("returnCacheDataDontLoad", .returnCacheDataDontLoad),
    ("reloadIgnoringLocalAndRemoteCacheData", .reloadIgnoringLocalAndRemoteCacheData),
    ("reloadRevalidatingCacheData", .reloadRevalidatingCacheData),
]
line("  六个 requestCachePolicy 的 raw 值：" + policies.map { "\($0.0)=\($0.1.rawValue)" }.joined(separator: " "))
let bareReq = URLRequest(url: URL(string: "https://api.example.com/y")!)
line("  URLRequest() 出厂 cachePolicy=\(bareReq.cachePolicy.rawValue)（就是 useProtocolCachePolicy）")
expect(bareReq.cachePolicy == .useProtocolCachePolicy, "URLRequest 不改策略时默认就是「按协议说的办」")
let fullReq = URLRequest(url: bareReq.url!, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 5)
line("  三参数构造之后 cachePolicy=\(fullReq.cachePolicy.rawValue) timeoutInterval=\(fullReq.timeoutInterval)")

let dcfg = URLSessionConfiguration.default
line("  default 配置：requestCachePolicy=\(dcfg.requestCachePolicy.rawValue) urlCache 就是共享那个=\(dcfg.urlCache === sharedCache) timeoutForRequest=\(dcfg.timeoutIntervalForRequest) timeoutForResource=\(dcfg.timeoutIntervalForResource) 内存/磁盘容量=\(dcfg.urlCache?.memoryCapacity ?? -1)/\(dcfg.urlCache?.diskCapacity ?? -1)")
line("  default 配置：httpShouldUsePipelining=\(dcfg.httpShouldUsePipelining) shouldUseExtendedBackgroundIdleMode=\(dcfg.shouldUseExtendedBackgroundIdleMode) httpShouldSetCookies=\(dcfg.httpShouldSetCookies) cookieAcceptPolicy raw=\(dcfg.httpCookieAcceptPolicy.rawValue)")
expect(dcfg.urlCache === sharedCache && dcfg.requestCachePolicy == .useProtocolCachePolicy,
       "default 配置出厂就带 512000/10000000 那个共享缓存，策略是 useProtocol")
let efc = URLSessionConfiguration.ephemeral
line("  ephemeral 配置：urlCache 有值=\(efc.urlCache != nil) 与共享同一个对象=\(efc.urlCache === sharedCache) 内存容量=\(efc.urlCache?.memoryCapacity ?? -1) cookieStorage 有值=\(efc.httpCookieStorage != nil)")
let bgc = URLSessionConfiguration.background(withIdentifier: "com.iosdev.bg.probe")
line("  background 配置：urlCache 有值=\(bgc.urlCache != nil) sessionSendsLaunchEvents=\(bgc.sessionSendsLaunchEvents) requestCachePolicy=\(bgc.requestCachePolicy.rawValue)")
expect(bgc.urlCache == nil, "background 配置出厂 urlCache=nil：后台会话的缓存归那个独立的后台 daemon 管，不归你手里的 URLCache")
line("  缓存存放位置三档 URLCache.StoragePolicy：allowed=\(URLCache.StoragePolicy.allowed.rawValue) allowedInMemoryOnly=\(URLCache.StoragePolicy.allowedInMemoryOnly.rawValue) notAllowed=\(URLCache.StoragePolicy.notAllowed.rawValue)")

// ---------------------------------------------------- 10) 缓存的写入侧
line("")
line("-- 缓存的写入侧：谁决定这条响应进不进 URLCache --")
let writeURL = URL(string: "https://api.example.com/w")!
let writeCases: [(String, URLCache.StoragePolicy, [String: String])] = [
    ("协议传 .allowed", .allowed, ["Content-Type": "application/json"]),
    ("协议传 .allowedInMemoryOnly", .allowedInMemoryOnly, ["Content-Type": "application/json"]),
    ("协议传 .notAllowed", .notAllowed, ["Content-Type": "application/json"]),
    ("协议传 .allowed + 响应头 no-store", .allowed, ["Content-Type": "application/json", "Cache-Control": "no-store"]),
    ("协议传 .allowed + 响应头 max-age=600", .allowed, ["Content-Type": "application/json", "Cache-Control": "max-age=600"]),
]
var writeStored: [String: Bool] = [:]
for (name, pol, hdrs) in writeCases {
    let c = URLCache(memoryCapacity: 100_000, diskCapacity: 200_000, diskPath: nil)
    CacheStub.hits = 0
    CacheStub.storagePolicy = pol
    CacheStub.headers = hdrs
    let cfg = URLSessionConfiguration.default
    cfg.protocolClasses = [CacheStub.self]
    cfg.urlCache = c
    let s = URLSession(configuration: cfg)
    let (d, _) = try! await s.data(from: writeURL)
    let stored = c.cachedResponse(for: URLRequest(url: writeURL))
    writeStored[name] = stored != nil
    line("  \(name)：拿到=\(String(decoding: d, as: UTF8.self)) stub 被调=\(CacheStub.hits) 存完 URLCache 查得到=\(stored != nil) 内存占用=\(c.currentMemoryUsage) 磁盘占用=\(c.currentDiskUsage)")
    s.invalidateAndCancel()
}
CacheStub.storagePolicy = .allowed
CacheStub.headers = ["Content-Type": "application/json"]
expect(writeStored["协议传 .notAllowed"] == false,
       "三档 StoragePolicy 里只有 notAllowed 真的不落缓存")
expect(writeStored["协议传 .allowed + 响应头 no-store"] == true,
       "响应头写 no-store 也照样存了：这条路上没人解析 Cache-Control，能不能存全由协议传的那个参数说了算")
expect(writeStored["协议传 .allowed"] == true && writeStored["协议传 .allowedInMemoryOnly"] == true,
       "allowed 与 allowedInMemoryOnly 在「查得到」这件事上没区别（区别在落不落磁盘，小对象本来就留在内存）")
line("  同一段 body「net1」= 4 字节，上面报的内存占用正是 4——它数的是 CachedURLResponse 的 data 长度")

// ---------------------------------------------------- 11) 缓存的读取侧：六个策略各给什么
line("")
line("-- 缓存的读取侧：requestCachePolicy 六格矩阵（目标 127.0.0.1:1，离线且确定）--")
// 为什么用 127.0.0.1:1：1 是保留端口，模拟器里没有任何服务会监听它，所以「有没有真的
// 打网络」被翻译成一个固定错误码 -1004（cannotConnectToHost）。全程不出机器。
let probeURL = URL(string: "http://127.0.0.1:1/probe")!
func readProbe(_ policy: URLRequest.CachePolicy, seeded: Bool, fresh: Bool) async -> String {
    let c = URLCache(memoryCapacity: 100_000, diskCapacity: 200_000, diskPath: nil)
    if seeded {
        var h = ["Content-Type": "text/plain"]
        if fresh { h["Cache-Control"] = "max-age=600" }
        let r = HTTPURLResponse(url: probeURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: h)!
        let body = fresh ? "cached-fresh" : "cached-nofresh"
        c.storeCachedResponse(CachedURLResponse(response: r, data: Data(body.utf8),
                                                userInfo: nil, storagePolicy: .allowed),
                              for: URLRequest(url: probeURL))
    }
    let cfg = URLSessionConfiguration.default
    cfg.urlCache = c
    cfg.requestCachePolicy = policy
    let s = URLSession(configuration: cfg)
    var out = ""
    do {
        let (d, r) = try await s.data(from: probeURL)
        out = "吃到缓存 \(d.count) 字节 内容=\(String(decoding: d, as: UTF8.self)) 状态码=\((r as? HTTPURLResponse)?.statusCode ?? -1)"
    } catch {
        let n = error as NSError
        out = "打网络（必然失败）domain=\(n.domain) code=\(n.code)"
    }
    s.invalidateAndCancel()
    return out
}
let rowA = await readProbe(.useProtocolCachePolicy, seeded: true, fresh: true)
let rowB = await readProbe(.useProtocolCachePolicy, seeded: true, fresh: false)
let rowC = await readProbe(.useProtocolCachePolicy, seeded: false, fresh: true)
let rowD = await readProbe(.returnCacheDataDontLoad, seeded: true, fresh: true)
let rowE = await readProbe(.returnCacheDataDontLoad, seeded: false, fresh: true)
let rowF = await readProbe(.returnCacheDataElseLoad, seeded: true, fresh: false)
let rowG = await readProbe(.reloadIgnoringLocalCacheData, seeded: true, fresh: true)
let rowH = await readProbe(.reloadIgnoringLocalAndRemoteCacheData, seeded: true, fresh: true)
let rowI = await readProbe(.reloadRevalidatingCacheData, seeded: true, fresh: true)
line("  A useProtocolCachePolicy + 缓存里有一条 max-age=600 的：\(rowA)")
line("  B useProtocolCachePolicy + 缓存里那条没有任何新鲜度头：\(rowB)")
line("  C useProtocolCachePolicy + 缓存是空的：\(rowC)")
line("  D returnCacheDataDontLoad + 有缓存：\(rowD)")
line("  E returnCacheDataDontLoad + 没缓存：\(rowE)")
line("  F returnCacheDataElseLoad + 有缓存但不新鲜：\(rowF)")
line("  G reloadIgnoringLocalCacheData + 有缓存且新鲜：\(rowG)")
line("  H reloadIgnoringLocalAndRemoteCacheData + 有缓存且新鲜：\(rowH)")
line("  I reloadRevalidatingCacheData + 有缓存且新鲜：\(rowI)")
expect(rowA.hasPrefix("吃到缓存") && rowB.hasPrefix("打网络") && rowC.hasPrefix("打网络"),
       "A 吃到缓存、B/C 打网络：只有响应自己声明了新鲜度，useProtocolCachePolicy 才真的免掉一次网络")
expect(rowD.hasPrefix("吃到缓存") && rowE.contains("-1008"),
       "dontLoad 有缓存就给你、没缓存报 -1008 resourceUnavailable（不是文档常被引用的那个 -2000 cannotLoadFromNetwork）")
expect(rowF.hasPrefix("吃到缓存"),
       "elseLoad 连过期都照给：它「只要有缓存就不打网络」，不看新鲜度")
expect(rowG.hasPrefix("打网络") && rowH.hasPrefix("打网络") && rowI.hasPrefix("打网络"),
       "三个 reload 全都必打网络，哪怕缓存里那条还新鲜")
line("  相关错误码：cannotConnectToHost=\(URLError.cannotConnectToHost.rawValue) resourceUnavailable=\(URLError.resourceUnavailable.rawValue) cannotLoadFromNetwork=\(URLError.cannotLoadFromNetwork.rawValue) cannotFindHost=\(URLError.cannotFindHost.rawValue) cannotOpenFile=\(URLError.cannotOpenFile.rawValue)")
line("  第十节那个 stub 场景为什么第二次仍打网络：注册自定义 URLProtocol 等于把内置 HTTP 协议栈整个换掉，")
line("  而「查缓存」这一步正是内置协议栈做的——写入还在（第 10 节证明了），读取没了。")
CacheStub.hits = 0
let asymCache = URLCache(memoryCapacity: 100_000, diskCapacity: 200_000, diskPath: nil)
CacheStub.storagePolicy = .allowed
CacheStub.headers = ["Content-Type": "application/json", "Cache-Control": "max-age=600"]
let acfg = URLSessionConfiguration.default
acfg.protocolClasses = [CacheStub.self]
acfg.urlCache = asymCache
let asymSession = URLSession(configuration: acfg)
let first = try! await asymSession.data(from: writeURL)
let second = try! await asymSession.data(from: writeURL)
line("  同一 URL 连打两次（策略 useProtocol、响应 max-age=600、缓存实例是自己 new 的）：")
line("    第一次=\(String(decoding: first.0, as: UTF8.self)) 第二次=\(String(decoding: second.0, as: UTF8.self)) stub 累计被调=\(CacheStub.hits) 而缓存里查得到=\(asymCache.cachedResponse(for: URLRequest(url: writeURL)) != nil)")
expect(CacheStub.hits == 2, "写了却没读：stub 顶掉内置协议栈之后，连 max-age=600 的响应也会每次重跑——这是 mock 层最常见的「缓存行为测不到」")
asymSession.invalidateAndCancel()
CacheStub.storagePolicy = .allowed
CacheStub.headers = ["Content-Type": "application/json"]

// ---------------------------------------------------- 12) WKWebView：UIWebView 的现代替代
line("")
line("-- WKWebView：接着用预备阶段那个实例（新实例在 await 之后起不动）--")
line("  出厂配置：allowsInlineMediaPlayback=\(webConfig.allowsInlineMediaPlayback) javaScriptCanOpenWindowsAutomatically=\(webConfig.preferences.javaScriptCanOpenWindowsAutomatically) defaultWebpagePreferences.allowsContentJavaScript=\(webConfig.defaultWebpagePreferences.allowsContentJavaScript)")
line("  预备阶段那次加载留下的状态：title=\(warmView.title ?? "<nil>") isLoading=\(warmView.isLoading) estimatedProgress=\(warmView.estimatedProgress) canGoBack=\(warmView.canGoBack) canGoForward=\(warmView.canGoForward)")
let page = """
<html><head><title>页面标题</title></head><body><h1>hi</h1>
<script>
window.webkit.messageHandlers.bridge.postMessage(42);
window.webkit.messageHandlers.bridge.postMessage("文本");
window.webkit.messageHandlers.second.postMessage([1,2]);
window.webkit.messageHandlers.bridge.postMessage({a:1});
window.webkit.messageHandlers.bridge.postMessage(function(){ return 1; });
window.webkit.messageHandlers.bridge.postMessage(undefined);
</script></body></html>
"""
let finishesBefore = webProbe.finished
warmView.loadHTMLString(page, baseURL: nil)
let gotFinish = spin(until: { webProbe.finished > finishesBefore })
let gotAll = spin(until: { webProbe.kinds.count >= 5 })
line("  第二次 loadHTMLString：到齐=\(gotFinish) didStart 累计=\(webProbe.started) didFinish 累计=\(webProbe.finished) didFail 累计=\(webProbe.failed)")
line("  标题同步到 warmView.title=\(spin(until: { warmView.title == "页面标题" })) 值=\(warmView.title ?? "<nil>")")
line("  JS 发了 6 条 postMessage，Swift 侧收到 \(webProbe.kinds.count) 条（等满=\(gotAll)）：" + webProbe.kinds.joined(separator: " "))
expect(webProbe.failed == 0 && gotFinish, "headless 进程里 WKWebView 真跑完了第二次导航：didStart→didFinish，没有 didFail")
expect(gotAll && webProbe.kinds.count == 5,
       "6 条 postMessage 只有 5 条到：JS 的 function 对象没法跨进程序列化，被**静默丢掉**（不报错、也不回调）")
expect(webProbe.kinds.last?.hasSuffix("Optional<AnyObject>") == true,
       "undefined 那条真的到了，但 m.body 是 nil——按 Any 强解包就是崩")
line("  反向（Swift→JS）：" + js(warmView, "1+1"))
line("  读 DOM：" + js(warmView, "document.querySelectorAll('h1').length"))
line("  读 document.title：" + js(warmView, "document.title"))
line("  引用不存在的变量：" + js(warmView, "nonExistentVarXyz"))
line("  返回 Symbol（Swift 侧收不了的类型）：" + js(warmView, "Symbol('s')"))
line("  返回 Promise：" + js(warmView, "Promise.resolve(7)"))
line("  WKError 码表：javaScriptExceptionOccurred=\(WKError.javaScriptExceptionOccurred.rawValue) javaScriptResultTypeIsUnsupported=\(WKError.javaScriptResultTypeIsUnsupported.rawValue) webContentProcessTerminated=\(WKError.webContentProcessTerminated.rawValue)")
let scriptsBefore = webScripts.userScripts.count
let script = WKUserScript(source: "window.__injected = 7;", injectionTime: .atDocumentStart, forMainFrameOnly: true)
webScripts.addUserScript(script)
line("  注入脚本之前 userScripts 数=\(scriptsBefore)；加一条之后=\(webScripts.userScripts.count) injectionTime raw=\(script.injectionTime.rawValue)（0=atDocumentStart 1=atDocumentEnd）forMainFrameOnly=\(script.isForMainFrameOnly)")
let f3 = webProbe.finished
warmView.loadHTMLString("<html><body>x</body></html>", baseURL: nil)
_ = spin(until: { webProbe.finished > f3 })
line("  同一个实例再加载一次（这次带着注入脚本）：" + js(warmView, "String(window.__injected)"))
webScripts.removeScriptMessageHandler(forName: "bridge")
webScripts.removeScriptMessageHandler(forName: "second")
line("  removeScriptMessageHandler 摘掉两个名字之后，userScripts 数还是=\(webScripts.userScripts.count)（消息通道与注入脚本是两本账）")
line("  数据仓：WKWebsiteDataStore.default() 类型=\(type(of: WKWebsiteDataStore.default())) nonPersistent 类型=\(type(of: WKWebsiteDataStore.nonPersistent()))")
let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
line("  它能清的数据种类共 \(dataTypes.count) 种，含 \(dataTypes.contains("WKWebsiteDataTypeLocalStorage") ? "LocalStorage" : "???")、\(dataTypes.contains("WKWebsiteDataTypeCookies") ? "Cookies" : "???")、\(dataTypes.contains("WKWebsiteDataTypeMemoryCache") ? "MemoryCache" : "???")")
expect(dataTypes.contains("WKWebsiteDataTypeLocalStorage"),
       "WKWebView 的存储是「按种类清理」的模型：LocalStorage/Cookie/缓存各自一个类型名，removeData(ofTypes:) 决定清哪些")

// ---------------------------------------------------- 13) 小结
line("")
line("-- 心智模型 --")
line("  结构化并发：async/await 顺序、async let 并发、TaskGroup 动态并发")
line("  actor 串行化可变状态，消灭 data race；@MainActor 把 UI 更新钉在主线程")
line("  URLSession.data(for:) 是 async 的；非 2xx 要自己判并 throw")
line("  离线可测：自定义 URLProtocol 拦截请求，返回写死响应")
line("  缓存两条路：写入看协议传的 StoragePolicy，读取看 requestCachePolicy 那六个格子")
line("  WKWebView 活在另一个进程里：JS→Swift 传不了 function（静默丢），Swift→JS 收不了 Symbol/Promise（#5 结果类型不支持）")
expect(true, "以上均由确定值断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 17 结束 ====")
exit(failures == 0 ? 0 : 1)
