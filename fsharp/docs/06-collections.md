# 06 · 集合：List、Array 与 Seq

> 对应示例：examples/06_collections

## 6.1 解决什么问题

数据处理 90% 的工作是"变换集合"：过滤、映射、分组、汇总。F# 为此提供三套同构的模块（`List`/`Array`/`Seq`），配上前一章的管道，多数循环从此消失。

## 6.2 三种集合怎么选

| | `list` | `array` | `seq` |
|---|---|---|---|
| .NET 类型 | 不可变单链表 | `T[]` 可变数组 | `IEnumerable<T>` 惰性 |
| 索引 | O(n) | O(1) | O(n) |
| 就地更新 | 不能（产新值） | 能 `arr[0] <- x` | 不能 |
| 典型场景 | 默认选择、递归处理 | 大数据量、热路径、互操作 | 大/无限流、管道中转 |

```fsharp
let ls = [ 1 .. 8 ]              // list：不可变链表
let arr = [| 1; 2; 3; 4 |]       // array：可变、连续内存
let sq = seq { 1; 2; 3 }         // seq：惰性 IEnumerable
```

默认用 `list`；测出性能需要才换 `array`；跨边界传集合或搭管道用 `seq`。

## 6.3 三胞胎模块：map / filter

`List`、`Array`、`Seq` 三个模块的函数名几乎一致：

```fsharp
let doubled = ls |> List.map (fun x -> x * 2)
let evens = ls |> List.filter (fun x -> x % 2 = 0)
// doubled=[2; 4; 6; 8; 10; 12; 14; 16]  evens=[2; 4; 6; 8]
```

## 6.4 fold 家族：万能归约

```fsharp
let total = ls |> List.fold (fun acc x -> acc + x) 0
let product = ls |> List.fold (fun acc x -> acc * x) 1
let steps = ls |> List.scan (fun acc x -> acc + x) 0  // 保留每步中间值
```

`fold` 从初始值出发逐步"吸收"元素——`sum`、`max`、`反转`、`建字典`全是它的特化：

| 函数 | 语义 | 对比 |
|---|---|---|
| `fold` | 左折叠，只要最终值 | 无初始值版是 `reduce`（空列表会抛异常） |
| `foldBack` | 右折叠 | 顺序敏感时选对方向 |
| `scan` | 折叠 + 保留中间序列 | `[0; 1; 3; 6; 10; 15; 21; 28; 36]` |

## 6.5 分组与排序

```fsharp
let words = [ "apple"; "pear"; "avocado"; "fig" ]
let grouped = words |> List.groupBy (fun w -> w[0]) |> List.map (fun (k, v) -> (k, List.length v))
let byLength = words |> List.sortBy (fun w -> w.Length)
// grouped=[('a', 2); ('p', 1); ('f', 1)]  byLength=["fig"; "pear"; "apple"; "avocado"]
```

`groupBy` 返回 `(键, 组)` 二元组列表——管道里常常再 map 一层取统计量。降序用 `sortByDescending`，多重键用 `sortWith`。

## 6.6 array：可变、就地更新

```fsharp
arr[0] <- 100
printfn "更新后 array=%A" arr
printfn "Array.map=%A" (arr |> Array.map (fun x -> x + 1))
```

索引语法 `arr[0]`（F# 6+ 统一写法，旧代码的 `arr.[0]` 等价）。array 的意义：连续内存、无 GC 压力、与 .NET API 天然对接。

## 6.7 seq：惰性与无限序列

```fsharp
let naturals = Seq.initInfinite (fun i -> i * i)
printfn "前 5 个平方数 = %A" (naturals |> Seq.truncate 5 |> List.ofSeq)
// [0; 1; 4; 9; 16]
```

`initInfinite` 定义了全体平方数——因为 seq 惰性，用到多少算多少。配套函数：`Seq.truncate`（取前 n）、`Seq.takeWhile`、`Seq.cache`（避免重复计算）。

## 6.8 互转

| 从 \ 到 | list | array | seq |
|---|---|---|---|
| list | — | `List.ofArray` 反向 | `list` 本身就是 seq |
| array | `Array.ofList` | — | 同上 |
| seq | `List.ofSeq` | `Array.ofSeq` | — |

## 6.9 与 LINQ 的关系

```fsharp
let linqStyle =
    System.Linq.Enumerable.Where(ls, fun x -> x > 3)
    |> Seq.map (fun x -> x + 100)
    |> List.ofSeq
```

F# 管道与 LINQ 方法链能力等价（LINQ 的 `Where/Select` 就是 `filter/map`）。日常用 F# 模块；要对接 C# 侧 IQueryable 或写 SQL 风格查询时用 LINQ（含 F# 的 `query { }` 语法，第 18 章）。

## 6.10 常用 API 速查

```fsharp
printfn "长度=%d，包含 4？%b" ls.Length (List.contains 4 ls)
printfn "splitAt 3 = %A" (List.splitAt 3 ls)
```

高频补充：`List.tryFind`/`tryHead`（返回 option，第 07 章）、`List.collect`（map 后拍平）、`List.distinct`、`List.zip`、`List.chunkBySize`。

## 6.11 坑位清单

- **`List.append` 是 O(n)**：循环里反复 append 是性能陷阱，改用 fold 或先收集再 concat。
- **seq 多次枚举**：惰性序列每枚举一次重算一次（还可能重复副作用），需要复用先 `Seq.cache` 或转 list。
- **`[1..n]` 两端闭合**：含 n；范围反了得 `[10..-1..1]`。
- **list/array 混用**：模块函数不通用，管道中途先统一类型。
- **索引越界**：`arr[10]` 抛 `IndexOutOfRangeException`，取前先判长度或用 `Array.tryItem`。
