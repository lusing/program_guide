# 15 · 扩展与下标

> 对应示例：`examples/15_extensions/`

## 15.1 extension：给任何类型加能力——事后也行

```swift
extension Int {
    var isEven: Bool { self % 2 == 0 }
    var squared: Int { self * self }
    func times(_ action: (Int) -> Void) {
        for i in 1...self { action(i) }
    }
}

4.isEven        // true
9.squared       // 81
var collected: [Int] = []
5.times { collected.append($0 * 10) }   // [10, 20, 30, 40, 50]
```

extension 能给**任何已有类型**追加：计算属性、方法（实例/静态/抛错的）、下标、
协议 conformance、便捷构造器——**包括你不拥有源码的类型**（标准库、第三方库）。
没有"必须改原文件"的限制，也没有 Objective-C category 的名字冲突陷阱（同一类型
同一签名的 extension 方法重复定义是编译错误，不是运行期踩雷）。

**能加什么/不能加什么**：

| 能 | 不能 |
|---|---|
| 计算属性 | 存储属性（布局已定，加字段会动 ABI） |
| 方法/下标 | 覆写已有方法（extension 里写重名 = 编译错误） |
| 协议 conformance | 析构/指定构造器（class） |
| 便捷 init（struct 任意/class 便捷） | —— |

## 15.2 扩展 String：安全下标

```swift
extension String {
    subscript(safe index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
}

"swift"[safe: 0]     // "s"
"swift"[safe: 5]     // nil —— 越界给 nil，不崩
```

**subscript（下标）**是"用方括号访问的成员"——能带参数标签、能只读或可写、能重载。
Array/Dictionary 的 `[]` 背后就是它。自定义下标的高频场景：安全访问（越界 nil）、
矩阵 `grid[row, col]`、环形缓冲取模。

## 15.3 泛型约束 extension：能力按需生长

```swift
extension Array where Element: Comparable {
    var median: Element? {
        guard !isEmpty else { return nil }
        return sorted()[count / 2]
    }
}

[3, 1, 2].median             // 2
["a", "c", "b"].median       // "b"
// [SomeNonComparable()].median   // ❌ 没有此方法——元素不可比就没有 median
```

`extension Array where Element: Comparable` 只对"元素可比"的数组生效（10 章条件
conformance 的方法版）。标准库同款：`sorted()` 只存在于 Comparable 元素的集合。
这是 Swift 泛型体系的点睛之笔——**能力跟着约束走，不跟着继承走**。

## 15.4 retroactive conformance：给别人的类型补协议

```swift
struct Meter { let value: Double }

extension Meter: CustomStringConvertible {
    var description: String { "\(value)m" }
}
```

**retroactive（追溯式）conformance**：类型与协议至少一个不归你管时，为其补上
conformance。规则与风险：

- 类型归你、协议不归你（示例情形）：常规操作，风险低；
- **类型不归你**（给标准库/库类型补协议）：**孤儿 conformance 风险**——库作者日后
  自己 conform 了这个协议，你的补丁与官方实现冲突，编译器报 redeclaration；修复
  方案通常是自己包一层新类型。新代码给外部类型补协议前先想想"包一层"是不是更稳。

## 15.5 property wrapper：把"属性 + 存取逻辑"打包

```swift
@propertyWrapper
struct Clamped {
    var wrappedValue: Int {
        didSet { wrappedValue = min(max(wrappedValue, low), high) }
    }
    let low: Int
    let high: Int

    init(wrappedValue: Int, low: Int, high: Int) {
        self.low = low
        self.high = high
        self.wrappedValue = min(max(wrappedValue, low), high)
    }
}

struct GameSettings {
    @Clamped(low: 1, high: 10) var volume: Int = 5
    @Clamped(low: 0, high: 100) var brightness: Int = 80
}

settings.volume = 42        // 夹到 10
settings.brightness = -5    // 夹到 0
```

property wrapper 把"属性的读写逻辑"（夹取、缓存、单位换算、默认值、防抖）抽成
可复用的类型，`@Clamped(...)` 一行声明换一整套行为。编译器把
`var volume: Int` 展开成 `_volume = Clamped(...)` + 代理 getter/setter。
SwiftUI 的 `@State`/`@Binding`、Combine 的 `@Published` 全是这个机制——本章种下
的种子在 GUI 框架里长成森林。

## 15.6 组织代码的 extension 惯用法

```swift
struct Order {
    let items: [String]
    let total: Double
}

// 同文件内按协议分组（可读性惯例，也是官方 API guidelines 建议）
extension Order: CustomStringConvertible {
    var description: String { "Order(\(items.count) items)" }
}
extension Order: Equatable {          // 合成时也常用 extension 显式分组
    static func == (l: Order, r: Order) -> Bool { l.total == r.total }
}
```

大类型的多协议 conformance 各占一个 extension 块，是 Swift 代码的"目录页"。

## 15.7 坑位清单（含实测）

1. **extension 不能加存储属性**（编译错误）——要状态就用包装类型（property wrapper）
   或关联对象（Objective-C 私有 API，不教学）。
2. **`let` 结构体不能设置属性包装器属性**（实测 15 示例踩过）：包装器 setter 是
   mutating——`var s = GameSettings()` 再改。
3. **median 的偶数长度取上中位**（`count/2` 向上取整的位）——[1,2,3,4] 的 median
   是 3：教学实现如此，真统计场景自己定义偶数规则。
4. **retroactive conformance 给外部类型的双重声明风险**——升级依赖时爆
   redeclaration；能包一层就包一层。
5. **extension 里的方法与原方法重名**是编译错误（不是静默覆盖）——想改行为得靠
   子类覆写（class）或协议见证（09 章）。
6. **泛型约束 extension 的方法在运行期仍静态特化**——`[3,1,2].median` 与手写函数
   无性能差；但通过 `any` 存在类型调用时走动态分发（09 章 any 的代价同样适用）。

上一章：[14 · 字符串](14-strings.md) ｜ 下一章：[16 · ARC 与内存](16-arc.md) ｜ 返回：[README](../README.md)
