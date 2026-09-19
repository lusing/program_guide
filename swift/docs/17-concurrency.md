# 17 · 并发 I

> 对应示例：`examples/17_concurrency/`

## 17.1 async/await：异步代码的同步写法

```swift
func fetchTemperature(city: String) async -> Int {
    City.temperatures[city] ?? 0     // 模拟 IO：真实代码这里 await 网络调用
}

let beijing = await fetchTemperature(city: "北京")   // 调用处 await
```

三件套语法：

- 函数签名 `async`：这函数**可能挂起**（suspend）——让出线程等 IO，不阻塞；
- 调用处 `await`：标记挂起点——"这里可能暂停，暂停期间线程去干别的"；
- 挂起点之间代码**不会**被并发打断——async 函数体内同步代码段是原子的（相对自身
  状态而言）。

对比回调/Promise 时代的"红蓝函数"，async/await 的胜利是**控制流回来了**：顺序写的
代码顺序执行，try/defer/循环都正常工作。main.swift 顶层代码可以直接 `await`
（编译器把顶层当 async main 处理）——示例全部演示。

**`await` 的语法细节（实测）**：运算符右侧的 await 必须加括号——`await a + await b`
是编译错误，`(await a) + (await b)` 才对。

## 17.2 结构化并发 I：async let（固定数量）

```swift
func pairSum(cityA: String, cityB: String) async -> Int {
    async let a = fetchTemperature(city: cityA)   // 起跑①
    async let b = fetchTemperature(city: cityB)   // 起跑②（与①并发）
    return (await a) + (await b)                  // 收账：两笔并发跑
}
```

`async let` 声明"子任务在此起步"，`await` 收结果——两个独立 IO 并发执行而非串行。
适用：**编译期已知数量**的并发（两个查询、三个服务）。作用域结束自动等待/取消所有
async let——"结构化"的含义：子任务的生命周期困在语法作用域里，不会失控逃逸。

## 17.3 结构化并发 II：TaskGroup（动态数量）

```swift
func gatherTemperatures(cities: [String]) async -> [(city: String, temp: Int)] {
    await withTaskGroup(of: (String, Int).self) { group in
        for city in cities {
            group.addTask { (city, await fetchTemperature(city: city)) }
        }
        var results: [(city: String, temp: Int)] = []
        for await (city, temp) in group {          // 谁先完成先收谁
            results.append((city, temp))
        }
        return results.sorted { $0.temp < $1.temp }   // 完成顺序不定 → 排序保证确定
    }
}
```

四步套路：`withTaskGroup` 开组 → `addTask` 播种 → `for await` 收割 → 返回时组自动
join（未完成的子任务被等待，出错的被聚合）。

**教学与实战共同的重点（确定性纪律）**：`for await` 的到达顺序**不确定**——示例把
结果**排序后再打印/断言**，输出才可复现。教程全部并发示例遵守此纪律（CI 才不闪断）。

## 17.4 非结构化 Task：自己管生命周期

```swift
let task = Task { () -> String in ... }   // 立即起步，不属于任何作用域
task.cancel()                             // 请求取消（协作式）
let value = await task.value              // 等结果
```

`Task { }` 是"脱离结构"的并发——用于"发后不管"的响应用户操作、桥接回调 API。代价：
生命周期你负责（忘了引用就没法 cancel）。**默认选择结构化**（async let / Group），
非结构化 Task 只在边界使用。

## 17.5 取消：协作式的自觉

```swift
let task = Task { () -> String in
    for i in stride(from: 100, through: 1, by: -1) {
        if Task.isCancelled {          // 检查点：取消是"请求"，退出靠自觉
            return "在第 \(visited) 步被取消"
        }
        visited += 1
    }
    return "跑完全程"
}
task.cancel()
```

Swift 的取消是**协作式**：`cancel()` 只立标志，任务在**检查点**（`Task.isCancelled`
查询、`try await Task.checkCancellation()`、或任何抛 `CancellationError` 的挂起）自觉
退出。没有强杀。写长任务时每轮循环/每个阶段放一个检查点——否则用户"取消"了你的
任务还在烧 CPU。

示例用"先 cancel 再 await value"（同一 actor 串行）保证首检查点必中，输出确定。

## 17.6 AsyncStream：异步序列一瞥

```swift
func numberStream(_ n: Int) -> AsyncStream<Int> {
    AsyncStream { continuation in
        for i in 1...n { continuation.yield(i) }
        continuation.finish()
    }
}

for await n in numberStream(5) { ... }   // 1 2 3 4 5
```

`AsyncStream` 是"生产者-消费者"的字面量：continuation 一端 yield，消费端 `for await`。
通知、事件、日志流的桥接全靠它。AsyncSequence 家族（maps/chunks/合并）是 Sequence
的异步镜像——教程点到为止，方向在此。

## 17.7 坑位清单（含实测）

1. **`await` 不能出现在非赋值运算符右侧**（实测）：`await a + await b` 编译错误——
   `(await a) + (await b)`。
2. **`precondition(...)` 里不能 `await`/`try`**（autoclosure 限制，与 16 章同源）：
   先求值成 `let`，再断言。
3. **`for await` 收割顺序不定**：并发结果的打印/断言前先排序或聚合——示例
   `gatherTemperatures` 的 `.sorted` 就是为此存在。
4. **忘记 await 编译器会提醒**，但**忘记取消是你自己的事**：非结构化 Task 持有引用
   以便 cancel；结构化并发的作用域退出自动收摊。
5. **Task 闭包的 Sendable 检查（Swift 6）**：捕获的变量必须可安全跨并发域——捕获
   `var` 直接编译错误，捕获值类型/let 没问题（18 章展开）。
6. **async 函数不会自动并发**：`for x in xs { await f(x) }` 是串行（逐个挂起等待）；
   要并发用 async let（少量）或 TaskGroup（批量）——示例 averageTemperature 对照
   gatherTemperatures 就是这两条路线。

上一章：[16 · ARC 与内存](16-arc.md) ｜ 下一章：[18 · 并发 II](18-actors.md) ｜ 返回：[README](../README.md)
