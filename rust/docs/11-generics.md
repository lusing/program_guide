# 11 · 泛型

> 对应示例：`examples/11_generics/`
>
> 泛型 = 参数化类型 + 编译期单态化（每个具体类型生成一份机器码，零虚调用）。
> 本章讲语法与约束；"trait 到底怎么设计"在下一章。

## 11.1 泛型函数：没有约束寸步难行

```rust
fn largest<T: PartialOrd>(items: &[T]) -> &T {   // T 必须能比大小
    let mut max = &items[0];
    for it in &items[1..] {
        if it > max { max = it; }
    }
    max
}

largest(&[34, 50, 12])       // T = i32
largest(&["milk", "bread"])  // T = &str —— 同一源码，两份实例
largest::<i32>(&[3, 1, 2])   // turbofish 显式指定（多数时候靠推断可省）
```

无约束的 `T` 只能做"所有类型都能做"的事（move、drop）——想 `>` 就得声明 `PartialOrd`，想打印就得 `Display`。**约束就是能力清单**，与 Go 的接口约束、C++20 concepts 同一思想，比 C++ 模板的"SFINAE 报错三百行"友好一个数量级。

## 11.2 多参数、多约束、where

```rust
fn print_pairs<K: Display, V: Display>(pairs: &[(K, V)]) { ... }

fn summary<T, U>(items: &[T], extra: U) -> String
where
    T: Display + Clone,      // + 连接多个约束
    U: Display,
{ ... }
```

约束复杂时 `where` 子句比内联签名可读——社区惯例是超过两个约束就下放 where。

**从集合的角度理解约束**（《Rust 编程之道》的视角，有助于读复杂签名）：类型是值的集合，`T: Display` 读作"T 属于实现了 Display 的类型集合"；`T: A + B` 是**交集**（同时满足 A 和 B）；`trait P: A + B`（trait 继承，12 章）读作"P 是 A∩B 的子集"。于是 `impl<T: A + B> C for T` 就是"为交集里的所有类型批量实现 C"——blanket impl（12.6）的数学本质。

## 11.3 泛型结构体与枚举

```rust
struct Pair<T, U = i32> {     // 默认类型参数（运算符重载里常见）
    first: T,
    second: U,
}
enum Either<L, R> { Left(L), Right(R) }   // Option/Result 就是泛型枚举
```

`Option<T>`、`Result<T, E>`、`Vec<T>`、`HashMap<K, V>`——标准库的半壁江山是泛型类型，你从第 02 章起就在用。标准库 `Vec<T>` 的真身就是个泛型结构体：

```rust
pub struct Vec<T> {
    buf: RawVec<T>,   // 堆缓冲的原始管理器
    len: usize,       // 元素个数
}
```

## 11.4 泛型 impl：方法有自己的约束

```rust
impl<T: Display + PartialEq, U: Display> Pair<T, U> {
    fn same_as(&self, other: &Self) -> bool { ... }   // Self = Pair<T, U>
}

impl Pair<f64, f64> {        // 只给具体类型加方法（部分具体化）
    fn distance(&self) -> f64 { ... }
}
```

方法约束可以比 impl 约束更紧；`Self` 在 impl 块里指"当前类型"。注意 `impl<T> Point<T>` 里的 `<T>` 是**重新声明**——为泛型类型写 impl 时泛型参数必须再次出现。类型不同则方法不同——`Pair<i32, f64>` 没有 `distance`（示例实测编译错）。

## 11.5 单态化：零成本的机制

```text
largest::<i32> 与 largest::<&str> 各生成一份机器码（编译期复制粘贴 + 类型检查）
→ 无虚表、无装箱、可内联 —— 与手写具体类型的代码性能一致
```

用《Rust 编程之道》的等价变换来理解：编译器把 `fn foo<T>(x: T) -> T` 在 `foo(1)` 和 `foo("hello")` 两处调用点分别实例化成：

```rust
fn foo_i32(x: i32) -> i32 { x }
fn foo_str(x: &'static str) -> &'static str { x }
```

这就是**单态化（monomorphization）**：泛型只是源码层的抽象，机器码层没有任何"泛型"。

代价在**编译时间和代码体积**：每个新类型组合都是一份新实例，泛型库的编译慢主要来自这里；二进制膨胀到 noticeable 时，热点路径可考虑 trait 对象（12 章）收敛代码体积。对照：trait 对象动态分发——一份代码 + 每次虚调用，编译快二进制小。这是 Rust 的核心权衡之一，12 章给决策表。

## 11.6 泛型返回值自动推导

```rust
trait Make { fn new(v: i32) -> Self; }
struct Foo(i32);
struct Bar(i32, i32);
impl Make for Foo { fn new(v: i32) -> Self { Foo(v) } }
impl Make for Bar { fn new(v: i32) -> Self { Bar(v, v + 10) } }

fn make<T: Make>(v: i32) -> T { T::new(v) }
let f: Foo = make(10);   // 标注返回值类型 → 推导出调用 Foo::new
let b: Bar = make(20);   // 同一函数，另一份实例
```

泛型函数的返回类型可以靠**调用处的标注**收敛——这是关联类型（12.4）与泛型协同的典型场景。

## 11.7 与 C++ 模板的关键差异

| | Rust 泛型 | C++ 模板 |
|---|---|---|
| 检查时机 | **定义处**按约束检查一遍 | 实例化处检查（错误滞后且爆炸） |
| 约束声明 | 必须（trait bound 先行） | 可选（concepts 出现后改善） |
| 特化 | 不支持（声明的约束就是全部） | 全特化/偏特化 |
| 元编程 | 泛型 + 宏（16 章）+ 过程宏 | 模板图灵完备 |
| 失败报错 | "缺 trait X" 一句话 | 数屏天书（concepts 前时代） |

不支持特化是有意的：约束即合同，没有"这个类型走后门"。

### 泛型特化（nightly 预览）：为特定类型开后门

Rust 正在实验泛型特化（`specialization` feature）——允许为泛型 impl 提供更具体的覆盖版本。这不稳定，但理解它有助于看懂标准库的设计意图：

```rust
#![feature(specialization)]   // nightly only！

trait Example { fn call(&self); }

impl<T> Example for T {                    // 最泛：所有类型
    default fn call(&self) { println!("most generic"); }
}

impl<T: std::fmt::Display> Example for T { // 较具体：Display 类型
    default fn call(&self) { println!("generic for Display, {self}"); }
}

impl Example for str {                     // 最具体：仅 str
    fn call(&self) { println!("specialized for str, {self}"); }
}

let v1 = vec![1i32, 2, 3];
v1.call();        // "most generic"——Vec<i32> 不满足 Display
1i32.call();      // "generic for Display, 1"——i32 满足 Display
"hello".call();   // "specialized for str, hello"——精确匹配 str
```

三个 impl 构成从泛到特的层次。编译器自动选最匹配版本。`default` 关键字标记"这个方法可以被更具体的 impl 覆盖"——没有 `default` 的方法不可被特化。

**为什么需要特化**——标准库 `ToString` 的性能问题：标准库为所有 `Display` 类型 blanket impl 了 `ToString`：

```rust
impl<T: fmt::Display + ?Sized> ToString for T {
    fn to_string(&self) -> String {
        let mut buf = String::new();
        buf.write_fmt(format_args!("{}", self)).expect("...");
        buf
    }
}
```

这对大多数类型是合理的默认。但对 `&str` 来说——它已经是字符串了，`to_string` 走 `write_fmt` 的格式化管道纯属浪费。特化允许：

```rust
impl<T: fmt::Display + ?Sized> ToString for T {
    default fn to_string(&self) -> String { /* 通用路径 */ }
}

impl ToString for str {
    fn to_string(&self) -> String {
        String::from(self)    // 直接拷贝，零格式化开销
    }
}
```

对外接口统一（都是 `to_string`），内部实现按需优化——零开销抽象的又一面。这也解释了为什么 `&str` 转 `String` 推荐 `String::from(s)` 或 `s.into()` 而非 `s.to_string()`（历史原因：特化稳定前 `to_string` 确实慢）。

**交叉 impl 问题**：特化的最大障碍不是语法，而是**一致性**。如果两个 impl 针对的类型集合有交集但互不包含，编译器无法判断哪个更"特化"：

```rust
trait Foo {}
trait B {}
trait C {}

impl<T: B> Foo for T {}    // B 类型
impl<T: C> Foo for T {}    // C 类型——与上面交叉！

// 如果 T: B + C，该用哪个 impl？真子集规则判不出。
// 方案：为交集再写一个 impl（最特化）
impl<T: B + C> Foo for T {}   // 交集版本——最匹配
```

但交集规则引入了跨 crate 问题：crate A 为 `Display` 类型实现了 `RichDisplay`，crate B 为 `Widget<T>` 实现了 `RichDisplay`——上游 crate 给 `Widget<T>` 加上 `Display` 后，两个 impl 突然冲突，下游代码编译错。上游的"非破坏性扩展"变成了下游的 breaking change——这是特化至今未稳定的根本原因。

**当前状态**：特化仍在 nightly 实验中，完整规则（negative impl、lifetime 特化、跨 crate 一致性）尚未定型。日常代码用不上，但读标准库源码时会遇到 `default fn`——知道它是"可被特化覆盖"的标记即可。

## 11.8 const 泛型（了解）

```rust
struct Buffer<const N: usize> { data: [u8; N] }     // 长度进类型
fn dot<const N: usize>(a: &[f64; N], b: &[f64; N]) -> f64 { ... }
```

数组按值传参（`[u8; 32]` 与 `[u8; 64]` 是不同类型）的桥——标准库的 `impl TryFrom<&[u8]> for [u8; N]` 靠它覆盖所有长度。日常业务少写，读标准库会遇到。

## 11.9 坑位清单

1. **裸 T 编译不过你的直觉**：`fn f<T>(x: T) { println!("{x}"); }` 缺 `Display`——报错第一条就是解药。
2. **默认类型参数的触发**：`Pair { first: "x", second: 42 }` 才用到默认；显式写全两参时默认不生效。
3. **turbofish 是 `::<>`**：`parse::<i32>()`、`collect::<Vec<_>>()`——`_` 让推断补其余。
4. **泛型函数与生命周期**：`fn f<T>(x: &T)` 能过（省略规则），但返回引用时约束要写 `T: 'a`（13 章）。
5. **impl 块类型对不上就"方法不存在"**：`Pair::new(3, 4)` vs `Pair::new(3, 4.5)` 是不同类型——示例 `same_as` 实测报 E0308（expected f64, found integer）。
6. **单态化膨胀**：库里大量小泛型函数 × 多类型 = 编译变慢、二进制变大；热点具体类型可专设别名。
7. **别忘了泛型 enum 的 derive**：`#[derive(Debug)] struct Pair<T, U>` 要求 T/U 也 Debug——derive 自动加 bounds，类型不满足时再报。
8. **DST 与 `?Sized`**：`fn f<T: ?Sized>(x: &T)` 允许 T 是 str/[T]/dyn Trait 这类动态大小类型——代价是只能经引用使用（03 章 3.6 的胖指针）。绝大多数泛型默认 `T: Sized`，遇到 `?Sized` 别慌，意思是"这个函数连切片都能收"。

---

上一章：[10 错误处理](10-errors.md) · 下一章：[12 Trait](12-traits.md)
