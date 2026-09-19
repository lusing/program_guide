// 17_concurrency 的 swift-testing 测试（async 测试函数直接支持）
import Testing

@testable import Ch17Concurrency

@Test func 固定温度表() async {
    #expect(await fetchTemperature(city: "北京") == 2)
    #expect(await fetchTemperature(city: "哈尔滨") == -8)
    #expect(await fetchTemperature(city: "不存在") == 0)
}

@Test func 串行平均() async {
    #expect(await averageTemperature(cities: ["北京", "上海", "成都"]) == Double(23) / 3)
    #expect(await averageTemperature(cities: []) == 0)
    #expect(await averageTemperature(cities: ["广州"]) == 21)
}

@Test func asyncLet并发求和() async {
    #expect(await pairSum(cityA: "广州", cityB: "哈尔滨") == 13)
    #expect(await pairSum(cityA: "北京", cityB: "北京") == 4)
}

@Test func taskGroup聚合排序() async {
    let gathered = await gatherTemperatures(cities: ["北京", "上海", "成都", "广州", "哈尔滨"])
    #expect(gathered.map(\.temp) == [-8, 2, 9, 12, 21])
    #expect(gathered.first?.city == "哈尔滨")
    #expect(gathered.count == 5)
    #expect(await gatherTemperatures(cities: []).isEmpty)
}

@Test func 协作式取消() async {
    let result = await countdown(from: 100)
    #expect(result.contains("被取消"))
    #expect(await countdownUncancelled(from: 5) == "跑完全程 5 步")
    #expect(await countdownUncancelled(from: 1) == "跑完全程 1 步")
}

@Test func asyncStream遍历() async {
    var collected: [Int] = []
    for await n in numberStream(3) {
        collected.append(n)
    }
    #expect(collected == [1, 2, 3])
}
