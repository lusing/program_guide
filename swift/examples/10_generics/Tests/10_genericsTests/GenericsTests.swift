// 10_generics 的 swift-testing 测试
import Testing

@testable import Ch10Generics

@Test func maximum多类型() {
    #expect(maximum([3, 1, 4, 1, 5, 9, 2, 6]) == 9)
    #expect(maximum(["苹果", "香蕉", "樱桃"]) == "香蕉")  // Unicode 标量序：香(U+9999) 最大
    #expect(maximum([Double.pi, 2.71]) == Double.pi)
    #expect(maximum([42]) == 42)
    #expect(maximum([Int]()) == nil)
}

@Test func stack推弹() {
    var stack = Stack<Int>()
    #expect(stack.isEmpty)
    stack.push(1)
    stack.push(2)
    #expect(stack.count == 2)
    #expect(!stack.isEmpty)
    #expect(stack.pop() == 2)
    #expect(stack.pop() == 1)
    #expect(stack.pop() == nil)
}

@Test func stack条件conform() {
    var stack = Stack<String>()
    stack.push("甲")
    stack.push("乙")
    #expect(stack.contains("甲"))
    #expect(!stack.contains("丙"))
}

@Test func countdown序列() {
    #expect(Array(Countdown(start: 5)) == [5, 4, 3, 2, 1])
    #expect(Array(Countdown(start: 0)) == [])
    #expect(Countdown(start: 3).map { $0 * 10 } == [30, 20, 10])
}

@Test func 泛型吃任意Sequence() {
    #expect(sum(of: Countdown(start: 100)) == 5050)
    #expect(sum(of: [1, 2, 3]) == 6)
    #expect(sum(of: 0..<5) == 10)
}

@Test func topThree排序() {
    #expect(topThree([3, 1, 4, 1, 5, 9, 2, 6]) == [9, 6, 5])
    #expect(topThree([1, 2]) == [2, 1])
    #expect(topThree([Int]()) == [])  // 空数组要显式给类型，否则推断成 [Any]
    #expect(topThree(["c", "a", "b", "d"]) == ["d", "c", "b"])
}

@Test func where约束计数() {
    #expect(countMatches(Countdown(start: 5), 3) == 1)
    #expect(countMatches(["a", "b", "a"], "a") == 2)
    #expect(countMatches([1, 1, 1], 1) == 3)
    #expect(countMatches(0..<10, 9) == 1)
}
