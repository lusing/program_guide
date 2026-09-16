open System

// ═══ 8.3 错误也建模成数据：可读的失败原因 ═══
type ParseError =
    | EmptyInput
    | NotANumber of string
    | OutOfRange of int

let parseInt (input: string) =
    if String.IsNullOrWhiteSpace input then Error EmptyInput
    else
        match Int32.TryParse input with
        | true, v -> Ok v
        | false, _ -> Error(NotANumber input)

let validateRange lo hi v =
    if v < lo || v > hi then Error(OutOfRange v) else Ok v

// ═══ 8.3 用 bind/map 串成校验链 ═══
let classifyAge input =
    parseInt input
    |> Result.bind (validateRange 0 150)
    |> Result.map (fun age -> if age >= 18 then "成年" else "未成年")

[<EntryPoint>]
let main _ =

    // ═══ 8.1 Result 的两轨结构 ═══
    let ok: Result<int, string> = Ok 1
    let err: Result<int, string> = Error "boom"
    printfn "ok = %A, err = %A" ok err

    // ═══ 8.2 map / bind / mapError ═══
    printfn "map = %A" (Ok 5 |> Result.map (fun x -> x * 2))
    printfn "map 不碰 Error = %A" (Error "e" |> Result.map (fun x -> x * 2))
    printfn "bind = %A" (Ok "20" |> Result.bind parseInt)
    printfn "mapError = %A" (Error(NotANumber "x") |> Result.mapError (sprintf "%A"))

    // ═══ 8.3 校验链实战 ═══
    [ "30"; "abc"; "200"; "" ]
    |> List.iter (fun s -> printfn "%A -> %A" s (classifyAge s))

    // ═══ 8.4 组合多个 Result ═══
    let addResults r1 r2 =
        match r1, r2 with
        | Ok a, Ok b -> Ok(a + b)
        | Error e, _ -> Error e
        | _, Error e -> Error e
    printfn "3 + 4 = %A" (addResults (parseInt "3") (parseInt "4"))
    printfn "3 + x = %A" (addResults (parseInt "3") (parseInt "x"))

    // ═══ 8.5 异常：try/with 与类型过滤 ═══
    let caught =
        try
            failwith "出错了"
            "没抛异常"
        with ex ->
            sprintf "捕获：%s" ex.Message
    printfn "%s" caught

    // ═══ 8.6 自定义异常抛出 ═══
    let parseOrThrow s =
        match parseInt s with
        | Ok v -> v
        | Error(NotANumber raw) -> raise (FormatException $"无法解析：{raw}")
        | Error e -> failwithf "%A" e
    try
        parseOrThrow "xyz" |> ignore
    with :? FormatException as ex ->
        printfn "自定义异常：%s" ex.Message

    // ═══ 8.7 分层策略总结 ═══
    printfn "经验：业务逻辑内部用 Result，边界（IO/框架）用异常。"
    0
