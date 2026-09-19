# 06 · 可选类型

> 对应示例：`examples/06_optionals/`

## 6.1 nil 不是 null：类型系统里的"可能没有"

```swift
struct Student {
    let name: String
    let score: Int?      // 问号 = 这格可能没有值
}
```

`Int?` 是**独立的类型**（`Optional<Int>` 的语法糖），不是"可为 nil 的 Int"。没有默认
初始化、忘记判 nil 就使用，都是编译错误——C/C++ 的空指针解引用、Java 的
NullPointerException，在 Swift 里被搬到编译期。

对比三家：

| 语言 | "可能没有"的表达 | 忘了检查的下场 |
|---|---|---|
| C/C++ | 指针可能为 NULL | 运行期崩溃（或更糟） |
| Rust | `Option<T>` | 编译错误（必须 match） |
| Swift | `T?` | 编译错误（必须解包） |

Swift 与 Rust 在这里同宗——代价是所有"取值"都要过解包这道门，收益是空值事故清零。

声明一个 Optional 却不赋值，默认就是 `nil`（Optional 是唯一有默认值的类型）。

## 6.2 解包四式

```swift
// ① if let：解包值只活在这个大括号里
if let score = scoreOf("小明") {
    print("小明 \(score) 分")
}

// ② guard let：解包值在函数余下部分持续可用（04 章讲过 guard 的语义）
func gradeOf(_ name: String) -> String {
    guard let score = scoreOf(name) else { return "无成绩" }
    return score >= 60 ? "及格" : "不及格"
}

// ③ ?? ：提供默认值（右结合可链）
scoreOf("小红") ?? 0

// ④ 强制解包 !：确知有值时才可——错了就崩
scoreOf("小明")!
```

Swift 5.7 起的**同名简写**（SE-0345）：`if let score = score` 可省去 `= score`，写成
`if let score { ... }`——已有同名可选变量时少敲一遍。04 章示例里
`guard let light, !light.isEmpty` 还展示了同一行里解包 + 附加条件的组合写法。教学代码
两种形态并存：初见写完整形态（读代码不猜），熟练后用简写。

四式的选择准则：

- 后续逻辑**只在有值时**执行 → `if let`
- **没有值就干不下去**、成功路径继续 → `guard let`
- 只是**展示**，缺省有合理默认 → `??`
- 编译器无法证明、你**人工能证明**有值 → `!`（写之前问自己三遍——它崩起来没有栈信息优雅）

## 6.3 可选链：`?.` 一路点到底

```swift
func scoreOf(_ name: String) -> Int? {
    findStudent(name)?.score      // findStudent 返回 Student?，再取 score（Int?）
}
```

链条上任一环是 nil，整条表达式直接得 nil，后续环节不执行——等价于 Rust 的 `?` 链或
一层层嵌套 if let，但零噪音。链尾的类型是各环 Optional 的**叠加**：
`student?.address?.city?.count` 是 `Int??`？不——可选链会自动压平，结果就是 `Int?`。

链还能带方法调用与下标：`order?.items.first?.price`、`dict[key]?.contains("x")`。

## 6.4 构造器也可能"没有"：`Int("...")` 返回可选

```swift
func parseAge(_ text: String) -> Int? {
    Int(text)      // 解析失败返回 nil，不抛异常
}
```

`Int("42") == 42`、`Int(" 42 ") == nil`（前后空格都不行）、`Int("4.2") == nil`。
Swift 标准库把"格式解析"设计为**返回可选**而非异常/错误码——失败的解析是常态业务，
不是异常路径。字典下标 `dict[key]` 同理返回 `V?`（13 章）。

## 6.5 map / flatMap / compactMap：函数式三件套

```swift
// map：有值才变换，结果仍是 Optional
parseAge("21").map { $0 * 2 }          // Optional(42)
parseAge("x").map { $0 * 2 }           // nil

// flatMap：变换本身返回可选时，摊平为一层
firstWord(of: "hello").flatMap { $0.first }   // Character?（而非 Character??）

// compactMap：数组层面的洗 nil
students.compactMap(\.score)           // [Int?] → [Int]
```

三者一句话：**map 保壳变换、flatMap 防套娃、compactMap 洗数组**。`\.score` 是 key path
简写（15 章细讲），等价 `{ $0.score }`。

## 6.6 隐式解包可选（IUO）：历史的活化石

```swift
let text: String! = loadFromStoryboard()   // 用的时候不用写 !
```

`T!` 声明的变量使用时自动解包—— Objective-C 互操作时代的遗产（Cocoa API 当年返回值
可能为 nil 但不想逼开发者写 `?`）。现代 Swift（5.x 起）把 IUO 在编译器里**重新实现为**
普通 `T?`，只在"使用点"做隐式解包。新代码准则：

- 自己的 API 永远用 `T?`；
- 遇到 `T!`（老库/Storyboard 出口）尽早 `if let` 收编成 `T?`。

## 6.7 坑位清单（含实测）

1. **Swift 6 严格并发：main.swift 顶层 `let` 是 MainActor 隔离的**——非隔离函数引用它
   直接编译错误（本教程 06 示例实测：`main actor-isolated let 'roster' can not be
   referenced from a nonisolated context`）。**正解**：全局常量收进
   `enum Registry { static let roster = ... }`——Sendable 值的 static let 随处可用。
2. **`Int(" 42 ")` 是 nil**：`Int(String)` 严格匹配，前后空白都拒绝；要宽松解析自己 trim。
3. **可选链自动压平**：`a?.b?.c` 的结果是一层 `Optional`，不需要也不应该再 flatMap 一次。
4. **`!` 的崩法很糟**：崩溃信息只有一句 `unexpectedly found nil`，没有你的业务上下文——
   能 `guard let ... else { return }` + 明确错误处理，就别用 `!`。
5. **`??` 优先级低于比较**：`x ?? 0 > 5` 解析为 `x ?? (0 > 5)`（类型错误提醒你加括号）；
   想比大小写 `(x ?? 0) > 5`。
6. **`Optional` 的 `==` 与 `nil` 字面量**：`opt == nil` 合法（Optional 与 nil 比较）；
   但元组可选比较要解包（03 章坑位提过，这里最容易撞——`optTuple == (1, 2)` 编译不过）。

上一章：[05 · 函数](05-functions.md) ｜ 下一章：[07 · 结构体与类](07-structs-classes.md) ｜ 返回：[README](../README.md)
