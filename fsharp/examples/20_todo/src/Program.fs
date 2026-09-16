module Program

open System

[<EntryPoint>]
let main argv =
    let todos = Todo.load ()
    match Todo.parse argv with
    | Error usage ->
        printfn "%s" usage
        printfn "用法：todo add <标题> | done <id> | remove <id> | show | reset"
        1
    | Ok cmd ->
        match Todo.apply cmd todos with
        | Error msg ->
            printfn "错误：%s" msg
            1
        | Ok (next, report) ->
            match cmd with
            | Todo.Command.Show -> ()           // 查询不改状态
            | _ -> Todo.save next
            printfn "%s" report
            0
