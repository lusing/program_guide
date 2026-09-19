# 05 · 函数

> 对应示例：`examples/05_functions/`

## 5.1 参数标签：让调用读起来像句子

```swift
func greet(person: String, from city: String) -> String {
    "你好 \(person)，来自\(city)"
}
print(greet(person: "小明", from: "成都"))
//        ↑ 外部标签        ↑ 外部标签

func absoluteValue(_ number: Int) -> Int { number < 0 ? -number : number }
print(absoluteValue(-7))   // _ = 调用处省略标签
```

每个参数有**两个名字**：外部标签（调用者写）+ 内部名（函数体用）。`from city` 的
读法是"from 成都"（标签）+"city"（体内）。`_` 表示不要外部标签。

设计惯例（Swift API Design Guidelines 的核心一条）：

- 第一个参数若不能与函数名连读成自然短语，就加 `_` 省掉（`absoluteValue(-7)`）；
- 其余参数**默认给标签**——调用处自带文档：`greet(person: "小明", from: "成都")`
  不看签名也知道第三个参数是什么意思。
- 对比 Go/C 的 positional 参数：大型调用 `f(x, y, true, false, nil)` 里 true 是什么
  意思？标签就是答案。

标签参与**函数签名**：`f(a:b:)` 与 `f(a:)` 是不同的函数（配合 5.6 重载）。

## 5.2 默认参数值

```swift
func power(_ base: Double, exponent: Int = 2) -> Double {
    var result = 1.0
    for _ in 0..<exponent { result *= base }
    return result
}
power(3)                 // 9（exponent 用默认值 2）
power(2, exponent: 10)   // 1024
```

带默认值的参数调用时可省——省略时形参从后往前连着省。与 C++ 一致的语义，但没有
"C++ 最恼人解析"那类歧义（Swift 参数必须带标签或 `_`，语法上分得清）。

## 5.3 inout：借用一下你的变量

```swift
func swapValues(_ a: inout Int, _ b: inout Int) {
    let temp = a
    a = b
    b = temp
}
var x = 1
var y = 99
swapValues(&x, &y)     // 调用处必须写 &——明示"这个变量可能被改"
print(x, y)            // 99 1
```

Swift 的参数默认是不可变的**值拷贝**；`inout` 打开"函数内修改调用方变量"的口子。
`&` 不是 C 的取地址——它是调用处的**警示灯**：读代码时一眼看出谁可能被改。

三条纪律：

1. 传入的必须是**变量**（`var`），不能是常量或字面量：`swapValues(&1, &2)` 编译不过。
2. 同一个变量不能在一次调用里传两个 inout 参数（独占访问，16 章内存安全细讲）。
3. 能用返回值就用返回值——inout 留给 swap、`remove(at:)` 这类"就地修改"语义。

## 5.4 变参：一个形参收一串

```swift
func sum(_ numbers: Int...) -> Int {
    numbers.reduce(0, +)     // 函数体内 numbers 就是 [Int]
}
sum()              // 0
sum(1, 2, 3, 4, 5) // 15

func average(_ numbers: Double...) -> Double {
    guard !numbers.isEmpty else { return 0 }
    return numbers.reduce(0, +) / Double(numbers.count)
}
```

`Int...` 声明变参，调用处展开任意个实参；函数体内它就是数组。一个函数至多一个
变参参数。`reduce(0, +)` 是"求和"的惯用姿势（11 章闭包章展开）。

## 5.5 函数是一等公民

```swift
typealias Operation = (Int, Int) -> Int     // 函数类型起名

func makeOperation(opSymbol: String) -> Operation? {
    switch opSymbol {
    case "+": return { $0 + $1 }            // 闭包表达式，返回给调用方
    case "×": return { $0 * $1 }
    default: return nil
    }
}

func apply(_ op: Operation, _ lhs: Int, _ rhs: Int) -> Int {
    op(lhs, rhs)                             // 函数值直接调用
}

if let multiply = makeOperation(opSymbol: "×") {
    print(apply(multiply, 6, 7))             // 42
}
```

函数能存进变量、当参数传、当返回值——这三件事是 11 章闭包与 17 章异步回调的地基。
`() -> Int`、`(Int, Int) -> Int` 都是正经类型，`typealias` 给它们上人类名字。

## 5.6 重载：同名不同签名

```swift
func describe(_ value: Int) -> String { "整数 \(value)" }
func describe(_ value: String) -> String { "字符串「\(value)」" }
func describe(_ value: Bool) -> String { value ? "真" : "假" }

describe(42)        // 整数 42 —— 按实参类型静态分派
describe("swift")   // 字符串「swift」
describe(true)      // 真
```

规则：**参数列表（含标签与类型）+ 返回值类型**共同构成签名，同名不同签名合法，
调用按实参静态选择。与 C++ 相同的机制，但 Swift 的标签让重载更常用也更安全——
`describe` 一家三口是"同一意图，三种输入"的惯用形态。

注意与**泛型**（10 章）的分界：对"任意类型同一套逻辑"用泛型，对"不同类型各自
一套逻辑"用重载。`describe` 若三种类型都要不同输出，重载正合适。

## 5.7 嵌套函数与隐式返回

```swift
func counterMaker(start: Int) -> () -> Int {
    var count = start          // 嵌套函数捕获外层 var——11 章深讲捕获语义
    func next() -> Int {
        count += 1
        return count
    }
    return next                // 把内层函数返回出去
}
let next = counterMaker(start: 10)
next()   // 11
next()   // 12
```

嵌套函数用于"只属于这个函数的辅助逻辑"；它捕获外层变量并随返回值逃逸——这就是
计数器（closure 的最小实例），16 章会看到它持有状态的内存代价。

单表达式函数的 `{ a + b }` 是**隐式返回**——表达式即返回值，`return` 可省（对
`-> Never` 的函数，如 `fatalError(...)`，永远不返回，编译器懂）。

## 5.8 坑位清单

1. **inout 传字面量/常量/同一变量两次**都是编译错误；`&` 是警示灯不是取地址——
   别拿 C 的指针直觉去理解它（真指针在 23 章 C 互操作里才出现）。
2. **变参在函数体内是数组**，但调用处不能传数组进去：`sum([1,2,3])` 编译不过
   （要传数组就再写个收数组的重载，或 `sum(numbers...)` 的字面量展开——不适用）。
3. **重载解析不看返回值上下文时可能歧义**：`let x = describe(...)` 若两个重载仅
   返回值不同且都能匹配实参，编译器报 ambiguous——设计重载时参数类型要有区分度。
4. **默认参数 + 标签省略的组合**会让调用形式剧增：`power(2, exponent: 10)` 与
   `power(2)` 都合法；文档注释里写清默认值语义（本例"默认平方"）。
5. **嵌套函数捕获的是变量本身**（引用语义），不是创建时的值副本——`counterMaker`
   的两个实例各自独立（每次调用新栈帧），但同一实例内共享 count（16 章 ARC 展开）。
6. **`Never` 返回型函数不能漏分支**：`crashReporter` 里只写 `fatalError` 就完整；
   若还有 return 路径反而类型不匹配——编译器用类型系统记住"这函数回不来"。

上一章：[04 · 控制流](04-control.md) ｜ 下一章：[06 · 可选类型](06-optionals.md) ｜ 返回：[README](../README.md)
