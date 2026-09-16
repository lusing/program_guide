open System
open System.IO
open System.Threading.Tasks

// ═══ 13.1 定义 async 工作流（此刻并不执行）═══
let fetchPage (url: string) =
    async {
        do! Async.Sleep 200
        return sprintf "%s → %d 字节（模拟）" url url.Length
    }

[<EntryPoint>]
let main _ =

    // ═══ 13.1 let! 串联 + RunSynchronously 触发 ═══
    let demo =
        async {
            let! a = fetchPage "https://example.com/a"
            let! b = fetchPage "https://example.com/b"
            return [ a; b ]
        }
    Async.RunSynchronously demo |> List.iter (printfn "%s")

    // ═══ 13.2 Async.Parallel：总耗时 ≈ 单个任务 ═══
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

    // ═══ 13.3 task {}：与 .NET Task 原生融合（F# 6+）═══
    let t =
        task {
            let! x = Task.FromResult 40
            do! Task.Delay 100
            return x + 2
        }
    printfn "task 结果 = %d" t.Result

    // ═══ 13.4 async ↔ Task 互转 ═══
    let roundTrip =
        async { return 7 }
        |> Async.StartAsTask
        |> Async.AwaitTask
        |> Async.RunSynchronously
    printfn "async↔Task 往返 = %d" roundTrip

    // ═══ 13.5 用 AwaitTask 桥接 .NET 的 XxxAsync ═══
    let path = Path.Combine(Path.GetTempPath(), "fsharp-async-demo.txt")
    async {
        do! File.WriteAllTextAsync(path, "异步写入的内容") |> Async.AwaitTask
        let! text = File.ReadAllTextAsync(path) |> Async.AwaitTask
        printfn "读回 %d 字符：%s" text.Length (text.Trim())
    }
    |> Async.RunSynchronously

    // ═══ 13.6 取消令牌 ═══
    // 注意：取消异常由运行器（RunSynchronously）抛出，try/with 要包住运行调用本身
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
    printfn "取消演示 outcome = %A" outcome
    0
