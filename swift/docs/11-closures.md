# 11 · 闭包

> 对应示例：`examples/11_closures/`

## 11.1 闭包是什么：自带环境的函数

闭包 = 函数体 + 捕获的环境。Swift 闭包三形态：**全局函数**（不捕获）、**嵌套函数**
（捕获可命名）、**闭包表达式**（轻量匿名，05 章已见过 `{ $0 + $1 }`）。本章主角是后两种
的捕获语义与逃逸规则——这也是 16 章 ARC 与 17 章异步回调的地基。

```swift
func makeCounters() -> (increment: () -> Int, reset: () -> Void) {
    var count = 0
    return (
        { count += 1; return count },   // 两个闭包共享同一个 count
        { count = 0 }
    )
}
let (increment, reset) = makeCounters()
increment()  // 1
increment()  // 2
reset()
increment()  // 1 —— count 是闭包们共同持有的"私有状态"
```

**闭包捕获的是变量本身（引用），不是创建那一刻的值**——这是 Swift 闭包最重要的一句
话。函数返回了，`count` 却活着，因为它被两个闭包引用着（16 章：这是堆上的盒子）。

## 11.2 捕获列表：要值快照就明说

```swift
var base = 10
let snapshot = { [base] in base }   // 捕获此刻 base 的副本
base = 999
snapshot()      // 10
let reference = { base }            // 普通捕获：变量本身
reference()     // 999
```

`[base]`（或 `[value = base]` 带改名）把"捕获引用"改成"捕获值副本"。两个时机用它：

1. 值语义快照（记录此刻状态，之后外界变化与我无关）；
2. **打破引用循环**——`[weak self]` 是它的常客（16 章专讲）。

## 11.3 语法进化五级

```swift
let names = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]
names.sorted(by: { (s1: String, s2: String) -> Bool in s1 < s2 })  // ① 完整
names.sorted(by: { s1, s2 in s1 < s2 })                             // ② 推断参数类型
names.sorted(by: { $0 < $1 })                                       // ③ $0/$1 位置名
names.sorted { $0 < $1 }                                            // ④ 尾随闭包
names.sorted(by: <)                                                 // ⑤ 运算符即函数
```

五级完全等价（示例 precondition 逐一验证）。**尾随闭包**：闭包是最后一个参数时，可以
甩到括号外面——多闭包 API（如 SwiftUI 的动画块）全是这个形态。**$0/$1** 是位置参数名，
超过三个参数还用 $2 $3 就该具名了（可读性红线）。⑤ `(<)` 提示一个事实：运算符就是
函数，能当值传递。

## 11.4 高阶函数三件套 + 组合器

```swift
let evens = numbers.filter { $0 % 2 == 0 }     // 筛
let squared = numbers.map { $0 * $0 }          // 变
let total = numbers.reduce(0, +)               // 聚

func compose<A, B, C>(_ f: @escaping (B) -> C, _ g: @escaping (A) -> B) -> (A) -> C {
    { x in f(g(x)) }
}
let plusThenDouble = compose(double, increment)   // 先 +1 再 ×2
plusThenDouble(5)   // 12
```

`filter/map/reduce` 是集合的标配（13 章更多）；`compose` 展示"函数值"的可组合性——
闭包签名即接口，组合即粘合。注意 `@escaping`：f 和 g 被**返回的闭包持有**，逃出了
函数作用域，必须显式标注。

## 11.5 @escaping 与非逃逸：编译器替你把关

```swift
// 非逃逸（默认）：transform 必须在 processNow 返回前用完
func processNow(_ value: Int, transform: (Int) -> Int) -> Int {
    transform(value)
}

// @escaping：闭包在函数返回后仍存活（存进属性/全局/返回值/异步上下文）
func registerHandler(_ handler: (String) -> String, into log: inout [String]) { ... }
```

默认**非逃逸**（non-escaping）是编译器的安全承诺：闭包在函数栈帧内用完即弃，不可能
产生"闭包持有已释放栈"或引用循环——所以非逃逸闭包里可以放心用 `self`，无需
`weak`。一旦闭包要"活过"函数（存储、异步调度、返回），标 `@escaping`，此刻起
生命周期由你负责（16 章的引用循环几乎都发生在这里）。

## 11.6 @autoclosure：把表达式打包成"以后再算"

```swift
func orDefault(_ value: @autoclosure () -> Int, _ fallback: @autoclosure () -> Int) -> Int {
    let v = value()
    return v != 0 ? v : fallback()   // fallback 只在需要时才求值
}
orDefault(42, 0)   // 42
orDefault(0, 7)    // 7
```

调用处写的是**表达式**（`42`、`7`），编译器自动包成闭包——是否求值由函数体决定。
`&&`/`||` 的短路、`assert` 在 Release 下的消失、`??` 的右侧惰性，全是 @autoclosure
的功劳。慎用：它隐藏了求值时机，API 设计时"惰性"是必要语义才上（如断言、默认值）。

## 11.7 lazy：序列版的闭包惰性

```swift
var computed: [Int] = []
let lazySeq = (1...10).lazy.map { (n: Int) -> Int in
    computed.append(n)
    return n * n
}
let takenTwo = Array(lazySeq.prefix(2))   // computed == [1, 2]，其余 8 个从未计算
```

`sequence.lazy` 把"先全部 map 再取前缀"变成"取到几个算几个"——大数据集过滤/映射
的第一反应。普通 `map` 是急切求值（先建整表），lazy 链是按需拉取（Sequence 体系的
两次出场，10 章关联类型 + 这里）。

## 11.8 坑位清单（含实测）

1. **闭包捕获变量 = 引用**：循环里 `for i in 0..<3 { handlers.append { print(i) } }`
   打出 0 1 2（每次迭代新变量 i）；但把 `var i` 声明在循环外就全员共享——语义差异
   全在"捕获的是哪个变量"。
2. **@escaping 与隔离**：Swift 6 下逃逸闭包跨并发域要 Sendable 检查（18 章），
   非逃逸闭包则豁免——"能不能不逃逸"在新代码里更值得先问一句。
3. **`sorted(by: <)` 需要类型锚点**：裸 `sorted(by: <)` 在元素类型明确时才行，
   泛型上下文里歧义——写成 `{ $0 < $1 }` 稳妥。
4. **lazy 链别复用**：`lazy.map` 的中间序列是"一次性"视图，遍历两遍会重复执行闭包
   （示例的 `computed` 就在验证这一点）——要复用先 `Array(...)` 固化。
5. **@autoclosure 参数不能直接传闭包值**：调用处永远是表达式（再包一层是常见新手
   错误）。
6. **修改捕获的 var 需要 non-const 上下文**：捕获局部 `var` 可改；捕获 `let` 编译
   错误（想让闭包持有可变状态，被捕获的必须是 var）。

上一章：[10 · 泛型](10-generics.md) ｜ 下一章：[12 · 错误处理](12-errors.md) ｜ 返回：[README](../README.md)
