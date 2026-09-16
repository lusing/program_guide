# 05 · 模式匹配：分支的完全体

> 对应示例：examples/05_patterns

## 5.1 解决什么问题

`if/else` 链和 `switch` 只能比较值；真实世界的分支条件是"数据的**形状**"——空列表还是单元素？这个结果成功还是失败？输入是不是能解析成数字？F# 的 `match` 把"按形状分派"做成语言核心，并且**编译器检查你覆盖了所有形状**。

## 5.2 match 是表达式

```fsharp
let meaning =
    match 42 with
    | 0 -> "零"
    | 42 -> "宇宙的答案"
    | other -> sprintf "其他(%d)" other
printfn "%s" meaning
```

match **有返回值**（每个分支产出同类型），像三目运算符的完全体。分支 = `| 模式 -> 表达式`；`other` 是变量模式（绑定命中值），最后兜底。删掉兜底分支试试——编译器报"未覆盖 int 的情况"，这叫**完备性检查**。

## 5.3 模式族谱

| 模式 | 示例 | 命中条件 |
|---|---|---|
| 常量 | `0`、`"abc"` | 值相等 |
| 变量 | `other` | 任意，绑定该值 |
| or | `1 \| 3 \| 5` | 任一命中 |
| 卫兵 | `x when x < 0` | 模式命中且条件为真 |
| 元组 | `(x, y)` | 按位置解构 |
| 列表 | `[]`、`[x]`、`x :: rest` | 按形状解构 |
| 记录 | `{ Name = n }` | 按字段解构 |
| 构造器 | `Circle r`、`Some v` | DU/option 按构造器分派 |

## 5.4 when 卫兵与 or 模式

```fsharp
let classify n =
    match n with
    | 0 -> "零"
    | x when x < 0 -> "负数"
    | 1 | 3 | 5 | 7 | 9 -> "个位奇数"
    | _ -> "其他"
[ -2; 0; 3; 8 ] |> List.iter (fun n -> printfn "%d -> %s" n (classify n))
```

`_` 是"任意值且丢弃"的通配符。卫兵可以引用绑定变量，做模式表达不了的数值判断。

## 5.5 元组与列表模式

```fsharp
match (3, 4) with
| (0, 0) -> printfn "原点"
| (x, y) -> printfn "点 (%d, %d)" x y
```

列表按"形状"分类（示例的 `describe`）：

```fsharp
let describe list =
    match list with
    | [] -> "空列表"
    | [ single ] -> sprintf "单元素 %d" single
    | [ a; b ] -> sprintf "两个元素 %d 和 %d" a b
    | head :: _ -> sprintf "多元素，开头是 %d" head
```

`x :: rest` 是 **cons 模式**：拆出第一个元素和剩余列表——递归处理列表的标准姿势（第 04 章 `sumTail` 就是它）。运行输出：

```
空列表 / 单元素 7 / 两个元素 2 和 9 / 多元素，开头是 4
```

## 5.6 记录模式 + function 关键字

```fsharp
let label =
    function
    | { Name = n; Age = a } when a >= 18 -> sprintf "%s（成年）" n
    | { Name = n } -> sprintf "%s（未成年）" n
```

`function` 等价于 `fun x -> match x with`——写"单参函数立刻匹配"时的糖。记录模式按字段名解构出 `n`、`a`，不用先点字段再 if。

## 5.7 活动模式（一）：完整——把规则变成形状

```fsharp
let (|Even|Odd|) n = if n % 2 = 0 then Even else Odd

let evenOrOdd n =
    match n with
    | Even -> "偶数"
    | Odd -> "奇数"
```

`(|Even|Odd|)` 定义了一个**完整活动模式**：把"任意 int"划成两种形状，match 时像用内置构造器一样用 `Even`/`Odd`。命名以 `(|...|)` 香蕉括号为标志。

## 5.8 活动模式（二）：部分——可能不命中

```fsharp
let (|DivisibleBy|_|) divisor n =
    if n % divisor = 0 then Some DivisibleBy else None

let fizz n =
    match n with
    | DivisibleBy 15 -> "FizzBuzz"
    | DivisibleBy 3 -> "Fizz"
    | DivisibleBy 5 -> "Buzz"
    | _ -> string n
```

`(|...|_|)` 是**部分活动模式**：命中返回 `Some`，不命中 `None`，可带参数（`DivisibleBy 15`）。FizzBuzz 从此不需要卫兵。它和 `option` 的关系一目了然——活动模式本质是"返回 option 的函数"的语法外套。

## 5.9 活动模式（三）：包装 TryParse 的惯用法

```fsharp
let (|IntParse|_|) (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | false, _ -> None

for s in [ "42"; "abc"; "7" ] do
    match s with
    | IntParse v -> printfn "\"%s\" 解析为 %d" s v
    | _ -> printfn "\"%s\" 不是整数" s
```

把 C# 风格的 `TryParse(bool, out)` 包装成可匹配的形状——几乎每个 F# 代码库都有几个这样的活动模式。

## 5.10 选型：if / match / 活动模式

| 场景 | 用 |
|---|---|
| 两三个布尔分支 | `if/elif` |
| 按值/形状多路分派 | `match` |
| 分类规则复杂且反复使用 | 提炼成活动模式 |

## 5.11 坑位清单

- **变量模式遮蔽**：`| x -> ...` 的 `x` 绑定新名，别和外围同名变量混淆。
- **`_` 过早兜底**：把 `_` 写在具体模式前面会让后面分支不可达（编译器告警 FS0045）。
- **活动模式里抛异常**：异常会穿透 match 正常传播，保持活动模式纯净。
- **`| x ->` 未用 x**：会有告警，改用 `_` 或 `| _ignored ->`。
- **cons 模式左边是单元素**：`x :: rest` 中 `rest` 是**剩余列表**不是最后一个元素。
