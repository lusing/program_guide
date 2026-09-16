# 12 · 泛型、SRTP 与度量单位

> 对应示例：examples/12_generics

## 12.1 解决什么问题

写一次、到处安全——泛型的价值不言自明。F# 在普通泛型之外还有两件独门兵器：**SRTP**（静态解析类型参数，编译期特化的"鸭子类型"）和**度量单位**（把物理量纲编进类型）。本章把三层能力一次讲清。

## 12.2 自动泛化：默认就是泛型

```fsharp
let firstOf list = List.head list       // 推断为 'a list -> 'a
printfn "firstOf [3;1;2] = %d" (firstOf [ 3; 1; 2 ])
printfn "firstOf ['a';'b'] = %c" (firstOf [ 'a'; 'b' ])
```

第 03 章的 `identity` 同理：F# 函数**能泛化就自动泛化**，不用你写 `<T>`。

## 12.3 显式约束

```fsharp
let areEqual (x: 'T when 'T : equality) (y: 'T) = x = y
let smallest list = list |> List.reduce (fun a b -> if a < b then a else b)
```

`smallest` 用了 `<`，编译器自动加上 comparison 约束。显式约束语法 `'T when 'T : 约束`，约束种类：

| 约束 | 含义 |
|---|---|
| `equality` | 可用 `=` 比较 |
| `comparison` | 可用 `<` 排序 |
| `struct` / `not struct` | 值类型 / 非值类型 |
| `null` | 可为 null |
| `new()` | 有无参构造 |
| `unmanaged` | 非托管（互操作场景） |

约束也支持**多个接口联用**与**类型继承**（`'T when 'T :> IComparable and 'T : equality`）。看约束最快的办法：把函数写完，悬停 IDE 或 `dotnet fsi` 里粘进去，`val` 行会印出编译器补全的完整签名——通常比你手写的更宽松。

```fsharp
// fsi 里查看 smallest 的实际签名：
// val smallest: list: 'a list -> 'a when 'a : comparison
```

## 12.4 SRTP：^T 与编译期特化

普通泛型 `'T` 是**运行时擦除**的；SRTP 用 `^T`（脱字符），在**每个调用点按实际类型特化**（配合 `inline`），于是可以要求"支持乘法的类型"这种 C# 泛型做不到的事：

```fsharp
let inline square (x: ^T) : ^T = x * x

printfn "square 4 = %d" (square 4)          // int 特化
printfn "square 1.5 = %.2f" (square 1.5)    // float 特化

let inline twiceSum (a: ^T) (b: ^T) : ^T = (a + b) + (a + b)
printfn "twiceSum 3 4 = %d" (twiceSum 3 4)          // 14
printfn "twiceSum 1.5 2.5 = %.1f" (twiceSum 1.5 2.5) // 8.0
```

同一个函数对 int、float 都工作——因为没有约束到具体运算符，运算在调用点解析。**成员约束**版 SRTP 更像鸭子类型：

```fsharp
let inline area2D (s: ^S) : float = (^S: (member Area: float) s)

type Disk = { Radius: float } with
    member this.Area = Math.PI * this.Radius * this.Radius

type Rect = { W: float; H: float } with
    member this.Area = this.W * this.H

printfn "disk.Area = %.2f" (area2D { Radius = 2.0 })   // 12.57
printfn "rect.Area = %.2f" (area2D { W = 3.0; H = 4.0 }) // 12.00
```

`^S: (member Area: float)` 的意思是"任何点得出 Area 成员的类型"——Disk 和 Rect 没有公共接口却都能用。

**SRTP 的代价**：错误信息冗长；函数不能当一等值传递/存列表（每个调用点都是特化代码）；调试难。经验：**运算符泛化（square/twiceSum）和标准库风格 API 用 SRTP；业务代码用普通泛型 + 接口**。

## 12.5 度量单位：量纲进类型系统

```fsharp
[<Measure>] type kg
[<Measure>] type m
[<Measure>] type s

let mass = 75.0<kg>
let height = 1.78<m>
let distance = 100.0<m>
let time = 9.58<s>
let speed = distance / time            // m/s
let bmi = mass / (height * height)     // kg/m^2
// let wrong = mass + height           // 编译错误：kg 与 m 不能相加
printfn "mass = %.1f kg" (float mass)  // float 剥掉单位用于打印
```

单位参与类型检查：kg 加 m 编译不过；除法自动推导 `m/s`、`kg/m^2`。示例输出：speed = 10.44 m/s、bmi = 23.7。`float mass` 剥掉单位取数值；`LanguagePrimitives.FloatWithMeasure<kg> 75.0` 反向贴标（第 20 章扩展练习可用）。适用场景：科学计算、工程、金融（区分币种）——量纲错误从运行时 bug 变成编译错误。

## 12.6 坑位清单

- **`^T` 函数不当一等值**：`let fns = [square]` 编不过；需要传递就包一层普通函数 `fun x -> square x`。
- **单位打印**：`printfn "%f"` 不收 `float<kg>`，先 `float` 剥单位。
- **SRTP 错误信息**：调用点类型不满足约束时报错一大段——从错误末尾往上找"期望的成员/运算符"。
- **inline 别滥用**：每个调用点生成代码，大面积 inline 编译变慢、程序集变大。
- **度量单位是编译期的**：擦除后运行时没有单位信息，序列化/打印要自己管理。
