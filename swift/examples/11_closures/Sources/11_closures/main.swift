// 11 · 闭包——捕获语义、逃逸/非逃逸、尾随闭包、高阶函数、@autoclosure、lazy

import Foundation

// ═══ 11.1 纯函数区（供测试）
func makeCounters() -> (increment: () -> Int, reset: () -> Void) {
    var count = 0
    return (
        {
            count += 1
            return count
        },  // 两个闭包共享同一个 count（引用捕获）
        { count = 0 }
    )
}

/// 捕获列表 [value = value]：捕获创建时的值副本（值语义快照）
func makeSnapshotCounter(start: Int) -> () -> Int {
    var value = start
    return { [value] in value + 100 }  // 捕获的是副本：无论外面怎么改 value
}

/// 高阶函数实战：组合器。@escaping：闭包逃出函数生命周期（存进返回值），必须显式标注
func compose<A, B, C>(_ f: @escaping (B) -> C, _ g: @escaping (A) -> B) -> (A) -> C {
    { x in f(g(x)) }
}

func double(_ x: Int) -> Int { x * 2 }
func increment(_ x: Int) -> Int { x + 1 }

/// @autoclosure：调用处写表达式，是否求值由函数体决定（&& 短路的原理）
func orDefault(_ value: @autoclosure () -> Int, _ fallback: @autoclosure () -> Int) -> Int {
    let v = value()
    return v != 0 ? v : fallback()
}

/// 非逃逸（默认）：函数返回前必须用完——编译器据此保证安全性
func processNow(_ value: Int, transform: (Int) -> Int) -> Int {
    transform(value)
}

/// 逃逸闭包 + 副作用收集的对照实验
func registerHandler(_ handler: (String) -> String, into log: inout [String]) {
    log.append("注册了一个处理器")
    log.append(handler("注册完成事件"))
}

// ═══ 11.2 闭包表达式语法进化：完整 → 推断 → 简写 → 尾随 → 运算符
let names = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]
let full = names.sorted(by: { (s1: String, s2: String) -> Bool in s1 < s2 })  // ① 完整形态
let inferred = names.sorted(by: { s1, s2 in s1 < s2 })  // ② 类型推断
let shorthand = names.sorted(by: { $0 < $1 })  // ③ 位置参数名
let trailing = names.sorted { $0 < $1 }  // ④ 尾随闭包
let method = names.sorted(by: <)  // ⑤ 运算符函数
print(
    "五种写法等价：\(full == inferred && inferred == shorthand && shorthand == trailing && trailing == method)"
)
precondition(trailing.first == "Alex" && trailing.last == "Ewa")

// ═══ 11.3 捕获语义：闭包捕获的是变量本身（引用），不是创建时的值
let (increment, reset) = makeCounters()
precondition(increment() == 1 && increment() == 2 && increment() == 3)
reset()
precondition(increment() == 1, "reset 后从头计数")
print("计数器：1→2→3→reset→\(increment())")

// ═══ 11.4 捕获列表：要值快照就明说
var base = 10
let snapshot = { [base] in base }  // 捕获此刻的 10
base = 999
precondition(snapshot() == 10, "捕获列表 = 值快照")
let reference = { base }  // 捕获变量本身
precondition(reference() == 999, "普通捕获 = 引用")
print("值快照 \(snapshot()) vs 引用捕获 \(reference())")

// ═══ 11.5 高阶函数三件套 + 组合器
let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
let evens = numbers.filter { $0 % 2 == 0 }
let squared = numbers.map { $0 * $0 }
let total = numbers.reduce(0, +)
print("filter→\(evens) map→\(squared.first!)… reduce→\(total)")
precondition(evens == [2, 4, 6, 8, 10] && squared[0] == 1 && total == 55)

let plusThenDouble = compose(double, increment)  // 先 +1 再 ×2
precondition(plusThenDouble(5) == 12)
print("compose(×2, +1)(5) = \(plusThenDouble(5))")

// ═══ 11.6 @autoclosure 与逃逸/非逃逸
precondition(orDefault(42, 0) == 42)
precondition(orDefault(0, 7) == 7)
print("orDefault(42, 0) = \(orDefault(42, 0))，orDefault(0, 7) = \(orDefault(0, 7))")

var logLines: [String] = []
registerHandler({ event in "处理：\(event)" }, into: &logLines)
print("日志条数 = \(logLines.count)")
precondition(logLines.count == 2)

precondition(processNow(10, transform: { $0 * 3 }) == 30)

// ═══ 11.7 惰性求值序列：闭包产线的延迟本性
var computed: [Int] = []  // 局部变量，记录哪些元素真的被算过
let lazySeq = (1...10).lazy.map { (n: Int) -> Int in
    computed.append(n)
    return n * n
}
let takenTwo = Array(lazySeq.prefix(2))  // 只对前 2 个执行 map（其余不算）
print("lazy 取前 2：\(takenTwo)，实际计算了 \(computed) （应为 [1, 2]）")
precondition(takenTwo == [1, 4] && computed == [1, 2])

print("==== 11 结束 ====")
