# 03 · 变量、类型、控制流与函数

> 对应示例：`examples/03_basics/`
>
> C/C++ 老手的"快速通道"章：三分熟悉七分陌生。重点是 Rust 特有的部分——
> 遮蔽、溢出策略、as 截断规则、一切皆表达式。官方书 TRB 也把这些放在同一章。

## 3.1 一切皆表达式：语句与表达式的分界

Rust 代码由**语句（statement）**和**表达式（expression）**组成，而 Rust 是"一切皆表达式"的语言——表达式皆有值，值皆有类型：

```rust
fn main() {
    let a = 40;              // let 语句：声明绑定（不返回值，所以 let x = (let y = 1) 非法）
    let b = 2;               // 表达式 40、2 求值得到值
    assert_eq!(a + b, 42);   // a + b 是表达式；assert_eq! 是宏语句
}
```

语句只有两种：**声明语句**（`let`、fn 定义、use 导入）和**表达式语句**（表达式 + 分号，把表达式的值丢弃为 `()`）。块 `{ ... }` 本身是表达式——块内最后一个**不带分号**的表达式就是块的值。这解释了 Rust 为什么没有"三元运算符"：`if c { a } else { b }` 已经是一个值。

## 3.2 位置表达式与值表达式：为什么赋值即 move

表达式按语义分两类（对应 C++ 的左值/右值）：

| | 位置表达式（place expression） | 值表达式（value expression） |
|---|---|---|
| 是什么 | 代表**内存位置**：本地变量、静态变量、解引用 `*p`、索引 `a[i]`、字段 `s.f` | 代表**值**：字面量、函数调用、运算结果、临时值 |
| 能干什么 | 可读可写（能出现在赋值号左边） | 只读 |

关键规则：**位置表达式出现在值上下文中（比如赋值号右边），会把内存位置"整体让渡"出去——这就是 move**：

```rust
let place1 = "hello";               // &str，Copy 类型
let place2 = "hello".to_string();   // String，move 语义类型
let other = place1;                 // 按位复制（Copy），place1 仍可用
let other2 = place2;                // move：内存位置让渡，place2 从此不可用
// println!("{place2}");            // ← 编译错：value used here after move
println!("{other} {other2}");
```

反过来，值表达式不能出现在位置上下文：`temp() = 3`（给函数返回值赋值）直接编译错 `invalid left-hand side expression`。引用操作符 `&` 是例外通道——它把值表达式"锚"到一个临时位置：`let e = &42;` 合法，编译器会为 42 创建临时存储。

这套"位置/值"二分是所有权（04 章）的语法基础：**move 不是运行时动作，是"哪个表达式代表哪块内存"的静态判定**。

## 3.3 绑定：默认不可变，且是编译期强制

```rust
let x = 42;        // 不可变绑定：再赋值直接编译错
let mut count = 0; // mut 才能改
count += 1;        // 没有 ++/--，用 += 1 / -= 1
```

C++ 的 `const` 是类型修饰符，Rust 的不可变是**绑定属性**。同理 `mut` 修饰的也是绑定：`let mut v: Vec<i32>` 里 v 本身可重新绑定内容……在 Rust 里你几乎不需要区分"顶层 const"和"底层 const"——不可变传递性由借用系统统一管（05 章）。

Rust 用 let 声明的"变量"实际是**绑定（binding）**：标识符与一块内存的关联。`let b = a` 对 move 语义类型来说，就是 a 解绑、b 重新绑定那块内存——"绑定"这个词提醒你所有权跟着走。

## 3.4 遮蔽（shadowing）：与 mut 完全不同

```rust
let spaces = "   ";        // &str
let spaces = spaces.len(); // 新绑定，同名不同类型，完全合法
```

`mut` 改的是**同一个绑定的值**（类型不能变）；遮蔽是**创建全新绑定**（类型随便换）。典型用途：把"原始输入"无缝转换成"解析结果"，不用起 `input_str`/`input_num` 两个名字。

## 3.5 标量类型

| 组 | 类型 | 备注 |
|---|---|---|
| 有符号整数 | `i8 i16 i32 i64 i128 isize` | 字面量默认 `i32` |
| 无符号整数 | `u8 u16 u32 u64 u128 usize` | `u8` 是字节；`usize` 做下标 |
| 浮点 | `f32 f64` | 字面量默认 `f64`；无隐式转换 |
| 布尔 | `bool` | 条件必须 bool：`if 1 {}` 编译不过 |
| 字符 | `char` | **4 字节** Unicode 标量值，单引号 `'中'` |

两个易错点：

1. **无隐式数值转换**：`let a: i64 = i32_var;` 编译错，必须 `as`（见 3.7）。
2. **`char` 不是 byte**：`'中'.len_utf8()` 是 3（UTF-8 编码占 3 字节），但 `char` 本身按 Unicode 标量值存 4 字节。字节是 `u8`，字符串按字节处理（06 章）。

## 3.6 复合类型：元组与数组

```rust
// 元组：异构、定长
let t: (i32, f64, char) = (500, 6.4, 'z');
let (q, _w, e) = t;      // 解构
let first = t.0;         // 按位置访问

// 数组：同构、定长、栈上
let arr: [u8; 5] = [1, 2, 3, 4, 5];
let zeros = [0u8; 8];        // [初值; 长度]
let [head, .., tail] = arr;  // 模式解构（08 章细讲模式）
```

越界行为是 Rust 的卖点之一：**安全代码里永远 panic（可捕获、可调试），绝不未定义行为**。数组长度编译期已知时，`arr[10]` 直接编译错；运行期才知道下标（切片）时 panic。

```rust
let v = vec![1, 2, 3];
let x = v.get(10);   // Option<&i32> = None，不 panic（09/10 章）
// let y = v[10];    // panic: index out of bounds
```

**类型大小的三种形态**（《Rust 编程之道》第 3 章的框架，后文反复用）：

| 形态 | 含义 | 例子 |
|---|---|---|
| Sized（可确定大小） | 编译期知道字节数，可以按值存放 | `i32`（4B）、`[u8; 5]`、`String`（栈上三元组 24B） |
| DST（动态大小） | 编译期不知大小，**只能通过胖指针间接使用** | `str`、`[T]`、trait 对象 `dyn Trait` |
| ZST（零大小） | 0 字节，"值即类型本身" | `()`、单元结构体、`[u8; 0]` |

胖指针 = 指针 + 元信息：`&str` 是（地址, 字节长度）、`&[T]` 是（地址, 元素个数）、`&dyn Trait` 是（数据地址, vtable 地址）——都占 16 字节（64 位），这是 12 章 trait 对象和 06 章字符串切片的共同地基。验证只要一行：

```rust
assert_eq!(std::mem::size_of::<&[u8; 5]>(), 8);  // 普通引用：纯地址
assert_eq!(std::mem::size_of::<&[u8]>(), 16);    // 胖指针：地址 + 长度
```

DST 的三条使用限制（记住即可，编译器会替你执法）：只能藏在胖指针后；不能当变量/参数/枚举字段的类型（参数要写成 `&[T]` 而不是 `[T]`）；结构体里只有**最后一个字段**可以是 DST。

## 3.7 类型推断与标注

```rust
let n = "42".parse::<i32>().unwrap(); // turbofish：在表达式处指定
let m: i64 = "42".parse().unwrap();   // 标注：让推断收敛
let mut v = Vec::new();               // 此时元素类型未定
v.push(1);                            // 收敛为 Vec<i32>——之后 push "a" 就报错
```

推断足够聪明，但**函数签名必须全标**（04 章函数规则）——这是刻意的：公共 API 不该靠猜。推断失败时编译器会给出 `{integer}` 这类**占位类型名**（"已知道是整数但定不下来"），此时补标注或 turbofish：

```rust
// let a = 0;
// a.is_positive();   // ← 报错 no method named `is_positive` on type `{integer}`
let a: i32 = 0;       // 显式收敛后一切正常
a.is_positive();
```

## 3.8 as 转换：截断规则必须背下来

```rust
let big = 300i32;
let small = big as u8;    // 44：取低 8 位（300 = 0b1_0010_1100）
let f = 2.9f64;
let n = f as i32;         // 2：朝零截断，不是四舍五入
let m = (-2.9f64) as i32; // -2：同样朝零
```

`as` 是"我知道我在干什么"的显式窄化。更严谨的转换家族（返回值自描述失败）：`TryFrom/TryInto`（10 章）、`checked_*`（见下）。

## 3.9 溢出：Debug panic，Release 环绕，以及四个显式策略

```rust
let (m, one) = (u8::MAX, 1u8);
m + one        // Debug 构建：panic；Release 构建：环绕成 0（UB 不存在，但值会"错"）
m.checked_add(one)     // Option<u8> = None      —— 可能失败就问
m.wrapping_add(one)    // 0                       —— 我要环形算术（哈希、序列号）
m.saturating_add(one)  // 255                     —— 夹在边界
m.overflowing_add(one) // (0, true)               —— 要值也要溢出标志
```

教学示例常在 Debug 下"演示 panic"，生产代码请写明策略——Rust 的态度是**溢出是设计决策，不是运气**。

## 3.10 const、static、类型别名

```rust
const MAX_POINTS: u32 = 100_000;  // 编译期常量：必须标类型，内联到使用处
static NAME: &str = "guide";      // 固定内存地址的 'static 数据
type Kilometers = i32;            // 类型别名（零开销，纯可读性）
```

`const` vs `static`：const 是编译期替换（没有"唯一地址"）；static 有地址、可被引用、生命周期 `'static`。mutable static（`static mut`）在 2024 edition 里限制极严（19 章），需要可变全局状态请用原子量或锁（22 章）。

## 3.11 控制流：一切皆表达式

```rust
// if 是表达式：有值
let parity = if n % 2 == 0 { "偶" } else { "奇" };

// loop + break 带值：替代 C 的 while(true)+flag
let result = loop { counter += 1; if counter == 10 { break counter * 2; } };

// while / for
let mut fuel = 3;  while fuel > 0 { fuel -= 1; }
for i in 0..5 {}       // 半开区间 0..5
for i in 1..=5 {}      // 闭区间 1..=5
for i in (0..4).rev() {} // 反向
for ch in "你好a".chars() {} // 任何 IntoIterator 都能 for（15 章）

// 标签：直接跳出指定层
'outer: for x in 0..5 {
    for y in 0..5 {
        if x * y > 6 { break 'outer; }
    }
}
```

块 `{ ... }` 末尾**无分号的表达式就是块的值**——这是 Rust 没有"三元运算符"的原因：`let m = if c { a } else { b };` 已经是表达式。

**发散与底类型 `!`**：`panic!`、`loop {}`、`break`/`continue`、空枚举 `enum Void {}` 这类"没有值"的情形，Rust 用底类型（bottom type）`!` 统一纳入类型系统——它是任何类型的子类型，所以 `if false { panic!() } else { 100 }` 类型检查能过（100 的分支定类型）。日常你只在 `fn die() -> ! { panic!() }` 这种签名里见到它。

## 3.12 函数：签名必须全标，返回值是表达式

```rust
fn add(a: i32, b: i32) -> i32 { a + b }   // 块末无分号 = 返回值

fn sign(x: i32) -> i32 {
    if x == 0 { return 0; }  // 提前返回才用 return（守卫子句惯用）
    if x > 0 { 1 } else { -1 }
}

fn log(msg: &str) { /* 无 -> 即返回 () */ }
```

- 参数、返回类型**必须显式**（泛型函数的约束也是签名的一部分，11 章）。
- `!` 是**发散类型**（never）：永不返回的函数（panic、无限循环）。`fn die() -> ! { panic!(...) }` 可以出现在任何需要值的位置——类型系统能"吞掉"它。
- 没有函数重载、没有默认参数、没有可变参数（用泛型/宏/Option 替代，11/16 章）。

## 3.13 坑位清单

1. **`if x = 1` 类笔误零机会**：赋值表达式返回 `()` 不是 bool，条件处直接编译错。
2. **遮蔽 ≠ 可变**：`let x = x + 1` 是新绑定；对非 mut 绑定 `x += 1` 才是编译错。
3. **整数默认 i32、浮点默认 f64**：`let x = 3.5;` 是 f64；放进 `Vec<f32>` 前要么字面量 `3.5f32`，要么标注。
4. **`as` 溢出静默**：`300i32 as u8` 得 44 不报错——边界数据转换用 `u8::try_from(big)` 拿 Result。
5. **元组下标访问越界是编译错**：`t.3` 对三元素元组直接编译不过（长度编译期已知）。
6. **`char` 与 `u8` 混淆**：`'a'` 是 char；字节字面量是 `b'a'`（u8）；`char as u8` 对非 ASCII 得到截断值——先想清楚单位。
7. **for 循环消费所有权**：`for x in v` 之后 v 不可用（被 move）；要保留用 `for x in &v`（15 章三兄弟 iter/iter_mut/into_iter）。
8. **函数忘了返回值导致 `()` 不匹配**：块末不小心加了分号 → "expected i32, found ()"——经典新手报错，检查块末分号。
9. **DST 当参数类型直接编译错**：`fn f(arr: [u32])` 报 "does not have a constant size known at compile-time"——改 `[u32; 5]` 或 `&[u32]`（胖指针）。
10. **`{integer}` 占位类型不是真实类型**：报错里出现它 = 推断没收敛，补标注，别去搜这个"类型"怎么用。

---

上一章：[02 第一个程序](02-hello.md) · 下一章：[04 所有权](04-ownership.md)
