open System
open System.IO

[<EntryPoint>]
let main _ =
    let writeLogAsync (path: string) (content: string) =
        async {
            do! Async.Sleep 50
            File.WriteAllText(path, content)
        }

    let directory = Path.Combine(Environment.CurrentDirectory, "build", "demo_output")
    Directory.CreateDirectory(directory) |> ignore
    let filePath = Path.Combine(directory, "notes.txt")
    let content = "F# async workflow\nready\n"

    writeLogAsync filePath content |> Async.RunSynchronously

    let readBack = File.ReadAllText(filePath)
    printfn "Wrote %d chars to %s" readBack.Length filePath
    printfn "Content: %s" (readBack.Trim())
    0
