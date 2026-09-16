# 07 · Option：与 null 划清界限

> 对应示例：examples/07_option

## 7.1 解决什么问题

null 引用被发明者 Tony Hoare 称为"十亿美元错误"：任何引用随时可能是 null，编译器却不吭声。F# 的回答是**用类型表达缺失**：`option<'T>` 要么 `Some 值`、要么 `None`——想忽略 None？编译器不答应（分支不完备不让过，见第 05 章）。

```fsharp
let someValue = Some 42
let noneValue: int option = None
printfn "直接打印 %A / %A" someValue noneValue   // Some 42 / None
```

## 7.2 函数返回 option 代替抛异常

```fsharp
let safeDivide a b = if b = 0 then None else Some(a / b)

printfn "10 / 2 = %A" (safeDivide 10 2)     // Some 5
printfn "10 / 0 = %A" (safeDivide 10 0)     // None
```

调用方拿到 `option` 就**必须**面对 None——失败从"约定"变成了"类型"。

## 7.3 消耗与串联：match / map / bind

match 消耗（第 05 章的老朋友）：

```fsharp
match someValue with
| Some v -> printfn "someValue = %d" v
| None -> printfn "没有值"
```

`Option.map` 对有值时变换：

```fsharp
printfn "map×2 = %A" (Some 5 |> Option.map (fun x -> x * 2))   // Some 10
```

`Option.bind` 串联多个"可能失败"的步骤（失败立即短路成 None）：

```fsharp
let parseInt (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | false, _ -> None

let reciprocal s =
    parseInt s |> Option.bind (fun n -> safeDivide 100 n)

printfn "reciprocal \"4\" = %A" (reciprocal "4")   // Some 25
printfn "reciprocal \"0\" = %A" (reciprocal "0")   // None（除零）
printfn "reciprocal \"x\" = %A" (reciprocal "x")   // None（解析失败）
```

对照命令式版本：两层嵌套 if-null；这里是一行管道。嵌套更深时升级为计算表达式（第 14 章）。

## 7.4 默认值与备选

```fsharp
printfn "defaultValue 0 = %d" (None |> Option.defaultValue 0)
printfn "orElse = %A" (None |> Option.orElse (Some 7))    // Some 7
printfn "isSome = %b" (Some 1 |> Option.isSome)
```

`defaultValue` 用于"缺失有合理默认"的场景；没有合理默认时**别用**——把 None 传下去才是正路。

## 7.5 集合 API 里的 option

标准库大量函数返回 option，而不是抛异常或返回哨兵值：

```fsharp
let found = [ 1; 3; 5; 7 ] |> List.tryFind (fun x -> x > 4)   // Some 5
let ages = Map [ ("Alice", 30); ("Bob", 25) ]
Map.tryFind "Alice" ages    // Some 30
Map.tryFind "Carol" ages    // None
```

同族：`tryFindIndex`、`tryHead`、`tryLast`、`tryPick`、`Array.tryItem`、`Dictionary.tryFind`（FSharp.Core 扩展）。

## 7.6 与 null / Nullable 的边界转换

F# 类型默认不可 null，但调用 C# 世界时 null 会漏进来。接住它的惯用法：

```fsharp
// C# 风格 API（如 Array.Find 找不到时）返回 null；用 `| null` 注解显式接住可空值
let csharpResult: string | null = System.Array.Find([||], fun (s: string) -> true)
printfn "Option.ofObj null = %A" (Option.ofObj csharpResult)   // None
```

四个边界函数：`Option.ofObj` / `Option.toObj`（引用类型 null）、`Option.ofNullable` / `Option.toNullable`（`Nullable<T>`）：

```fsharp
printfn "Option.ofNullable 5 = %A" (Option.ofNullable (Nullable 5))    // Some 5
printfn "Option.toNullable None = %A" (Option.toNullable None)         // null
```

`string | null` 注解与编译器提示是 F# 9 引入的 nullness 检查在工作（第 18 章展开）。

## 7.7 坑位清单

- **`Some None`**：类型是 `option<option<T>>`，通常说明逻辑写错了。
- **defaultValue 掩盖错误**：拿 None 当默认值糊弄过去，bug 从此无声无息。
- **判空别绕路**：`(opt = Some x)` 这种比较不如直接 match；判有无用 `Option.isSome`。
- **`%A` 打印**：调试友好（`Some 42`），面向用户文本要自己解包格式化。
- **值类型小优化**：热路径可用 `voption`（`ValueSome`/`ValueNone`，免装箱），API 层保持 option 即可。
