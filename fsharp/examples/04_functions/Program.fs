[<EntryPoint>]
let main _ =

    // ═══ 4.1 函数是一等公民 + 柯里化 ═══
    let add a b = a + b        // 签名 int -> int -> int（柯里化）
    let add5 = add 5           // 部分应用：只喂第一个参数
    printfn "add 3 4 = %d" (add 3 4)
    printfn "add5 10 = %d" (add5 10)

    // ═══ 4.2 管道 |>：数据流式表达 ═══
    let values = [ 3; 1; 4; 1; 5; 9; 2; 6 ]
    let result =
        values
        |> List.filter (fun x -> x % 2 = 1)   // 奇数
        |> List.map (fun x -> x * 10)         // ×10
        |> List.sum                           // 求和
    printfn "管道结果 = %d" result

    // ═══ 4.3 组合 >>：函数拼接 ═══
    let square x = x * x
    let negate x = -x
    let squareThenNegate = square >> negate    // 先 square 再 negate，产生新函数
    printfn "(square >> negate) 5 = %d" (squareThenNegate 5)

    // ═══ 4.4 高阶函数 ═══
    let twice f x = f (f x)
    printfn "twice square 3 = %d" (twice square 3)
    let adders = [ (fun x -> x + 1); (fun x -> x * 2) ]   // 函数也能进列表
    adders |> List.iter (fun f -> printfn "f 7 = %d" (f 7))

    // ═══ 4.5 递归：let rec ═══
    let rec factorial n = if n <= 1 then 1 else n * factorial (n - 1)
    printfn "5! = %d" (factorial 5)

    // ═══ 4.6 尾递归 + 累加器：不爆栈 ═══
    let rec sumTail acc list =
        match list with
        | [] -> acc
        | head :: tail -> sumTail (acc + head) tail
    printfn "sumTail [1..100] = %d" (sumTail 0 [ 1 .. 100 ])

    // ═══ 4.7 互递归：and ═══
    let rec isEven n = if n = 0 then true else isOdd (n - 1)
    and isOdd n = if n = 0 then false else isEven (n - 1)
    printfn "isEven 10 = %b" (isEven 10)
    0
