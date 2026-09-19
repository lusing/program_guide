# 08 · 枚举

> 对应示例：`examples/08_enums/`

## 8.1 枚举是代数数据类型，不是整数常量集

C 的 enum 是"一堆 int 的别名"；Swift 的 enum 是**和类型**（sum type）——"这个值是
A、B 或 C 中的一种，每种可以携带不同的数据"：

```swift
enum Shape {
    case circle(radius: Double)               // 圆：带一个半径
    case rect(width: Double, height: Double)   // 矩形：带宽高
    case point                                 // 点：不带载荷
}

func area(of shape: Shape) -> Double {
    switch shape {
    case let .circle(r): return .pi * r * r
    case let .rect(w, h): return w * h
    case .point: return 0
    }
}
```

对比 C++ 的 `std::variant<Double, pair<Double, Double>>`：enum + switch 把"带载荷的
多态值"做成了一等语法，且**穷尽性检查**保证你处理了每一种情况。这一对（enum +
switch）是 Swift 处理"数据多形态"的首选——比类继承树更轻、比 tag+union 更安全。

## 8.2 关联值的使用姿势

- **取值必须走模式匹配**：`.circle(let r)` 在 case 里绑定载荷——没有 `.circle.radius`
  这种直接访问（不同 case 载荷不同，没法统一）。
- **`case let` 的摆放**：`case let .circle(r)`（let 在外）与 `case .circle(let r)`
  等价，多载荷时后者更常见。
- **省略上下文**：变量已是 `Shape` 类型时，写 `.circle(radius: 1)` 不用写
  `Shape.circle(...)`——类型推断处处帮你省前缀。

## 8.3 raw value：枚举与底层值的联姻

```swift
enum Planet: Int {
    case mercury = 1, venus, earth, mars   // 自动递增：1 2 3 4
}

Planet.earth.rawValue          // 3
Planet(rawValue: 4)            // Optional(.mars)——反向构造可能失败！
Planet(rawValue: 99)           // nil
```

- raw value 类型限 `Int/Double/String/Character` 等**字面量型**，每个成员恰好一个。
- Int raw value 支持自动递增（首个赋值后 +1）。
- **`init?(rawValue:)` 返回可选**——非法 raw 值造不出成员，这个失败是正常的
  （06 章的"解析"哲学）。
- String raw value 省略时自动取成员名：`case debug, info` 的 rawValue 就是
  `"debug"`、`"info"`。

**关联值与 raw value 互斥**：一个 enum 只能选一边——要"带载荷 + 有底值"就自己写
计算属性桥接。

## 8.4 indirect：递归枚举

```swift
indirect enum Expr {
    case number(Double)
    case add(Expr, Expr)          // 成员的载荷里又出现 Expr 自己
    case multiply(Expr, Expr)
}

let expr = Expr.multiply(.add(.number(1), .number(2)), .add(.number(3), .number(4)))
evaluate(expr)   // (1+2)×(3+4) = 21
```

枚举值是内联存储的，`add(Expr, Expr)` 尺寸取决于 Expr 自身——无限递归尺寸算不出，
`indirect` 告诉编译器"这个成员用引用存储"。实战里这就是**表达式树 / JSON 模型 /
链表**的标准写法：

```swift
indirect enum JSON {
    case null, bool(Bool), number(Double), string(String)
    case array([JSON]), object([String: JSON])
}
```

（成员整体标 indirect 也行：`indirect enum` 全体引用存储。）

## 8.5 CaseIterable 与带方法的枚举

```swift
enum LogLevel: String, CaseIterable {
    case debug, info, warning, error

    var emoji: String {           // 枚举可以有计算属性、方法
        switch self {
        case .debug: return "🌱"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

for level in LogLevel.allCases { ... }    // CaseIterable 免费送遍历
```

枚举是一等类型：属性、方法、static 工厂、协议 conformance 全都可有。**把行为放进
枚举**（而不是在调用处 switch 来 switch 去）是 Swift 的惯用法——`moonCount`、`emoji`
都是"数据自解释"。

## 8.6 关联值 + where：精细匹配

```swift
switch event {
case .received(let bytes) where bytes > 1024: return "大块数据 \(bytes)B"
case .received(let bytes): return "小数据 \(bytes)B"
case .failed(let code) where code == 404: return "资源不存在"
case .failed(let code): return "错误码 \(code)"
}
```

04 章的 where 谓词直接作用于关联值——"拆载荷 + 条件筛选"一个 case 搞定，不用先
绑定再 if。

## 8.7 坑位清单（含实测）

1. **`CaseIterable` 要显式声明**——示例实测：枚举只写了 `: String` 就用
   `allCases`，报 `type 'LogLevel' has no member 'allCases'`。关联值枚举也能
   CaseIterable（载荷无关的遍历）。
2. **关联值枚举没有 rawValue**，也没有 `init?(rawValue:)`——两套机制互斥。
3. **`Planet(rawValue:)` 返回可选**：`Planet(rawValue: 99) == nil` 是正常路径，
   `Planet(rawValue: 4)!` 强解前想清楚来源。
4. **switch 枚举时别写 default**（尤其关联值枚举）：新加 case 时 default 会把
   "漏处理"藏进 silence——让编译器的穷尽性检查替你站岗。
5. **递归枚举忘写 indirect** 报错文案是 `recursive enum 'Expr' is not marked
   'indirect'`——看见它就补关键字。
6. **枚举相等比较**：无关联值枚举自动 Equatable（含 raw value 枚举）；**关联值
   枚举**要关联值类型都 Equatable 才自动合成（写了载荷类型不 Equatable 就得手写
   `==`）。

上一章：[07 · 结构体与类](07-structs-classes.md) ｜ 下一章：[09 · 协议](09-protocols.md) ｜ 返回：[README](../README.md)
