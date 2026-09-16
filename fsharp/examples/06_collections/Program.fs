open System.Linq

[<EntryPoint>]
let main _ =
    let values = [ 8; 3; 11; 7; 5; 9; 2 ]

    let doubled = values |> List.map (fun x -> x * 2)
    let evens = values |> List.filter (fun x -> x % 2 = 0)
    let total = values |> List.sum
    let largeValues = values.AsQueryable().Where(fun x -> x > 5).ToList()

    printfn "doubled = %A" doubled
    printfn "evens = %A" evens
    printfn "sum = %d" total
    printfn "large values = %A" largeValues
    0
