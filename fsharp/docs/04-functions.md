# 04 · 函数：柯里化、管道与组合

> 对应示例：examples/04_functions

## 4.1 解决什么问题

函数式编程的杠杆全在"把函数当值"：传函数、造函数、拼函数。F# 把这件事做成了语言骨架——理解柯里化与管道，后面每一章都顺。

## 4.2 柯里化：多参函数的真实形状

```fsharp
let add a b = a + b        // 签名 int -> int -> int（柯里化）
let add5 = add 5           // 部分应用：只喂第一个参数
printfn "add 3 4 = %d" (add 3 4)
printfn "add5 10 = %d" (add5 10)
```

`add a b` 不是"两参函数"，而是 `int -> (int -> int)`：吃一个 int，返回"再吃一个 int"的函数。所以只喂一个参数是合法的——**部分应用**（partial application），得到 `add5` 这个新函数。箭头签名 `->` 右结合，是 F# 类型世界的语法糖核心。

## 4.3 管道 |>：让数据流式表达

```fsharp
let values = [ 3; 1; 4; 1; 5; 9; 2; 6 ]
let result =
    values
    |> List.filter (fun x -> x % 2 = 1)   // 奇数
    |> List.map (fun x -> x * 10)         // ×10
    |> List.sum                           // 求和
printfn "管道结果 = %d" result
```

`x |> f` 就是 `f x`。管道的价值是**读的方向 = 执行的方向**：数据从上往下流过每个变换。本示例输出 190（奇数 3+1+1+5+9 各乘 10 再求和）。常用变体：

| 写法 | 含义 |
|---|---|
| `x \|> f` | `f x` |
| `(a, b) \|\|> f` | `f a b`（二元组一次喂两参） |
| `expr \|> ignore` | 丢弃结果 |

## 4.4 组合 >>：函数拼接成新函数

```fsharp
let square x = x * x
let negate x = -x
let squareThenNegate = square >> negate    // 先 square 再 negate，产生新函数
printfn "(square >> negate) 5 = %d" (squareThenNegate 5)
```

`f >> g` 产出"先 f 后 g"的新函数，**不需要提到输入值**——这是它和管道的本质区别：管道喂值，组合造函数。反向组合 `<<`（先右后左）偶尔在手写"内嵌表达式"时好用：

```fsharp
let round (x: float) = System.Math.Round x
let percent = round << fun x -> x * 100.0    // 先 ×100 再取整（重载方法要先绑定成函数）
```

## 4.5 高阶函数

```fsharp
let twice f x = f (f x)
printfn "twice square 3 = %d" (twice square 3)
let adders = [ (fun x -> x + 1); (fun x -> x * 2) ]   // 函数也能进列表
adders |> List.iter (fun f -> printfn "f 7 = %d" (f 7))
```

函数可以存进列表、当参数、当返回值——`twice` 把"执行两次"抽象成了独立于具体行为的组合子。

## 4.6 递归：let rec

```fsharp
let rec factorial n = if n <= 1 then 1 else n * factorial (n - 1)
printfn "5! = %d" (factorial 5)
```

F# 里递归必须显式 `rec` 标记（编译器要求作用域内自引用显式化）。

## 4.7 尾递归 + 累加器：不爆栈

```fsharp
let rec sumTail acc list =
    match list with
    | [] -> acc
    | head :: tail -> sumTail (acc + head) tail
printfn "sumTail [1..100] = %d" (sumTail 0 [ 1 .. 100 ])
```

`sumTail` 的递归调用是函数体**最后一步**（尾调用），编译器把它优化成循环——栈帧复用，百万级列表也不会 `StackOverflowException`。技巧是把"算到哪了"用累加器 `acc` 随身携带。`head :: tail` 模式拆列表的原理在第 05 章。

## 4.8 互递归：and

```fsharp
let rec isEven n = if n = 0 then true else isOdd (n - 1)
and isOdd n = if n = 0 then false else isEven (n - 1)
printfn "isEven 10 = %b" (isEven 10)
```

两个函数互相引用时，第二个起用 `and` 替代 `let rec`。

## 4.9 坑位清单

- **应用 vs 柯里化**：`add 5 6` 是完整应用返回 11；`add 5` 才是部分应用返回函数。
- **`>>` 方向记反**：`f >> g` 先 f 后 g（从左到右），与数学复合 `g∘f` 相反。
- **忘写 rec**：自引用函数漏 `rec` 报"未定义"。
- **方法不能柯里化**（连第 20 章）：`.NET` 方法部分应用是编译错误，先绑定到 let 或写 lambda。
- **闭包捕获可变值**：循环里生成闭包时捕获的是变量槽，不是快照。
