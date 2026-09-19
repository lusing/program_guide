# 09 · 协议

> 对应示例：`examples/09_protocols/`

## 9.1 协议即契约

```swift
protocol Drawable {
    var label: String { get }     // { get } = 至少可读（实现方可给 var）
    func draw() -> String
}

struct Circle: Drawable {
    let label = "圆"
    var radius: Double
    func draw() -> String { "◯ 半径 \(radius)" }
}
```

协议是**能力的声明**：谁 conform 谁就得提供这些成员。与 Java/C# 接口的表亲关系
明显，但 Swift 把它玩出了两个新高度：

1. **值类型（struct/enum）也能 conform**——协议不是类的专利；
2. **extension 默认实现**——协议可以带"免费午餐"方法，conformance 只需补差异项。

选型直觉：**继承回答"你是什么"（is-a），协议回答"你会什么"（can-do）**。Swift 的
多态主力是后者。

## 9.2 extension 默认实现：面向协议编程的核心

```swift
extension Drawable {
    func draw() -> String {
        "【\(label)】用默认画笔绘制"      // 用协议声明的 label 拼默认行为
    }

    func drawTwice() -> String {          // 完全由默认实现提供的新能力
        draw() + " ×2"
    }
}

struct Square: Drawable {
    let label = "方"
    var side: Double
    // 不写 draw() → 自动用协议默认实现
}
```

- 实现方**不写就继承默认，写了就覆盖**——协议从"纯契约"升级为"契约 + 基类行为"，
  却没有继承树的耦合（任何类型随时补票上车）。
- 默认实现里只能用协议声明的成员——这正是它跨类型复用的原因。
- 标准库大量使用：`Sequence`/`Collection`（13 章）的几十个方法全是 extension 在
  极少数核心要求上的免费午餐。

## 9.3 协议作为类型：多态不靠继承

```swift
func banner(of drawable: some Drawable) -> String {
    "──────\n\(drawable.drawTwice())\n──────"
}
```

`Drawable` 可以当参数类型、数组元素类型、字典 value 类型——**协议存在证（existential
container）** 在运行期装着"具体类型 + 值"。调用 `drawTwice()` 时动态分发到具体实现
（协议见证表 witness table 一瞥：每个 conformance 一张方法表，运行期查表调用）。

## 9.4 some 与 any：Swift 5.7 后的正确姿势

```swift
func render(_ shapes: [some Drawable]) -> [String] {   // 同构：全是一种具体类型
    shapes.map { $0.draw() }
}

func renderAny(_ shapes: [any Drawable]) -> [String] { // 异构：混合具体类型
    shapes.map { $0.draw() }
}

let circles: [Circle] = [...]            // ✅ render(circles)
let mixed: [any Drawable] = [Circle(...), Square(...)]   // ✅ renderAny(mixed)
```

- **`some P`（不透明类型）**："某种满足 P 的**具体**类型，编译期定死但调用方不知道
  是谁"——零动态分发开销，泛型的糖（10 章接续）。
- **`any P`（存在类型）**："运行期才知道是谁的 P 盒子"——有装箱开销，换来异构
  灵活。
- **Swift 5.7 之前**只能裸写 `Drawable` 当类型（隐式 any），5.7 起编译器提醒你
  显式二选一——新代码永远写 some/any，见到裸协议类型当类型用的老代码，心里补个
  `any`。

选择：能 some 就 some（同构、热路径），要装"不同具体类型"才 any。

## 9.5 标准库协议大观：贴上就有免费能力

```swift
struct Book: Equatable, Hashable, Comparable, CustomStringConvertible {
    let title: String
    let year: Int

    var description: String { "《\(title)》(\(year))" }   // print 时的样子

    static func < (lhs: Book, rhs: Book) -> Bool {        // Comparable 的最小要求
        lhs.year < rhs.year
    }
}
```

| 协议 | 最小要求 | 得到什么 |
|---|---|---|
| `Equatable` | `==`（或全字段存储属性自动合成） | `!=`、`contains`、`firstIndex(of:)` |
| `Hashable` | `hash(into:)`（可自动合成） | 进 `Set`、当 `Dictionary` 键 |
| `Comparable` | `<`（+ Equatable） | `sorted()`、`max()`、区间匹配 |
| `CustomStringConvertible` | `description` | `print`/插值的人类可读输出 |
| `CaseIterable` | （枚举自动） | `allCases` 遍历 |
| `Error` | （空协议，枚举 conform 即可） | 可被 `throws` 抛出（12 章） |
| `Sendable` | （标记值可跨并发域） | 并发安全检查放行（18 章） |

**合成 conformance 的条件**：所有存储属性/关联值都符合 → `Equatable/Hashable` 免费。
Book 的两个字段都是 String/Int，所以 `==` 与 `hash` 全自动；只有 `<` 手写。

## 9.6 协议的协议：继承与组合

```swift
protocol Comparable: Equatable { ... }                    // 协议继承协议

protocol Payable { func pay() -> Double }
protocol HasVacation { func takeVacation(_ days: Int) }
typealias Employee = Payable & HasVacation                // & 组合多个要求

func process(_ staff: some Employee) { ... }
```

一个类型要 conform `Comparable` 就得先满足 `Equatable`；`A & B` 组合出"既要又要"的
临时契约，不用为每个组合专门声明协议。

## 9.7 坑位清单（含实测）

1. **Comparable 忘声明、只写了 `<`**——示例实测：报
   `referencing instance method 'sorted()' ... requires that 'Book' conform to
   'Comparable'`。静态运算符只是函数，conformance 才让标准库认识你。
2. **`some` 参数是"一个"具体类型**：`func render(_ shapes: [some Drawable])` 里
   整个数组同一种类型；想混装 Circle + Square 必须用 `[any Drawable]`。
3. **extension 默认实现与覆写的分派**：通过协议类型调用时走协议见证表（具体类型的
   覆盖生效）；通过具体类型调用时静态绑定——两边语义一致，但"性能敏感 + 默认实现
   很大"时值得知道分发发生在哪。
4. **retroactive conformance（给不属于自己的类型补协议）有孤儿风险**——库升级时
   冲突，15 章展开。
5. **协议里的 `{ get }` 是下限不是上限**：声明 `{ get }` 实现方可以给 `var`（可写）；
   声明 `{ get set }` 强制可写——这直接把 struct 挡在门外（struct 的 let 满足不了
   set）。设计协议时 `{ get set }` 慎用。
6. **存在类型（any）的装箱成本**：小值直接装、大值堆分配——热路径上的
   `[any P]` 换成泛型（10 章）是常见优化。

上一章：[08 · 枚举](08-enums.md) ｜ 下一章：[10 · 泛型](10-generics.md) ｜ 返回：[README](../README.md)
