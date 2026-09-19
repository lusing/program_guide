// 15_extensions 的 swift-testing 测试
import Testing

@testable import Ch15Extensions

@Test func int扩展() {
    #expect(4.isEven)
    #expect(!7.isEven)
    #expect(0.isEven)
    #expect((-3).squared == 9)
}

@Test func times执行() {
    var collected: [Int] = []
    3.times { collected.append($0) }
    #expect(collected == [1, 2, 3])
}

@Test func titleCased() {
    #expect("the swift".titleCased == "The Swift")
    #expect("single".titleCased == "Single")
    #expect("".titleCased == "")
}

@Test func 安全下标() {
    let text = "swift"
    #expect(text[safe: 0] == "s")
    #expect(text[safe: 4] == "t")
    #expect(text[safe: 5] == nil)  // 越界
    #expect(text[safe: -1] == nil)
}

@Test func median约束扩展() {
    #expect([3, 1, 2].median == 2)
    #expect([1, 2, 3, 4].median == 3)  // count/2 = 2 → 排序后第 3 个
    #expect([Int]().median == nil)
    #expect(["a", "c", "b"].median == "b")
}

@Test func clamped包装器() {
    let s = makeSettings(volume: 42, brightness: -5)
    #expect(s.volume == 10)
    #expect(s.brightness == 0)
    let normal = makeSettings(volume: 7, brightness: 50)
    #expect(normal.volume == 7)
    #expect(normal.brightness == 50)
}

@Test func retroactive描述() {
    #expect(Meter(value: 3.5).description == "3.5m")
    #expect(Meter(value: 0).description == "0.0m")
}
