module Todo

open System
open System.IO
open System.Text.Json

// ═══ 20.2 领域模型：数据用 record，命令用 DU ═══
type Todo =
    { Id: int
      Title: string
      Done: bool }

type Command =
    | Add of title: string
    | Done of id: int
    | Remove of id: int
    | Show
    | Reset

// ═══ 20.3 解析：argv → Result<Command, string> ═══
let parse (argv: string array) : Result<Command, string> =
    match argv |> Array.toList with
    | [] -> Ok Show
    | [ "show" ] -> Ok Show
    | [ "reset" ] -> Ok Reset
    | "add" :: rest when rest <> [] -> Ok(Add(String.concat " " rest))
    | [ "add" ] -> Error "add 需要标题参数"
    | [ "done"; id ] ->
        match Int32.TryParse id with
        | true, v -> Ok(Done v)
        | false, _ -> Error $"done 需要整数 id：{id}"
    | [ "remove"; id ] ->
        match Int32.TryParse id with
        | true, v -> Ok(Remove v)
        | false, _ -> Error $"remove 需要整数 id：{id}"
    | unknown -> Error $"无法识别的命令：{unknown}"

// ═══ 20.4 持久化：JSON 文件 ═══
let statePath () = Path.Combine(Path.GetTempPath(), "fsharp-todo.json")

let load () : Todo list =
    let path = statePath ()
    if File.Exists path then
        try
            JsonSerializer.Deserialize<Todo list>(File.ReadAllText path)
            |> Option.ofObj
            |> Option.defaultValue []
        with _ -> []          // 文件损坏时从空状态开始
    else []

let save (todos: Todo list) =
    // 注意：.NET 方法不能柯里化，不能写 `json |> File.WriteAllText(path)`
    let json = JsonSerializer.Serialize(todos, JsonSerializerOptions(WriteIndented = true))
    File.WriteAllText(statePath (), json)

// ═══ 20.5 核心逻辑：纯函数，不碰 IO ═══
let nextId (todos: Todo list) =
    if todos = [] then 1
    else (todos |> List.map (fun t -> t.Id) |> List.max) + 1

let apply (cmd: Command) (todos: Todo list) : Result<Todo list * string, string> =
    match cmd with
    | Reset -> Ok([], "状态已清空")
    | Add title ->
        let t = { Id = nextId todos; Title = title; Done = false }
        Ok(t :: todos, $"已添加 #{t.Id} {t.Title}")
    | Show ->
        let render t = (if t.Done then "[x]" else "[ ]") + $" #{t.Id} {t.Title}"
        let body =
            if todos = [] then "（空）"
            else todos |> List.rev |> List.map render |> String.concat "\n"
        Ok(todos, body)
    | Done id ->
        match todos |> List.tryFind (fun t -> t.Id = id) with
        | None -> Error $"没有 id={id} 的待办"
        | Some _ ->
            let next = todos |> List.map (fun t -> if t.Id = id then { t with Done = true } else t)
            Ok(next, $"完成 #{id}")
    | Remove id ->
        match todos |> List.tryFind (fun t -> t.Id = id) with
        | None -> Error $"没有 id={id} 的待办"
        | Some _ ->
            let next = todos |> List.filter (fun t -> t.Id <> id)
            Ok(next, $"已删除 #{id}")
