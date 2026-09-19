// 18 · 并发 II——actor 隔离域、Sendable、@MainActor、Swift 6 严格并发

import Foundation

// ═══ 18.1 纯函数区（供测试）
/// 对照组：普通 class 的可变状态在并发下不安全（数据竞争）
final class UnsafeCounter {
    var count = 0
    func increment() {
        count += 1  // 非原子：read-modify-write 三步，并发下互相踩
    }
}

/// actor：状态默认隔离，一次只有一个任务在"里面"
actor SafeCounter {
    private(set) var count = 0

    func increment() {
        count += 1  // actor 内部同步访问自己的状态——安全
    }

    func incrementBy(_ n: Int) {
        count += n
    }

    func reset() {
        count = 0
    }

    /// actor 方法可以调用同 actor 的其他方法：无需 await
    func incrementTwice() {
        increment()
        increment()
    }
}

/// actor + 异步方法：内部有 await 时隔离依然成立（跨 await 状态不被外部偷看）
actor Statistics {
    private var samples: [Int] = []

    func record(_ value: Int) {
        samples.append(value)
    }

    func average() async -> Double {
        guard !samples.isEmpty else { return 0 }
        // 模拟一次耗时计算（真实代码是 await IO/网络）
        return Double(samples.reduce(0, +)) / Double(samples.count)
    }

    var count: Int { samples.count }
}

/// Sendable：值跨并发域传递的安全性标记
struct Config: Sendable {  // 全 let + Sendable 成员 → 自动安全
    let host: String
    let port: Int
}

func describe(_ config: Config) -> String {
    "\(config.host):\(config.port)"
}

/// 非 Sendable 对照：含可变状态的 class 跨任务传递 = 数据竞争风险
final class MutableBag {
    var items: [String] = []
}

/// @MainActor：钉死在主 actor 上（UI 代码的标配，本例演示语义）
@MainActor
final class Dashboard {
    private var updates = 0

    func refresh() {
        updates += 1
    }

    var total: Int { updates }
}

// ═══ 18.2 串行 vs 并发竞态的确定性对照（不真开多线程，用 Task 顺序演示语义）
let unsafe = UnsafeCounter()
for _ in 0..<10 {
    unsafe.increment()
}
precondition(unsafe.count == 10)  // 单线程下当然对——多线程下这行是赌博
print("① 单线程串行：unsafe.count = \(unsafe.count)（多线程下不保证）")

let safe = SafeCounter()
for _ in 0..<10 {
    await safe.increment()  // 跨隔离边界调用：必须 await
}
let firstCount = await safe.count
precondition(firstCount == 10)
print("② actor 计数：\(firstCount)（任何并发度下都对）")

// ═══ 18.3 actor 的方法互调与批量操作
await safe.reset()
await safe.incrementTwice()
await safe.incrementBy(8)
let secondCount = await safe.count
precondition(secondCount == 10)
print("③ reset → incrementTwice → +8：\(secondCount)")

// ═══ 18.4 TaskGroup 并发打点，actor 聚合（确定性聚合）
let stats = Statistics()
await withTaskGroup(of: Void.self) { group in
    for i in 1...50 {
        group.addTask {
            await stats.record(i * 100)  // 50 个并发子任务往同一个 actor 打点
        }
    }
}
let avg = await stats.average()
let sampleCount = await stats.count
precondition(sampleCount == 50)
precondition(avg == Double((1...50).map { $0 * 100 }.reduce(0, +)) / 50)
print("④ 50 并发打点：count=\(sampleCount)，average=\(avg)")

// ═══ 18.5 Sendable 值跨域自由飞行
let config = Config(host: "api.example.com", port: 443)
precondition(describe(config) == "api.example.com:443")
let result = await withTaskGroup(of: String.self) { group in
    group.addTask { describe(config) }  // Sendable 值随便跨
    return await group.next() ?? ""
}
precondition(result == "api.example.com:443")
print("⑤ Sendable 配置跨任务：\(result)")

// ═══ 18.6 @MainActor：隔离的"单线程世界"
await MainActor.run {
    let dashboard = Dashboard()
    dashboard.refresh()
    dashboard.refresh()
    dashboard.refresh()
    precondition(dashboard.total == 3)
    print("⑥ MainActor 仪表盘：\(dashboard.total) 次刷新")
}

print("==== 18 结束 ====")
