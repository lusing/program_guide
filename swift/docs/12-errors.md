# 12 · 错误处理

> 对应示例：`examples/12_errors/`

## 12.1 错误就是值：conform Error 的类型

```swift
enum VendingError: Error, Equatable {
    case outOfStock(item: String)
    case insufficientFunds(needed: Int, given: Int)
}
```

Swift 的错误模型三句话：

1. 任何 conform `Error` 的类型都能被抛出（枚举最自然——带关联值的错误信息）；
2. `throws` 标在函数签名上，**调用处必须显式 `try`**——错误路径在代码里可见；
3. 错误是值，能被 switch、存储、传递——比异常的栈展开透明，比错误码强类型。

与 C++/Java 异常对比：Swift 错误**不自动传播**（不 throws 就得当场处理）、不携带栈
展开的开销语义；与 Go 的 error 对比：Swift 有类型化错误 + 模式匹配，且不会忘写
`if err != nil`（忘 try 是编译错误）。

## 12.2 throws / try / do-catch 全家

```swift
mutating func vend(_ item: String, with money: Int) throws -> Int {
    guard let price = prices[item] else {
        throw VendingError.outOfStock(item: item)
    }
    guard money >= price else {
        throw VendingError.insufficientFunds(needed: price, given: money)
    }
    stock[item, default: 0] -= 1
    return money - price
}

do {
    let change = try machine.vend("可乐", with: 5)
    print("找零 \(change)")
} catch VendingError.outOfStock(let item) {
    print("缺货：\(item)")                    // 按错误模式精确捕获
} catch VendingError.insufficientFunds(let needed, let given) {
    print("要 \(needed) 给了 \(given)")
} catch {
    print("兜底：\(error)")                    // 最后的 catch 绑定 error
}
```

- 函数体内 `throw`；调用处 `try`——这对标记成对出现，是错误传播的"账本"。
- catch 子句就是 switch 模式（含值绑定与 where），穷尽性上最后的裸 `catch` 当
  default。
- `try` 只标记"这里可能抛"，不是开关；同一个 do 里可以有多处 try。

**try 的三兄弟**：

| 写法 | 语义 | 失败时 |
|---|---|---|
| `try` | 正常传播（配合 do-catch 或外层 throws） | 抛给上层 |
| `try?` | 错误折叠成 nil，返回 `T?` | 得 nil |
| `try!` | 断言不失败 | 崩溃（`try!` 前想三遍） |

## 12.3 Result：把成功或失败装进值里

```swift
func vendResult(_ machine: inout VendingMachine, item: String, money: Int)
    -> Result<Int, VendingError> {
    do {
        return .success(try machine.vend(item, with: money))
    } catch let error as VendingError {
        return .failure(error)
    } catch {
        return .failure(.outOfStock(item: item))
    }
}

switch vendResult(&machine, item: "可乐", money: 1) {
case .success(let change): print("找零 \(change)")
case .failure(.insufficientFunds(let needed, _)): print("要 \(needed)")
case .failure(.outOfStock): print("缺货")
}
```

`Result<Success, Failure>` 是"已发生的错误"的**值形态**：能存储、能传递、能异步回调
——throws 是"正在发生"的控制流形态。互转：`Result { try ... }`（注意它产生
`any Error`，要具体类型得像上面那样 do-catch 收窄——实测坑）。选择：

- 同步调用链、能当场处理 → **throws**
- 要存起来/跨异步边界/重试计数 → **Result**

## 12.4 typed throws（Swift 6）：错误类型进签名

```swift
enum ScoreError: Error, Equatable {
    case invalid(text: String)
}

func parseScore(_ text: String) throws(ScoreError) -> Int {
    guard let value = Int(text), (0...100).contains(value) else {
        throw ScoreError.invalid(text: text)
    }
    return value
}

do {
    _ = try parseScore("abc")
} catch {
    let e = error          // 编译器已知 e 是 ScoreError——不用 as? 转换
    precondition(e == ScoreError.invalid(text: "abc"))
}
```

`throws(ScoreError)` 把"会抛什么"钉进签名：catch 里的 `error` 已是具体类型，
调用方可以精确 switch 而非兜底 `as?`。**语法注意（实测坑）**：括号里是**错误类型**，
不是返回类型——`throws(Int) -> Int` 的意思是"抛 Int"（Int 不 conform Error，编译
错误一堆且误导）。库的公开 API 慎用（错误类型成为 ABI 一部分），应用内与泛型桥接
处是真香场景（`throws` 泛型参数）。

## 12.5 rethrows：只重抛别人的错

```swift
func transformAll(_ values: [String], _ transform: (String) throws -> Int) rethrows -> [Int] {
    try values.map(transform)
}

let ints = try transformAll(["1", "x"], { try parseScore($0) })  // 闭包抛 → 这里要 try
let plain = transformAll(["3"], { Int($0)! })                     // 闭包不抛 → 调用不带 try！
```

`rethrows` 承诺"我自己不产生错误，只重抛你传进来的闭包的错"——传非抛闭包时调用
处连 `try` 都不用写。`map`/`filter`/`compactMap` 全家都是 rethrows，所以
`array.map { $0 * 2 }` 从不需要 try。

## 12.6 错误分层：可恢复 vs 程序员错误

```swift
func mustBePositive(_ n: Int) -> Int {
    precondition(n > 0, "必须为正数，得到 \(n)")   // 契约违反 = bug，立即崩溃
    return n
}
```

Swift 的错误处理是**双层**的，别混用：

| 层 | 工具 | 语义 | 例子 |
|---|---|---|---|
| **可恢复错误** | throws / Result | 业务预期内的失败，调用方决策 | 文件不存在、输入非法、网络超时 |
| **程序员错误** | precondition / assertion / fatalError | bug，不可恢复，崩溃暴露 | 数组越界、契约违反、不可达分支 |

判据一句话：**"调用方拿到这个错误后能干什么？"** 能重试/能提示/能降级 → throws；
只能改代码 → precondition。用 throws 处理 bug 会把错误藏进"宽容的兜底 catch"里，
用 fatalError 处理业务失败会把用户数据崩没——两边都是反模式。

`assertionFailure`/`fatalError` 还有个妙用：让 switch 的"不可达分支"类型检查通过
（04 章 scoreLevel 的 default 就演示了）。

## 12.7 坑位清单（含实测）

1. **`throws(Int)` 的括号是错误类型**（实测）：误写成返回类型时错误信息全线误导
   （`thrown expression type 'Int' does not conform to 'Error'`）——正确形式
   `throws(ScoreError) -> Int`。
2. **`Result { try ... }` 产生 `Result<T, any Error>`**（实测）：赋给
   `Result<T, MyError>` 要 do-catch + `as` 收窄，或用 `mapError`。
3. **`try? expr == nil` 优先级坑**（实测）：解析为 `try? (expr == nil)` 得 `Bool?`——
   判 nil 要括号 `(try? expr) == nil`。
4. **rethrows 函数传非抛闭包时不能写 try**（实测：警告级别的语法错误）：`try` 只在
   闭包真会抛时出现。
5. **typed throws 的错误类型 Equatable 要显式声明**——想 `#expect(throws: .invalid(...))`
   精确断言错误值，enum 记得 `: Error, Equatable`。
6. **do-catch 模式捕获的顺序即优先级**（与 switch 同理）：精确的在前，兜底 `catch`
   收尾；两个 catch 都可能匹配时先写的赢。

上一章：[11 · 闭包](11-closures.md) ｜ 下一章：[13 · 集合](13-collections.md) ｜ 返回：[README](../README.md)
