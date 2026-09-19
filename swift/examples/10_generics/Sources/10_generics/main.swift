// 10 · 泛型——泛型函数/类型、约束、where、关联类型、some/any 深入

import Foundation

// ═══ 10.1 纯函数区（供测试）
// 泛型函数 + 约束：T 必须可比，才能找最大
func maximum<T: Comparable>(_ items: [T]) -> T? {
    guard var best = items.first else { return nil }
    for item in items.dropFirst() where item > best {
        best = item
    }
    return best
}

// where 子句：元素级的约束写不进尖括号时，用 where 追加
func countMatches<S: Sequence>(_ sequence: S, _ target: S.Element) -> Int
where S.Element: Equatable {
    sequence.filter { $0 == target }.count
}

// 泛型类型：一个栈，元素类型调用时定
struct Stack<Element> {
    private var items: [Element] = []

    var count: Int { items.count }
    var isEmpty: Bool { items.isEmpty }

    mutating func push(_ item: Element) {
        items.append(item)
    }

    mutating func pop() -> Element? {
        items.popLast()
    }
}

extension Stack where Element: Equatable {  // 条件 conform：元素可比时才有此能力
    func contains(_ item: Element) -> Bool {
        items.contains(item)
    }
}

// 泛型 + 协议关联类型：IteratorProtocol 的迷你版
struct Countdown: Sequence {
    let start: Int

    struct Iterator: IteratorProtocol {
        var current: Int
        mutating func next() -> Int? {
            guard current > 0 else { return nil }
            defer { current -= 1 }
            return current
        }
    }

    func makeIterator() -> Iterator {
        Iterator(current: start)
    }
}

func sum<S: Sequence>(of numbers: S) -> Int where S.Element == Int {
    var total = 0
    for n in numbers { total += n }
    return total
}

// 泛型约束链：T Comparable → 可排序；返回仍收窄为 Array
func topThree<T: Comparable>(_ items: [T]) -> [T] {
    Array(items.sorted().reversed().prefix(3))
}

// ═══ 10.2 泛型函数：同一套逻辑，类型安全地服务多种类型
precondition(maximum([3, 1, 4, 1, 5, 9, 2, 6]) == 9)
// String 的 Comparable 按 Unicode 标量序：樱(U+6A31) < 苹(U+82F9) < 香(U+9999)
precondition(maximum(["苹果", "香蕉", "樱桃"]) == "香蕉")
precondition(maximum([Int]()) == nil)
print("max 整数 \(maximum([3, 1, 4, 1, 5, 9, 2, 6])!)，max 字符串 \(maximum(["苹果", "香蕉", "樱桃"])!)")

// ═══ 10.3 泛型类型 Stack
var stack = Stack<Int>()
stack.push(1)
stack.push(2)
stack.push(3)
precondition(stack.contains(2))  // 条件 conform 生效（Int 是 Equatable）
precondition(stack.pop() == 3 && stack.pop() == 2 && stack.pop() == 1 && stack.pop() == nil)
print("Stack 弹空后 isEmpty = \(stack.isEmpty)")

var wordStack = Stack<String>()
wordStack.push("甲")
wordStack.push("乙")
// wordStack.contains("甲")  // ✅ String 也是 Equatable
// stack.push("丙")          // ❌ 编译错误：Stack<Int> 不吃 String——泛型是编译期类型安全

// ═══ 10.4 关联类型：Sequence 协议族
let countdown = Array(Countdown(start: 5))
print("Countdown(5) = \(countdown)")
precondition(countdown == [5, 4, 3, 2, 1])
precondition(sum(of: Countdown(start: 100)) == 5050)  // 泛型函数吃任意 Int Sequence

// ═══ 10.5 约束的威力：topThree 对任意可比序列
print("topThree = \(topThree([3, 1, 4, 1, 5, 9, 2, 6]))")
precondition(topThree([3, 1, 4, 1, 5, 9, 2, 6]) == [9, 6, 5])

// ═══ 10.6 where 约束：countMatches 吃任意"元素可比"的序列
print("Countdown(5) 里 3 出现 \(countMatches(Countdown(start: 5), 3)) 次")
print("数组里 \"a\" 出现 \(countMatches(["a", "b", "a"], "a")) 次")
precondition(countMatches(Countdown(start: 5), 3) == 1)
precondition(countMatches(["a", "b", "a"], "a") == 2)

print("==== 10 结束 ====")
