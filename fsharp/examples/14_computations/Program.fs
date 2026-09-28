open System

// ═══ 14.2 讲解性 builder：打印每次 Bind/Return ═══
type TraceBuilder() =
    member _.Bind(x, f) =
        printfn "Bind: %A" x
        match x with
        | Some v -> f v
        | None -> None
    member _.Return x =
        printfn "Return: %A" x
        Some x
    member _.ReturnFrom x = x

let trace = TraceBuilder()

// ═══ 14.3 maybe builder：option 上的 let! 语法糖 ═══
type MaybeBuilder() =
    member _.Bind(x, f) =
        match x with
        | Some v -> f v
        | None -> None
    member _.Return x = Some x
    member _.ReturnFrom x = x

let maybe = MaybeBuilder()

// ═══ 14.4 result builder：Result 上的校验链 ═══
type ResultBuilder() =
    member _.Bind(x, f) =
        match x with
        | Ok v -> f v
        | Error e -> Error e
    member _.Return x = Ok x
    member _.ReturnFrom x = x

let validate = ResultBuilder()

let tryParseInt (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | false, _ -> None

// ═══ 14.6 生产级 CE 实例：asyncRetry（重试语义藏进 let!）═══
// 《Concurrency in .NET》第 9 章的 AsyncRetry：操作失败自动重试，成功才继续链
type AsyncRetryBuilder(maxRetries: int) =
    // 重试住在公共路径 runWithRetry 里——ReturnFrom 若写成恒等，return! 会整个绕过重试（实测踩过）
    let runWithRetry (m: Async<'T>) : Async<'T> =
        async {
            let rec attempt n =
                async {
                    try
                        return! m
                    with ex ->
                        if n < maxRetries then
                            printfn "  重试 %d/%d（%s）" (n + 1) maxRetries ex.Message
                            return! attempt (n + 1)
                        else
                            return raise ex                             // 重试次数用尽：异常上抛
                }
            return! attempt 0
        }
    member _.Bind(m: Async<'T>, f: 'T -> Async<'R>) : Async<'R> =
        async {
            let! v = runWithRetry m
            return! f v
        }
    member _.Return x = async { return x }
    member _.ReturnFrom x = runWithRetry x

let asyncRetry = AsyncRetryBuilder(3)

[<EntryPoint>]
let main _ =

    // ═══ 14.1 内置 CE：seq { }（async/task 见第 13 章）═══
    let squares =
        seq {
            for i in 1 .. 5 do
                yield i * i
        }
    printfn "seq CE = %A" (List.ofSeq squares)

    // ═══ 14.2 trace：看清 let! 的本质 ═══
    let traced =
        trace {
            let! a = Some 1
            let! b = Some 2
            return a + b
        }
    printfn "trace 结果 = %A" traced

    // ═══ 14.3 maybe：串联可失败操作 ═══
    let calc input1 input2 =
        maybe {
            let! a = tryParseInt input1
            let! b = tryParseInt input2
            let! c = if b = 0 then None else Some(100 / b)
            return a + c
        }
    printfn "maybe 成功 = %A" (calc "40" "8")
    printfn "maybe 失败 = %A" (calc "40" "x")

    // ═══ 14.4 validate：业务校验链 ═══
    let parse (s: string) =
        match Int32.TryParse s with
        | true, v -> Ok v
        | false, _ -> Error $"{s} 不是数字"

    let inRange lo hi v =
        if v < lo || v > hi then Error $"{v} 超出 [{lo}, {hi}]" else Ok()

    let processInput s =
        validate {
            let! n = parse s
            do! inRange 1 100 n
            return n * 2
        }
    printfn "validate 成功 = %A" (processInput "21")
    printfn "validate 非数字 = %A" (processInput "abc")
    printfn "validate 超范围 = %A" (processInput "150")

    // ═══ 14.5 return!：直接透传另一个同类计算 ═══
    let passthrough = maybe { return! Some 9 }
    printfn "return! = %A" passthrough

    // ═══ 14.6 asyncRetry：失败自动重试的 async 链 ═══
    let mutable failures = 0
    let flaky () =
        async {
            failures <- failures + 1
            if failures < 3 then failwith $"第 {failures} 次故意失败"
            return $"第 {failures} 次尝试终于成功"
        }
    let retryOutcome = asyncRetry { return! flaky () } |> Async.RunSynchronously
    printfn "asyncRetry = %s" retryOutcome
    0
