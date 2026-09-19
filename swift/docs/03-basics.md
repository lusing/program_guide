# 03 · 基础类型

> 对应示例：`examples/03_basics/`

## 3.1 let 与 var：不可变是默认

```swift
let goldenRatio = 1.618  // 常量——推断为 Double
var counter = 0          // 变量
counter += 1             // ✅
// goldenRatio = 1.414   // ❌ error: cannot assign to value: 'goldenRatio' is a 'let' constant
```

Swift 的选择与 Rust（`let` / `let mut`）同族：**默认不可变，要可变必须显式声明**。
编译器还会反过来劝你：一个 `var` 从未被重新赋值时发出警告"never mutated，考虑改 let"。
从 C++ 来的读者可以把 `let` 想成 `const auto`，`var` 想成 `auto`——只是 Swift 里这是
社会共识级别的默认。

类型标注在需要时写：`let poem: String = "静夜思"`。绝大多数场景推断足够；标注出现于
三种时刻——推断不出来（空集合字面量）、想收窄类型（`let x: Double = 5`，字面量 `5`
本可当 Int）、以及给读者看的文档时刻。

## 3.2 基本类型与尺寸表

| 类型 | 说明 | 大小（本机 x86_64） |
|---|---|---|
| `Int` / `UInt` | 平台字长（**默认选它**） | 8 B |
| `Int8/16/32/64`、`UInt8/16/32/64` | 定宽整数 | 1/2/4/8 B |
| `Double` | 64 位浮点（**默认浮点**） | 8 B |
| `Float` | 32 位浮点 | 4 B |
| `Bool` | `true` / `false` | 1 B |
| `Character` | 一个 Unicode 字位（grapheme cluster） | 16 B（类型有存储） |
| `String` | Unicode 字符串（14 章专讲） | 16 B（小字符串优化看实现） |
| `Range`/元组等 | 03.6 / 03.7 | — |

实测代码（示例 3.4 节）：

```swift
print("Int=\(MemoryLayout<Int>.size)B  Int8=\(MemoryLayout<Int8>.size)B  "
    + "Double=\(MemoryLayout<Double>.size)B  Bool=\(MemoryLayout<Bool>.size)B")
// Int=8B  Int8=1B  Double=8B  Bool=1B
```

`MemoryLayout<T>.size` 是编译期可知的尺寸三件套（size/stride/alignment）之一——
对标 C++ 的 `sizeof`。整数的极值用静态属性：`Int.max`、`Int.min`、`UInt8.max`。

两个使用纪律：

- **整数默认 `Int`**：即使值域很小也用 `Int`，除非内存布局或协议要求（网络协议、
  文件格式）才换定宽——`UInt8` 与 `Int` 混运处处显式转换，自找麻烦。
- **浮点默认 `Double`**：`Float` 只在批量存储（图形学顶点、音频采样）时用。

## 3.3 字面量：比 C 多三种写法

```swift
let binary = 0b1010        // 二进制 10
let octal = 0o17           // 八进制 15
let hex = 0xFF             // 十六进制 255
let grouped = 1_000_000    // 下划线分组，纯可读性
let scientific = 1.25e3    // 指数 1250.0
let millionDouble = 2.5e-3 // 0.0025
```

字面量本身没有类型，是"上下文要求的类型"定了它：`let x: Double = 5` 里 5 是 Double；
`5 & 1` 里 5 是 Int。整数与浮点字面量可以互转（`let y: Double = 1 + 0.5` 合法），
但**已定型的变量之间不行**——见 3.5。

## 3.4 溢出：默认崩溃，& 家族显式回绕

```swift
// let overflow: UInt8 = UInt8.max + 1   // ❌ 编译期即报错（常量折叠后就超界）
// var u: UInt8 = 250; u += 10           // ❌ 运行期 trap（进程崩溃，不是 UB！）
let wrapped = UInt8.max &+ 1             // ✅ 回绕到 0——你说了算
```

这是 Swift 与 C/C++ 的分水岭之一：**有符号算术溢出在 Swift 是确定的运行期错误**
（trap），不是未定义行为。真想模拟 CPU 回绕语义（哈希、加密），用 `&+` `&-` `&*`。

对比表：

| 场景 | C/C++ | Swift |
|---|---|---|
| 有符号溢出 | UB（优化后可能错飞） | trap，进程终止 |
| 想要回绕 | 依赖 UB 或转型 uint | `&+` 家族，明确合法 |
| 编译期可判溢出 | UB 依旧 | 直接编译错误 |

## 3.5 无隐式数值转换：C 背景第一大坑

```swift
let intVal = 42
let doubleVal = Double(intVal)   // ✅ 显式构造
// let bad = intVal + 1.5        // ❌ error: binary operator '+' cannot be applied to Int and Double
let wide: Int64 = 7
// let narrow = intVal + wide    // ❌ Int 与 Int64 也不能混！
```

**任何**数值类型混算都要先显式转换，包括 `Int` 与 `Int64` 这种同宽度不同名。
初学很烦，实战收益是溢出语义与精度损失全部摆上明面——`Double(intVal)` 看得见，
隐式提升看不见。转换可能失败的（`Double("3.14")`）返回可选值，06 章接续。

## 3.6 元组：匿名小结构

```swift
let httpSuccess = (code: 200, message: "OK")
print("HTTP \(httpSuccess.code) \(httpSuccess.message)")   // 命名分量

let pair = (3, 5)                    // 也可以不命名
let (lo, hi) = (pair.0, pair.1)      // 解构

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
```

元组适合"临时打 包两三个值"：函数多返回值（`minMax`）、`enumerated()` 的
`(index, element)`、字典遍历的 `(key, value)`。它没有标识类型、不能 conform 协议
（除按位比较）——一旦这个形状开始到处传播，就该升级成 `struct`（07 章）。

坑：元组不能整体当字典键/Set 元素（不 Hashable）；可选元组的比较要解包后比
（`minMax(of: xs)! == (min: 1, max: 2)`，或逐分量比较——教程测试里两种都写了）。

## 3.7 Bool 与 Character：两个"不能凑合"的类型

```swift
let isSwift = true
// if 1 { }        // ❌ 条件必须是 Bool——整数不当布尔用
// let n = isSwift + 1  // ❌ Bool 也不当数字

let initial: Character = "唐"    // 单个字位
let poem = "床前明月光"
print(poem.count)                 // 5——注意不是字节数（14 章深讲）
```

- 条件表达式必须是 `Bool`：`if someInt {}` 编译不过——C 里"非零即真"的口子被焊死。
- `Character` 是**一个字位**（可能由多个 Unicode 标量组成，如 `"é"` 或国旗 emoji），
  不是字节也不是 UTF-16 码元。`"a"` 是 Character，`"ab"` 是 String。

## 3.8 坑位清单

1. **元组比较与可选提升**：`optionalTuple == (a, b)` 编译不过（元组的 == 是编译器
   魔法，不参与 Optional 提升）——用 `!` 解包或逐分量比较。
2. **`Bool` 与数字零互转不存在**：`Int(bool)` 没有这个构造；需要 `b ? 1 : 0`。
3. **整数下溢同样 trap**：`UInt8.min - 1` 崩；`0 &- 1` 得 255（回绕）。教学口诀：
   普通运算符=崩溃告诉我，`&` 运算符=回绕我认了。
4. **`Int` 就是 `Int64`**（64 位平台），但**是两个名字不能混算**——`Int(1) + Int64(1)`
   都要转换。写库接口时参数统一用 `Int` 最省心。
5. **`MemoryLayout<T>.size` 与 `stride`**：结构体有 padding 时 size ≠ stride，
   算偏移用 stride（07 章结构体布局时回来对照）。
6. **字面量 `5` 可以是任何数值类型，变量不行**：`let d: Double = 5` 合法（5 直接
   定型为 Double），但 `let i = 5; let d2 = i + 0.5` 非法——定型后的 i 就钉死 Int。

上一章：[02 · 第一个程序](02-hello.md) ｜ 下一章：[04 · 控制流](04-control.md) ｜ 返回：[README](../README.md)
