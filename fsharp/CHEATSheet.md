# F# 速查表

## 语法骨架

```fsharp
let x = 1                    // 不可变绑定
let mutable y = 0            // 可变（y <- 1 赋值）
let f a b = a + b            // 函数（柯里化）
let g () = printfn "hi"      // 无参函数定义/调用都带 ()
let rec fact n = if n <= 1 then 1 else n * fact (n - 1)
let rec a1 () = ... and a2 () = ...          // 互递归
if c then a else b           // 表达式
for i in 1 .. 10 do ...      // 循环
match e with | p1 -> v1 | _ -> v2
let f = function | Some v -> v | None -> 0   // fun x -> match x with
try e with :? FormatException as ex -> ...
|> ignore                    // 丢弃值
```

## printfn 格式符

`%s` 字符串 · `%d` 整数 · `%x` 十六进制 · `%f`/`%.2f` 浮点 · `%M` decimal · `%b` bool · `%c` char · `%A` 结构化打印 · `%O` ToString

## 集合速查（List / Array / Seq 同名）

```fsharp
map filter sum collect sortBy groupBy distinct zip tryFind tryHead
fold (fun acc x -> ...) init      // 归约
scan                              // fold 保留中间值
reduce                            // 无初始值 fold（空表抛异常）
Seq.initInfinite |> Seq.truncate n
List.ofArray / Array.ofList / List.ofSeq / Array.ofSeq
```

## Option / Result

```fsharp
Option.map f x          Option.bind f x        Option.defaultValue d
Option.orElse other     Option.isSome          Option.ofObj / toObj
Option.ofNullable / toNullable
Result.map f r          Result.bind f r        Result.mapError f r
match r with Ok v -> ... | Error e -> ...
```

## 类型定义

```fsharp
type P = { Name: string; Age: int }        // record（with / 结构相等）
type Shape = Circle of r: float | Rect of w: float * h: float   // DU
type OrderId = OrderId of int              // 单 case 包装
[<Struct>] type Pt = { X: float; Y: float }
[<RequireQualifiedAccess>] type St = On | Off
[<Measure>] type kg                        // 75.0<kg>；float 剥单位
type C(x: int) =                           // 类
    let mutable cur = x
    member _.Value = cur
    static member Start() = C 0
let logger = { new ILogger with member _.Log m = ... }   // 对象表达式
use t = new TempFile(p)                    // 自动 Dispose
```

## async / task

```fsharp
async { let! a = f (); do! Async.Sleep 100; return a } |> Async.RunSynchronously
Async.Parallel [ job1; job2 ] |> Async.RunSynchronously
task { let! x = task1; return x + 1 }
Async.StartAsTask / Async.AwaitTask
// 取消异常由 RunSynchronously 抛出，try/with 包运行调用
```

## 计算表达式

`let!` = Bind · `do!` = Bind(unit) · `return` = Return · `return!` = ReturnFrom · `yield` / `yield!`（seq）

内置：`async {}`、`task {}`、`seq {}`、`query { for x in xs do select ... }`

## dotnet CLI

```bash
dotnet new console -lang F# -o app     # 控制台工程
dotnet new xunit -lang F# -o tests     # 测试工程
dotnet run --project app               # 运行
dotnet test tests --filter "FullyQualifiedName~关键字"
dotnet fsi                             # REPL（;; 提交，#quit;; 退出）
dotnet fsi script.fsx                  # 脚本
```

## fsproj 要点

- `<Compile Include>` 顺序 = 编译顺序（入口文件最后）。
- GUI：`net10.0-windows` + `UseWindowsForms`/`UseWPF` + `WinExe`。
- Web：`Sdk="Microsoft.NET.Sdk.Web"`。
- 测试三件套：`Microsoft.NET.Test.Sdk` / `xunit` / `xunit.runner.visualstudio`。
