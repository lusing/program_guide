// ═══ 2.1 最小的 F# 程序：值与函数 ═══
let message = "Hello from F#"       // let 绑定：默认不可变
let add a b = a + b                 // 函数：空格传参，无大括号

[<EntryPoint>]
let main _ =

    // ═══ 2.2 printfn 格式化输出 ═══
    printfn "%s" message
    let name = "F#"
    let version = 10
    printfn "Hello, %s %d!" name version      // %s 字符串、%d 整数
    printfn "浮点 %.2f、布尔 %b" 3.14159 true  // %.2f 保留两位、%b 布尔
    printfn "任意值 %A" [ 1; 2; 3 ]            // %A 万能打印（列表/记录/联合）

    // ═══ 2.3 字符串插值（F# 5+）═══
    let who = "world"
    printfn $"Hello, {who}!"                          // $"..." 内插
    printfn $"表达式 {add 12 8}、浮点 {3.14159:f2}"    // 内插里可放表达式与格式

    // ═══ 2.4 类型推断初识 ═══
    let count = 42                        // 推断为 int
    let pi = 3.14                         // 推断为 float（即 double）
    let words = "a b c".Split ' '         // 调用 .NET 方法，推断为 string[]
    printfn "count=%d pi=%f words=%A" count pi words

    // ═══ 2.5 REPL 工作流提示 ═══
    printfn "在终端运行 dotnet fsi，逐行粘贴以上代码即可交互验证。"
    0
