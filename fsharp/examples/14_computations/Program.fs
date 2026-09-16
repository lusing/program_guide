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
    0
