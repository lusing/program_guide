# 18 · 智能指针

> 对应示例：`examples/18_smartptr/`
>
> `&` 与 `&mut` 只是借用；智能指针**拥有**数据并附加行为：Box 独占堆、
> Rc/Arc 共享计数、RefCell/Mutex 内部可变性。选型表在 18.7，先逐个拆开看。

## 18.1 Box：堆分配的独占指针

三个不可替代的用途（TRB 的明确分类）：

```rust
// 1) 递归类型：enum 直接含自己大小不定 → Box 固定大小指针解围
enum List {
    Node(i32, Box<List>),   // 没有 Box 这里无限大小，编译错
    Nil,
}

// 2) 大数据转移（避免栈上复制大值）
let big = Box::new([0u8; 1_000_000]);

// 3) trait 对象（12 章）
let shapes: Vec<Box<dyn Debug>> = vec![Box::new(1), Box::new("文本")];
```

三类场景对应三种动机：**大小不定**（递归类型编译期算不出大小，Box 指针大小恒定）、**转移昂贵**（堆上大块数据 move 只搬指针）、**类型抹除**（dyn Trait 运行时多态）。Box 零开销（相对普通引用多一次堆分配）；自动 Deref 让 `*b`、`b.field`、`b.method()` 直接用。

## 18.2 Deref 与 Drop：智能指针的两大 trait

智能指针本质上是一个结构体，只是它的行为类似指针。它区别于常规结构体的关键：实现了 **Deref** 和 **Drop** 这两个 trait。Deref 提供解引用能力，Drop 提供自动析构能力——"类型决定行为"，不是指针胜似指针。

```rust
struct MyBox<T>(T);

impl<T> std::ops::Deref for MyBox<T> {
    type Target = T;
    fn deref(&self) -> &T { &self.0 }
}
impl<T> Drop for MyBox<T> {           // 析构钩子（04 章演示过）
    fn drop(&mut self) { println!("[MyBox] 释放"); }
}
```

Drop 被标记为 `#[lang = "drop"]` 语言项——编译器在生成析构代码时靠它找到该调哪个 trait。String、Vec、File 全都实现了 Drop：Vec 被丢弃时自动释放堆缓冲，File 被丢弃时自动关闭文件句柄——**不需要显式 free、不需要 close**。Drop 比 GC 更广泛：GC 只能回收内存，Drop 可以回收内存及内存之外的一切资源（文件、网络连接、锁）。这就是 RAII（资源获取即初始化）——Rust 和现代 C++ 的共同根基。

**Deref 强转链**是 `&String → &str`、`&Vec<T> → &[T]`、`&Box<String> → &String → &str` 的公共机制——编译器沿 Deref 链自动插 `.deref()`，直到类型匹配。方法调用 `s.len()` 同理穿透。这解释了 06 章的"函数收 &str 什么都能传"。

### `*y` 到底发生了什么

写 `*y` 时，编译器隐式展开为 `*(y.deref())`——先调 `deref()` 拿到 `&T`，再对这个引用做一次朴素的 `*` 解引用。**每个 `*` 只展开一次**，不会无限递归：所以 `MyBox<i32>` 解一次得到 `i32`，不会再对 `i32` 调 deref。`deref` 必须返回 `&T` 而不是 `T`——如果返回值，所有权就从 `self` 移出去了，而绝大多数解引用场景只是"看一眼"不想要所有权。

### Deref 强转的三条精确规则

Rust 只在三种情形下做隐式 deref coercion：

| 情形 | trait 约束 | 允许的转换 |
|---|---|---|
| 1 | `T: Deref<Target=U>` | `&T → &U` |
| 2 | `T: DerefMut<Target=U>` | `&mut T → &mut U` |
| 3 | `T: Deref<Target=U>` | `&mut T → &U` |

情形 3 值得多看一眼：**可变引用可以自动降级为不可变引用，反向绝不行**。原因在借用规则：存在 `&mut` 时它必然唯一（否则编译不过），降级为 `&` 不破坏任何约束；但 `& → &mut` 要求"这个引用此刻必须是唯一的"，借用规则无法静态保证——所以 Rust 干脆禁止。这是 05 章"可变独占"的又一面。

### `Rc::clone(&a)` 的惯例

`Rc::clone(&a)` 与 `a.clone()` 效果相同，但社区**强烈推荐前者**——一眼区分"深度拷贝"与"增加引用计数"。性能审查时看到 `Rc::clone` 可以直接跳过（只是计数器 +1），看到 `.clone()` 才需要警惕是不是在大块搬数据。这个命名习惯在多所有者代码库里是性能排查的快捷键。

## 18.3 Rc：共享所有权（单线程引用计数）

```rust
use std::rc::Rc;

let a = Rc::new(String::from("共享数据"));
let b = Rc::clone(&a);        // 计数 +1，不复制数据（廉价）
let c = Rc::clone(&a);
println!("{}", Rc::strong_count(&a));   // 3
drop(b);
println!("{}", Rc::strong_count(&a));   // 2
// 计数归零（a、c 都没了）→ 数据释放
```

适用：树/图中多个节点引用同一子结构、多处缓存同一份只读数据。限制：**只读共享**（要改配 RefCell）、**禁止跨线程**（计数非原子——跨线程用 Arc，22 章）。

### Rc 的内部构造：Cell 的最佳教材

剥开 Rc 的源码，能看到 Cell 存在的真正理由——**引用计数器必须在 `&self` 下被修改**：

```rust
// Rc 的内部结构（标准库源码简化）
struct RcBox<T> {
    strong: Cell<usize>,     // 强引用计数——Cell 包裹！
    weak: Cell<usize>,       // 弱引用计数
    value: T,
}

pub struct Rc<T: ?Sized> {
    ptr: NonNull<RcBox<T>>,  // 指向堆上的 RcBox
}

// Clone 的实现——注意 self 是 &Self，不是 &mut Self
impl<T: ?Sized> Clone for Rc<T> {
    fn clone(&self) -> Rc<T> {
        self.inc_strong();    // 在 &self 下修改计数器！
        Rc { ptr: self.ptr }
    }
}

fn inc_strong(&self) {
    let n = self.inner().strong.get();
    self.inner().strong.set(n + 1);   // Cell::get + Cell::set
}
```

`clone` 的签名是 `fn clone(&self) -> Self`——只拿到共享引用。但引用计数必须 +1，这意味着**在不可变引用下修改数据**——这正是内部可变性的定义。如果不用 `Cell<usize>` 而用 `usize`，`clone` 就需要 `&mut self`，于是同一时刻只能有一个 `Rc` 可变——共享计数就无从谈起了。

`Rc<RefCell<T>>` 的嵌套也是同理：`Rc` 提供"共享所有权"，`RefCell` 提供"共享下的可变访问"——两层各管一层。

## 18.4 RefCell：把借用检查挪到运行期（内部可变性）

```rust
use std::cell::RefCell;

let cell = RefCell::new(Logger { level: "INFO".into(), count: 0 });
cell.borrow_mut().count += 1;      // 编译器看 cell 不可变，运行期独占借用
println!("{}", cell.borrow().count);
```

**借用规则没消失，是推迟强制**：`borrow()`（共享）+`borrow_mut()`（独占）在运行期记账——冲突不再编译错，而是 **panic**（示例实测：`already borrowed`）。返回的 Ref/RefMut guard 走 Drop 归还。

适用面：对编译器"撒谎"说不可变、实际要改的场景（配合 Rc 共享、日志/缓存/回调注册）。原则：**RefCell 冲突要在测试里炸出来**——它是把问题从编译期换到运行期的期权，不是免检通行证。

## 18.5 Rc<RefCell<T>>：共享 + 可变的经典组合（单线程）

```rust
let shared = Rc::new(RefCell::new(vec![1, 2]));
let writer = Rc::clone(&shared);
writer.borrow_mut().push(3);       // 一个句柄写
shared.borrow_mut().push(4);       // 另一个句柄写
println!("{:?}", shared.borrow()); // [1, 2, 3, 4]
```

多线程等价物：`Arc<Mutex<T>>`（22 章）——形制完全对应，只换两个零件。

## 18.6 Weak：打破 Rc 循环引用

Rc 环（A→B→A）计数永不归零 → 泄漏。**Weak 不增计数**，访问要 upgrade：

```rust
use std::rc::{Rc, Weak};

struct Node {
    name: &'static str,
    parent: RefCell<Weak<Node>>,          // 父：弱引用（孩子拥有父母没有道理）
    children: RefCell<Vec<Rc<Node>>>,     // 子：强引用（父拥有孩子，天经地义）
}

let leaf = Rc::new(Node { name: "leaf", parent: RefCell::new(Weak::new()), ... });
let root = Rc::new(Node { name: "root", ..., children: vec![Rc::clone(&leaf)] });
*leaf.parent.borrow_mut() = Rc::downgrade(&root);

leaf.parent.borrow().upgrade().map(|p| p.name)   // Some("root")
drop(root);
leaf.parent.borrow().upgrade()                   // None——不悬垂，优雅降级
```

规则：**所有权方向用 Rc，回指方向用 Weak**（双向强引用 = 泄漏；C++ 的 weak_ptr 同款思想）。

### 内存泄漏 ≠ 内存不安全

Rust 不能百分百阻止内存泄漏——Rc 循环引用就是安全代码里的泄漏路径。但**内存泄漏不在"内存安全"的定义范围内**。内存安全指的是：无未定义内存访问、无空指针、无悬垂指针、无缓冲区溢出、无非法释放。Rust 在 Safe 代码里消灭了这五条；泄漏只是"该释放的没释放"，进程退出时操作系统会回收所有内存——它是资源管理问题，不是安全问题。

## 18.7 选型总表（背下来）

| 需求 | 单线程 | 多线程 |
|---|---|---|
| 独占堆/递归/trait 对象 | `Box<T>` | `Box<T>` |
| 共享只读 | `Rc<T>` | `Arc<T>` |
| 内部可变（逻辑不可变绑定） | `RefCell<T>` | `Mutex<T>` / `RwLock<T>` / 原子 |
| 共享 + 可变 | `Rc<RefCell<T>>` | `Arc<Mutex<T>>` |
| 打破循环 | `Weak<T>` | `Weak<T>`（Arc 版） |

另两个顺路的：`Cow<T>`（写时克隆，06 章字符串场景偶用）、`Cell<T>`（Copy 类型的轻量内部可变，`get/set` 无借用检查）。

### Cow：写时克隆

`Cow<'a, B>`（Clone-On-Write）是一个 enum：要么借用一个 `&B`，要么拥有一个 `B::Owned`——读时零拷贝，写时才克隆：

```rust
use std::borrow::Cow;

fn remove_spaces(input: &str) -> Cow<'_, str> {
    if input.contains(' ') {
        let owned: String = input.chars().filter(|c| *c != ' ').collect();
        Cow::Owned(owned)          // 需要修改 → 分配新内存
    } else {
        Cow::Borrowed(input)       // 不需要修改 → 零拷贝，直接借用
    }
}

let r1 = remove_spaces("no_spaces");       // Cow::Borrowed——零开销
let r2 = remove_spaces("has spaces");      // Cow::Owned——按需分配
println!("{r1} {r2}");                      // 用法完全一致
```

返回值用 `&str` 不行（需要新分配时生命周期不够），用 `String` 又强迫调用方接受堆分配（不需要修改时也是）。`Cow` 解了这个两难：**调用方按需付费，不需要时零开销**。它实现了 `Deref<Target = B>`，所以 `cow.len()`、`cow.chars()` 等方法直接可用——调用方甚至不需要知道背后是借用还是拥有。

## 18.8 Cell：Copy 类型的"无借用检查"内部可变

`Cell<T>` 与 `RefCell<T>` 同属 `std::cell` 家族，但机制更轻：没有运行期借用计数，直接**整体替换值**（`get`/`set`），所以只支持 `Copy` 类型。想"改"一个 `Cell<i32>`，实际是读出旧值、写入新值——没有 `&mut` 参与，借用规则无从检查也不需要检查。

典型用法是**惰性缓存**——逻辑上"只读"的方法，内部悄悄记一笔下次省重算：

```rust
use std::cell::Cell;

struct Data {
    values: Vec<u8>,
    cached_sum: Cell<Option<u8>>,   // 缓存位：None = 未算过
}

impl Data {
    fn new(values: Vec<u8>) -> Self {
        Self { values, cached_sum: Cell::new(None) }
    }

    fn sum(&self) -> u8 {                    // &self 不是 &mut self！
        if let Some(s) = self.cached_sum.get() {
            return s;                        // 命中缓存：O(1) 返回
        }
        let s: u8 = self.values.iter().sum(); // 未命中：现场算
        self.cached_sum.set(Some(s));        // 写回缓存（&self 下完成！）
        s
    }
}

let d = Data::new(vec![1, 2, 3, 4]);
assert_eq!(d.sum(), 10);   // 第一次：真算
assert_eq!(d.sum(), 10);   // 第二次：走缓存
```

`&self` 里完成"读旧值 + 写新值"是 Cell 的独门绝技——`RefCell` 需要运行期记账（borrow/borrow_mut 可能 panic），`Cell` 用"整体替换"绕开了借用语义，零记账开销。代价是只能搬整个值（Copy 类型才划算），大结构或要部分修改的场景还是 RefCell。

选型：**小 Copy 值 + 逻辑只读 + 内部要改 → Cell；非 Copy 或要部分修改 → RefCell**。

## 18.9 坑位清单

1. **Rc 跨线程直接编译错**：`Rc<i32>` 非 Send/Sync——报错会指向 rc.rs 注释劝你用 Arc（22 章 Send/Sync）。
2. **RefCell 双重 borrow 是 panic 不是编译错**：测试要覆盖冲突路径；借用 guard 活得过长（存进变量）是隐形炸弹——`let g = cell.borrow(); ...` 拖到 borrow_mut 就炸。
3. **Rc 循环 = 内存泄漏但不 UB**：泄漏在 Rust 里是"安全 bug"（内存仍会被进程回收）；设计上先想方向性。
4. **upgrade 返回 Option**：弱引用可能已失效——`if let Some(p) = weak.upgrade()` 是标准姿势，别 unwrap。
5. **Drop 顺序**：字段按声明逆序、变量按作用域逆序释放（04 章）——依赖释放顺序的代码加注释。
6. **`Box::new([0u8; 大])` 先在栈上构造再搬堆**？现代编译器多数场景直接堆构造，但超大数组Debug 构建仍可能栈溢出——`vec![0u8; n]` 更稳。
7. **dead_code 对"只写不读"的字段也报警**：children 塞了从未读 → 警告；要么读一次要么删（示例加了 len 打印）。

---

上一章：[17 模块与 Cargo](17-cargo.md) · 下一章：[19 unsafe 与 FFI](19-unsafe-ffi.md)
