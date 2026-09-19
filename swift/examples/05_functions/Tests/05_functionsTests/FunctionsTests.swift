// 05_functions 的 swift-testing 测试
import Testing

@testable import Ch05Functions

@Test func 参数标签() {
    #expect(greet(person: "小明", from: "成都") == "你好 小明，来自成都")
    #expect(absoluteValue(-7) == 7)
    #expect(absoluteValue(7) == 7)
    #expect(absoluteValue(0) == 0)
}

@Test func 默认参数() {
    #expect(power(3) == 9)
    #expect(power(2, exponent: 10) == 1024)
    #expect(power(9, exponent: 0) == 1)
    #expect(power(-2) == 4)
}

@Test func swap原地交换() {
    var a = 1
    var b = 99
    swapValues(&a, &b)
    #expect(a == 99 && b == 1)
    swapValues(&a, &b)
    #expect(a == 1 && b == 99)
}

@Test func 变参() {
    #expect(sum() == 0)
    #expect(sum(1, 2, 3, 4, 5) == 15)
    #expect(average(1, 2, 3) == 2)
    #expect(average() == 0)
}

@Test func 函数作为值() {
    let add: Operation = { $0 + $1 }
    #expect(apply(add, 2, 3) == 5)
    #expect(apply(makeOperation(opSymbol: "×")!, 6, 7) == 42)
    #expect(makeOperation(opSymbol: "÷") == nil)
}

@Test func 重载按参数类型分发() {
    #expect(describe(42) == "整数 42")
    #expect(describe("swift") == "字符串「swift」")
    #expect(describe(false) == "假")
}

@Test func 嵌套函数捕获状态() {
    let next = counterMaker(start: 10)
    #expect(next() == 11)
    #expect(next() == 12)
    #expect(next() == 13)
    let other = counterMaker(start: 0)
    #expect(other() == 1)  // 各计数器互不干扰
}
