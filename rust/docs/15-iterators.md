# 15 · 迭代器 ⭐

> 对应示例：`examples/15_iterators/`
>
> Rust 惯用法的分水岭：会用迭代器管道之前你在"写循环"，之后你在"描述变换"。
> 14 章的闭包是燃料，本章是发动机。

## 15.1 三种来源：一个容器的三种交出方式

```rust
let v = vec![1, 2, 3];
for x in v.iter()        { }   // &T      借用元素，v 完好 —— 最常用
for x in v.iter_mut()    { }   // &mut T  就地改（绑定需 mut）
for x in v.into_iter()   { }   // T       拿走元素，v 之后不可用
```

`for x in expr` 的真身：`expr.into_iter()`——所以 `for x in &v` 走借用版、`for x in v` 消费版。数组、Range（`0..5`）、`&String`、HashMap 都实现了 `IntoIterator`，都能直接 for。

## 15.2 适配器 × 消费器：惰性流水线

```text
适配器（返回新迭代器，什么都不做）：map / filter / take / skip / zip / chain / enumerate / rev …
消费器（驱动真正遍历）：collect / sum / fold / count / for_each / max / any / all / find / position …
```

```rust
let v = [1, 2, 3, 4, 5];
let out: Vec<i32> = v.iter()
    .copied()                 // &i32 → i32
    .filter(|x| x % 2 == 0)   // 留偶数
    .map(|x| x * 10)          // ×10
    .collect();               // 落地 [20, 40]
```

**惰性是承诺也是坑**：不接消费器，管道一行代码都不会执行（示例用 `Cell` 计数器实测：构造后 0 次，collect 后恰好 N 次）。忘了 collect 是新手三大 bug 之一（另两个：`mut` 未加、生命周期）。

## 15.3 常用适配器速查

| 适配器 | 作用 | 备注 |
|---|---|---|
| `map(f)` | 逐元素变换 | f 消费元素 |
| `filter(f)` | f 返回 bool 的留下 | f 收 `&T`（所以常看到 `**x`） |
| `filter_map(f)` | 变换+过滤合一 | f 返回 Option |
| `enumerate()` | 附带下标 `(usize, T)` | |
| `zip(other)` | 拉链成对 | 长度截短 |
| `chain(other)` | 首尾相接 | |
| `take(n)` / `skip(n)` | 取前 n / 跳前 n | |
| `rev()` | 反向 | 双端迭代器才有 |
| `peekable()` | 能先看一眼 | peek 借用会活到下一次调用（实测坑） |
| `flatten()` | 压平一层嵌套 | `Vec<Vec<T>>` → T |
| `flat_map(f)` | map + flatten | 字符串→字符常用 |
| `copied()` / `cloned()` | &T → T（Copy/Clone） | 修 15.2 的 `**x` 问题 |
| `inspect(f)` | 副作用钩子（调试） | map 干副作用会被 clippy 劝改 |

## 15.4 消费器速查

```rust
sum::<i32>()                     // 求和（.sum() 靠推断，冲突时 turbofish）
fold(init, |acc, x| ...)         // 万能聚合：折出任何东西（String、树…）
count() / len 等价在迭代器上是 count()
max() / min() / max_by_key(f)
any(f) / all(f) / find(f)        // find 返回 Option<&T>，短路
position(f)                      // Option<usize>
collect::<Vec<_>>() / into String / HashSet …
for_each(f)                      // for 循环的消费器形态
```

**collect 的多态目标**是迭代器的杀手锏——凡实现 `FromIterator` 的都行：Vec、String（`['r','u','s','t'].into_iter().collect()`）、HashMap/HashSet、甚至 `Result<Vec<T>, E>`（一错全败，10 章）、`Option<T>`。类型标注或 turbofish 二选一：

```rust
let set: HashSet<i32> = v.iter().copied().collect();
let s = v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join("-");
```

> 注意 `collect::<i32>()` **不存在**（i32 没实现 FromIterator）——求和用 `.sum()`。

## 15.5 自定义迭代器：Iterator trait 25 行

```rust
struct Fib { a: u64, b: u64, left: u32 }

impl Iterator for Fib {
    type Item = u64;                         // 关联类型（12 章）
    fn next(&mut self) -> Option<u64> {      // 唯一必须方法；None = 结束
        if self.left == 0 { return None; }
        self.left -= 1;
        let out = self.a;
        (self.a, self.b) = (self.b, self.a + self.b);
        Some(out)
    }
}

let fibs: Vec<u64> = Fib { a: 0, b: 1, left: 10 }.collect();
let evens: Vec<u64> = Fib { a: 0, b: 1, left: 20 }.filter(|x| x % 2 == 0).collect();
```

实现 `next` 一项，**全套适配器白送**——filter/map/take 全都基于 next 组合出来。这是 trait 设计的教科书案例。

## 15.6 迭代器 vs 手写循环

```rust
// 索引循环（能跑，但处处边界检查、且"意图"藏在细节里）
let mut out = vec![];
for i in 0..words.len() {
    let w = words[i];
    if w.len() > 5 { out.push(w.to_uppercase()); }
}

// 管道（惯用：零边界检查、可组合、常更优——优化器对迭代器的别名信息更友好）
let out: Vec<String> = words.iter()
    .filter(|w| w.len() > 5)
    .map(|w| w.to_uppercase())
    .collect();
```

clippy 会主动建议把索引循环改成迭代器（`needless_range_loop`）——本教程零警告纪律下，索引循环基本只在"真正需要下标参与运算"时出现。

## 15.7 性能一句话

适配器是**零成本抽象的模范**：`filter+map` 的组合在 release 下内联成与手写循环等价的机器码（无函数调用、无边界检查）。放心叠管道。

## 15.8 坑位清单

1. **忘 collect，一切静默**：惰性 + `#[must_use]` 警告（`unused` 警告会提示）——但零警告纪律下这是编译期就抓到的；调试期记得"管道不通电"。
2. **filter 的闭包收 `&T`**：`|x| x % 2 == 0` 对 `&i32` 编译错——写 `|x| *x % 2 == 0` 或先 `.copied()`。clippy 有时建议再加一层解引用，实测最稳的是 copied 前置。
3. **zip 元素类型对齐**：`v.iter().zip(names.iter())` 出来是 `(i32, &&str)`——一边 `.copied()` 对齐再 collect（示例实测 E0277）。
4. **peek 的借用活到下一次调用**：`println!("{:?} {:?}", p.peek(), p.next())` 双可变借用编译错——先 `let ahead = p.peek().copied();` 再 next（实测）。
5. **collect 成标量不存在**：`collect::<i32>()` ✘；`.sum::<i32>()` ✔。
6. **into_iter 消费容器**：循环后容器不可用——还想用就 `iter()`；确实要消费（转成 String 列表等）才 into_iter。
7. **HashMap 迭代顺序不定**（09 章）：管道后 collect 进 Vec 比较/打印前排序。
8. **迭代器是单次通行证**：一个迭代器 collect 过就耗尽了，再用要重造（IntoIterator 的 &v 每次都新造）。

---

上一章：[14 闭包](14-closures.md) · 下一章：[16 宏系统](16-macros.md)
