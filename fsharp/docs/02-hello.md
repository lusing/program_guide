# 02 · 第一个程序：值、输出与 REPL

> 对应示例：examples/02_hello

## 2.1 为什么 F# 程序这么短

C# 新手模板是 `class Program { static void Main() { ... } }`；F# 的等价程序只有绑定和表达式——**F# 里一切皆表达式**，顶层 `let` 就是"模块级值"，编译器会自动找到 `[<EntryPoint>]` 作为入口。示例全文：

```fsharp
// ═══ 2.1 最小的 F# 程序：值与函数 ═══
let message = "Hello from F#"       // let 绑定：默认不可变
let add a b = a + b                 // 函数：空格传参，无大括号

[<EntryPoint>]
let main _ =
    // …（后面各节逐段展开）
    0
```

`let main _ = ... 0`：参数 `_` 表示忽略 argv，返回 `0` 是进程退出码。想接收命令行参数就写 `let main argv =`（第 20 章实战用到）。

## 2.2 printfn：编译期检查的格式化输出

```fsharp
printfn "%s" message
let name = "F#"
let version = 10
printfn "Hello, %s %d!" name version      // %s 字符串、%d 整数
printfn "浮点 %.2f、布尔 %b" 3.14159 true  // %.2f 保留两位、%b 布尔
printfn "任意值 %A" [ 1; 2; 3 ]            // %A 万能打印（列表/记录/联合）
```

| 格式符 | 对应类型 | 说明 |
|---|---|---|
| `%s` | string | 字符串 |
| `%d` / `%x` | int | 十进制 / 十六进制 |
| `%f` / `%.2f` | float | 默认 6 位 / 指定精度 |
| `%M` | decimal | 金额首选（第 03 章） |
| `%b` / `%c` | bool / char | |
| `%A` | 任意 | 结构化打印，调试神器 |
| `%O` | 任意（ToString） | 用 .NET 的 ToString |

printfn 的杀手锏：**格式符与实参类型不匹配是编译错误**，不是运行时崩。

同族函数速记：`printf`（不换行）、`printfn`（换行）、`sprintf`（返回字符串，第 05 章的 `describe` 用到）、`eprintfn`（打到 stderr）。

## 2.3 字符串插值：$"" 与 printfn 的取舍

```fsharp
let who = "world"
printfn $"Hello, {who}!"                          // $"..." 内插
printfn $"表达式 {add 12 8}、浮点 {3.14159:f2}"    // 内插里可放表达式与格式
```

- 插值赢在**可读性与表达式内嵌**；
- printfn 赢在**类型检查与惯用性**（F# 代码里管道输出常用它）。
- 两者都能写格式说明符（`{x:f2}` 对应 `%.2f`）。

## 2.4 类型推断初识

```fsharp
let count = 42                        // 推断为 int
let pi = 3.14                         // 推断为 float（即 double）
let words = "a b c".Split ' '         // 调用 .NET 方法，推断为 string[]
printfn "count=%d pi=%f words=%A" count pi words
```

不需要写类型，但类型是**静态且确定**的——传错地方编译期就报错。细节（何时需要显式注解、为什么 int 不能直接加 float）在第 03 章。

## 2.5 REPL 工作流：dotnet fsi

F# 最好的学习工具是交互窗口。终端输入 `dotnet fsi`，逐行粘贴示例：

```
> let message = "Hello from F#";;
val message: string = "Hello from F#"

> let add a b = a + b;;
val add: a: int -> b: int -> int

> add 12 8;;
val it: int = 20
```

REPL 用 `;;` 结束多行输入，`val` 行是编译器"说"出的类型。改完代码立刻看到类型与结果，这是 F# 学习曲线最快的一段。也可以把代码存成 `demo.fsx` 用 `dotnet fsi demo.fsx` 整体执行。`#quit;;` 退出；`#r "nuget: 包名"` 可在会话内临时引包。

示例程序结尾那行提示正是这个工作流：

```fsharp
printfn "在终端运行 dotnet fsi，逐行粘贴以上代码即可交互验证。"
```

## 2.6 坑位清单

- **格式符类型不匹配是编译错误**：`printfn "%d" "x"` 直接编不过。
- **%A 用于调试**：输出带结构（`[1; 2; 3]`），别用于面向用户的排版。
- **缩进 4 空格**：块由缩进决定，混用 Tab 会报错（编辑器设为空格缩进）。
- **`;;` 只在 fsi 里需要**：`.fs` 文件里永远不写。
- **隐式 main**：默认入口是最后一个文件里名为 `main` 的函数；`[<EntryPoint>]` 是显式形式，本教程统一用显式写法。
