# 13 · 异步：async 与 task 两个世界

> 对应示例：examples/13_async

## 13.1 解决什么问题

网络/磁盘 I/O 期间线程干等是浪费。F# 有两套异步设施：**async 计算表达式**（F# 原创，2007 年就有）和 **task 计算表达式**（F# 6 加入，直连 .NET Task）。都能写 `let!` 风格代码；差别在底层与前男友们的兼容性——先学语法，再讲选型。

## 13.2 async：定义不执行，触发才有结果

```fsharp
let fetchPage (url: string) =
    async {
        do! Async.Sleep 200
        return sprintf "%s → %d 字节（模拟）" url url.Length
    }
```

`async { ... }` 造出的是**描述**，不是动作——不触发就不跑。`let!` 等待结果并绑定、`do!` 执行丢弃结果、`return` 返回。触发用 `Async.RunSynchronously`：

```fsharp
let demo =
    async {
        let! a = fetchPage "https://example.com/a"
        let! b = fetchPage "https://example.com/b"
        return [ a; b ]
    }
Async.RunSynchronously demo |> List.iter (printfn "%s")
```

示例实测耗时约 400ms——两次 Sleep **串行**。

## 13.3 Async.Parallel：并发执行

```fsharp
let sw = Diagnostics.Stopwatch.StartNew()
let squares =
    [ 1 .. 3 ]
    |> List.map (fun i ->
        async {
            do! Async.Sleep 300
            return i * i
        })
    |> Async.Parallel
    |> Async.RunSynchronously
sw.Stop()
printfn "并行结果 = %A，耗时 %d ms（串行需 900ms）" (Array.toList squares) sw.ElapsedMilliseconds
// 并行结果 = [1; 4; 9]，耗时 ≈310ms
```

三个 300ms 任务并行完成只花约一个任务的时间——示例实测 314ms，白纸黑字。

## 13.4 task {}：与 .NET Task 原生融合（F# 6+）

```fsharp
let t =
    task {
        let! x = Task.FromResult 40
        do! Task.Delay 100
        return x + 2
    }
printfn "task 结果 = %d" t.Result    // 42
```

`task { }` 里 `let!` 直接接 `Task<T>`（async 里要桥接）。两者对比：

| | `async {}` | `task {}` |
|---|---|---|
| 底层 | F# 自己的 Async | .NET Task/ValueTask |
| 与 C# 互作 | 要 StartAsTask/AwaitTask 转换 | 零转换 |
| 取消令牌 | 显式传递 | 隐式流动（CurrentExecutionContext） |
| 性能 | 冷启动开销略高 | 更贴近 C# async |
| 建议 | 老代码、库 | **新代码默认** |

## 13.5 互转 API

```fsharp
let roundTrip =
    async { return 7 }
    |> Async.StartAsTask       // Async<T> → Task<T>
    |> Async.AwaitTask         // Task<T> → Async<T>
    |> Async.RunSynchronously
printfn "async↔Task 往返 = %d" roundTrip   // 7
```

桥接 .NET 的 XxxAsync 文件 API 是 AwaitTask 的日常：

```fsharp
async {
    do! File.WriteAllTextAsync(path, "异步写入的内容") |> Async.AwaitTask
    let! text = File.ReadAllTextAsync(path) |> Async.AwaitTask
    printfn "读回 %d 字符：%s" text.Length (text.Trim())
}
|> Async.RunSynchronously
```

## 13.6 取消令牌

```fsharp
// 取消异常由运行器（RunSynchronously）抛出，try/with 要包住运行调用本身
let cts = new Threading.CancellationTokenSource()
cts.CancelAfter(100)
let work =
    async {
        do! Async.Sleep 3000
        return "完成"
    }
let outcome =
    try
        Async.RunSynchronously(work, cancellationToken = cts.Token) |> Some
    with :? OperationCanceledException ->
        None
printfn "取消演示 outcome = %A" outcome   // None
```

**示例踩过的坑**：`OperationCanceledException` 从 `RunSynchronously` 运行器抛出，async 体内部的 try/with 接不住——with 要包运行调用（task{} 世界里取消经 CurrentExecutionContext 流动，语义更自然）。

## 13.7 MailboxProcessor：agent = 消息循环 + 状态隔离

F# 独有的并发原语 `MailboxProcessor<'Msg>`（社区惯称 **agent**，《Concurrency in .NET》第 11 章整章的主角，也是 F# 相对 C# 最锋利的一把刀）。思路：**与其用锁保护共享可变状态，不如让状态只活在一个串行处理消息的循环里**——外面谁都摸不到：

```fsharp
type CounterMsg =
    | Increment of int
    | GetCount of AsyncReplyChannel<int>          // 回信通道：两向通信的"回执"

let counter =
    MailboxProcessor<CounterMsg>.Start(fun inbox ->
        let rec loop count =                      // 「当前状态」就是递归参数
            async {
                let! msg = inbox.Receive()        // 等下一条消息（不占线程）
                match msg with
                | Increment n -> return! loop (count + n)     // 新状态 = f(旧状态, 消息)
                | GetCount reply -> reply.Reply count; return! loop count
            }
        loop 0)

for _ in 1 .. 1000 do counter.Post(Increment 1)   // Post 立即返回（只入队）
let finalCount = counter.PostAndAsyncReply(GetCount) |> Async.RunSynchronously
// → 1000
```

要点拆解：

- **状态在递归参数里**：`loop count` 每处理一条消息就带着新状态递归——没有一行 `mutable`，却是"有状态"的并发组件。这是第 14 章计算表达式之外的另一类函数式状态管理
- **消息类型是 DU**：编译器保证 `match` 穷尽——新增消息形态时漏处理直接编译错误
- **`Post` 异步入队、`PostAndAsyncReply` 带回执**：前者即发即忘，后者通过 `AsyncReplyChannel<'T>` 拿到 agent 的回答（请求-响应模式）
- **顺序保证**：mailbox 是 FIFO——示例先投 1000 条 `Increment` 再发 `GetCount`，回复必然是 1000。1000 次"并发"写同一个计数器，零锁零丢失

它解决的正是第 30/31 章（C# 教程）里"锁族/Interlocked/并发容器"那一整层问题——**share-nothing**：没有共享就没有竞态，消息排队天然串行。适合：串行化写库/写文件（书里用它做数据库写入代理）、缓存、日志收集、每玩家一个 agent 的游戏实体。F# 的 `Array.Parallel.map` 则是数据并行的一行版（`Array.Parallel.map f [|1..8|]`，对应 C# 的 PLINQ）。

## 13.8 Array.Parallel 与并行路线

`Array.Parallel.map`/`Array.Parallel.iter`（FSharp.Core 内置）是数据并行的最短路径，对应 C# 的 PLINQ。路线直觉：**数据并行**（每个元素独立算）用 `Array.Parallel`；**任务并行/IO 并发**用 `Async.Parallel`（13.3）；**共享状态串行化**用 agent（13.7）——三件套覆盖绝大多数并发场景。

## 13.9 坑位清单

- **忘了触发**：`async { ... }` 不 RunSynchronously/Start，程序结束它都没跑——新手第一大坑。
- **Sleep 家族不混用**：async 里用 `Async.Sleep`，task 里用 `Task.Delay`；跨界先转换。
- **task 里 `let!` 已解包**：`let! x = Task.FromResult 40` 的 x 是 int 不是 Task<int>。
- **取消要包对位置**：见 13.6，OCE 在运行器层抛。
- **闭包捕获循环变量**：并行循环里 `fun i -> ...` 每次捕获当时的 i（F# 的 for 每次迭代新绑定，比 C# 老 for 安全，但 mutable 捕获仍要小心）。
- **agent 体里抛异常默认干掉整个循环**：`Receive` 之后的处理抛了异常，agent 停摆、后续消息没人收——危险操作在循环内 try/with，或用 `MailboxProcessor.Start` 的重载传错误处理函数。
- **`PostAndAsyncReply` 不设超时**：agent 死了（上一条坑）就永久等待——`agent.DefaultTimeout <- 5000` 或调用重载传超时毫秒数，超时抛 `TimeoutException`。
- **agent 内再做耗时同步 IO**：串行化是把双刃剑——所有消息排队，一个慢操作堵住整条队列；耗时工作丢给 `Async.StartChild`/`Task`，agent 只做协调。

---

上一章：[12 泛型与度量单位](12-generics.md) · 下一章：[14 计算表达式](14-computations.md)
