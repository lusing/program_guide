# 08 · 枚举与模式匹配

> 对应示例：`examples/08_enums/`
>
> Rust 的 enum 是"标签联合 + 代数数据类型"：每个变体可以携带不同的数据。
> 配合必须穷尽的 match，它是 Rust 取代 null、异常和大量 if-else 的根基。

## 8.1 enum = 带数据的标签联合

C 的 enum 只是整数常量；C++ 的 `std::variant` 接近但要 `std::get_if` 查询；Rust 把"变体 + 数据 + 匹配"做成语言核心。Rust 的枚举有三种形态：

```rust
enum Number { Zero, One, Two }              // 无参数：就是 C 风格枚举
enum Color { Red = 0xff0000, Green = 0x00ff00, Blue = 0x0000ff }  // 类 C：显式 discriminant
enum IpAddr { V4(u8, u8, u8, u8), V6(String) }  // 带数据：每个变体类型可以不同
```

第三种是 Rust 的精髓——**每个变体可以携带不同类型、不同数量的数据**。从类型论角度看，enum 是**和类型（sum type）**：一个 `IpAddr` 的值"要么是 V4 要么是 V6"，两种可能性**求和**；struct 是**积类型（product type）**：一个 `Rect` 同时有 width **和** height，两种成分**求积**。Rust 基于代数数据类型统一了结构体和枚举——这是函数式语言（ML/Haskell/OCaml）的血统，比 OOP 的继承层级更自由地构造类型。

### 代数类型系统：用基数理解类型

类型可以做代数运算——这是理解 enum 与 struct 关系的精确工具。一个类型的**基数（cardinality）**是它可能的取值个数。由此：

```rust
// 单位类型 () 的基数 = 1（只有一个值：()）
// bool 的基数 = 2（true / false）
// i32 的基数 = 2³²

// 积类型（struct/tuple）：基数相乘
struct R { var1: bool, var2: bool }
// Cardinality(R) = 2 × 2 = 4

// 和类型（enum）：基数相加
enum Direction { North, East, South, West }
// Cardinality(Direction) = 1 + 1 + 1 + 1 = 4

// 混合运算
enum Message {
    Quit,                        // 基数 1
    ChangeColor(i32, i32, i32),  // 基数 = i32³
    Move { x: i32, y: i32 },     // 基数 = i32²
}
// Cardinality(Message) = 1 + i32³ + i32²

// Option<T> 的基数 = Cardinality(T) + 1（多了一个 None）
// 空 enum 的基数 = 0——没有任何值可以构造
```

基数相同的类型是**同构**的——它们携带的信息量完全一样。`[i32; 2]`、`(i32, i32)`、`struct P(i32, i32)`、`struct R { a: i32, b: i32 }` 是四种不同的类型（不能互换），但基数都是 `i32²`——它们只是给同样的信息起了不同的名字。这个视角解释了为什么 Rust 的类型系统如此严格又如此灵活：**类型是信息的度量，不是内存布局的偶然**。

代数直觉还能推导语言的性质：加法交换律 ↔ enum 变体换序不影响表达能力；乘法交换律 ↔ struct 字段换序不影响；`()` 是乘法单位元（加进 struct 不改变基数）；空 enum 是加法单位元（加进 enum 不改变基数）。

带数据的变体本质上是一个**构造函数**：

```rust
let f: fn(u8, u8, u8, u8) -> IpAddr = IpAddr::V4; // 变体是函数指针类型！
let home = IpAddr::V4(127, 0, 0, 1);             // 调用它 = 构造一个值
```

`Option<T>` 与 `Result<T, E>` 就是标准库里用 enum 定义的两个类型（10 章），你天天用的 `Some(3)` 本质是 `Option::Some(3)` 构造：

```rust
enum Option<T> { Some(T), None }  // 标准库定义（简化）：有值 / 无值 二选一
enum Result<T, E> { Ok(T), Err(E) } // 成功 / 失败 二选一，各自携带数据
```

Rust 没有 null——`Option<T>` 用类型系统强迫你处理"可能没有值"的情况，把 Tony Hoare 称之为"十亿美元错误"的空指针问题在编译期消灭。

### Option 的零开销证明

`Option<T>` 不只是类型安全——它对指针类型的包装是**零开销**的。实测：

```rust
use std::mem::size_of;

assert_eq!(size_of::<isize>(), 8);
assert_eq!(size_of::<Option<isize>>(), 16);        // 普通整数：需要额外空间存 discriminant
assert_eq!(size_of::<&isize>(), 8);
assert_eq!(size_of::<Box<isize>>(), 8);
assert_eq!(size_of::<Option<&isize>>(), 8);         // 可空引用：和裸引用一样大！
assert_eq!(size_of::<Option<Box<isize>>>(), 8);     // 可空 Box：也一样大！
assert_eq!(size_of::<*const isize>(), 8);
assert_eq!(size_of::<Option<*const isize>>(), 16);  // 裸指针本身可为 null，无法优化
```

原理：`&T` 和 `Box<T>` 从语义上**不可能为 0**（Rust 不允许空引用/空 Box），编译器用 `NonZero<T>` 包装这个承诺。于是 `Option<&T>` 的内存表示就是：0 = None，非 0 = Some（指向 T）。机器码层面和 C 的指针**完全一样**——判别位藏在指针的"不可能值"里，不花一分钱。这就是为什么 `HashSet<T>` 能定义为 `HashMap<T, ()>`（值类型是零大小的 `()`），以及为什么 `Option<Box<T>>` 不比 `Box<T>` 大——**零开销抽象**在类型系统的最底层就成立。

## 8.2 match：穷尽性是生命线

```rust
fn area(s: &Shape) -> f64 {
    match s {
        Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
        Shape::Rect(w, h) => w * h,
        Shape::Point => 0.0,      // 漏掉任何变体 → 编译错：non-exhaustive patterns
    }
}
```

- **match 是表达式**（有值），每个分支产出同类型；
- **必须穷尽**：加新变体后，所有 match 处编译错——这是重构安全网（C 的 switch 忘 default 静默漏过，Rust 不给机会）；
- `_ =>` 是兜底；把 `_` 放前面会遮蔽后面分支（编译器警告 unreachable）。

## 8.3 模式语法全家

```rust
match n {
    0 => "零",                        // 字面量
    1 | 7 => "幸运",                  // 或模式（不连续值；连续值用范围更短）
    4..=9 => "中",                    // 范围（含端点；`..` 不含上界，用于切片语境）
    x if x % 2 == 0 => "偶大",        // 守卫：任意布尔条件
    x => "奇大（{x}）",               // 绑定：捕获匹配值
}
```

解构可以一层挖到底：

```rust
match (a, b) {                 // 匹配元组
    (0, y) => format!("a 是零，b = {y}"),
    (x, 0) => format!("a = {x}，b 是零"),
    (x, y) if x == y => format!("相等 {x}"),
    (x, y) => format!("({x}, {y})"),
}
match msg {                    // 匹配嵌套 enum/结构体
    Message::Move { x, y: 0 } => ..,      // 字段模式：只有 y==0 才命中
    Message::Write(ref s) if s.len() > 5 => ..,
    _ => ..,
}
```

**@ 绑定**——既要测试范围又要拿到值：

```rust
match age {
    n @ 0..=17 => println!("未成年（{n}）"),
    n @ 18..=65 => println!("劳动年龄（{n}）"),
    n => println!("退休（{n}）"),
}
```

## 8.4 if let / let else / matches!

只关心一种形态时的简写：

```rust
// if let：一种分支 + 可选 else
if let Some(n) = favorite { println!("{n}") } else { println!("无") }

// let else（1.65+）：解构失败必须发散（return/break/continue/panic）
let Some(c) = s.chars().next() else { return None };  // 此后 c 一定有值
// else 分支写普通表达式是编译错 —— 保证后续代码"已解包"

// matches!：只要布尔判定（守卫也支持）
assert!(matches!(Some(9), Some(n) if n > 5));
```

let-else 的适用面：函数开头"剥洋葱"（连续解包 Option/Result，失败早退），比层层 if let 嵌套清爽。注意它解构失败就发散，**不能**用来做"两种都走"的分支。

`while let` 是循环版的 if let——只要模式还匹配就一直循环：

```rust
while let Some(x) = v.pop() {  // Vec 取空返回 None，循环自动结束
    println!("{x}");
}
```

## 8.5 impl 也可以在 enum 上

enum 与 struct 平权——方法、trait、derive 全都适用：

```rust
impl Message {
    fn summarize(&self) -> String {
        match self { ... }        // 把 match 收进方法，调用方不用重复匹配
    }
}
```

把"按变体的行为"封装进 enum 方法，是替代 C++ 虚函数继承树的常用手法（配合 12 章 trait 对象）。

## 8.6 常用搭配模式

```rust
// 状态机：enum 做状态，match 做转移
enum State { Idle, Running { elapsed: u32 }, Done { code: i32 } }

// 错误分类：enum 做错误类型（10 章主角）
enum AppError { EmptyInput, Parse(ParseIntError), OutOfRange { .. } }

// "一个或另一个"：Either 风格
enum Either<L, R> { Left(L), Right(R) }   // 11 章泛型版
```

## 8.7 模式的可失败性：irrefutable vs refutable

模式分两种：**不可失败模式（irrefutable）**能匹配任何值——变量名、`(_)`、结构体解构（所有字段都是不可失败模式）。**可失败模式（refutable）**可能对某些值匹配失败——`Some(x)`、`Ok(v)`、字面量、`4..=9`。

这个区分不是学术概念——它决定了模式**能用在哪**：

| 场合 | 要求的模式 | 原因 |
|---|---|---|
| `let` 语句 | 只能不可失败 | `let Some(x) = opt;` 在 opt 为 None 时无法执行任何操作 |
| 函数参数 | 只能不可失败 | 参数不匹配时函数体无法执行 |
| `for` 循环 | 只能不可失败 | 元素不匹配时循环体无法执行 |
| `if let` / `while let` | 两种都行（可失败才有意义） | 不匹配就走 else 或退出循环 |
| `match` 分支 | 可失败（但全体必须穷尽） | 不匹配就试下一个分支 |

```rust
// let Some(x) = some_option;  // ← 编译错：可失败模式不能用在 let
if let Some(x) = some_option {   // ✔ if let 允许可失败模式
    println!("{x}");
}
```

`match` 的穷尽性检查本质上是在确保：所有可失败模式的不匹配路径，最终被某个不可失败模式（`_` 或变量绑定）兜住。

## 8.8 坑位清单

1. **`|` 或模式不能带不同的绑定**：`A(x) | B(x)` 要求 x 同类型同位置；不同形态的变体拆成两个分支。
2. **连续字面量 1 | 2 | 3 被 clippy 建议改 1..=3**（manual_range_patterns）——本教程按建议写，或用不连续值演示或模式。
3. **守卫里的变量遮蔽**：`x if let x = ...` 这类写法易踩；守卫用外层已绑定的名字即可。
4. **match 分支返回类型必须一致**：一个分支返回 String 另一个返回 &str → 编译错；统一 `to_string()` 或都返回 `&str`。
5. **`_` 吞掉新变体**：加了兜底就失去"新增变体报警"的保险——公开 API 的 enum 少用 `_`，显式列出所有变体。
6. **matches! 与 if let 的选择**：要"是否"用 matches!，要"值"用 if let——用 matches! 取值是误解。
7. **let-else 的 else 分支忘 return**：写 `{ println!(...) }` 不发散 → 编译错 "else branch must diverge"。这是特性不是 bug。
8. **unwrap 在不确定时用是定时炸弹**：`Some(42).unwrap()` 没问题；`maybe_value.unwrap()` 在 maybe 为 None 时 panic。不确定时用 `if let` / `match` / `?`。

---

上一章：[07 结构体](07-structs.md) · 下一章：[09 集合](09-collections.md)
