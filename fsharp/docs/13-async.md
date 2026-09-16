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

## 13.7 坑位清单

- **忘了触发**：`async { ... }` 不 RunSynchronously/Start，程序结束它都没跑——新手第一大坑。
- **Sleep 家族不混用**：async 里用 `Async.Sleep`，task 里用 `Task.Delay`；跨界先转换。
- **task 里 `let!` 已解包**：`let! x = Task.FromResult 40` 的 x 是 int 不是 Task<int>。
- **取消要包对位置**：见 13.6，OCE 在运行器层抛。
- **闭包捕获循环变量**：并行循环里 `fun i -> ...` 每次捕获当时的 i（F# 的 for 每次迭代新绑定，比 C# 老 for 安全，但 mutable 捕获仍要小心）。
