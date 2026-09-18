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
- **guard 是 RAII 锁**：作用域结束自动释放——05 章的借用规则顺带保证了"锁内改数据、锁外摸不着"（guard 活着期间独占借用）；
- `lock()` 返回 Result：**毒锁**机制——持锁线程 panic 后锁标记 poisoned，后来者 unwrap 拿 Err 而不是拿到可能半写的状态。恢复手法：`lock().unwrap_or_else(|e| e.into_inner())`（要数据不管毒）。

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

```rust
fn assert_send<T: Send>() {}    // 值可以 move 到别的线程（所有权搬家）
fn assert_sync<T: Sync>() {}    // &T 可以跨线程共享

assert_send::<JoinHandle<i32>>();
assert_sync::<Mutex<i32>>();
// assert_send::<Rc<i32>>();    // ← 编译错：Rc 非 Send（计数非原子）
// assert_sync::<RefCell<i32>>();  // ← 编译错：借用计数非原子
```

编译器按字段自动推导（含泛型），**unsafe 手动实现是最终手段**（19 章）。这就是"编译期消灭数据竞争"的执行机构：Rc/RefCell 想跨线程，类型系统先拦住，Arc/Mutex 是指定的替换品——**18 章选型表的多线程列由此而来**。

## 22.7 死锁与经典陷阱

- **锁顺序**：两线程各持一锁互相等对方——固定全局加锁顺序或一次拿一把；
- **guard 跨 await**（23 章）：std::Mutex 的 guard 不是 Send，跨 await 点持有会编译错——那是 tokio::Mutex 的场景；
- **忘 join 的线程**：主线程退出时后台线程直接被杀（不是等待）——scope 或显式 join；
- **饥饿**：RwLock 写者可能饿死（实现相关），高竞争场景实测选型。

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
