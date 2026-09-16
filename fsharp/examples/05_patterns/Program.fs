open System

// ═══ 5.6 完整活动模式：把分类规则变成可 match 的形状 ═══
let (|Even|Odd|) n = if n % 2 = 0 then Even else Odd

// ═══ 5.7 部分活动模式：可能不匹配 ═══
let (|DivisibleBy|_|) divisor n =
    if n % divisor = 0 then Some DivisibleBy else None

// ═══ 5.8 参数化活动模式：包装 TryParse ═══
let (|IntParse|_|) (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | false, _ -> None

// ═══ 5.4 列表模式：按形状分类 ═══
let describe list =
    match list with
    | [] -> "空列表"
    | [ single ] -> sprintf "单元素 %d" single
    | [ a; b ] -> sprintf "两个元素 %d 和 %d" a b
    | head :: _ -> sprintf "多元素，开头是 %d" head

// ═══ 5.5 记录模式用到的类型 ═══
type Person = { Name: string; Age: int }

[<EntryPoint>]
let main _ =

    // ═══ 5.1 常量与变量模式 ═══
    let meaning =
        match 42 with
        | 0 -> "零"
        | 42 -> "宇宙的答案"
        | other -> sprintf "其他(%d)" other
    printfn "%s" meaning

    // ═══ 5.2 when 卫兵与 or 模式 ═══
    let classify n =
        match n with
        | 0 -> "零"
        | x when x < 0 -> "负数"
        | 1 | 3 | 5 | 7 | 9 -> "个位奇数"
        | _ -> "其他"
    [ -2; 0; 3; 8 ] |> List.iter (fun n -> printfn "%d -> %s" n (classify n))

    // ═══ 5.3 元组解构模式 ═══
    match (3, 4) with
    | (0, 0) -> printfn "原点"
    | (x, y) -> printfn "点 (%d, %d)" x y

    // ═══ 5.4 列表与 cons 模式 ═══
    printfn "%s" (describe [])
    printfn "%s" (describe [ 7 ])
    printfn "%s" (describe [ 2; 9 ])
    printfn "%s" (describe [ 4; 5; 6 ])

    // ═══ 5.5 记录模式 + function 关键字 ═══
    let users = [ { Name = "Alice"; Age = 30 }; { Name = "Bob"; Age = 15 } ]
    let label =
        function
        | { Name = n; Age = a } when a >= 18 -> sprintf "%s（成年）" n
        | { Name = n } -> sprintf "%s（未成年）" n
    users |> List.iter (fun u -> printfn "%s" (label u))

    // ═══ 5.6 使用完整活动模式 ═══
    let evenOrOdd n =
        match n with
        | Even -> "偶数"
        | Odd -> "奇数"
    [ 1 .. 4 ] |> List.iter (fun n -> printfn "%d 是%s" n (evenOrOdd n))

    // ═══ 5.7 使用部分活动模式（FizzBuzz）═══
    let fizz n =
        match n with
        | DivisibleBy 15 -> "FizzBuzz"
        | DivisibleBy 3 -> "Fizz"
        | DivisibleBy 5 -> "Buzz"
        | _ -> string n
    [ 1 .. 7 ] |> List.iter (fun n -> printf "%s " (fizz n))
    printfn ""

    // ═══ 5.8 使用 IntParse 活动模式 ═══
    for s in [ "42"; "abc"; "7" ] do
        match s with
        | IntParse v -> printfn "\"%s\" 解析为 %d" s v
        | _ -> printfn "\"%s\" 不是整数" s
    0
