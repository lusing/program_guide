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

## 11.3 泛型结构体与枚举

```rust
struct Pair<T, U = i32> {     // 默认类型参数（运算符重载里常见）
    first: T,
    second: U,
}
enum Either<L, R> { Left(L), Right(R) }   // Option/Result 就是泛型枚举
```

`Option<T>`、`Result<T, E>`、`Vec<T>`、`HashMap<K, V>`——标准库的半壁江山是泛型类型，你从第 02 章起就在用。

## 11.4 泛型 impl：方法有自己的约束

```rust
impl<T: Display + PartialEq, U: Display> Pair<T, U> {
    fn same_as(&self, other: &Self) -> bool { ... }   // Self = Pair<T, U>
}

impl Pair<f64, f64> {        // 只给具体类型加方法（部分具体化）
    fn distance(&self) -> f64 { ... }
}
```

方法约束可以比 impl 约束更紧；`Self` 在 impl 块里指"当前类型"。类型不同则方法不同——`Pair<i32, f64>` 没有 `distance`（示例实测编译错）。

## 11.5 单态化：零成本的机制

```text
largest::<i32> 与 largest::<&str> 各生成一份机器码（编译期复制粘贴 + 类型检查）
→ 无虚表、无装箱、可内联 —— 与手写具体类型的代码性能一致
```

代价在**编译时间和代码体积**：每个新类型组合都是一份新实例。泛型库的编译慢主要来自这里。对照：trait 对象（12 章）动态分发——一份代码 + 每次虚调用，编译快二进制小。这是 Rust 的核心权衡之一，12 章给决策表。

## 11.6 与 C++ 模板的关键差异

| | Rust 泛型 | C++ 模板 |
|---|---|---|
| 检查时机 | **定义处**按约束检查一遍 | 实例化处检查（错误滞后且爆炸） |
| 约束声明 | 必须（trait bound 先行） | 可选（concepts 出现后改善） |
| 特化 | 不支持（声明的约束就是全部） | 全特化/偏特化 |
| 元编程 | 泛型 + 宏（16 章）+ 过程宏 | 模板图灵完备 |
| 失败报错 | "缺 trait X" 一句话 | 数屏天书（concepts 前时代） |

不支持特化是有意的：约束即合同，没有"这个类型走后门"。

## 11.7 const 泛型（了解）

```rust
struct Buffer<const N: usize> { data: [u8; N] }     // 长度进类型
fn dot<const N: usize>(a: &[f64; N], b: &[f64; N]) -> f64 { ... }
```

数组按值传参（`[u8; 32]` 与 `[u8; 64]` 是不同类型）的桥——标准库的 `impl TryFrom<&[u8]> for [u8; N]` 靠它覆盖所有长度。日常业务少写，读标准库会遇到。

## 11.8 坑位清单

1. **裸 T 编译不过你的直觉**：`fn f<T>(x: T) { println!("{x}"); }` 缺 `Display`——报错第一条就是解药。
2. **默认类型参数的触发**：`Pair { first: "x", second: 42 }` 才用到默认；显式写全两参时默认不生效。
3. **turbofish 是 `::<>`**：`parse::<i32>()`、`collect::<Vec<_>>()`——`_` 让推断补其余。
4. **泛型函数与生命周期**：`fn f<T>(x: &T)` 能过（省略规则），但返回引用时约束要写 `T: 'a`（13 章）。
5. **impl 块类型对不上就"方法不存在"**：`Pair::new(3, 4)` vs `Pair::new(3, 4.5)` 是不同类型——示例 `same_as` 实测报 E0308（expected f64, found integer）。
6. **单态化膨胀**：库里大量小泛型函数 × 多类型 = 编译变慢、二进制变大；热点具体类型可专设别名。
7. **别忘了泛型 enum 的 derive**：`#[derive(Debug)] struct Pair<T, U>` 要求 T/U 也 Debug——derive 自动加 bounds，类型不满足时再报。

---

上一章：[10 错误处理](10-errors.md) · 下一章：[12 Trait](12-traits.md)
