# 04 · 所有权 ⭐

> 对应示例：`examples/04_ownership/`
>
> Rust 的一切独特性都从这里长出来。本章讲"值归谁、何时释放"；
> 借用（不拿走所有权也能用）在下一章。读懂这两章，Rust 就入门了一半。

## 4.1 三条规则

1. 每个值有**唯一 owner**（变量、结构体字段、容器元素……）。
2. 同一时刻所有权只能在一处（赋值/传参 = **move**，除非类型是 `Copy`）。
3. owner 离开作用域，值被**立即释放**（drop，确定性析构——无 GC、无引用计数）。

```rust
{
    let s = String::from("hello"); // s 拥有堆上的缓冲
}   // s 离开作用域：缓冲在这里释放，精确、自动
```

对照 C++：这就是 RAII，但语言级强制——忘记 free、double free、内存泄漏（在安全代码里）都写不出来。对照 Go：没有 GC 停顿、没有逃逸分析的隐晦。对照 Zig：`defer` + allocators 是手动纪律，所有权是编译器纪律。

## 4.2 move：赋值的默认语义

```rust
let s1 = String::from("hello");
let s2 = s1;               // 所有权 s1 → s2
// println!("{s1}");       // ← 编译错：borrow of moved value: `s1`
```

为什么这么激进？`String` = 栈上的（指针, 长度, 容量）三元组 + 堆缓冲。如果 s1/s2 都"活着"，作用域结束时缓冲会被释放两次。C++ 的拷贝构造在这里深拷贝（隐式高成本），Rust 选择 **move + 显式 clone**：

```rust
let s2 = s1.clone();       // 显式深拷贝——成本写在脸上
println!("{s1} {s2}");     // 两个独立值，都能用
```

> move 之后原变量不是"空壳"，是**编译器标记的不可用状态**——用它就编译错。不存在 use-after-move。

## 4.3 Copy：栈上小类型的豁免

```rust
let x = 5;
let y = x;         // i32 是 Copy：按位复制，x 仍可用
println!("{x} {y}");
```

`Copy` 的判定（自动的，不能手动实现一半）：纯标量类型、只含 `Copy` 字段的定长类型（如 `(i32, f64)`、`[u8; 4]`）、共享引用 `&T`。凡是要管堆资源的（String、Vec、Box……）都不 Copy——**实现了 Drop 的类型不可能 Copy**。

一张决策表：

| 类型 | 赋值语义 | 原值可用 |
|---|---|---|
| `i32`/`f64`/`bool`/`char` | Copy | ✔ |
| `(i32, f64)`、`[u8; 4]` | Copy（成员全 Copy） | ✔ |
| `String`/`Vec<T>`/`Box<T>` | move | ✘（clone 才行） |
| `&String`（共享引用） | Copy | ✔ |
| `&mut T`（可变引用） | move（独占！见 05 章） | ✘ |

## 4.4 函数边界：传参 move 进，返回值 move 出

```rust
fn takes_ownership(s: String) { }        // s 进入函数，函数结束时释放
fn gives_ownership() -> String { String::from("新值") }  // move 出去
fn take_and_give_back(s: String) -> String { s }          // 接力

let s = String::from("hello");
takes_ownership(s);          // 此后 s 不可用
let s = gives_ownership();   // 接住新值（遮蔽旧名）
let s = take_and_give_back(s); // 典型"接力"写法
```

每个值像接力棒。不想到处接力的正解是**借用**（05 章）：

```rust
fn byte_len(s: &String) -> usize { s.len() }   // 只读借用，所有权不动
let n = byte_len(&s);                          // s 完好
```

## 4.5 Drop：释放的确定性

```rust
struct Tracer(&'static str);
impl Drop for Tracer {
    fn drop(&mut self) { println!("释放 {}", self.0); }
}
{
    let a = Tracer("先声明");
    let b = Tracer("后声明");
}   // 输出顺序：先 b 后 a —— 与声明相反（栈序）
```

- 释放时机**确定**（作用域结束）、**自动**（无 forget/free）、**只发生一次**。
- 提前释放：`drop(x)`（没有 `x.delete()`/`x.close()` 这种手动半成品）。
- 资源 = 内存 + 文件句柄 + 锁……全都走 Drop（锁的 guard 是 22 章并发安全的基石）。

## 4.6 容器与字段：所有权是递归的

```rust
let mut v = vec![String::from("a"), String::from("b")];
let first = v.remove(0);   // 元素所有权出容器（remove 是 move out）
let owner = v;             // 容器整体 move，元素跟着走
// println!("{v:?}");      // ← v 已 move
println!("{first} {:?}", owner);
```

字段同理：结构体拥有字段；`let Rect { width, .. } = r` 解构时把 width move 出来（字段是 Copy 则复制，07 章）。

## 4.7 心智模型：画"所有权流向图"

遇到编译错误时的排查顺序：

1. 这个值现在**归谁**？（最后一个合法 owner）
2. 我在这里是想**读**、**写**、还是**长期持有**？→ 读用 `&`，写用 `&mut`（05 章），长期持有才 move/clone。
3. 两个地方都要长期持有？→ `Rc`/`Arc` 共享计数（18 章），或克隆分家。
4. 谁的生命周期应该更长？→ 让 owner 活得比所有借用者久（05/13 章）。

## 4.8 坑位清单

1. **"moved value" 不是运行时错误**：是编译期拦截。报错信息里 "value moved here" 会标出 move 发生的那行——顺着改。
2. **闭包默认捕获引用，`move` 闭包捕获所有权**（14 章）：线程场景忘了 `move` 是高频错误。
3. **`clone` 不是耻辱**：初学优先 clone 跑通，再想能不能消除。过早优化所有权结构是新人最大的时间黑洞。
4. **函数返回局部变量的引用永远编译错**（悬垂），返回**值**（move 出来）永远没问题：`fn make() -> String { let s = ...; s }` 零拷贝神话的另一面——值直接交接，无堆复制。
5. **`Vec<u8>` vs `&[u8]`**：前者拥有，后者是视图。API 参数要"一段字节"时收 `&[u8]`（能接受 `&Vec` 自动 deref），别强迫调用者交出所有权（06 章）。
6. **结构体更新语法 `..base` 是 move**：`Rect { width: 5.0, ..base }` 把未列出的字段从 base **搬走**——字段全 Copy 时无感，含 String 时 base 变成部分 moved（07 章示例实测）。
7. **`Copy` 类型被装进容器仍是元素级 Copy**：`Vec<i32>` 赋值时整体 move（容器管堆），别和元素 `Copy` 混淆。

---

上一章：[03 基础](03-basics.md) · 下一章：[05 借用与引用](05-borrowing.md)
