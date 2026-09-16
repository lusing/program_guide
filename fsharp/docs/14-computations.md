# 14 · 计算表达式：把语法糖做成语言

> 对应示例：examples/14_computations

## 14.1 解决什么问题

第 07/08 章的 `Option.bind`/`Result.bind` 链一长，嵌套与箭头就糊成一团。计算表达式（CE）把"按某种规则串接计算"提炼成**自定义语法**：`maybe { ... }`、`validate { ... }`、`async { ... }`、`task { ... }`——后两个你已经用了（第 13 章），本章拆开引擎盖看它们为什么能这样写，并造出自己的。

## 14.2 内置 CE：seq {}

```fsharp
let squares =
    seq {
        for i in 1 .. 5 do
            yield i * i
    }
printfn "seq CE = %A" (List.ofSeq squares)   // [1; 4; 9; 16; 25]
```

## 14.3 trace builder：看清 let! 的本质

CE 的一切从 builder 类型开始。示例定义了一个**边执行边打印**的讲解性 builder：

```fsharp
type TraceBuilder() =
    member _.Bind(x, f) =
        printfn "Bind: %A" x
        match x with
        | Some v -> f v
        | None -> None
    member _.Return x =
        printfn "Return: %A" x
        Some x
    member _.ReturnFrom x = x

let trace = TraceBuilder()
```

用它跑一段 CE，**输出就是脱糖过程**：

```fsharp
let traced =
    trace {
        let! a = Some 1
        let! b = Some 2
        return a + b
    }
```

运行输出（逐行对照脱糖）：

```
Bind: Some 1     ← trace.Bind(Some 1, fun a -> ...)
Bind: Some 2     ← 内层 trace.Bind(Some 2, fun b -> ...)
Return: 3        ← trace.Return (a + b)
trace 结果 = Some 3
```

一句话：**`let! x = e` 就是 `builder.Bind(e, fun x -> ...)`，`return e` 就是 `builder.Return e`**。整个 CE 体被编译器重写成嵌套的 Bind/Return 调用链。

## 14.4 builder 协议成员表

| 成员 | 触发语法 | 必要性 |
|---|---|---|
| `Bind(m, f)` | `let! x = m` | 核心 |
| `Return(x)` | `return x` | 核心 |
| `ReturnFrom(m)` | `return! m` | 透传常用 |
| `Zero()` | 无 return 的分支（如纯 `do`） | 有 if 分支时需要 |
| `Delay(f)` / `Combine(a, b)` | 多段顺序执行、try | 进阶 |
| `While(g, b)` / `For(xs, b)` | CE 内 for/while | 进阶 |
| `TryWith` / `TryFinally` | CE 内 try/with | 进阶 |
| `Yield(x)` / `YieldFrom(m)` | `yield` / `yield!`（seq 类） | 生成器用 |

前四个覆盖本教程全部场景；后几项在写生产级 CE（如自定义异步/重试）时按需补。

## 14.5 maybe builder：option 的语法糖

```fsharp
type MaybeBuilder() =
    member _.Bind(x, f) =
        match x with
        | Some v -> f v
        | None -> None
    member _.Return x = Some x
    member _.ReturnFrom x = x

let maybe = MaybeBuilder()

let calc input1 input2 =
    maybe {
        let! a = tryParseInt input1
        let! b = tryParseInt input2
        let! c = if b = 0 then None else Some(100 / b)
        return a + c
    }

printfn "maybe 成功 = %A" (calc "40" "8")   // Some 52
printfn "maybe 失败 = %A" (calc "40" "x")   // None（第二步就短路）
```

对照第 07 章的 `Option.bind` 链：语义相同，但读起来就是普通命令式代码——任何一步 None，后面整段自动跳过。

## 14.6 result builder：校验链的完全体

第 08 章埋的伏笔在此兑现——Bind 对 Result 的实现：

```fsharp
type ResultBuilder() =
    member _.Bind(x, f) =
        match x with
        | Ok v -> f v
        | Error e -> Error e
    member _.Return x = Ok x
    member _.ReturnFrom x = x

let validate = ResultBuilder()

let processInput s =
    validate {
        let! n = parse s
        do! inRange 1 100 n        // do! 对 Result<unit, _>：失败短路
        return n * 2
    }

printfn "validate 成功 = %A" (processInput "21")     // Ok 42
printfn "validate 非数字 = %A" (processInput "abc")  // Error "abc 不是数字"
printfn "validate 超范围 = %A" (processInput "150")  // Error "150 超出 [1, 100]"
```

`do!` 脱糖同样是 Bind——只是后续计算不消费其值。`inRange` 失败返回 `Error ...`、成功返回 `Ok()`。

## 14.7 return!：透传同类计算

```fsharp
let passthrough = maybe { return! Some 9 }   // Some 9
```

`return! m` = `ReturnFrom m`——不做包装直接采用另一个同类值。async 世界的 `return! otherAsync`、seq 的 `yield! 子序列` 同源。

## 14.8 何时自定义 CE

- bind/map 链**超过两三层**、或普通管道读着费劲 → 值得；
- 需要统一处理横切关注点（短路、日志、重试、资源池）→ CE 是 F# 的"语法级中间件"；
- 一两层就停的简单串联 → 高阶函数足够，别过度抽象。

## 14.9 坑位清单

- **缺 Zero() 的编译错**：CE 体里有不产出 return 的分支（如 if 无 else）时需要 `Zero()`，错误提示很隐晦。
- **副作用时机**：CE 体是按 Bind 链求值的，想惰性要 Delay；别假设"定义即整体执行"。
- **Delay 忘调 f**：自定义 Delay 时 `f()` 不调用会拿到闭包而非结果。
- **builder 命名习惯**：类型叫 XxxBuilder、实例叫小写（maybe/validate/async），全仓库一致。
- **可读性边界**：CE 太"聪明"（隐藏大量控制流）会失去透明性——注释里写清短路语义。
