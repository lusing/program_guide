# 18 · 智能指针

> 对应示例：`examples/18_smartptr/`
>
> `&` 与 `&mut` 只是借用；智能指针**拥有**数据并附加行为：Box 独占堆、
> Rc/Arc 共享计数、RefCell/Mutex 内部可变性。选型表在 18.7，先逐个拆开看。

## 18.1 Box：堆分配的独占指针

三个不可替代的用途：

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

Box 零开销（相对普通引用多一次堆分配）；自动 Deref 让 `*b`、`b.field`、`b.method()` 直接用。

## 18.2 Deref 与 Drop：智能指针的两大 trait

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

**Deref 强转链**是 `&String → &str`、`&Vec<T> → &[T]`、`&Box<String> → &String → &str` 的公共机制——编译器沿 Deref 链自动插 `.deref()`，直到类型匹配。方法调用 `s.len()` 同理穿透。这解释了 06 章的"函数收 &str 什么都能传"。

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

## 18.7 选型总表（背下来）

| 需求 | 单线程 | 多线程 |
|---|---|---|
| 独占堆/递归/trait 对象 | `Box<T>` | `Box<T>` |
| 共享只读 | `Rc<T>` | `Arc<T>` |
| 内部可变（逻辑不可变绑定） | `RefCell<T>` | `Mutex<T>` / `RwLock<T>` / 原子 |
| 共享 + 可变 | `Rc<RefCell<T>>` | `Arc<Mutex<T>>` |
| 打破循环 | `Weak<T>` | `Weak<T>`（Arc 版） |

另两个顺路的：`Cow<T>`（写时克隆，06 章字符串场景偶用）、`Cell<T>`（Copy 类型的轻量内部可变，`get/set` 无借用检查）。

## 18.8 坑位清单

1. **Rc 跨线程直接编译错**：`Rc<i32>` 非 Send/Sync——报错会指向 rc.rs 注释劝你用 Arc（22 章 Send/Sync）。
2. **RefCell 双重 borrow 是 panic 不是编译错**：测试要覆盖冲突路径；借用 guard 活得过长（存进变量）是隐形炸弹——`let g = cell.borrow(); ...` 拖到 borrow_mut 就炸。
3. **Rc 循环 = 内存泄漏但不 UB**：泄漏在 Rust 里是"安全 bug"（内存仍会被进程回收）；设计上先想方向性。
4. **upgrade 返回 Option**：弱引用可能已失效——`if let Some(p) = weak.upgrade()` 是标准姿势，别 unwrap。
5. **Drop 顺序**：字段按声明逆序、变量按作用域逆序释放（04 章）——依赖释放顺序的代码加注释。
6. **`Box::new([0u8; 大])` 先在栈上构造再搬堆**？现代编译器多数场景直接堆构造，但超大数组Debug 构建仍可能栈溢出——`vec![0u8; n]` 更稳。
7. **dead_code 对"只写不读"的字段也报警**：children 塞了从未读 → 警告；要么读一次要么删（示例加了 len 打印）。

---

上一章：[17 模块与 Cargo](17-cargo.md) · 下一章：[19 unsafe 与 FFI](19-unsafe-ffi.md)
