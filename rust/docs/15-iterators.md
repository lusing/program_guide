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

### 外部迭代器 vs 内部迭代器

迭代器分两种流派：**外部迭代器**由调用方控制遍历节奏（C++/Java/Python 的迭代器模式）；**内部迭代器**由容器自己控制遍历，外部只能传一个闭包让它对每个元素执行（Ruby 的 `each`）。Rust 1.0 之前用的是内部迭代器——与所有权系统叠加后非常难用，社区论证后改成了外部迭代器。

`for` 循环就是外部迭代器的语法糖，展开后等价于：

```rust
let mut _iter = v.into_iter();      // 拿到迭代器
loop {
    match _iter.next() {             // 反复问"下一个"
        Some(x) => { /* 循环体 */ }
        None => break,               // None = 遍历完毕
    }
}
```

### IntoIterator：从容器到迭代器的桥

```rust
pub trait IntoIterator {
    type Item;
    type IntoIter: Iterator<Item = Self::Item>;  // 关联类型约束：必须是迭代器
    fn into_iter(self) -> Self::IntoIter;         // 消耗 self！
}
```

`into_iter` 按值接收 self——所以 `for x in v` 之后 v 不可用。`&Vec<T>` 和 `&mut Vec<T>` 也各自实现了 `IntoIterator`（产出 `&T` / `&mut T`），这就是 `for x in &v` 能工作的原因。

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

Iterator trait 的核心就三行（标准库源码简化）：

```rust
trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
    // …其余 70+ 方法全部有默认实现
}
```

实现 `next` 一项，**全套适配器白送**——filter/map/take 全都基于 next 组合出来。这是 trait 设计的教科书案例。

还有一个可选的优化点：`size_hint()` 返回 `(usize, Option<usize>)`——迭代器剩余长度的（下限，上限）。`collect` 进 Vec 时用它预分配容量，避免反复扩容。实现了 `ExactSizeIterator`（能给出精确 len）的迭代器还能享受进一步优化的 `Iterator::len()`。

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

## 15.7 零开销抽象：迭代器的性能哲学

适配器是**零成本抽象的模范**：`filter+map` 的组合在 release 下内联成与手写循环等价的机器码（无函数调用、无边界检查）。放心叠管道。

TRB 引用了 Stroustrup（C++ 之父）对零开销原则的定义，这也是 Rust 的设计目标：

> 你无须为自己没有使用过的功能付出代价。甚至更进一步，你无法为自己使用的那些功能编写出更好的代码。

一个具体的优化案例（TRB 的音频解码器示例）：对 12 个系数做 `zip + map + sum` 的迭代器管道，编译器**完全展开循环**（12 次迭代写成 12 段直线代码，消除循环控制开销），把所有系数留在寄存器里，并消去全部边界检查——产出的汇编与手写汇编几乎一致。你写高层抽象的迭代器管道，编译器给你底层的直线代码——**高表达力和高性能不冲突**，这是 Rust 的核心承诺之一。

## 15.8 Vec 源码解剖：unsafe 如何服务安全抽象

迭代器不是魔法——它是标准库用 unsafe 原语精心构造的安全 API。解剖 `Vec` 的三个核心操作，看 unsafe 的正确使用姿势。

### push：一次 move = 按位拷贝 + 抑制旧值析构

```rust
// Vec::push 的简化实现（标准库源码骨架）
pub fn push(&mut self, value: T) {
    if self.len == self.buf.capacity() {
        self.grow();    // 容量不够先扩容（见下）
    }
    unsafe {
        let end = self.as_mut_ptr().add(self.len);
        std::ptr::write(end, value);    // 按位拷贝 value 到 end，不调用拷贝构造
        self.len += 1;
    }
}
```

`ptr::write(dst, src)` 把 `src` 按位搬到 `dst`，**不调用 `src` 的析构函数**——Rust 没有 C++ 的拷贝构造/移动构造，move 就是按位复制 + 旧标脏。`ptr::write` 恰好完成这个语义：值到了新位置，旧位置被视为未初始化（不会 double drop）。

### grow：扩容 = realloc + 按位搬运

```rust
// RawVec::grow 的简化逻辑
fn grow(&mut self) {
    let new_cap = if self.cap == 0 { 4 } else { self.cap * 2 };
    // 首次分配 4 个元素（或 1 个大元素），之后每次翻倍
    let new_ptr = unsafe {
        self.alloc.realloc(self.ptr, old_layout, new_layout)
        // realloc：旧内存数据按位拷贝到新内存，旧内存释放
    };
    self.ptr = new_ptr;
    self.cap = new_cap;
}
```

容量从 0 → 4 → 8 → 16 …… 倍增策略摊销了每次 push 的拷贝成本——均摊 O(1)。`realloc` 是 allocator 的 unsafe 原语：它假定旧指针有效、旧布局正确——这些不变量由 `RawVec` 的结构维持。

### set_len：一行赋值为何是 unsafe

```rust
pub unsafe fn set_len(&mut self, new_len: usize) {
    self.len = new_len;    // 内部只是一个 usize 赋值
}
```

一个 `usize` 赋值为什么标记 unsafe？因为 Vec 的所有其它 unsafe 操作都依赖 `self.len` 准确反映已初始化元素的个数。如果外部代码用 `set_len` 把 len 调大，随后 `Vec` 会尝试 drop 未初始化的内存——UB。**判断一个函数是否该是 unsafe，不看它内部做了什么，看调用方可能用它造成什么后果**。这是 unsafe API 设计的核心原则。

### drain：泄漏安全的设计

`drain(range)` 移除一个范围内的元素并返回迭代器。关键问题：如果调用方 `mem::forget` 了这个迭代器（合法的安全操作），被移除的元素会怎样？

```rust
// Vec::drain 的简化实现
pub fn drain<R>(&mut self, range: R) -> Drain<'_, T> {
    let start = ...; let end = ...;
    unsafe {
        self.set_len(start);    // ← 先把 len 缩到 start！
        Drain { iter: /* 指向 start..end */, vec: self, tail_len: len - end }
    }
}
// Drain 的 Drop：把 end 之后的元素移到 start，更新 len
```

`set_len(start)` 在返回迭代器**之前**就把 Vec 的 len 缩到安全值。即使 `Drain` 被 forget（析构函数不执行），最坏结果也只是"Vec 少了几个元素"——**绝不会出现"Vec 认为未初始化内存是合法元素"的 UB**。底线是：**即使析构泄漏导致逻辑错误，也不能导致内存不安全**。

### truncate：panic safety 的微观体现

`truncate(new_len)` 丢弃尾部元素。如果元素的 `drop` 实现 panic 了怎么办？

```rust
// Vec::truncate 的简化实现
pub fn truncate(&mut self, len: usize) {
    unsafe {
        while len < self.len {
            self.len -= 1;                              // ← 先减 len
            let last = self.len;
            std::ptr::drop_in_place(self.get_unchecked_mut(last));
            // 再 drop：即使这里 panic，len 已经减过了
            // 不会 double drop 同一个元素
        }
    }
}
```

先减 len 再 drop——如果 drop 中 panic，unwind 会跳过剩余元素的析构，但 len 已经准确反映了"还剩多少活着的元素"。下次访问 Vec 时不会碰到已 drop 的值。**panic safety 不是"不 panic"，是"panic 之后数据结构仍然合法"**。

这些模式（`ptr::write` 搬运、`set_len` 维护不变量、先缩 len 再 drop）是写 unsafe 容器的标准套路——19 章的 `split_at_mut` 是入门，这里是进阶。

## 15.9 坑位清单

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
