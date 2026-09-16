# 20 · 实战：待办管理器 CLI

> 对应示例：examples/20_todo（嵌套 src / tests 双工程）

## 20.1 这一章做什么

把全书知识组装成一个真实的小工具：**待办管理器 CLI**。命令表：

| 命令 | 行为 | 退出码 |
|---|---|---|
| `todo add <标题>` | 新增待办（标题可多词） | 0 |
| `todo done <id>` | 标记完成 | 0 |
| `todo remove <id>` | 删除 | 0 |
| `todo show` | 列出全部（无参数默认 show） | 0 |
| `todo reset` | 清空状态 | 0 |
| 解析/操作失败 | 打印原因 + 用法 | 1 |

状态持久化到 `%TEMP%\fsharp-todo.json`。先看效果（build.ps1 的演示序列，实测输出）：

```
$ todo add learn F#
已添加 #1 learn F#
$ todo add write tutorial
已添加 #2 write tutorial
$ todo done 2
完成 #2
$ todo show
[ ] #1 learn F#
[x] #2 write tutorial
$ todo remove 1
已删除 #1
```

## 20.2 工程结构：为什么分两个工程

```text
examples/20_todo/
├── src/
│   ├── Todo.fsproj      # Exe
│   ├── Todo.fs          # 领域 + 解析 + 存储 + 核心逻辑
│   └── Program.fs       # 薄壳入口
└── tests/
    ├── Todo.Tests.fsproj    # xUnit，ProjectReference 引 src
    └── Tests.fs
```

`<ProjectReference Include="..\src\Todo.fsproj" />` 让测试直接调用 `Todo.parse`/`Todo.apply`——**核心逻辑可测，入口壳够薄**（第 17 章的架构落地）。fsproj 的 `Compile` 顺序照旧：`Todo.fs` 在前、`Program.fs` 殿后（第 01 章）。

## 20.3 领域建模：数据用 record，命令用 DU

`Todo.fs` 开头：

```fsharp
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
```

第 09/10 章的口诀实战：**待办是数据（record），命令是选择（DU）**。先定这两个类型，后面所有函数的签名自然浮现。

## 20.4 解析：argv → Result<Command, string>

```fsharp
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
```

第 05 章的模式匹配在此全功率输出：列表模式分形状、`::` 收多词标题、TryParse 包进 Ok/Error。**非法输入在边界就变成 `Result`**——后面没有任何 throw。

## 20.5 持久化：JSON 文件

```fsharp
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
```

第 15 章的 STJ 原生支持 record list；`load` 的 try/with + Option.ofObj 是"文件可能坏/空"的现实防御。`save` 里那行注释是示例实测踩的坑：**方法不能柯里化**（第 04 章），管道要改成显式两参调用。

## 20.6 核心逻辑：apply 纯函数

全书最核心的 20 行——命令 × 状态 → （新状态, 报告）：

```fsharp
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
```

`with` 非破坏更新（09 章）、`tryFind`+option 判存在（07 章）、DU 完备匹配（05/10 章）、**零 IO**（17 章可测性）——一本书的知识点在一个函数里合流。`Show` 返回原状态不改文件，由调用方决定。

## 20.7 Program 薄壳：只做 IO 与退出码

```fsharp
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
```

三层各一行：load → parse → apply；错误路径返回退出码 1（脚本可判成功失败）。

## 20.8 测试：每个命令至少一个用例

tests/Tests.fs 十个用例分布：parse 三组（默认 show、多词标题、非法命令 Theory×3）、apply 六个（add 分配递增 id 且断言**报告文本**、done 只改目标、remove 清空、不存在 id 返回 Error×2、reset 报告文案）。跑法（build.ps1 自动执行）：

```
已通过! - 失败: 0，通过: 10，已跳过: 0，总计: 10 - Todo.Tests.dll
```

注意测试类名用单一名词（`type 解析测试 ()`，第 17 章的坑）。

## 20.9 扩展练习

1. **优先级**：record 加 `Priority` DU（Low/Mid/High），show 按优先级排序。
2. **过滤**：`todo list --done` / `--todo` 只看已完成/未完成（解析器加参数分支）。
3. **交互模式**：无参数时进 REPL 循环读命令（`Console.ReadLine` + `string.Split` 喂 parse）。
4. **度量单位**：给"预计分钟数"加 `[<Measure>] type minute`，sum 时量纲安全（第 12 章）。
5. **JSON 输出**：`--json` 开关把 show 结果序列化输出（对接脚本）。

## 20.10 全书回顾映射

| 章 | 在本项目的落点 |
|---|---|
| 03 值/不可变 | 所有状态走新值，无 mutable |
| 04 函数/管道 | `todos |> List.map ... |> String.concat` |
| 05 模式匹配 | parse 的列表模式、apply 的 DU 分派 |
| 06 集合 | tryFind/map/filter/rev |
| 07 Option | tryFind 判存在、load 的 ofObj |
| 08 Result | parse/apply 的全链路错误处理 |
| 09/10 record/DU | Todo + Command 建模 |
| 13 异步 | （CLI 场景未用——扩展练习接 HTTP 同步即可） |
| 15 文件 JSON | load/save 持久化 |
| 17 测试 | tests 工程十用例全绿 |

## 20.11 坑位清单

- **argv 的引号**：`todo add "learn F#"` 的引号由 shell 处理，程序收到的是已拆好的数组——所以 parse 用 `String.concat " "` 重新拼标题。
- **TEMP 文件冲突**：多机/多用户共享 TEMP 时加进程或用户名后缀。
- **apply 里做 IO 会毁掉可测性**：想加"写日志"？放在 Program 壳层，核心保持纯。
- **退出码要返回**：`main` 的最后一个表达式就是进程退出码，别忘写 0/1。
- **状态文件被手改**：load 的 try/with 兜底为空列表，别让坏文件拖崩整个 CLI。
