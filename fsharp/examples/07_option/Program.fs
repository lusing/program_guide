open System

// ═══ 7.2 返回 option 而不是抛异常 ═══
let safeDivide a b = if b = 0 then None else Some(a / b)

// ═══ 7.3 解析可能失败：返回 option ═══
let parseInt (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | false, _ -> None

[<EntryPoint>]
let main _ =

    // ═══ 7.1 构造与模式匹配消耗 ═══
    let someValue = Some 42
    let noneValue: int option = None
    match someValue with
    | Some v -> printfn "someValue = %d" v
    | None -> printfn "没有值"
    printfn "直接打印 %A / %A" someValue noneValue

    // ═══ 7.2 安全除法 ═══
    printfn "10 / 2 = %A" (safeDivide 10 2)
    printfn "10 / 0 = %A" (safeDivide 10 0)

    // ═══ 7.3 Option.map / bind 串联 ═══
    printfn "map×2 = %A" (Some 5 |> Option.map (fun x -> x * 2))
    let reciprocal s =
        parseInt s |> Option.bind (fun n -> safeDivide 100 n)
    printfn "reciprocal \"4\" = %A" (reciprocal "4")
    printfn "reciprocal \"0\" = %A" (reciprocal "0")
    printfn "reciprocal \"x\" = %A" (reciprocal "x")

    // ═══ 7.4 默认值与备选 ═══
    printfn "defaultValue 0 = %d" (None |> Option.defaultValue 0)
    printfn "orElse = %A" (None |> Option.orElse (Some 7))
    printfn "isSome = %b" (Some 1 |> Option.isSome)

    // ═══ 7.5 集合 API 里的 option ═══
    let found = [ 1; 3; 5; 7 ] |> List.tryFind (fun x -> x > 4)
    printfn "tryFind = %A" found
    let ages = Map [ ("Alice", 30); ("Bob", 25) ]
    printfn "Map.tryFind Alice = %A" (Map.tryFind "Alice" ages)
    printfn "Map.tryFind Carol = %A" (Map.tryFind "Carol" ages)

    // ═══ 7.6 与 null / Nullable 的边界转换 ═══
    // C# 风格 API（如 Array.Find 找不到时）返回 null；用 `| null` 注解显式接住可空值
    let csharpResult: string | null = System.Array.Find([||], fun (s: string) -> true)
    printfn "Option.ofObj null = %A" (Option.ofObj csharpResult)
    printfn "Option.ofNullable 5 = %A" (Option.ofNullable (Nullable 5))
    printfn "Option.toNullable None = %A" (Option.toNullable None)
    0
