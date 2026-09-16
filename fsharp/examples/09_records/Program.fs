type Person =
    { Name: string
      Age: int }

type Shape =
    | Circle of radius: float
    | Rectangle of width: float * height: float

[<EntryPoint>]
let main _ =
    let alice = { Name = "Alice"; Age = 28 }

    let area shape =
        match shape with
        | Circle r -> System.Math.PI * r * r
        | Rectangle (w, h) -> w * h

    printfn "%s is %d years old." alice.Name alice.Age
    printfn "Circle area = %.2f" (area (Circle 3.0))
    printfn "Rectangle area = %.2f" (area (Rectangle (2.0, 5.0)))
    0
