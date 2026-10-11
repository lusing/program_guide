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

### Sync 的等价定义

TRB 给出一个更精确的角度：**`T: Sync` 当且仅当 `&T: Send`**——"T 可被多线程共享"等价于"T 的引用可被送到别的线程"。这个等价式把两个 trait 统一了起来：Sync 不是独立概念，是 Send 在引用上的投影。`Mutex<T>` 是 Sync 的典型（`&Mutex` 可以跨线程），`Cell`/`RefCell` 不是（内部计数非原子）。

### 为什么不默认全用 Arc

`Arc` 的计数是原子的——每次 clone/drop 都要做原子读写（CPU 级同步指令），比 `Rc` 的非原子计数慢。如果数据只在单线程用，`Rc` 就是零代价的正确选择；跨线程才付原子税。标准库不默认 `Arc` 的原因：**线程安全不是免费的，按需付费**——和 `Mutex` vs `Cell`、`Box` vs 栈分配是同一哲学。

## 22.7 死锁与经典陷阱

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

## 22.8 坑位清单

1. **spawn 不 move 直接编译错**：借用局部 = "线程可能用悬垂"，借用检查器六亲不认——加 `move`，需要共享再 Arc。
2. **`rx` 死等的元凶是忘 drop(tx)**：主线程持有 sender 句柄，迭代器等它——示例里 `drop(tx)` 单独一行是教学重点。
3. **join 返回 Result 别 unwrap 到底**：子线程 panic 时你要的是记录/降级，不是主线程陪崩。
4. **毒锁 unwrap 双刃**：unwrap 会让第二个 panic 级联——服务型代码 `unwrap_or_else(|e| e.into_inner())` + 日志。
5. **Arc::clone 不复制数据**：它只加计数——真要复制数据是 `(*arc).clone()`，写错语义静默（能跑但行为两样）。
6. **`static mut` 不是并发方案**：2024 edition 禁取引用（19 章），用 `AtomicUsize`/`OnceLock`/`Mutex`。
7. **测试里的线程要确定性收束**：join 全部再断言；依赖时序的测试是 flaky 之源（本教程 22 章示例测试全部 join 后断言）。

---

上一章：[21 测试](21-testing.md) · 下一章：[23 async/await](23-async.md)
