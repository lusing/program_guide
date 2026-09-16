# 18 · .NET 互操作：两个语言一个运行时

> 对应示例：examples/18_interop

## 18.1 解决什么问题

"F# 能用 C# 的库吗？能被 C# 调用吗？"——都能，因为它们编译到同一个 IL、共享同一个 BCL。互操作的摩擦点集中在几处：null、委托、泛型差异。本章逐一过墙。

## 18.2 日常互作：直接调用 C# 风格 API

```fsharp
let sb = StringBuilder()
sb.Append("F#").Append(" <-> ").Append("C#") |> ignore
printfn "%s" (sb.ToString())

printfn "join=%s format=%s" (String.Join(", ", [ "a"; "b"; "c" ])) (String.Format("{0:D4}", 42))
// join=a, b, c format=0042
```

F# 的 `string` 就是 `System.String`，`list` 能直接传给收 `IEnumerable<T>` 的 API。`String.Join`/`Format`/`StringBuilder` 这些老朋友零成本可用。

## 18.3 null 边界：C# 会漏 null 进来

F# 类型默认不可 null，但 C# API 不保证。接住的惯用法（示例实测零警告）：

```fsharp
let found: string | null = Array.Find([||], fun (s: string) -> true)   // C# API：找不到返回 null
match Option.ofObj found with
| Some s -> printfn "有值 %s" s
| None -> printfn "C# 返回了 null → Option.ofObj 安全包装"
```

两层防御：`string | null` **注解**显式声明可空（F# 9 nullness——编译器会对裸接 null 发警告，注解让它合法化）；`Option.ofObj` 把可空值转成 option，此后走第 07 章的正轨。反方向 `Option.toObj` 输出给 C#。

F# 9 的 nullness 是**引用类型空值注解的编译期检查**：C# NRT 标注的 API 在 F# 侧会提示可空性，F# 值域内仍维持"默认非空"。它不是新的运行时机制，而是把第 07 章的类型防线又加固了一圈。

## 18.4 Nullable<T> 双向转换

```fsharp
printfn "ofNullable=%A %A" (Option.ofNullable (Nullable 5)) (Option.ofNullable (Nullable<int>()))
// Some 5 / None
```

`int?`（数据库字段、老 API）用 `Option.ofNullable/toNullable` 桥接。

## 18.5 byref：传引用

```fsharp
// byref 参数只能放顶层函数/方法上
let bump (v: byref<int>) = v <- v + 1

let mutable x = 10
bump &x
printfn "byref 后 x = %d" x    // 11
```

`&x` 取地址传入，函数内修改直落 `x`。**限制很重要**：byref 不能进闭包、不能存字段、不能异步跨越——栈引用出不了作用域（示例实测：把 `bump` 定义成局部函数直接编译错误 FS0425"第一类函数的类型不能包含 byref"）。日常交给 `ref`/`mutable`，byref 留给高性能与互操作场景（`Span` 内部全是它）。

## 18.6 Span：高性能切片

```fsharp
let arr = [| 1; 2; 3; 4; 5 |]
let span = arr.AsSpan(1, 3)          // 从下标 1 起 3 个元素，零拷贝
let mutable sum = 0
for i in 0 .. span.Length - 1 do
    sum <- sum + span[i]
printfn "span 求和 = %d" sum         // 9（2+3+4）
```

`Span<T>` 是"指向连续内存的窗口"——不复制、栈上结构。热点路径（解析、缓冲）用它免分配；限制同 byref（不能进闭包/async/字段）。普通业务代码不必强上。

## 18.7 订阅 .NET 事件

```fsharp
use timer = new Timers.Timer(200.0)
timer.Elapsed.Add(fun _ -> printfn "Timer 事件触发")
timer.Start()
Threading.Thread.Sleep 400
timer.Stop()
```

F# 侧事件是 `IEvent`，`.Add` 订阅（`.Remove` 退订要保存 handler）。第 19 章 GUI 的 `button.Click.Add` 就是同一机制——UI 事件与 BCL 事件在 F# 里一个写法。

## 18.8 Task 与 async 互转 + query

互转回顾（第 13 章详解）：

```fsharp
let fromTask: Task<int> = Task.FromResult 20
let viaAsync = fromTask |> Async.AwaitTask |> Async.RunSynchronously
let viaTask = async { return viaAsync + 1 } |> Async.StartAsTask
printfn "Task→async→Task: %d" viaTask.Result   // 21
```

F# 还有一套 LINQ 查询语法：

```fsharp
let squares =
    query { for i in [ 1 .. 5 ] do select (i * i) }
    |> Seq.toList   // [1; 4; 9; 16; 25]
```

## 18.9 反向暴露：F# 给 C# 用

三个要点：**柯里化函数在 C# 侧难看**（`add.Apply(1).Invoke(2)`）——对外 API 参数改元组式 `let add (a, b) = a + b`；record 在 C# 侧是只读属性类（可用对象初始化器）；想要 C# 风格命名加 `[<CompiledName("AddValues")>]`。

## 18.10 坑位清单

- **curried 函数出墙**：给 C# 的公开函数用元组参数（或写成方法 `member`）。
- **byref/span 限制**：不进闭包、不跨 async、不存字段——编译器会拦。
- **null 只堵边界**：在互操作入口 ofObj 一次，内部永远 option；让 null 蔓延进核心等于白设防。
- **事件忘退订**：长生命周期对象订阅短生命周期源会泄漏，handler 存变量 `Remove`。
- **委托转换**：F# lambda 到 `Func`/`Action`/`Predicate` 自动转换，但**多重载方法**（第 16 章 MapGet）要显式 `Func<...>` 包装。
