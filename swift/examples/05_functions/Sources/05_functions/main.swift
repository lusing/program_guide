// 05 · 函数——参数标签、默认值、inout、变参、函数类型、重载、嵌套

import Foundation

// ═══ 5.1 参数标签与省略标签（API 自文档化：调用处读起来像句子）
func greet(person: String, from city: String) -> String {
    "你好 \(person)，来自\(city)"
}

func absoluteValue(_ number: Int) -> Int {
    number < 0 ? -number : number
}

// ═══ 5.2 默认参数值
func power(_ base: Double, exponent: Int = 2) -> Double {
    var result = 1.0
    for _ in 0..<exponent { result *= base }
    return result
}

// ═══ 5.3 inout：函数内修改调用方的变量（传的是引用语义的口子）
func swapValues(_ a: inout Int, _ b: inout Int) {
    let temp = a
    a = b
    b = temp
}

// ═══ 5.4 变参：一个形参收任意个实参（函数内是数组）
func sum(_ numbers: Int...) -> Int {
    numbers.reduce(0, +)
}

func average(_ numbers: Double...) -> Double {
    guard !numbers.isEmpty else { return 0 }
    return numbers.reduce(0, +) / Double(numbers.count)
}

// ═══ 5.5 函数是一等公民：类型、变量、参数、返回
typealias Operation = (Int, Int) -> Int

func makeOperation(opSymbol: String) -> Operation? {
    switch opSymbol {
    case "+": return { $0 + $1 }
    case "×": return { $0 * $1 }
    case "−": return { $0 - $1 }
    default: return nil
    }
}

func apply(_ op: Operation, _ lhs: Int, _ rhs: Int) -> Int {
    op(lhs, rhs)
}

// ═══ 5.6 重载：同名不同签名（返回值也算签名的一部分）
func describe(_ value: Int) -> String {
    "整数 \(value)"
}

func describe(_ value: String) -> String {
    "字符串「\(value)」"
}

func describe(_ value: Bool) -> String {
    value ? "真" : "假"
}

// ═══ 5.7 嵌套函数：隐藏实现 + 捕获外层状态
func counterMaker(start: Int) -> () -> Int {
    var count = start
    func next() -> Int {
        count += 1
        return count
    }
    return next
}

/// 隐式返回与 never（无返回路径的函数）
func crashReporter(message: String) -> Never {
    fatalError("报告：\(message)")  // 演示用；正常示例不会走到这里
}

// ═══ 5.8 演示输出
print(greet(person: "小明", from: "成都"))
print("absoluteValue(-7) = \(absoluteValue(-7))")
print("power(3) = \(power(3))  power(2, exponent: 10) = \(power(2, exponent: 10))")

var x = 1
var y = 99
swapValues(&x, &y)
precondition(x == 99 && y == 1, "swap 断言失败")
print("swap 后 x=\(x) y=\(y)（调用处必须写 &）")

print("sum(1,2,3,4,5) = \(sum(1, 2, 3, 4, 5))  average(1,2,3) = \(average(1, 2, 3))")

if let multiply = makeOperation(opSymbol: "×") {
    print("apply(×, 6, 7) = \(apply(multiply, 6, 7))")
}
print("describe(42) = \(describe(42))")
print("describe(\"swift\") = \(describe("swift"))")
print("describe(true) = \(describe(true))")

let next = counterMaker(start: 10)
precondition(next() == 11 && next() == 12 && next() == 13, "计数器断言失败")
print("计数器 10 → \(next()) → \(next())")

print("==== 05 结束 ====")
