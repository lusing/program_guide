open System
open System.Text
open System.Threading.Tasks

// ═══ 18.4 byref：向函数传可变引用（byref 参数只能放顶层函数/方法上）═══
let bump (v: byref<int>) = v <- v + 1

[<EntryPoint>]
let main _ =

    // ═══ 18.1 直接调用 C# 风格的 BCL ═══
    let sb = StringBuilder()
    sb.Append("F#").Append(" <-> ").Append("C#") |> ignore
    printfn "%s" (sb.ToString())
    printfn "join=%s format=%s" (String.Join(", ", [ "a"; "b"; "c" ])) (String.Format("{0:D4}", 42))

    // ═══ 18.2 null 边界：用 option 包装 C# 的 null ═══
    let found: string | null = Array.Find([||], fun (s: string) -> true)   // C# API：找不到返回 null
    match Option.ofObj found with
    | Some s -> printfn "有值 %s" s
    | None -> printfn "C# 返回了 null → Option.ofObj 安全包装"

    // ═══ 18.3 Nullable<T> 双向转换 ═══
    printfn "ofNullable=%A %A" (Option.ofNullable (Nullable 5)) (Option.ofNullable (Nullable<int>()))

    // ═══ 18.4 byref：向函数传可变引用 ═══
    let mutable x = 10
    bump &x
    printfn "byref 后 x = %d" x

    // ═══ 18.5 Span：高性能切片 ═══
    let arr = [| 1; 2; 3; 4; 5 |]
    let span = arr.AsSpan(1, 3)
    let mutable sum = 0
    for i in 0 .. span.Length - 1 do
        sum <- sum + span[i]
    printfn "span 求和 = %d" sum

    // ═══ 18.6 订阅 .NET 事件 ═══
    use timer = new Timers.Timer(200.0)
    timer.Elapsed.Add(fun _ -> printfn "Timer 事件触发")
    timer.Start()
    Threading.Thread.Sleep 400
    timer.Stop()

    // ═══ 18.6b 事件 → IObservable：可组合的事件流（FSharp.Core 内置组合子）═══
    // 《Concurrency in .NET》第 6 章：IEvent 本身继承 IObservable，事件流能 map/filter 像序列一样组合
    use timer2 = new Timers.Timer(80.0)
    let ticks = ref 0
    use sub =
        timer2.Elapsed                                       // IEvent<_,_> 继承 IObservable<_>，直接进管道
        |> Observable.map (fun _ -> incr ticks; !ticks * 100)   // 变换：刻度序号 → 数字
        |> Observable.filter (fun v -> v >= 200)                // 筛选：只留第 2 个刻度起
        |> Observable.subscribe (fun v -> printfn "observable: 第 %d 个刻度 → %d" (v / 100) v)
    timer2.Start()
    Threading.Thread.Sleep 400
    timer2.Stop()

    // ═══ 18.7 Task 与 async 互转 ═══
    let fromTask: Task<int> = Task.FromResult 20
    let viaAsync = fromTask |> Async.AwaitTask |> Async.RunSynchronously
    let viaTask = async { return viaAsync + 1 } |> Async.StartAsTask
    printfn "Task→async→Task: %d" viaTask.Result

    // ═══ 18.8 query 表达式：F# 的 LINQ 查询语法 ═══
    let squares =
        query { for i in [ 1 .. 5 ] do select (i * i) }
        |> Seq.toList
    printfn "query 结果 = %A" squares
    0
