# 03 · 值与不可变性：默认不可变的世界

> 对应示例：examples/03_values

## 3.1 解决什么问题

命令式语言里"这个变量会不会被谁改掉"是永恒的心智负担。F# 把默认反过来：**let 绑定的值不可变**，需要可变时必须显式声明。这换来两类红利：读代码时可放心"值不会变"；并发场景下天然安全（第 13 章）。

## 3.2 基本类型与字面量

```fsharp
let i = 42            // int（int32）
let big = 42L         // int64
let f = 3.14          // float（double）
let money = 19.99m    // decimal（金额）
let c = 'A'
let b = true
printfn "int=%d int64=%d float=%f decimal=%M char=%c bool=%b" i big f money c b
```

| 类型 | 字面量示例 | 适用 |
|---|---|---|
| `int`（int32） | `42` | 默认整数 |
| `int64` | `42L` | 大整数 |
| `float`（double） | `3.14` | 科学计算（**F# 的 float 就是 double**） |
| `float32` | `3.14f` | 单精度 |
| `decimal` | `19.99m` | 金额（十进制精确） |
| `char` / `string` / `bool` | `'A'` / `"文字"` / `true` | |

## 3.3 类型推断与显式注解

```fsharp
let x = 10
let y = x + 5                 // 同类型才可直接运算
// let z = x + 3.14            // 编译错误：int 与 float 不能隐式互转
let z = float x + 3.14        // 显式转换：float x 把 int 变 float
printfn "y=%d z=%.2f" y z
let toUpper (s: string) = s.ToUpper()   // 参数注解：调用 .NET API 时常见
```

F# **没有隐式数值转换**——这是刻意的立场：`int + float` 该按谁算有歧义，F# 要你显式表态。常用转换函数：`float`、`int`、`int64`、`decimal`、`char`、`string`。

什么时候需要写注解？三种：调用重载多的 .NET API 时、编译器推断不出时（错误信息会明说）、给读者看文档时。

## 3.4 自动泛化

```fsharp
let identity x = x            // 推断为 'a -> 'a：什么类型都能传
printfn "identity 5 = %d" (identity 5)
printfn "identity hi = %s" (identity "hi")
```

`'a` 读作 "alpha"，是编译器自动泛化出的类型参数——一个函数没理由限定类型时，F# 自动把它变成泛型（第 12 章展开）。

## 3.5 不可变性是默认

```fsharp
let baseValue = 10
let next = baseValue + 1      // next 是新值，baseValue 不变
```

"改数据"在 F# 里是"造新值"：`{ record with Age = 31 }`（第 09 章）、`List.map` 产新列表（第 06 章）都是这个思路。

## 3.6 let mutable：需要可变时显式声明

```fsharp
let mutable counter = 0
counter <- counter + 1        // <- 赋值运算符
counter <- counter + 10
printfn "counter = %d" counter
```

注意赋值是 `<-`，`=` 是**比较**（返回 bool）。局部计数、循环累加这类场景用 `let mutable` 就够了。

## 3.7 ref cell：另一种可变容器

```fsharp
let cell = ref 0
cell := !cell + 5             // := 写入，! 读取
printfn "cell = %d" !cell
```

ref cell 是"包含可变槽的盒子"，历史代码里常见。现代 F# 建议：能用 `let mutable` 就用 mutable，ref 留给特殊场景（如闭包内修改）。

## 3.8 unit：没有有意义的返回值

```fsharp
let greet () = printfn "hello"  // 无参函数必须写 ()
greet ()
let nothing = ignore 42         // ignore：把任意值变成 unit
printfn "unit 打印为 %A" nothing
```

`unit` 类似 void 但**是真实类型**，只有值 `()`。无参函数定义必须写 `greet ()`（空括号是模式匹配"零元组"）；调用也要括号。产生副作用不关心结果时用 `|> ignore`。

## 3.9 数值边界速查

```fsharp
printfn "int 上限 = %d" System.Int32.MaxValue
printfn "int64 上限 = %d" System.Int64.MaxValue
```

F# 算术**默认不检查溢出**（回绕），关键计算用 `Checked.(+)` 系列或提前用位宽足够的类型。

## 3.10 坑位清单

- **`float` 是 double**：要单精度写 `float32`；从 C# 迁移最常踩。
- **`=` 是比较、`<-` 是赋值**：`if x = 1 then` 正确，`x = 1` 当赋值用会得到一个 bool。
- **int 与 float 不互转**：`float x` 显式转换，没有隐式捷径。
- **mutable 闭包捕获**：lambda 里捕获 mutable 值要小心语义（捕获的是变量槽）。
- **无参函数别忘了 `()`**：`greet` 是函数值，`greet ()` 才是调用。
