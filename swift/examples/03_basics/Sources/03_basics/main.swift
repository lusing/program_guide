// 03 · 基础类型——let/var、推断、字面量、溢出、显式转换、元组

import Foundation

// ═══ 3.1 let 不可变 / var 可变（编译器强制，不是约定）
let goldenRatio = 1.618  // 类型推断为 Double
var counter = 0
counter += 1
precondition(counter == 1, "counter 断言失败")

// ═══ 3.2 纯函数区（供测试）
func clamp(_ value: Double, low: Double, high: Double) -> Double {
    min(max(value, low), high)
}

func minMax(of numbers: [Int]) -> (min: Int, max: Int)? {
    guard let first = numbers.first else { return nil }
    var lo = first
    var hi = first
    for n in numbers.dropFirst() {
        if n < lo { lo = n }
        if n > hi { hi = n }
    }
    return (lo, hi)
}

/// 安全字节转十六进制（演示 Int 显式构造 + 格式化）
func hexByte(_ byte: UInt8) -> String {
    String(format: "%02X", byte)
}

// ═══ 3.3 整数家族与字面量（0b/0o/0x、下划线分组、指数）
let binary = 0b1010  // 10
let octal = 0o17  // 15
let hex = 0xFF  // 255
let grouped = 1_000_000  // 下划线只为可读
let scientific = 1.25e3  // 1250.0
print("0b1010=\(binary) 0o17=\(octal) 0xFF=\(hex) 1_000_000=\(grouped) 1.25e3=\(scientific)")
precondition(binary == 10 && octal == 15 && hex == 255 && scientific == 1250.0)

// ═══ 3.4 尺寸与极值（Windows x86_64：Int = Int64 = 8 字节）
print(
    "Int=\(MemoryLayout<Int>.size)B  Int8=\(MemoryLayout<Int8>.size)B  "
        + "Double=\(MemoryLayout<Double>.size)B  Bool=\(MemoryLayout<Bool>.size)B")
print("Int.max=\(Int.max)  Int.min=\(Int.min)")
print("UInt8.max=\(UInt8.max) → 十六进制 \(hexByte(UInt8.max))")

// ═══ 3.5 溢出：普通运算符会 trap（崩溃），& 家族回绕
// let overflow: UInt8 = UInt8.max + 1        // ❌ 编译期即报错
// var u: UInt8 = 250; u += 10                 // ❌ 运行期 trap（EXC_BAD_INSTRUCTION 类）
let wrapped = UInt8.max &+ 1  // 回绕到 0
precondition(wrapped == 0, "回绕断言失败")
print("UInt8.max &+ 1 = \(wrapped)（回绕而非崩溃）")

// ═══ 3.6 无隐式数值转换——必须显式构造（C 背景第一大坑）
let intVal = 42
let doubleVal = Double(intVal)  // 显式：Double(42)
let back = Int(doubleVal)
precondition(back == intVal)
print("Int→Double→Int：\(intVal) → \(doubleVal) → \(back)")
print("clamp(3.7, 0...1 风格) = \(clamp(3.7, low: 0, high: 1))")

// ═══ 3.7 元组：轻量匿名结构（命名分量 + 解构）
let httpSuccess = (code: 200, message: "OK")
print("HTTP \(httpSuccess.code) \(httpSuccess.message)")
if let range = minMax(of: [3, 1, 4, 1, 5, 9, 2, 6]) {
    let (lo, hi) = (range.min, range.max)  // 解构
    print("minMax → 最小 \(lo)，最大 \(hi)")
}
precondition(minMax(of: []) == nil, "空数组应返回 nil")

// ═══ 3.8 Character 与 String 初识（14 章深讲）
let initial: Character = "唐"
let poem = "床前明月光"
print("首字 \(initial)，诗句长度（字符数）=\(poem.count)")

print("==== 03 结束 ====")
