# 05 · 借用与引用 ⭐

> 对应示例：`examples/05_borrowing/`
>
> 所有权解决"归谁"；实际写代码 90% 的场景是"借来用一下"。
> 本章是 borrow checker 正面交锋——规则只有两条，后果需要练习。
> 理论框架参考《Rust 编程之道》第 5 章，全部代码按 edition 2024 实测。

## 5.1 两条铁律

```text
铁律 1：任意时刻，同一数据 —— 要么任意多个 &T（共享引用），要么恰好一个 &mut T（可变引用）。
铁律 2：引用的存活期绝不超过被引用的数据（悬垂引用编译错）。
```

铁律 1 就是"多读单写"的编译期版本——读写锁的语义，零运行时成本。数据竞争（data race）在经典定义里需要三个条件同时成立：**两个以上指针访问同一内存、至少一个写入、没有同步机制**。铁律 1 直接消灭了第三个条件的前提——安全 Rust 里不可能存在"无同步的并发读写"，因为编译器在单线程就先堵死了"共享引用与可变引用共存"这个模式。数据竞争在安全代码里**无法构造**（22 章展开多线程视角）。

铁律 1 的**理由**值得想清楚（原书用了一个绝佳反例）：假设编译器允许共享借用与可变借用同时存在——

```rust
// 假想世界：没有借用检查
fn compute(input: &u32, output: &mut u32) {
    if *input > 10 {
        *output = 1;
    }
    if *input > 5 {          // 期望 input 还是 10
        *output = 2;
    }
}
let i = 10;
let mut o = 0;
compute(&i, &mut o);         // o == 2，符合预期
compute(&o, &mut o);         // input 和 output 指向同一块内存！
```

最后一行调用后 `o == 1`——第二个 if 读到的"input"已被第一个 if 改写。C 里这种 aliasing 是优化杀手（编译器不敢把 input 缓存进寄存器）；Rust 直接让这类代码**编译不过**，于是编译器可以放心缓存、重排——**借用规则同时也是性能规则**。这是 5.8 节"noalias 优化"的理论根。

### 没有这两条规则，世界会怎样

规则是抽象的，事故是具体的。以下三个真实事故场景（C++ 里每天都在发生）展示了"mutation + alias"规则防住的每一类灾难：

**事故一：枚举变体被中途替换**。设想你持有一个指向枚举内部 String 的引用，然后把整个枚举改写成 i64——引用现在指向一块被重新解释的内存：

```rust
enum StringOrInt { Str(String), Int(i64) }

let mut x = StringOrInt::Str("Hello world".to_string());
if let StringOrInt::Str(insides) = &x {
    // x = StringOrInt::Int(1);          // ← 编译错：cannot assign to `x` because it is borrowed
    // println!("{insides}");            //    若放行：String 引用指向 i64 的内存——类型系统被击穿
}
```

C 的 `union` 加指针强转就是这个场景——Rust 在编译期按住。规则不是洁癖，是**防止用一种类型的指针去读另一种类型的数据**。

**事故二：迭代器失效**。C++ 的经典崩溃：遍历 vector 时 clear 它，迭代器指向已释放内存（UB）：

```cpp
// C++：编译通过，运行崩溃
for (auto it = v.begin(); it != v.end(); ++it) {
    if (*it % 2 == 0) { v.clear(); }   // 迭代器立刻变野指针
}
```

Rust 里同样的代码编译不过：

```rust
let mut arr = vec!["ABC", "DEF", "GHI"];
for item in &arr {
    // arr.clear();                     // ← 编译错：for 循环持有 &arr，clear 需要 &mut arr
    let _ = item;
}
```

`for` 循环展开后持有一个指向容器的借用，循环体内任何对容器的修改都会与这个借用冲突。Java 用运行时异常（`ConcurrentModificationException`）兜底——Rust 在编译期就不给机会。**编译期的读写锁**（多读 OK、单写独占）是同一个思想在单线程的投影。

**事故三：悬空指针**。C++ 里指向 vector 元素的指针，在 push 引发扩容后变成悬空指针：

```cpp
// C++：编译通过，运行输出垃圾值
std::vector<int> v(100, 5);
int* p = &v[0];
for (int i = 0; i < 100; i++) { v.push_back(10); }  // 扩容 → 旧内存释放
std::cout << *p << std::endl;                         // 悬空：输出未定义
```

Rust 里同样的模式被铁律 1 拦截：

```rust
let mut arr: Vec<i32> = vec![1, 2, 3, 4, 5];
let p: &i32 = &arr[0];
// for i in 1..100 { arr.push(i); }    // ← 编译错：cannot borrow `arr` as mutable
let _ = p;                             //    因为也被借为 immutable
```

三个事故的共同根源：**"读"的引用和"写"的路径同时存在**。铁律 1 不区分场景、不做 case-by-case 判断——一条规则统一堵死所有变体。

## 5.2 共享引用 &：只读

```rust
let s = String::from("共享");
let r1 = &s;
let r2 = &s;               // 任意多个共享引用相安无事
println!("{r1} {r2} {s}"); // 大家都活着
```

`&T` 是 Copy（04 章 4.4 决策表），随便复制。Deref 链让引用调用方法就像直接调用：`r1.len()`。

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

出借所有权的前提是绑定本身可变——`let s` 开不出 `&mut s`。借用是**所有权的出借**：所有者把读写权限临时让渡，到期自动收回，全程不发生 move。

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

**NLL 之前的世界：Lexical Lifetime**。2018 版之前的借用检查基于 AST，引用的存活期从声明点一直延伸到**当前代码块结束**——与"最后使用"无关。这导致大量"逻辑上正确但编译不过"的误伤。经典案例：

```rust
fn get_default(map: &mut HashMap<String, String>, key: String) {
    match map.get_mut(&key) {
        Some(value) => println!("{value}"),
        None => {
            map.insert(key, String::new());  // NLL 之前：编译错
        }                                    // get_mut 的借用"应该"在 None 分支已死
    }
}
```

在 Lexical Lifetime 下，`get_mut` 返回的 `Option<&mut V>` 让整个 `match` 块都被视为借用期——即使 `None` 分支里根本不存在这个引用。当时的"绕法"是先 `contains_key` 再 `get_mut`（两次哈希查找），或者用标准库的 `entry` API：

```rust
fn get_default_modern(map: &mut HashMap<String, String>, key: String) {
    map.entry(key).or_insert_with(String::new);   // 一次查找，语义精确
}
```

`entry` API 之所以存在，部分原因就是 Lexical Lifetime 太严格——它把"查不到就插入"这个常见需求做成了原子操作。NLL 落地后，`match get_mut` 的直写版本也能编译了，但 `entry` 仍然是更好的 API（一次哈希、语义清晰）。**NLL 不是让烂代码变合法，而是让正确的代码不再需要绕路**。

**NLL 的原理**（《Rust 编程之道》5.8 节）：早期借用检查基于 AST/HIR，生命周期的长短由变量声明的**词法顺序**决定——于是出现过"`let z; let y = ...; z = foo(&x, &y)` 报错、把两句换个位置就好"这种反直觉行为（变量声明晚却活得久的悖论）。NLL 把借用检查下沉到 **MIR**（01 章 1.4 的编译流水线）：MIR 是控制流图（CFG），节点是语句、边是分支跳转。检查器沿图追踪每个引用在哪些节点活跃、在哪些节点已死——循环、分支、早退路径全部精确覆盖。所以现在的规则是"最后使用即到期"，与声明顺序无关。这也是报错能精确指向"某次使用"的原因。

可以用 `rustc --emit=mir test.rs` 查看 MIR 文本——控制流图的可视化对理解 NLL 很有帮助。

## 5.5 悬垂引用：铁律 2 的拦截

```rust
// fn dangle() -> &String {
//     let s = String::from("x");
//     &s                       // ← 编译错：返回的引用活不过 s
// }                            //    （cannot return reference to local variable）
```

正解永远是返回**值**（所有权交出去）：`fn make() -> String`。

借用检查器对**跨函数**的借用无法靠推断（函数体可以单独编译），这正是 13 章生命周期标注存在的理由——本章先记住结论：函数返回引用时，编译器必须能证明它来自参数而非局部变量。

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
3. Rust 的 `&mut T` 是**独占权限**而不仅是"可写"——这使优化器能做激进的别名分析（LLVM 的 noalias 标记），是 Rust 性能的秘密武器之一。独占 ⇒ 无别名 ⇒ 可缓存可重排，5.1 的反例在这个世界不存在。

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
8. **NLL 之前的老代码风格**：网上 2015 edition 的教程会教你"用花括号手动缩借用作用域"（`{ let r = &v[0]; ... }`）——NLL 之后多数情况多余，按"最后使用"理解即可；但把借用 guard（如 MutexGuard）控制在窄作用域仍是好风格（22 章）。

---

上一章：[04 所有权](04-ownership.md) · 下一章：[06 切片与字符串](06-strings.md)
