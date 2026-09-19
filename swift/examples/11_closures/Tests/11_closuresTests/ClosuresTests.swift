// 11_closures 的 swift-testing 测试
import Testing

@testable import Ch11Closures

@Test func 双闭包共享捕获() {
    let (increment, reset) = makeCounters()
    #expect(increment() == 1)
    #expect(increment() == 2)
    #expect(increment() == 3)
    reset()
    #expect(increment() == 1)
}

@Test func 捕获列表是值快照() {
    var base = 10
    let snapshot = { [base] in base }
    base = 999
    #expect(snapshot() == 10)
    let reference = { base }
    #expect(reference() == 999)
}

@Test func makeSnapshotCounter() {
    let counter = makeSnapshotCounter(start: 5)
    #expect(counter() == 105)
    #expect(counter() == 105)  // 副本不变
}

@Test func compose组合器() {
    let plusThenDouble = compose(double, increment)
    #expect(plusThenDouble(5) == 12)
    let doubleThenPlus = compose(increment, double)
    #expect(doubleThenPlus(5) == 11)
}

@Test func autoclosure惰性() {
    #expect(orDefault(42, 0) == 42)
    #expect(orDefault(0, 7) == 7)
    #expect(orDefault(0, 0) == 0)
}

@Test func 非逃逸闭包直接用() {
    #expect(processNow(10, transform: { $0 * 3 }) == 30)
    #expect(processNow(7, transform: { $0 - 7 }) == 0)
}

@Test func 高阶函数三件套() {
    let numbers = Array(1...10)
    #expect(numbers.filter { $0 % 2 == 0 } == [2, 4, 6, 8, 10])
    #expect(numbers.map { $0 * $0 }.prefix(3) == [1, 4, 9])
    #expect(numbers.reduce(0, +) == 55)
}
