[<EntryPoint>]
let main _ =
    let name = "guide"
    let age = 21
    let score = 98.5
    let active = true

    printfn "Name: %s" name
    printfn "Age: %d" age
    printfn "Score: %.1f" score
    printfn "Active: %b" active

    if active then
        printfn "Status: ready to learn F#"
    else
        printfn "Status: paused"
    0
