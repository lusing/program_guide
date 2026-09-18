# 16 · 宏系统

> 对应示例：`examples/16_macros/`
>
> Rust 宏 = 编译期代码生成。声明宏（macro_rules!）本章动手写；
> 过程宏（#[derive]、#[tokio::main] 背后那类）讲清原理即可——它们是独立的编译器插件 crate。

## 16.1 为什么 println! 是宏而 print 不是函数

三个只有宏能做的事：

1. **参数数量可变**：`println!("x")`、`println!("{} {}", a, b)`——fn 签名做不到；
2. **编译期检查格式串**：占位符与参数的类型/数量对不上直接编译错；
3. **语法扩展**：`vec![a; n]`、`assert_eq!(x, y, "带格式 {x}")` 的语法根本不是函数调用。

代价：宏定义难读、错误信息指向展开后的位置、IDE 支持弱于函数。**能用函数就不用宏，宏用在"重复模式"和"必须编译期"两处**。

## 16.2 声明宏解剖：规则 + 片段 + 重复

```rust
macro_rules! my_sum {
    () => { 0 };                                    // 规则 1：空 → 0
    ($last:expr) => { $last };                      // 规则 2：单个表达式
    ($first:expr $(, $rest:expr)* $(,)?) => {       // 规则 3：多个
        $first $(+ $rest)*                          // 展开：首项 + 其余各项
    };
}

my_sum!()          // 0
my_sum!(5)         // 5
my_sum!(1, 2, 3)   // 6（自上而下尝试规则，先匹配先用）
my_sum!(1, 2, 3,)  // 6（$(,)? 允许尾逗号）
```

读法：

- `$x:expr` 捕获一个**片段（fragment）**并命名 x；
- `$(...)* ` 重复零次或多次，`$(...)+ ` 至少一次，`$(,)?` 可选项；
- 匹配侧写"输入长什么样"，展开侧写"生成什么代码"，两处用同名 `$x` 缝合。

**片段类型全表**（匹配后能干什么受类别限制）：

| 片段 | 匹配 | 典型用途 |
|---|---|---|
| `expr` | 表达式 | 参与运算 |
| `ident` | 标识符 | 造函数/变量名 |
| `ty` | 类型 | 泛型代码生成 |
| `pat` | 模式 | match 分支生成 |
| `stmt` | 语句 | 逐条展开 |
| `literal` | 字面量 | 编译期常量 |
| `tt` | 单个 token 树 | 万能兜底（写 DSL） |
| `block` | 块 | 包装用户代码 |
| `path` | 路径 | `std::vec::Vec` 这类 |

## 16.3 实战三个：调试宏、vec 宏、代码生成

```rust
// 打印"源码 = 值"（stringify! 拿 token 的文本形态）
macro_rules! dbg_vars {
    ($($name:expr),* $(,)?) => {
        $(println!("  {} = {:?}", stringify!($name), $name);)*
    };
}
let a = 10;
dbg_vars!(a, a * 2);        //   a = 10 /  a * 2 = 20

// 造一个 vec!-like 宏（这正是 vec! 的原理，教学展开）
macro_rules! my_vec {
    ($($item:expr),* $(,)?) => {{
        #[allow(unused_mut, clippy::vec_init_then_push)]
        let mut v = Vec::new();
        $(v.push($item);)*
        v
    }};
}

// 生成结构体 + 构造函数（元编程：ident/ty 片段造类型）
macro_rules! make_point {
    ($name:ident, $($field:ident : $ty:ty),* $(,)?) => {
        #[derive(Debug, Clone, Copy)]
        struct $name { $($field: $ty,)* }
        impl $name {
            fn new($($field: $ty),*) -> Self { Self { $($field,)* } }
        }
    };
}
make_point!(Point2, x: f64, y: f64);
make_point!(Point3, x: f64, y: f64, z: f64);
let p = Point3::new(1.0, 2.0, 3.0);
```

## 16.4 宏卫生（hygiene）：展开的变量不会串味

```rust
let v = 999;
let made = my_vec![1];       // 展开里有自己的 v
println!("{v}");             // 999，安全——宏内部的 v 与调用处的 v 互不相认
```

宏里引入的绑定带"来源标记"，不可能意外捕获/遮蔽调用处变量——比 C 宏的文本替换安全一个次元。也因此**宏无法引用调用处的局部变量名**（想传名字就显式传 ident）。

## 16.5 导出与可见性

```rust
#[macro_export]              // 挂到 crate 根，外部 crate 可用 crate::shout!
macro_rules! shout { ($s:expr) => { println!("{}！", $s.to_uppercase()) }; }

// 本 crate 内：mod 位置无关，直接可用
// 想限定 crate 内部：#[macro_use] mod macros; 或 pub(crate) use shout;
```

跨 crate 用宏靠 `#[macro_export]` + `use`；新版惯用法是 `pub(crate) use` 重导出控制范围。

## 16.6 过程宏：另一颗星球（原理课）

`#[derive(Debug)]`、`#[serde(rename_all)]`、`#[tokio::test]`、`sqlx::query!` 全是过程宏——**接收 TokenStream、返回 TokenStream 的编译器插件**，独立 crate（`proc-macro = true`）：

| 种类 | 形态 | 例子 |
|---|---|---|
| derive 宏 | 给 struct/enum 挂 #[derive(X)] | serde 的 Serialize |
| 属性宏 | 包住任意条目 | #[tokio::main] |
| 函数式宏 | 像函数调用 | sqlx::query! |

写过程宏需要 `syn`（解析 Rust 语法树）+ `quote`（生成代码）——工作量大但能力完整（能读类型、能生成 impl）。**本教程不手写过程宏**：会用 derive、看得懂报错即可；真实需求（给内部框架造 DSL）再学，推荐官方 Process Macros 一书。

## 16.7 坑位清单

1. **规则顺序敏感**：自上而下首匹配生效——具体的放前面，兜底放最后（写反 = 永远走不到）。
2. **`$($x:expr),*` 与 `$(,)?`**：前者管"逗号分隔重复"，后者管"尾逗号可省"——两个东西，别混。
3. **expr 片段不能当位置用**：`let $x:expr = ...` 非法（expr 不是名字）；要造名字用 ident。
4. **宏内 `Vec::new()+push` 被 clippy 抓**（vec_init_then_push）——教学宏在定义/调用处 `#[allow]` 并注明原因（示例实测：豁免要打到**调用处所在模块**，宏定义上的 allow 不跟随展开）。
5. **宏展开的 lint 报在调用处**：`#[allow]` 放调用点所在函数/模块才生效。
6. **递归宏**：macro_rules! 可以自调用但深度受限；真递归代码生成考虑过程宏。
7. **导入路径怪异**：宏从 `crate_name::macro_name` 导入（#[macro_export] 后属于 crate 根），不是从定义模块——`use my_crate::shout;` 而不是 `use my_crate::macros::shout;`。

---

上一章：[15 迭代器](15-iterators.md) · 下一章：[17 模块、crate 与 Cargo](17-cargo.md)
