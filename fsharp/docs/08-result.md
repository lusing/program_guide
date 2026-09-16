# 08 · Result 与异常：失败处理的两个世界

> 对应示例：examples/08_result

## 8.1 解决什么问题

失败分两种：**可预期的**（用户输入不是数字、余额不足——这是业务逻辑的一部分）和**不可预期的**（磁盘没了、代码 bug）。F# 的分工是：可预期失败用 `Result` 建模成值，走类型检查；不可预期用异常，走运行时。混着用是多数代码库烂掉的开始。

## 8.2 Result：带错误轨道的值

```fsharp
let ok: Result<int, string> = Ok 1
let err: Result<int, string> = Error "boom"
```

`Result<'T, 'E>` 要么 `Ok 值` 要么 `Error 原因`。与 option 的区别：**None 不解释，Error 说清楚为什么**。

错误类型也是建模对象——示例用判别联合（第 10 章）：

```fsharp
type ParseError =
    | EmptyInput
    | NotANumber of string
    | OutOfRange of int
```

> 命名提醒：错误 DU 别叫 `Error`，会和 Result 的 Error 构造器撞名，match 时一片混乱。

## 8.3 map / bind / mapError：双轨铁路

```fsharp
printfn "map = %A" (Ok 5 |> Result.map (fun x -> x * 2))                // Ok 10
printfn "map 不碰 Error = %A" (Error "e" |> Result.map (fun x -> x * 2)) // Error "e"
printfn "bind = %A" (Ok "20" |> Result.bind parseInt)                    // Ok 20
printfn "mapError = %A" (Error(NotANumber "x") |> Result.mapError (sprintf "%A"))
```

`map` 只变换成功轨；`bind` 接续下一个可能失败的操作；`mapError` 加工错误轨。链式实战（解析 → 范围校验 → 分类）：

```fsharp
let classifyAge input =
    parseInt input
    |> Result.bind (validateRange 0 150)
    |> Result.map (fun age -> if age >= 18 then "成年" else "未成年")
```

四个输入一行看完：

```
"30" -> Ok "成年"    "abc" -> Error (NotANumber "abc")
"200" -> Error (OutOfRange 200)    "" -> Error EmptyInput
```

bind 链再长两层就该换计算表达式了（第 14 章把这段重写成 `validate { ... }`）。

## 8.4 组合多个 Result

```fsharp
let addResults r1 r2 =
    match r1, r2 with
    | Ok a, Ok b -> Ok(a + b)
    | Error e, _ -> Error e
    | _, Error e -> Error e

printfn "3 + 4 = %A" (addResults (parseInt "3") (parseInt "4"))   // Ok 7
printfn "3 + x = %A" (addResults (parseInt "3") (parseInt "x"))   // Error (NotANumber "x")
```

两个都成功才成功；要收集**所有**错误（表单校验场景）则改用遍历拼接列表，或用社区库（FsToolkit.ErrorHandling 的 `Validation`）。

## 8.5 异常侧：try/with 与类型过滤

```fsharp
let caught =
    try
        failwith "出错了"
        "没抛异常"
    with ex ->
        sprintf "捕获：%s" ex.Message
```

F# 的 `with` 支持**按异常类型过滤**——比 C# 多个 catch 块更紧凑：

```fsharp
try
    parseOrThrow "xyz" |> ignore
with :? FormatException as ex ->
    printfn "自定义异常：%s" ex.Message
```

## 8.6 抛异常的工具箱

| 函数 | 用途 |
|---|---|
| `raise (exn)` | 抛任意异常 |
| `failwith "msg"` | 抛 `Failure`（常用兜底） |
| `failwithf "%d" x` | 格式化版 failwith |
| `invalidArg "参数名" "原因"` | 参数校验失败 |
| `nullArg "参数名"` | 参数为 null |

自定义异常类型直接继承：

```fsharp
let parseOrThrow s =
    match parseInt s with
    | Ok v -> v
    | Error(NotANumber raw) -> raise (FormatException $"无法解析：{raw}")
    | Error e -> failwithf "%A" e
```

## 8.7 分层策略

经验法则（第 20 章实战采用）：

- **业务逻辑内部**：Result——调用方被迫处理，类型可组合；
- **边界（IO、框架回调、Program 入口）**：异常——最后防线 try/with；
- **别用异常做控制流**：可预期的失败返回 Result，栈展开不便宜。

## 8.8 坑位清单

- **Error 类型不统一**：`Result<int, string>` 和 `Result<int, ParseError>` bind 不到一起，链路两端先对齐。
- **`with ex` 太宽**：连 OutOfMemory 都吞了；尽量 `:? 具体类型`。
- **撞名 `Error`**：自己的错误 DU 叫 `ParseError`、`AppError`，别叫 `Error`。
- **bind/map 混用类型错**：`bind` 的函数要返回 Result，`map` 的返回普通值；接错了编译器立刻骂人（这正是价值）。
- **Result 打印**：`%A` 输出 `Ok 1` / `Error "boom"`，调试直观。
