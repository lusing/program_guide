[<EntryPoint>]
let main _ =
    let add a b = a + b

    let isEven n =
        n % 2 = 0

    let describeNumber n =
        match n with
        | x when x < 0 -> "negative"
        | 0 -> "zero"
        | x when x % 2 = 0 -> "even"
        | _ -> "odd"

    printfn "add(12, 8) = %d" (add 12 8)
    printfn "isEven(10) = %b" (isEven 10)

    [1; 2; 3; 4; 5; 6]
    |> List.iter (fun x -> printfn "%d -> %s" x (describeNumber x))

    0
