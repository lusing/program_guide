# 10 · 判别联合：用类型表达"或"

> 对应示例：examples/10_unions

## 10.1 解决什么问题

命令式建模"多种可能"的惯用手法是 `kind: int` 加一堆可空字段——于是"圆形却有高度"这种非法状态遍地。判别联合（DU）把"**或**"编码进类型：一个 Shape **要么** Circle **要么** Rectangle，不可能两者都是、也不可能两者都不是：

```fsharp
type Shape =
    | Circle of radius: float
    | Rectangle of width: float * height: float

let area shape =
    match shape with
    | Circle r -> System.Math.PI * r * r
    | Rectangle (w, h) -> w * h

printfn "圆面积 = %.2f" (area (Circle 3.0))            // 28.27
printfn "矩形面积 = %.2f" (area (Rectangle(2.0, 5.0)))  // 10.00
```

`Circle`/`Rectangle` 是**构造器**：`Circle 3.0` 直接造出值。`match` 按构造器分派并解出负载，漏分支编译器报错（第 05 章的完备性检查）。**非法状态不可表示**——这是 DU 的全部意义。

## 10.2 单 case DU：强类型包装

裸 `int` 的订单号可以和裸 `int` 的用户 ID 相加——类型系统管不着。单 case DU 给原始值穿一层类型外衣：

```fsharp
type OrderId = OrderId of int
type Email = Email of string

let makeEmail (s: string) = if s.Contains "@" then Some(Email s) else None

let orderNo = OrderId 1001
let (OrderId raw) = orderNo          // 解构取出原始值
match makeEmail "a@b.com" with
| Some (Email e) -> printfn "合法邮箱：%s" e   // a@b.com
| None -> printfn "非法邮箱"
```

`OrderId` 和 `int` 不再混用；`makeEmail` 顺带把"构造即校验"做成了智能构造器。

## 10.3 递归 DU：表达式树（本教程最经典段落）

DU 的字段可以引用**自身类型**——于是树形结构直接长在类型里：

```fsharp
type Expr =
    | Num of float
    | Var of string
    | Add of Expr * Expr
    | Mul of Expr * Expr

let rec eval (vars: Map<string, float>) expr =
    match expr with
    | Num v -> v
    | Var name -> Map.find name vars
    | Add (a, b) -> eval vars a + eval vars b
    | Mul (a, b) -> eval vars a * eval vars b

let rec toStr expr =
    match expr with
    | Num v -> string v
    | Var n -> n
    | Add (a, b) -> sprintf "(%s + %s)" (toStr a) (toStr b)
    | Mul (a, b) -> sprintf "(%s * %s)" (toStr a) (toStr b)
```

`(2 + x) * 3` 在 x=4 时求值：

```fsharp
let expr = Mul(Add(Num 2.0, Var "x"), Num 3.0)
let vars = Map [ ("x", 4.0) ]
printfn "%s = %.1f" (toStr expr) (eval vars expr)   // ((2 + x) * 3) = 18.0
```

解释器、AST、配置树、消息协议——递归 DU 是 F# 的招牌能力，C# 要等大量样板才能模拟。

## 10.4 递归 DU：JSON 值建模

```fsharp
type Json =
    | JString of string
    | JNumber of float
    | JBool of bool
    | JArray of Json list
    | JObject of (string * Json) list

let rec depth json =
    match json with
    | JString _ | JNumber _ | JBool _ -> 1
    | JArray items -> 1 + (items |> List.map depth |> List.fold max 0)
    | JObject fields -> 1 + (fields |> List.map (snd >> depth) |> List.fold max 0)
```

三十行内手写了一个 JSON 树 + 遍历函数（`| A _ | B _` 多模式同分支是常用糖）。第 15 章会看到 System.Text.Json 替你做序列化，但"自己建模数据格式"的思路值得练一遍。

## 10.5 DU vs enum

| | enum | DU |
|---|---|---|
| 本质 | int 的命名常量 | 独立类型，每 case 可带负载 |
| 安全 | 可强转出非法值 | 非法值不可表示 |
| 负载 | 无 | 任意类型（含递归） |
| 场景 | 纯标记、互操作边界 | 一切业务建模 |

## 10.6 RequireQualifiedAccess

```fsharp
[<RequireQualifiedAccess>]
type Status = Active | Paused | Stopped

let state = Status.Active      // 必须写全名，裸 Active 不行
```

避免构造器名字污染外围作用域——case 名字太通用（Active/Done/Error）时加上它。

## 10.7 DU 无处不在

你已经用过很多 DU 了：`option`（Some/None）、`Result`（Ok/Error）都是标准库里的判别联合；第 20 章的 `Command` 用 DU 建模 CLI 命令。**"数据是 record，选择是 DU"**——这是 F# 领域建模的口诀。

## 10.8 坑位清单

- **大小写**：`Circle` 是构造器、`circle` 不是；C# 侧调用要用 `Shape.Circle`。
- **分支遗漏**：新增 case 后所有 match 编译报错——这是功能不是 bug，顺着报错补全。
- **enum 不是 DU**：C# enum 传进来只是 int，别指望 match 它做完备检查。
- **序列化要额外照顾**：DU 的 JSON 形态见第 15 章，跨语言协议要先定好形态。
- **别为两个字段建 20 个 case**：case 是"种类"，字段塞 record；扁平小 DU 最可读。
