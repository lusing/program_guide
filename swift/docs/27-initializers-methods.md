# 27 · 构造器高级主题：可失败构造器、必要构造器、class func、defer

> 对应示例：`examples/27_initializers_methods/`
> 运行：`swift run Ch27InitializersMethods`，测试：`swift test --filter Ch27InitializersMethodsTests`

26 章讲了继承与类型转换，其中构造器只覆盖了"指定 vs 便利"和继承规则。本章把
构造器的剩余高级主题补齐——**可失败构造器**（`init?`）、**必要构造器**
（`required init`）、**构造器的四项安全检查**；然后讲两个独立但相关的话题：
**`class func` 与 `static func` 的区别**（能不能被重写），以及 **`defer`**
（函数退出前必执行的清理块）。

## 27.1 可失败构造器：`init?`

有些构造在参数不合法时应该**拒绝创建对象**——比如分母为 0 的分数、空字符串的
用户 ID、格式错误的 URL。Swift 允许构造器返回 `nil` 来表示"构造失败"：
在 `init` 后面加 `?`，变成 `init?`：

```swift
struct Fraction {
    let numerator: Int
    let denominator: Int

    // 分母为 0 → 构造失败
    init?(numerator: Int, denominator: Int) {
        guard denominator != 0 else { return nil }
        self.numerator = numerator
        self.denominator = denominator
    }

    var decimal: Double {
        Double(numerator) / Double(denominator)
    }
}

if let half = Fraction(numerator: 1, denominator: 2) {
    print(half.decimal)  // 0.5
} else {
    print("构造失败")
}

let bad = Fraction(numerator: 1, denominator: 0)
// bad 的类型是 Fraction?，值为 nil——不会崩溃
```

`init?` 的返回值是 `Self?`（可选）。构造过程中任何位置 `return nil` 都会
中止构造，不会留下"半个对象"。调用方拿到可选值，用 `if let` 或 `guard let`
处理——这就是 06 章的可选类型哲学在构造器上的延伸。

标准库里到处都有 `init?`：`Int("42")`（字符串解析失败返回 nil）、
`URL(string:)`（非法 URL 返回 nil）、枚举的 `init?(rawValue:)`（08 章）。
**只要构造可能失败，就用 `init?`**——别让调用方拿到一个"内部状态非法"的对象。

### `init!`：隐式解包的可失败构造器

`init!` 与 `init?` 类似，但返回值是**隐式解包可选**（`Self!`）——编译器
允许你当非可选值用，但如果构造失败（返回了 nil），运行期访问时崩溃：

```swift
struct ImplicitID {
    let raw: String
    init!(raw: String) {
        guard !raw.isEmpty else { return nil }
        self.raw = raw
    }
}

let okID = ImplicitID(raw: "ABC123")
print(okID!.raw)  // 实际仍带 !，失败即崩
// let badID = ImplicitID(raw: "")  // 构造时返回 nil，后续访问崩溃
```

`init!` 是 Objective-C 桥接时代的遗留——OC 的 `init` 可以返回 nil，
桥接过来自然变成 `init!`。新代码**优先用 `init?`**，显式处理失败路径。

## 27.2 必要构造器：`required init`

在构造器前加 `required`，表示"**每个子类都必须实现这个构造器**"——要么
直接继承（不写就是继承），要么显式重写：

```swift
class BaseView {
    let frame: (x: Double, y: Double, w: Double, h: Double)

    required init(frame: (x: Double, y: Double, w: Double, h: Double)) {
        self.frame = frame
    }
}

class Button: BaseView {
    var label: String

    // 子类必须实现 required init（继承或重写均可）
    required init(frame: (x: Double, y: Double, w: Double, h: Double)) {
        self.label = "按钮"
        super.init(frame: frame)
    }
}

class IconButton: Button {
    var icon: String

    // 再子类也要实现——required 是"每一级子类都必须可见"的契约
    required init(frame: (x: Double, y: Double, w: Double, h: Double)) {
        self.icon = "star"
        super.init(frame: frame)
    }
}
```

为什么需要 `required`？因为 Swift 的构造器不是普通方法——你不能通过
"父类引用"来调子类的构造器（构造器没有多态）。如果框架代码需要一个
"保证所有子类都能用 frame 构造"的承诺，`required` 就是这个承诺的编译期
强制。UIKit 的 `UIView.init?(coder:)` 就是 `required` 的典型场景。

> 注意：`required init` 不需要同时写 `override`——`required` 本身
> 就隐含了"子类必须提供实现"的语义，与 `override` 的职责不重叠。

## 27.3 `class func` vs `static func`：能否被重写

07 章讲了实例方法，26 章讲了 `override`。但类型方法（static/class method）
有一个关键区别书中很少讲透：**`class func` 可以被重写，`static func` 不能**。

```swift
class Shape {
    // class func：子类可以 override
    class func describe() -> String {
        "一个形状"
    }

    // static func：子类不能 override（等价 final class func）
    static func unit() -> String {
        "单位形状"
    }

    // class 计算属性：子类可 override
    class var category: String { "几何" }

    // static 计算属性：子类不可 override
    static var version: String { "1.0" }
}

class Circle: Shape {
    // ✅ 可以重写 class func
    override class func describe() -> String {
        "一个圆"
    }

    // ✅ 可以重写 class 计算属性
    override class var category: String { "圆形" }

    // ❌ 编译错误：static 方法不能重写
    // override static func unit() -> String { "单位圆" }
}
```

规则一句话：**`static` 是封死的，`class` 是开放的**。`static func` 等价于
`final class func`。这个区别只对有继承的类有意义——结构体和枚举没有继承，
它们的 `static` 就是纯粹的"类型级成员"，不存在 `class func` 一说：

```swift
struct Point {
    var x = 0.0, y = 0.0
    static func origin() -> Point { Point(x: 0, y: 0) }
}
```

什么时候用哪个？**默认 `static`**——除非你明确希望子类能重写这个类型方法
（比如工厂方法、类型描述符），才用 `class`。与实例方法的默认（可被重写）
相反，类型方法的默认是**不可重写**——Swift 在类型级别更倾向于封闭。

## 27.4 构造器的四项安全检查

26 章讲了两段式初始化的概念，这里把编译器在构造器中强制的**四项安全检查**
列全。这些不是"建议"，是**编译错误**——理解它们能帮你读懂编译器的报错：

**检查 1：指定构造器必须先初始化本类所有存储属性，才能调 `super.init`。**

```swift
class SafeChild: SafeBase {
    var extra: Int

    init(value: Int, extra: Int) {
        self.extra = extra       // ✅ 先初始化本类属性
        super.init(value: value) // ✅ 然后才能向上委托
    }
}
```

如果把 `super.init` 放在 `self.extra = extra` 之前 → 编译错误。
原因：`super.init` 会触发父类构造，父类构造可能用到被子类重写的属性——
如果子类属性还没初始化，就访问到了"半个对象"。

**检查 2：子类要改继承来的属性，必须在 `super.init` 之后。**

```swift
init(value: Int, extra: Int) {
    self.extra = extra
    super.init(value: value)
    self.value = value * 2   // ✅ super.init 之后才能改继承来的属性
}
```

`value` 是父类的存储属性，在 `super.init` 之前它可能还没被初始化
（父类构造器里可能赋了别的值）。Swift 要求：先让父类把它的属性安顿好，
子类再动。

**检查 3：便利构造器要改属性，必须在 `self.init` 之后。**

```swift
convenience init(defaultExtra: Int) {
    self.init(value: 10, extra: defaultExtra)
    self.extra = defaultExtra + 100   // ✅ self.init 之后
}
```

原因：便利构造器的职责是"给指定构造器的结果做微调"。如果在 `self.init`
之前改属性，指定构造器里的赋值会覆盖你的修改——白改了。

**检查 4：`super.init` / `self.init` 之前不能用 `self` 调属性或方法。**

```swift
// init(bad: Int) {
//     self.doSomething()          // ❌ 编译错误：self 还没构造完
//     super.init(value: bad)
//     self.extra = 0
// }
```

`self` 在构造完成前不是一个合法对象——它的存储属性可能处于未初始化状态。
方法可能访问属性，属性观察者可能触发副作用——一切都要等"完全构造"之后。

> 这四条检查的共同目标：**任何对象的任何属性，在任何时候都有确定的值**。
> 没有"未初始化的内存被意外读到"的窗口——这是 Swift 比 C++ 更安全的
> 核心机制之一。

## 27.5 `defer`：函数退出前必执行的清理块

`defer` 块里的代码**无论函数怎么退出都会执行**——正常走完、`return` 提前返回、
`break` 跳出循环、`throw` 抛出异常，全都算数：

```swift
func demoDefer(flag: Bool) -> String {
    defer { print("  defer：清理资源（总会执行）") }
    if flag {
        print("  提前 return")
        return "提前返回"
    }
    print("  正常走完")
    return "正常结束"
}
```

两次调用，两种退出路径，`defer` 都执行了。这就是它的价值：**把"清理逻辑"
从"控制流"里解耦**——不用在每个 `return` 前复制粘贴清理代码，也不会因为
忘了某个 `break` 而泄漏资源。

### 多个 defer：栈式（后写的先执行）

```swift
func multiDefer() {
    defer { print("  defer 1（先写）") }
    defer { print("  defer 2（后写，先执行）") }
    print("  函数体")
}
// 输出顺序：函数体 → defer 2 → defer 1
```

`defer` 像栈一样后进先出（LIFO）。这个特性在嵌套资源获取时很有用：
先获取的资源后释放，与获取顺序相反。

### 典型场景：临时文件的清理

```swift
func readTempFile() -> String {
    let path = NSTemporaryDirectory() + "swift-guide-27-demo.txt"
    let url = URL(fileURLWithPath: path)
    try? "hello defer".write(to: url, atomically: true, encoding: .utf8)

    guard let data = try? Data(contentsOf: url) else { return "" }
    // defer 保证无论后面怎么走，临时文件都会被删掉
    defer { try? FileManager.default.removeItem(at: url) }
    return String(data: data, encoding: .utf8) ?? ""
}
```

`guard` 的 `else` 分支在 `defer` **之前**返回——所以文件不会被删。
这引出一个重要细节：`defer` 只保护**它之后**的退出路径。把 `defer`
放在资源获取的**紧接着的下一行**，别放在函数开头。

> `defer` 不是 `try/finally` 的语法糖——它比 finally 更灵活：可以写
> 多个、可以嵌套、可以放在任何作用域（`if` 块、`for` 块、`do` 块）里。
> 作用域结束时 `defer` 就执行，不限于函数返回。

## 27.6 闭包构造属性：复杂初始化的"一次性函数"

属性的初始值如果不只是"一个字面量"，而是需要多行逻辑（循环、条件、
临时变量），可以用**闭包**来构造：

```swift
class DataProcessor {
    // 简单默认值
    var name = "处理器"

    // 复杂初始化：多行逻辑 → 用闭包包起来，末尾的 () 立即执行
    let lookupTable: [String: Int] = {
        var table: [String: Int] = [:]
        for (i, key) in ["alpha", "beta", "gamma", "delta"].enumerated() {
            table[key] = (i + 1) * 10
        }
        return table
    }()  // ← 这个小括号是关键：没有它就是个只读计算属性

    // 也可以利用标准库链式方法
    let factors: [Double] = [1.0, 0.5, 0.25].map { $0 * 2 }
}

let proc = DataProcessor()
print(proc.lookupTable)  // ["beta": 20, "alpha": 10, ...]
print(proc.factors)      // [2.0, 1.0, 0.5]
```

模式是 `let x: T = { ... return value }()`。闭包执行**一次**，结果存进
属性。末尾的 `()` 是"立即调用"——漏掉它，属性就变成了一个**只读计算属性**
（每次访问都重新执行闭包），语义完全不同。

与 `lazy var`（11 章）的区别：闭包构造的 `let` 在**构造时**就执行，
`lazy var` 在**首次访问时**才执行。需要常量（`let`）或初始化必须在构造期
完成时，用闭包构造；初始化昂贵且不一定用到时，用 `lazy var`。

## 27.7 坑位清单

1. **`init?` 里 `return nil` 之前不能访问 `self`**——对象还没构造完，
   没有 `self` 可用。只能做参数校验，然后初始化属性或返回 nil。
2. **`required init` 不需要 `override`**：写了反而可能报
   "'override' is implied when overriding a required initializer"。
3. **`static` 方法不能 `override`**：想给子类留重写余地，用 `class func`；
   封死用 `static func`。结构体/枚举没有 `class func`。
4. **`defer` 只保护它之后的退出路径**：写在 `guard` 的 `else` 之后，
   前面的 `return` 不会被清理。位置紧跟资源获取。
5. **闭包构造属性漏写 `()`**：`let x = { ... }` 是闭包值（类型是 `() -> T`），
   `let x = { ... }()` 才是执行结果（类型是 `T`）。编译器会报类型不匹配，
   但新手常盯着错误信息看不出原因。
6. **可失败构造器不能改成不可失败**：`init?` 不能 `override` 为 `init`，
   反之可以（子类可以收紧——父类可失败，子类保证成功）。但 `init` 不能
   重写 `init?`——子类不能放宽父类的失败承诺。

上一章：[26 · 继承与类型转换](26-inheritance-casting.md) ｜ 返回：[README](../README.md)
