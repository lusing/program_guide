# 10 · 泛型

> 对应示例：`examples/10_generics/`

## 10.1 泛型函数：一套逻辑，类型安全地服务多种类型

```swift
func maximum<T: Comparable>(_ items: [T]) -> T? {
    guard var best = items.first else { return nil }
    for item in items.dropFirst() where item > best {
        best = item
    }
    return best
}

maximum([3, 1, 4, 1, 5, 9, 2, 6])        // 9
maximum(["苹果", "香蕉", "樱桃"])          // "香蕉"——String 也 Comparable
maximum([Int]())                          // nil
```

尖括号里的 `T` 是**类型参数**，`T: Comparable` 是**约束**——"什么类型都行，只要
可比"。调用时类型实参自动推断（不需要写 `maximum<Int>(...)`）。

与"用 `Any` + 强转"的假泛型对比：泛型在**编译期**钉死类型——`Stack<Int>` 塞不进
String（编译错误），`Any` 版本运行期才崩。与 C++ 模板对比：Swift 泛型是**类型系统
内的参数化**（不是宏展开），约束即接口，报错信息讲人话。

## 10.2 泛型类型

```swift
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

var stack = Stack<Int>()
stack.push(1)
// stack.push("丙")    // ❌ 编译错误：Stack<Int> 不吃 String
var wordStack = Stack<String>()
```

类型参数贯穿属性、方法、返回值——`Stack<Int>` 与 `Stack<String>` 是两个独立类型。
**同一套源码，编译期为你用到的每种类型实例化**（静态特化或见证表分发，实现细节
不影响语义）。

## 10.3 约束的三种写法

```swift
// ① 尖括号内直接约束
func maximum<T: Comparable>(_ items: [T]) -> T?

// ② where 子句：约束复杂时的正身（可约束关联类型）
func sum<S: Sequence>(of numbers: S) -> Int where S.Element == Int {
    var total = 0
    for n in numbers { total += n }
    return total
}

// ③ 多约束用 & 组合
func weight<T: Comparable & Hashable>(_ x: T) -> Int { x.hashValue }
```

`sum(of:)` 接受**任何**元素为 Int 的 Sequence——数组、Range、自定义 Countdown 全
收。示例里 `sum(of: Countdown(start: 100)) == 5050` 与 `sum(of: 0..<5) == 10` 用的
同一个函数。这就是标准库算法的设计方式：`Sequence`/`Collection` 约束 + 关联类型
`where`。

**限制**：`where A == B`（两个类型参数划等号）在函数上是**非法**的——报
`same-type requirement makes generic parameters equivalent`（示例实测踩到）。表达
"两种相同类型"用单类型参数即可。

## 10.4 关联类型：协议里的泛型

```swift
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
```

`Sequence` 协议内部有个 `associatedtype Element`——conform 的类型**用具体类型填空**
（Countdown 的 Element 是 Int）。协议不能自己泛型（`Sequence<T>` ❌），关联类型就是
它的类型参数；泛型函数用 `where S.Element == Int` 消费它。

手写 Iterator 三步：包一个可变状态 → `next()` 返回 `Element?`（nil = 迭代结束）→
`Sequence` 的 `makeIterator()` 交出去。之后 `for-in`、`map`、`filter`、`Array(...)`
全套免费——`countdown.map { $0 * 10 }` 直接能用。

## 10.5 条件 conformance：约束到才有能力

```swift
extension Stack where Element: Equatable {
    func contains(_ item: Element) -> Bool {
        items.contains(item)
    }
}
```

`Stack` 本身不知道元素可不可比；**元素是 Equatable 时**，这个 extension 给它补上
`contains`。`Stack<Int>` 有此方法，`Stack<SomeCustomNonEquatable>` 没有——能力随
约束按需生长。标准库同理：`Array` 只在 `Element: Comparable` 时才有 `sorted()`。

## 10.6 some 与不透明类型：泛型的反向

```swift
func makeNumbers() -> some Sequence<Int> {   // 返回"某个"具体类型，调用方看不见
    Countdown(start: 5)
}
```

泛型是"调用方定类型，函数体适配"；`some` 是反过来——"函数定类型（编译期已定死），
调用方只知道它满足协议"。收益：**抽象不付存在类型的装箱钱**（对比 `any Sequence`
的运行期盒子）。09 章讲了参数位的 some；返回位同理，且最常见的舞台是
`some View`（SwiftUI 的地基，虽然本教程不涉及 UI）。

## 10.7 泛型 or 协议 or 重载？选型速查

| 场景 | 用什么 |
|---|---|
| 同一套逻辑、任意满足约束的类型 | **泛型**（maximum/Stack） |
| 不同类型各自一套逻辑 | **重载**（05 章 describe 一家三口） |
| 需要异构容器/运行期换实现 | **any 协议**（09 章 renderAny） |
| 只想隐藏返回值的具体类型 | **some**（10.6） |

## 10.8 坑位清单（含实测）

1. **`where A == B` 同型约束在函数上非法**（实测报
   `same-type requirement makes generic parameters 'B' and 'A' equivalent`）——
   一个类型参数就够了，别写两个再画等号。
2. **空数组字面量推断成 `[Any]`**（实测）：`topThree([]) == []` 报
   `type 'Any' cannot conform to 'Comparable'`——写 `topThree([Int]())` 给编译器
   一个类型锚点。
3. **String 的 Comparable 是 Unicode 标量序**（实测好坑）：
   `maximum(["苹果", "香蕉", "樱桃"])` 是 **"香蕉"**——按首字标量
   樱(U+6A31) < 苹(U+82F9) < 香(U+9999)。中文"大小序"与拼音/笔画无关，
   要拼音排序自己实现（14 章字符串再会）。
4. **泛型函数吃 Sequence 时别急着 `Array(...)`**：约束已经保证可遍历，转数组是
   O(n) 白拷贝——除非要多次遍历或下标访问。
5. **关联类型协议（如 Sequence）不能当 `some` 返回值裸用**——`some Sequence` 还行，
   `Sequence` 裸类型在 Swift 6 模式下要求显式 `any`，且作为泛型约束时必须配
   `where Element == ...`。
6. **过度泛化**：只有一个调用点的"泛型"，约束比实现还长——先写具体版本，第二个
  使用场景出现时再泛化（YAGNI 同样适用于类型参数）。

上一章：[09 · 协议](09-protocols.md) ｜ 下一章：[11 · 闭包](11-closures.md) ｜ 返回：[README](../README.md)
