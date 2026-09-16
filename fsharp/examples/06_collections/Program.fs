[<EntryPoint>]
let main _ =

    // ═══ 6.1 三种集合的构造 ═══
    let ls = [ 1 .. 8 ]              // list：不可变链表
    let arr = [| 1; 2; 3; 4 |]       // array：可变、连续内存
    let sq = seq { 1; 2; 3 }         // seq：惰性 IEnumerable
    printfn "list=%A array=%A" ls arr
    printfn "seq 转列表：%A" (sq |> List.ofSeq)

    // ═══ 6.2 List 模块：map / filter ═══
    let doubled = ls |> List.map (fun x -> x * 2)
    let evens = ls |> List.filter (fun x -> x % 2 = 0)
    printfn "doubled=%A" doubled
    printfn "evens=%A" evens

    // ═══ 6.3 fold 家族 ═══
    let total = ls |> List.fold (fun acc x -> acc + x) 0
    let product = ls |> List.fold (fun acc x -> acc * x) 1
    let steps = ls |> List.scan (fun acc x -> acc + x) 0  // 保留每步中间值
    printfn "sum=%d product=%d" total product
    printfn "scan 中间步骤=%A" steps

    // ═══ 6.4 分组与排序 ═══
    let words = [ "apple"; "pear"; "avocado"; "fig" ]
    let grouped = words |> List.groupBy (fun w -> w[0]) |> List.map (fun (k, v) -> (k, List.length v))
    let byLength = words |> List.sortBy (fun w -> w.Length)
    printfn "按首字母分组=%A" grouped
    printfn "按长度排序=%A" byLength

    // ═══ 6.5 array：可变、就地更新 ═══
    arr[0] <- 100
    printfn "更新后 array=%A" arr
    printfn "Array.map=%A" (arr |> Array.map (fun x -> x + 1))

    // ═══ 6.6 seq：惰性与无限序列 ═══
    let naturals = Seq.initInfinite (fun i -> i * i)
    printfn "前 5 个平方数 = %A" (naturals |> Seq.truncate 5 |> List.ofSeq)

    // ═══ 6.7 三种集合互转 ═══
    printfn "List.ofArray=%A" (List.ofArray arr)
    printfn "Array.ofList=%A" (Array.ofList ls)

    // ═══ 6.8 与 LINQ 的关系 ═══
    let linqStyle =
        System.Linq.Enumerable.Where(ls, fun x -> x > 3)
        |> Seq.map (fun x -> x + 100)
        |> List.ofSeq
    printfn "LINQ 风格等价结果=%A" linqStyle

    // ═══ 6.9 常用 API 速查 ═══
    printfn "长度=%d，包含 4？%b" ls.Length (List.contains 4 ls)
    printfn "splitAt 3 = %A" (List.splitAt 3 ls)
    0
