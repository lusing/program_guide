# 18 · 并发 II

> 对应示例：`examples/18_actors/`

## 18.1 数据竞争：共享可变状态的死罪

```swift
final class UnsafeCounter {
    var count = 0
    func increment() { count += 1 }   // read-modify-write 三步，非原子
}
```

`count += 1` 是三条指令（读、加、写）。两个线程同时执行时交错——丢失更新。锁、
原子变量、消息传递是三种传统解法；Swift 6 的答案是**把状态隔离进 actor**，并让
编译器**在编译期**抓住越界访问（严格并发检查）。

## 18.2 actor：一次只放一个任务进门

```swift
actor SafeCounter {
    private(set) var count = 0

    func increment() {
        count += 1          // actor 内部：同步、安全、无需锁
    }

    func incrementTwice() {  // actor 方法互调：不需要 await
        increment()
        increment()
    }
}

await safe.increment()   // 外部调用：必须 await（跨隔离边界）
```

actor 像"自带串行队列的 class"：状态默认**隔离**（isolated），同一时刻只有一个任务
在执行 actor 方法——增量互斥免费获得，且**没有死锁**（等待的是"进门权"而非锁序）。

三条边界规则：

1. **外部调用 actor 方法/属性必须 `await`**——哪怕是同步方法（进门要排队）；
2. **actor 内部互调不需要 await**——已经在门里；
3. **跨 actor 传值要过 Sendable 检查**（18.4）。

与 class 的关系：actor 是引用类型、可 conform 协议，但**不能继承**、没有 `self`
逃逸的口子（编译器拦）。

## 18.3 隔离与挂起：跨 await 的安全性

```swift
actor Statistics {
    private var samples: [Int] = []

    func record(_ value: Int) {
        samples.append(value)      // 隔离域内：原子
    }

    func average() async -> Double {
        guard !samples.isEmpty else { return 0 }
        return Double(samples.reduce(0, +)) / Double(samples.count)
    }
}

// 50 个并发子任务往同一个 actor 打点
await withTaskGroup(of: Void.self) { group in
    for i in 1...50 {
        group.addTask { await stats.record(i * 100) }
    }
}
await stats.count      // 50 —— 任何并发度下都对
```

关键语义：async actor 方法在**挂起点**让出门时，其他任务可以进入 actor——但你的
`self` 状态不会在同步代码段中间被改。写 actor 的纪律：**把 await 放在计算的边界**
（先算完再 await），别让"读-改-写"被 await 劈成两半（劈开的时刻状态可能变——
reentrancy 是 actor 的高级课题，记住"同步段原子、跨 await 要重新校验假设"）。

## 18.4 Sendable：跨并发域的安全护照

```swift
struct Config: Sendable {     // 全 let + Sendable 成员 → 编译器认可
    let host: String
    let port: Int
}

group.addTask { describe(config) }   // Sendable 值随便跨域
```

`Sendable` 是"这个值可以安全地同时出现在多个并发域"的标记：

- **自动 Sendable**：值类型（struct/enum）全字段不可变或本身 Sendable；不可变类；
  `let` 集合；
- **永远不 Sendable**：内含可变状态的 class（除非加锁并手写 conformance 说明理由）；
- **actor 天然 Sendable**（隔离保证了安全）。

Swift 6 严格模式下，Task/TaskGroup 闭包捕获非 Sendable 值 = 编译错误。看到
"xxx is not Sendable" 的诊断，三条出路：改成值类型（多数情况）、改成 actor、
`@Sendable` 标注闭包并审查捕获。

## 18.5 @MainActor：主线程的官邸

```swift
@MainActor
final class Dashboard {
    private var updates = 0
    func refresh() { updates += 1 }
}

await MainActor.run {          // 在主 actor 上执行一段代码
    let dashboard = Dashboard()
    dashboard.refresh()
}
```

`@MainActor` 把类型/函数钉在主 actor 上——UI 代码的标配（所有 UI 框架都要求主线程
操作控件）。跨 actor 调用 MainActor 方法同样要 await。本教程 CLI 场景用得少，但
"隔离的类型标注"与 actor 完全同一套机制——SwiftUI 里 `@MainActor` 无处不在。

## 18.6 Swift 6 严格并发：报错是恩惠

Swift 5 时代这些检查是警告（可无视），Swift 6 语言模式升级为**编译错误**：

- 跨域捕获非 Sendable 值 → error；
- 非隔离上下文摸 actor 状态 → error（`actor-isolated property can not be
  referenced`）；
- 顶层可变全局状态 → error（06 章的 `enum Registry` 正解由此而来）。

迁移心法：**先让编译器骂完**。报错点位就是数据竞争候选点；值类型化、入 actor、
标注 Sendable 三板斧处理后，代码在并发正确性上是"证明过"的——这是 Swift 6 相对
旧并发模型的代际差。

## 18.7 坑位清单（含实测）

1. **外部访问 actor 属性也要 await**（实测）：`precondition(await safe.count == 10)`
   还会撞 autoclosure 墙——先 `let c = await safe.count` 再断言（16 章坑的并发版）。
2. **Int / Double 混型无处不在**（实测）：`samples.reduce(0, +) / Double(n)` 是
   Int÷Double 编译错误——`Double(samples.reduce(0, +)) / Double(n)`。
3. **guard + 表达式不是隐式返回**（实测）：async 方法里 guard 之后要显式 `return`
   （16 章同款，这里再踩一次）。
4. **actor 方法互调别加 await**：门内调用同步直达；加了 await 反而引入不必要的
   挂起点（还可能在 reentrancy 语义下出意外）。
5. **async actor 方法的可重入**：跨 await 后"我刚检查过 samples 非空"这类假设要
   重新校验——其他任务可能在挂起点进了门。
6. **Sendable 检查误报的例外**：`@unchecked Sendable`（自己担保线程安全）是逃生
   门——用之前问问为什么不是值类型/actor。

上一章：[17 · 并发 I](17-concurrency.md) ｜ 下一章：[19 · 文件与 IO](19-files.md) ｜ 返回：[README](../README.md)
