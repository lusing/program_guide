# 05 · 借用与引用 ⭐

> 对应示例：`examples/05_borrowing/`
>
> 所有权解决"归谁"；实际写代码 90% 的场景是"借来用一下"。
> 本章是 borrow checker 正面交锋——规则只有两条，后果需要练习。

## 5.1 两条铁律

```text
铁律 1：任意时刻，同一数据 —— 要么任意多个 &T（共享引用），要么恰好一个 &mut T（可变引用）。
铁律 2：引用的存活期绝不超过被引用的数据（悬垂引用编译错）。
```

铁律 1 就是"多读单写"的编译期版本——读写锁的语义，零运行时成本。数据竞争（两线程一读一写无同步）在安全 Rust 里**无法构造**，根源在此（22 章）。

## 5.2 共享引用 &：只读

```rust
let s = String::from("共享");
let r1 = &s;
let r2 = &s;               // 任意多个共享引用相安无事
println!("{r1} {r2} {s}"); // 大家都活着
```

`&T` 是 Copy（05 章 4.3 决策表），随便复制。Deref 链让引用调用方法就像直接调用：`r1.len()`。

## 5.3 可变引用 &mut：独占写权限

```rust
let mut s = String::from("可变");   // 注意：绑定本身要先 mut
change(&mut s);
fn change(s: &mut String) { s.push_str("（改写）"); }
```

独占的含义：**w 活着期间，任何其它路径（读或写）都碰不了原值**：

```rust
let mut s = String::from("x");
let w1 = &mut s;
w1.push('!');
// let w2 = &mut s;     // ← 编译错：second mutable borrow
// println!("{s}");     // ← 编译错：不可变借用与可变借用冲突
println!("{w1}");       // w1 的最后使用，此后借用到期
```

## 5.4 NLL：按"最后使用"判定，不是按作用域

2018 起的 Non-Lexical Lifetimes——借用从创建到**最后一次使用**就算存活，不拖到作用域结尾：

```rust
let mut v = vec![1, 2, 3];
let first = &v[0];
println!("{first}");  // first 的最后使用——共享借用到此结束
v.push(4);            // 新的可变借用，合法！
println!("{v:?}");
```

反过来，把 `println!("{first}")` 挪到 `v.push` 之后，同一段代码立即编译错。**报错与修复往往只差一行位置调整**——这是 NLL 时代最常见的日常。

## 5.5 悬垂引用：铁律 2 的拦截

```rust
// fn dangle() -> &String {
//     let s = String::from("x");
//     &s                       // ← 编译错：返回的引用活不过 s
// }                            //    （cannot return reference to local variable）
```

正解永远是返回**值**（所有权交出去）：`fn make() -> String`。

## 5.6 切片：一段数据的借用视图

```rust
let arr = [1, 2, 3, 4, 5];
let mid: &[i32] = &arr[1..4];   // 指向 arr 中间三个元素的视图，不拥有
```

切片 = 胖指针（起点 + 长度），因此 `&[T]` 可以指数组的一段、整个数组、Vec 的一段……**函数收 `&[T]` 就能同时服务三者**。字符串切片 `&str` 同理（06 章）。

TRB 经典例子——`first_word` 展示了借用如何防住"视图悬垂"：

```rust
fn first_word(s: &str) -> &str {          // 返回值借自入参（生命周期省略，13 章）
    match s.find(' ') {
        Some(i) => &s[..i],
        None => s,
    }
}
let words = String::from("the quick brown fox");
let first = first_word(&words);   // first 持有 words 的共享借用
// words.clear();                 // ← 编译错！clear 要 &mut，与 first 冲突
println!("{first}");
```

C/C++ 里这就是"指针指向被 clear 的缓冲"的经典 UAF；Rust 在编译期按住。

## 5.7 函数参数的黄金法则

| 你需要 | 签名收 |
|---|---|
| 只读 | `&T`（更宽：字符串用 `&str`、序列用 `&[T]`） |
| 就地修改 | `&mut T` |
| 消耗/存储 | `T`（拿走所有权） |

**能收 `&T` 就不要收 `T`**：调用方保留所有权，还能自动配合 deref 强转（`&String → &str`、`&Vec<T> → &[T]`）。

## 5.8 与 C++ 引用的三点不同

1. C++ 引用不可为空、不可重绑定，Rust 引用还叠加"借用规则"（读写互斥）。
2. C++ 的 `const T&` 绑定右值能延长临时值寿命，Rust 没有这个机制——临时值寿命规则严格（13 章）。
3. Rust 的 `&mut T` 是**独占权限**而不仅是"可写"——这使优化器能做激进的别名分析（noalias），是 Rust 性能的秘密武器之一。

## 5.9 常见报错速查

| 报错关键词 | 含义 | 常见修法 |
|---|---|---|
| `cannot borrow as mutable because it is also borrowed as immutable` | 共享借用活着时开可变 | 提早结束共享借用（NLL）、clone、重构 |
| `cannot borrow as mutable more than once at a time` | 两个 &mut 并存 | 顺序化使用、拆字段借用（见下）、RefCell（18 章） |
| `cannot borrow as immutable because it is also borrowed as mutable` | &mut 活着时读 | 先用完 &mut |
| `borrowed value does not live long enough` | 引用比数据活得久 | 延长 owner 作用域 / 返回值而非引用 |

**拆字段借用**是合法的——编译器按字段独立分析：

```rust
let mut r = Rect { w: 1.0, h: 2.0 };
let w = &mut r.w;   // 借 w 字段
let h = &mut r.h;   // 借 h 字段——不同字段，互不冲突 ✔
```

## 5.10 坑位清单

1. **`let mut s` 与 `&mut s` 是两层**：绑定不 mut，连可变引用都开不出来。
2. **在方法调用链里隐藏的借用**：`v[v.len()-1]` 这类"同表达式又读又写"会触发冲突——拆成两行 + 中间变量。
3. **循环里反复借用**：把借用创建挪出循环（借用一次、循环下标），或改用迭代器消费（15 章后这类错误自然消失）。
4. **结构体同时借两个字段没问题，借"整个结构体+一个字段"才冲突**：`let a = &r; let b = &mut r.w;` ✘（前者覆盖全部字段）。
5. **RefCell 不是解药是延时**：把冲突推迟到运行期 panic（18 章）。先用 NLL 重排，真需要共享可变再上 Rc<RefCell>/Arc<Mutex>。
6. **`&String` 参数写法被 clippy 盯上**（ptr_arg）：改成 `&str`，一改全兼容。
7. **借检查器不看运行期条件**：`if cond { let r = &mut x; }` 即使 cond 恒 false，借用冲突照样报——编译器只看类型与路径，不看值。

---

上一章：[04 所有权](04-ownership.md) · 下一章：[06 切片与字符串](06-strings.md)
