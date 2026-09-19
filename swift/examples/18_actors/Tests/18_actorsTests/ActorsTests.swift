// 18_actors 的 swift-testing 测试
import Testing

@testable import Ch18Actors

@Test func actor计数() async {
    let safe = SafeCounter()
    for _ in 0..<10 {
        await safe.increment()
    }
    #expect(await safe.count == 10)
    await safe.reset()
    #expect(await safe.count == 0)
    await safe.incrementTwice()
    await safe.incrementBy(8)
    #expect(await safe.count == 10)
}

@Test func actor并发聚合() async {
    let stats = Statistics()
    await withTaskGroup(of: Void.self) { group in
        for i in 1...50 {
            group.addTask {
                await stats.record(i * 100)
            }
        }
    }
    #expect(await stats.count == 50)
    let avg = await stats.average()
    #expect(avg == Double((1...50).map { $0 * 100 }.reduce(0, +)) / 50)
}

@Test func 空样本平均值() async {
    let stats = Statistics()
    #expect(await stats.average() == 0)
    #expect(await stats.count == 0)
}

@Test func sendable配置() async {
    let config = Config(host: "api.example.com", port: 443)
    #expect(describe(config) == "api.example.com:443")
    let result = await withTaskGroup(of: String.self) { group in
        group.addTask { describe(config) }
        return await group.next() ?? ""
    }
    #expect(result == "api.example.com:443")
}

@Test func mainActor仪表盘() async {
    await MainActor.run {
        let dashboard = Dashboard()
        dashboard.refresh()
        dashboard.refresh()
        dashboard.refresh()
        #expect(dashboard.total == 3)
    }
}

@Test func 单线程对照() {
    let unsafe = UnsafeCounter()
    for _ in 0..<10 {
        unsafe.increment()
    }
    #expect(unsafe.count == 10)  // 单线程正确；多线程下 UnsafeCounter 无此保证
}
