# 22 · 并发 ⭐

> 对应示例：`examples/22_threads/`
>
> Rust 的招牌承诺：**数据竞争在安全代码里编译不过**。靠的不是运行时检查，
> 是 05 章的借用规则跨线程生效 + Send/Sync 两个自动 trait。

## 22.1 线程基础：spawn / join / move

```rust
use std::thread;

let data = vec![1, 2, 3];
let handle = thread::spawn(move || {      // move 必须：闭包要活过当前栈帧
    data.iter().sum::<i32>()
});
let sum = handle.join().unwrap();          // join：等待 + 取回返回值
```

三个细节：

- **`move` 是刚需不是风格**：借用局部变量的闭包进线程，编译器直接拒绝（线程可能活得比栈帧久）；
- **`join` 返回 `Result`**：子线程 panic 会在这里变 Err——panic 不跨线程传染，但也不会静默消失；
- 命名线程：`thread::Builder::new().name("worker-1".into()).spawn(...)`（调试器/日志里可读）。

### spawn 的完整签名：把约束拆开看

`thread::spawn` 的签名（std 源码简化）是理解 Rust 线程模型的最好教材：

```rust
pub fn spawn<F, T>(f: F) -> JoinHandle<T>
where
    F: FnOnce() -> T,       // 闭包只调一次（线程入口），所以最宽约束 FnOnce
    F: Send + 'static,      // 闭包本身（含捕获变量）能跨线程 move、且不含短命借用
    T: Send + 'static,      // 返回值也要能跨线程搬回来
```

三行 where 子句各自堵死一类事故：

1. **`FnOnce`**：线程入口只执行一次，不需要 Fn/FnMut 的"可重复调用"承诺——约束最宽，什么闭包都收；
2. **`F: Send + 'static`**：闭包按值 move 进新线程，捕获的每个变量跟着搬家——非 Send 类型（`Rc`、`RefCell`）在这里被拦下；
3. **`T: Send + 'static`**：返回值从子线程 move 回 `join()` 的调用方——反向搬家同样要通行证。

`'static` 反复出现的原因：线程的生命周期与当前栈帧**没有任何同步关系**——它可能在你 return 之后还跑很久。任何借用局部变量的闭包都可能在"被调时数据已死"，编译器一律拒绝。这就是 22.2 scoped threads 的存在意义：scope 用类型技巧保证"所有子线程在函数返回前 join"，从而放开 `'static` 限制、允许直接借用局部变量。

## 22.2 scoped threads（1.63+）：借用局部变量的现代写法

```rust
let mut scores = vec![0i32; 4];
thread::scope(|s| {
    for (i, slot) in scores.iter_mut().enumerate() {
        s.spawn(move || *slot = (i as i32 + 1) * 10);   // 直接借局部变量！
    }
});   // scope 结束自动 join —— 保证借用期，因此不需要 Arc
println!("{scores:?}");
```

scope 保证所有子线程在闭包返回前 join 完——借用检查器放行。**新代码优先 scope，数据要长期后台跑才 spawn + Arc**。

这个 API 的设计有一个深刻的历史教训（04 章详述）：早期 Rust 有 `thread::scoped` 函数，它返回一个 guard，guard 的 `Drop` 中 join 子线程。问题是 `mem::forget(guard)` 可以阻止 Drop 执行——子线程脱离控制，父函数返回后子线程访问已回收的栈内存——安全代码构造出内存不安全。`scoped` 因此被移除。现代的 `thread::scope` 把 join 逻辑放在**函数体内**而非 guard 的析构中——不依赖析构函数一定执行，从根上消除了泄漏路径。

## 22.3 mpsc：通道（消息传递）

并发编程有两条哲学路线：**共享内存**（加锁保护）和**消息传递**（通过通信来共享内存，而非共享内存来通信）。消息传递的数学基础是 CSP（Communicating Sequential Processes，通信顺序进程）——Erlang 的 Actor 模型和 Go 的 Channel 都是这一路线的实现。Rust 标准库选了 CSP：线程是进程，Channel 是通道，**不关注谁发谁收，只关注消息本身**。

```rust
use std::sync::mpsc;

let (tx, rx) = mpsc::channel();
for i in 0..3 {
    let tx = tx.clone();                    // 多生产者：每线程一个句柄
    thread::spawn(move || { tx.send(format!("消息{i}")).unwrap(); });
}
drop(tx);                                   // 主句柄弃权
for msg in rx {                             // 所有 sender drop 后迭代自然结束
    println!("{msg}");
}
```

- `mpsc` = Multi-Producer Single-Consumer：多生产者、单消费者的 FIFO 队列；
- `send` 拿值的所有权（**消息传递 = 所有权转移**，收发两端无共享内存）；
- `rx` 迭代终止条件：所有 sender drop——忘了 drop 会死等（示例 `drop(tx)` 是必要的一行）；
- `try_recv` 非阻塞轮询、`recv_timeout` 带超时；跨线程 async 用 `tokio::sync::mpsc`（23 章）。

**有界通道 `sync_channel`**：标准库还有一种带容量上限的通道——队列满时 `send` 阻塞，等消费者腾出位置：

```rust
let (tx, rx) = mpsc::sync_channel::<String>(2);   // 容量 2：第 3 条消息会阻塞发送方

thread::spawn(move || {
    for i in 0..5 {
        tx.send(format!("任务{i}")).unwrap();   // 发到第 3 条时在这里等 rx 消费
    }
});
for msg in rx { println!("{msg}"); }
```

选型：**无界 `channel`**——生产者不受消费者速度反压（内存换吞吐，小心消费者挂掉时队列无限膨胀）；**有界 `sync_channel`**——天然背压，生产者速度被消费者自动节流（内存占用可控，但 send 可能阻塞）。async 世界的 `tokio::sync::mpsc::channel(n)` 就是有界版，n 的取值是吞吐与内存的经典权衡。

## 22.4 共享可变状态：Arc<Mutex<T>>

```rust
use std::sync::{Arc, Mutex};

let counter = Arc::new(Mutex::new(0u64));
let mut handles = vec![];
for _ in 0..4 {
    let c = Arc::clone(&counter);           // 原子计数 +1（不是复制数据）
    handles.push(thread::spawn(move || {
        let mut guard = c.lock().unwrap();  // 拿锁
        *guard += 1;
    }));   // guard drop → 锁释放（RAII：忘记 unlock 在类型上不可能）
}
for h in handles { h.join().unwrap(); }
```

- **Mutex 包住数据**而不是 lock 方法满天飞：拿锁的同时拿到数据访问权；
- **MutexGuard 是智能指针**：`lock()` 返回的 guard 实现 Deref（解出 `&mut T`）和 Drop（作用域结束自动解锁）——18 章的两大 trait 在并发原语上原样复现。忘记 unlock 在类型上不可能；
- `lock()` 返回 Result：**毒锁**机制——持锁线程 panic 后锁标记 poisoned，后来者 unwrap 拿 Err 而不是拿到可能半写的状态。恢复手法：`lock().unwrap_or_else(|e| e.into_inner())`（要数据不管毒）。

**Mutex 的现实隐喻**（TRB）：一场仅有一个话筒的座谈会——每个人讲话前必须申请话筒，讲完必须移交，否则全场沉默。Rust 的类型系统把"申请"和"移交"都变成了类型约束：不 `lock()` 拿不到数据（编译错），guard 离开作用域自动释放（Drop）。其他语言把这两条交给程序员的记忆，Rust 交给编译器。

## 22.5 RwLock 与原子量

```rust
use std::sync::RwLock;
let cfg = RwLock::new(String::from("verbose=true"));
{
    let (r1, r2) = (cfg.read().unwrap(), cfg.read().unwrap());  // 多读共存
}
{
    cfg.write().unwrap().push_str(", level=debug");             // 独占写
}

use std::sync::atomic::{AtomicUsize, Ordering};
let hits = Arc::new(AtomicUsize::new(0));
h.fetch_add(1, Ordering::Relaxed);       // 无锁自增（计数器不需要 Mutex）
hits.load(Ordering::Relaxed);
```

选型：**读多写少 RwLock；简单计数/标志用原子；复杂不变量用 Mutex**。原子 Ordering 深似海，Relaxed（计数）与 AcqRel/SeqCst（同步语义）覆盖 99% 需求，其余场景先读 std 文档再写。

**RwLock 的写者饥饿**：std 的 `RwLock` 在 Linux 上由 pthread 读写锁实现，**不保证公平**——读者源源不断到来时，写者可能永远排不上队（读者优先策略）。读多写少且写不紧迫的场景没问题；写延迟敏感的场景（缓存刷新、配置热更新）要么换 `parking_lot::RwLock`（公平队列），要么用 `Mutex` 实测对比——Mutex 在竞争低时反而更快（单次原子操作 vs 读写锁的状态机）。

### Barrier：多线程同步起跑线

`Barrier::new(n)` 让 n 个线程在某个点集合——全部到达后才一起放行：

```rust
use std::sync::{Arc, Barrier};
use std::thread;

let barrier = Arc::new(Barrier::new(3));
let mut handles = vec![];
for i in 0..3 {
    let b = Arc::clone(&barrier);
    handles.push(thread::spawn(move || {
        println!("线程{i} 准备完毕");
        b.wait();                    // 等所有线程都到这里
        println!("线程{i} 开始工作");  // 这行一定在全部"准备完毕"之后打印
    }));
}
for h in handles { h.join().unwrap(); }
```

输出永远是 3 行"准备完毕"在前、3 行"开始工作"在后——`wait()` 就是同步起跑线。删掉 `b.wait()`，两行输出就会交错。适用：并行计算中"所有线程加载完数据再同时开始"、分阶段算法中"阶段间同步"。

### Condvar：等待一个条件

`Condvar` 让线程阻塞等待某个条件变为真——必须与 `Mutex` 配对使用（条件本身需要锁保护）：

```rust
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time::Duration;

let pair = Arc::new((Mutex::new(false), Condvar::new()));
let pair2 = Arc::clone(&pair);

thread::spawn(move || {
    thread::sleep(Duration::from_millis(100));   // 模拟工作
    let (lock, cvar) = &*pair2;
    let mut started = lock.lock().unwrap();
    *started = true;                             // 条件变为真
    cvar.notify_one();                           // 通知等待者
});

let (lock, cvar) = &*pair;
let mut started = lock.lock().unwrap();
while !*started {                                // 必须用 while 不是 if（防止虚假唤醒）
    started = cvar.wait(started).unwrap();       // 释放锁 + 阻塞，被通知后重新拿锁
}
println!("条件满足，继续执行");
```

经典模式：**`Mutex<bool>` 存条件 + `while !cond { cvar.wait(guard) }` 等待**。`wait` 会原子地释放锁并阻塞——醒来时重新拿锁，所以条件检查在锁保护下。用 `while` 而非 `if` 是防御虚假唤醒（spurious wakeup）的标准做法。注意 `Condvar` 与 `Mutex` 必须一一配对，混用会导致运行期 panic。

### 线程局部存储：每个线程一份

`thread_local!` 声明的变量在每个线程有独立副本——跨线程读写无需同步：

```rust
use std::cell::RefCell;
use std::thread;

thread_local! {
    static FOO: RefCell<u32> = RefCell::new(1);
}

FOO.with(|f| {
    println!("主线程初始: {}", *f.borrow());   // 1
    *f.borrow_mut() = 2;
});

thread::spawn(|| {
    FOO.with(|f| {
        println!("子线程初始: {}", *f.borrow());   // 还是 1——独立副本！
        *f.borrow_mut() = 3;
    });
}).join().unwrap();

FOO.with(|f| println!("主线程最终: {}", *f.borrow()));   // 2——不受子线程影响
```

输出：`主线程初始: 1`、`子线程初始: 1`、`主线程最终: 2`。子线程修改自己的副本到 3，主线程的副本不受影响。访问必须用 `.with(|val| ...)` 闭包——因为线程局部存储的地址在线程内才有效。适用：线程池里每个 worker 的临时缓冲、随机数生成器、格式化器的复用缓存。

## 22.6 Send 与 Sync：自动判定的通行证

Rust 看待线程安全的哲学：**多线程共享内存并非问题所在，问题在于错误地共享数据**。Send 和 Sync 是给类型贴的标签——编译器按标签决定哪些类型可以跨线程移动/共享，从而在编译期发现线程不安全。

```rust
fn assert_send<T: Send>() {}    // 值可以 move 到别的线程（所有权搬家）
fn assert_sync<T: Sync>() {}    // &T 可以跨线程共享

assert_send::<JoinHandle<i32>>();
assert_sync::<Mutex<i32>>();
// assert_send::<Rc<i32>>();    // ← 编译错：Rc 非 Send（计数非原子）
// assert_sync::<RefCell<i32>>();  // ← 编译错：借用计数非原子
```

`thread::spawn` 的签名要求闭包 `F: Send + 'static`——闭包的捕获变量和返回值都必须是 Send。`'static` 是因为线程可能活得比当前函数久，借用局部变量就是悬垂。编译器按字段自动推导（含泛型），**unsafe 手动实现是最终手段**（19 章）。这就是"编译期消灭数据竞争"的执行机构：Rc/RefCell 想跨线程，类型系统先拦住，Arc/Mutex 是指定的替换品——**18 章选型表的多线程列由此而来**。

### Send 和 Sync 的精确语义

两个 trait 都是 **auto trait**（编译器自动推导，不需要手写 impl）：

```rust
// 标准库中的定义——注意 unsafe impl
unsafe impl<T: ?Sized> !Send for *const T {}    // 裸指针不是 Send
unsafe impl<T: ?Sized> !Send for *mut T {}
unsafe impl<'a, T: Sync + ?Sized> Send for &'a T {}   // &T 是 Send 当且仅当 T 是 Sync
unsafe impl<'a, T: Send + ?Sized> Send for &'a mut T {} // &mut T 是 Send 当且仅当 T 是 Send
```

`!Send` 是"否定实现"——显式声明某类型**不**满足某 auto trait。手动实现（或否定）Send/Sync 必须是 `unsafe`——你在向编译器担保"我比自动推导更懂这个类型的线程安全性"。FFI 封装裸指针的类型是典型场景：裸指针本身 `!Send`，但你的封装如果做了适当的同步，可以 `unsafe impl Send for MyWrapper`。

**哪些类型是 Send？** 不包含非 Send 字段的类型。`i32`、`String`（拥有的堆数据随值搬家）、`Vec<T: Send>` 都是 Send。`Rc<T>` 不是——计数器非原子，两个线程同时 clone/drop 会数据竞争。`RefCell<T>` 不是——borrow 计数非原子。

**哪些类型是 Sync？** `&T` 可以安全跨线程共享的类型。`i32` 是 Sync（只读共享安全）。`Mutex<T>` 是 Sync 即使 `T` 不是——锁保证了内部可变性安全。`Cell<T>`/`RefCell<T>` 不是 Sync——`&Cell` 可以调 `set` 修改内部值，多线程同时 set 就竞争。

**Mutex 的"构造器"角色**：`Mutex<T>` 把非 Sync 的 T 包成 Sync——这是"构造器类型"（wrapper type）的典范。同理 `Arc<T>` 把非 Send 的 Rc 变成 Send（原子计数）。**包一层，改变线程安全属性**——这是类型系统层面的装饰器模式。

### 实战：游戏引擎资源的 Sync + Send 约束

游戏引擎（如 Legion ECS）的资源系统要求所有资源实现 `Sync + Send`——因为系统可能在不同线程中并行访问同一资源。这不是建议，是 trait 定义中的硬约束：

```rust
// 地图主题 trait：只有 Sync + Send 的类型才能做资源
pub trait MapTheme: Sync + Send {
    fn tile_to_render(&self, tile_type: TileType) -> FontCharType;
}

// 纯函数实现自动满足 Sync + Send（无内部可变状态）
pub struct DungeonTheme;
impl MapTheme for DungeonTheme {
    fn tile_to_render(&self, tile_type: TileType) -> FontCharType {
        match tile_type {
            TileType::Floor => to_cp437('.'),
            TileType::Wall  => to_cp437('#'),
        }
    }
}

// 存入资源系统：编译器验证 Sync + Send
resources.insert(Box::new(DungeonTheme) as Box<dyn MapTheme>);
```

`tile_to_render` 是**纯函数**（只依赖输入、无副作用、不存状态）——纯函数天然线程安全，因为"没有共享状态"就谈不上"竞争"。如果主题需要缓存（比如预计算渲染查找表），用 `Mutex<HashMap<...>>` 包一层即可恢复 Sync——这就是"构造器类型"的实战价值。

这个约束的实际效果：**编译器在插入资源的那一刻就检查了线程安全性**，而不是等到运行时才出现数据竞争。如果开发者忘了给非 Sync 字段加锁，编译错会精确指向 `resources.insert(...)` 那一行。

### 全局变量与 Sync 的交汇

`static` 全局变量要求类型实现 `Sync`——这是编译器的额外检查，堵住了"通过全局变量绕过 Send 约束"的漏洞：

```rust
use std::cell::Cell;
use std::thread;

// static G: Cell<i32> = Cell::new(1);
// ← 编译错：`Cell<i32>` cannot be shared between threads safely
//    即使闭包不捕获任何局部变量（满足 Send），
//    两个线程同时通过全局变量修改同一个 Cell → 数据竞争

// 正解：用满足 Sync 的原子类型
static N: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);
// 多线程通过全局 AtomicU32 计数完全安全（19 章 static mut 的对比）
```

闭包不捕获局部变量就满足 `Send`——但全局变量是"共享 + 可变"的另一种路径。`static` 的 `Sync` 要求是第二道防线：**线程安全不能靠"碰巧没捕获"来保证**。

### Sync 的等价定义

TRB 给出一个更精确的角度：**`T: Sync` 当且仅当 `&T: Send`**——"T 可被多线程共享"等价于"T 的引用可被送到别的线程"。这个等价式把两个 trait 统一了起来：Sync 不是独立概念，是 Send 在引用上的投影。`Mutex<T>` 是 Sync 的典型（`&Mutex` 可以跨线程），`Cell`/`RefCell` 不是（内部计数非原子）。

### 为什么不默认全用 Arc

`Arc` 的计数是原子的——每次 clone/drop 都要做原子读写（CPU 级同步指令），比 `Rc` 的非原子计数慢。如果数据只在单线程用，`Rc` 就是零代价的正确选择；跨线程才付原子税。标准库不默认 `Arc` 的原因：**线程安全不是免费的，按需付费**——和 `Mutex` vs `Cell`、`Box` vs 栈分配是同一哲学。

## 22.7 并发生态：标准库之外

std 的并发原语刻意精简（spawn/scope/mpsc/Mutex/RwLock/原子），真实项目按需求从 crates.io 补：

| crate | 解决什么 | 何时选它 |
|---|---|---|
| `rayon` | 数据并行（`par_iter()` 把迭代器管道自动拆到线程池） | CPU 密集批处理：`.par_iter().map(...).sum()` 一行并行化 |
| `crossbeam` | 无锁数据结构 + 有界通道 + scoped 线程的"祖师爷" | 高性能队列（`ArrayQueue`）、多消费者通道 |
| `parking_lot` | 更快更小的 Mutex/RwLock（无毒锁、无系统调用快路径） | 锁竞争是热点时的 drop-in 替换 |
| `tokio` / `async-std` | async 运行时（23 章主角） | I/O 密集、万级并发连接 |
| `actix` | Actor 模型框架（每个 Actor 独占状态、靠消息通信） | 状态机/长连接网关（WebSocket 推送等） |

**Actor 模型**值得一提：它是"不共享任何状态"路线的极致——每个 actor 拥有私有数据，actor 之间只通过消息通信（与 mpsc 同哲学，但把"线程 + 邮箱 + 生命周期"打包成框架）。`actix` 的用法长这样：

```rust
use actix::prelude::*;

struct Counter { count: usize }
impl Actor for Counter { type Context = Context<Self>; }

struct Increment;
impl Message for Increment { type Result = usize; }

impl Handler<Increment> for Counter {
    type Result = usize;
    fn handle(&mut self, _: Increment, _: &mut Context<Self>) -> usize {
        self.count += 1;
        self.count
    }
}

// 使用：Addr<Counter> 是 actor 的句柄，.send(Increment).await 发消息
```

Actor 模型消灭了数据竞争（状态私有 + 消息驱动），代价是消息协议的类型样板。选型直觉：**共享状态少而集中 → Arc<Mutex>；流水线/扇出 → 通道；状态机林立 → Actor**。

## 22.8 死锁与经典陷阱

- **锁顺序**：两线程各持一锁互相等对方——固定全局加锁顺序或一次拿一把；
- **guard 跨 await**（23 章）：std::Mutex 的 guard 不是 Send，跨 await 点持有会编译错——那是 tokio::Mutex 的场景；
- **忘 join 的线程**：主线程退出时后台线程直接被杀（不是等待）——scope 或显式 join；
- **饥饿**：RwLock 写者可能饿死（实现相关），高竞争场景实测选型。

### `while let` 的隐形锁陷阱（TRB 线程池章的精髓）

TRB 在实现线程池时踩了一个极其微妙的坑，值得单独记录：

```rust
// ✘ 错误：锁在整个循环体期间持有——其他 Worker 全部饿死
while let Ok(job) = receiver.lock().unwrap().recv() {
    job();  // 执行期间锁没释放！其他 Worker 拿不到任务
}

// ✔ 正确：锁只在 recv 那一刻持有
loop {
    let job = receiver.lock().unwrap().recv().unwrap();  // 临时值在 let 结束即 drop
    job();  // 执行时锁已释放
}
```

原因：`while let`（以及 `if let`、`match`）会把**条件表达式的临时值活到整个代码块结束**；而 `let` 语句的右侧临时值在语句结束就丢弃。`MutexGuard` 的 Drop 就是解锁——所以 `while let` 版本在 `job()` 执行期间一直持锁，其他 Worker 线程干等。**这是作用域语义在并发下的直接后果**，不写线程池很难遇到，一遇到就是生产事故。

## 22.9 坑位清单

1. **spawn 不 move 直接编译错**：借用局部 = "线程可能用悬垂"，借用检查器六亲不认——加 `move`，需要共享再 Arc。
2. **`rx` 死等的元凶是忘 drop(tx)**：主线程持有 sender 句柄，迭代器等它——示例里 `drop(tx)` 单独一行是教学重点。
3. **join 返回 Result 别 unwrap 到底**：子线程 panic 时你要的是记录/降级，不是主线程陪崩。
4. **毒锁 unwrap 双刃**：unwrap 会让第二个 panic 级联——服务型代码 `unwrap_or_else(|e| e.into_inner())` + 日志。
5. **Arc::clone 不复制数据**：它只加计数——真要复制数据是 `(*arc).clone()`，写错语义静默（能跑但行为两样）。
6. **`static mut` 不是并发方案**：2024 edition 禁取引用（19 章），用 `AtomicUsize`/`OnceLock`/`Mutex`。
7. **测试里的线程要确定性收束**：join 全部再断言；依赖时序的测试是 flaky 之源（本教程 22 章示例测试全部 join 后断言）。

---

上一章：[21 测试](21-testing.md) · 下一章：[23 async/await](23-async.md)
