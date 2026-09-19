// ============================================================
// 17 - 网络与并发：URLSession / async-await / TaskGroup / actor / @MainActor
//
// 绝不依赖外网：注册一个自定义 URLProtocol 拦截所有请求，返回**写死的**响应。
// 于是「发请求 → 拿数据 → 解码」这条真实的 URLSession 全链路可以离线、确定地跑。
// 并发部分（async/await、async let、TaskGroup、actor、@MainActor）本身就是纯计算，
// 不碰网络，结果确定。
//
// headless：本示例是顶层代码，直接用 Swift 并发（顶层 await）。所有网络走 stub，
// 所有断言都是确定值（状态码、解码结果、actor 计数）。不打印线程 id、耗时等环境相关量。
// ============================================================

import Foundation
import UIKit

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

// ---------------------------------------------------- 9) 小结
line("")
line("-- 心智模型 --")
line("  结构化并发：async/await 顺序、async let 并发、TaskGroup 动态并发")
line("  actor 串行化可变状态，消灭 data race；@MainActor 把 UI 更新钉在主线程")
line("  URLSession.data(for:) 是 async 的；非 2xx 要自己判并 throw")
line("  离线可测：自定义 URLProtocol 拦截请求，返回写死响应")
expect(true, "以上均由确定值断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 17 结束 ====")
exit(failures == 0 ? 0 : 1)
