# 08 · 枚举与模式匹配

> 对应示例：`examples/08_enums/`
>
> Rust 的 enum 是"标签联合 + 代数数据类型"：每个变体可以携带不同的数据。
> 配合必须穷尽的 match，它是 Rust 取代 null、异常和大量 if-else 的根基。

## 8.1 enum = 带数据的标签联合

```rust
enum Message {
    Quit,                        // 无数据
    Move { x: i32, y: i32 },     // 结构体式字段
    Write(String),               // 一个值
    ChangeColor(u8, u8, u8),     // 多个值（元组式）
}
```

C 的 enum 只是整数常量；C++ 的 `std::variant` 接近但要 `std::get_if` 查询；Rust 把"变体 + 数据 + 匹配"做成语言核心。`Option<T>` 与 `Result<T, E>` 就是标准库里的两个 enum（10 章），你天天用的 `Some(3)` 本质是 `enum Option::Some(3)` 构造。

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

## 8.7 坑位清单

1. **`|` 或模式不能带不同的绑定**：`A(x) | B(x)` 要求 x 同类型同位置；不同形态的变体拆成两个分支。
2. **连续字面量 1 | 2 | 3 被 clippy 建议改 1..=3**（manual_range_patterns）——本教程按建议写，或用不连续值演示或模式。
3. **守卫里的变量遮蔽**：`x if let x = ...` 这类写法易踩；守卫用外层已绑定的名字即可。
4. **match 分支返回类型必须一致**：一个分支返回 String 另一个返回 &str → 编译错；统一 `to_string()` 或都返回 `&str`。
5. **`_` 吞掉新变体**：加了兜底就失去"新增变体报警"的保险——公开 API 的 enum 少用 `_`，显式列出所有变体。
6. **matches! 与 if let 的选择**：要"是否"用 matches!，要"值"用 if let——用 matches! 取值是误解。
7. **let-else 的 else 分支忘 return**：写 `{ println!(...) }` 不发散 → 编译错 "else branch must diverge"。这是特性不是 bug。

---

上一章：[07 结构体](07-structs.md) · 下一章：[09 集合](09-collections.md)
