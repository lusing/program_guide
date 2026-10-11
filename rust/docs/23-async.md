# 23 · async/await ⭐

> 对应示例：`examples/23_async/`（依赖 tokio）
>
> async 是"百万连接"的成本答案：线程是 OS 资源（栈 MB 级），任务是状态机（字节 KB 级）。
> 本章以 tokio 为运行时讲清心智模型与核心 API。

## 23.1 心智模型：先立四条

1. **`async fn` 是"造 Future 的函数"**：`async fn f() -> T` ≡ `fn f() -> impl Future<Output = T>`。调用它**什么都不执行**，只造一个惰性状态机（15 章迭代器同款惰性）。
2. **`.await` 才驱动**：在 await 点可能让出线程，调度器去跑别的任务——这就是单线程也能万级并发的原理。
3. **并发 ≠ 并行**：并发是"交替推进"（单核也行），并行是"同时执行"（要多核）。多线程调度器（tokio 默认）两者都有。
4. **std 只有协议没有运行时**：`Future` trait、async/await 语法在 std；调度器、定时器、异步 IO 来自 tokio/async-std 等库——这是 Rust 的分层设计，不是缺件。

```rust
async fn fetch(name: &str, ms: u64) -> String {
    tokio::time::sleep(Duration::from_millis(ms)).await;   // 异步等待：让出，不占线程
    format!("[{name} 完成]")
}

#[tokio::main]                     // 展开为：建多线程运行时 + block_on(main())
async fn main() {
    let s = fetch("A", 30).await;  // 此刻才真正执行
}
```

## 23.2 顺序 vs 并发：join! / try_join!

```rust
let a = fetch("A", 30).await;         // 顺序：总耗时 = 和
let b = fetch("B", 30).await;

let (x, y, z) = tokio::join!(fetch("X", 40), fetch("Y", 20), fetch("Z", 30));
// 并发：总耗时 ≈ 最慢者（示例实测 join 两个 40ms 任务 < 75ms 断言通过）

let (r1, r2) = tokio::try_join!(ok_fut(), fallible_fut())?;   // 全成功才成功
```

`join!` 是宏（16 章那类）——同时 poll 多个 Future，不是"先等第一个"。

## 23.3 spawn：托管任务

```rust
let handle = tokio::spawn(fetch("后台", 10));   // 丢进调度器（可多核并行）
let bg = handle.await.unwrap();                 // JoinHandle.await；panic 变 Err

// 后台任务与主流程解耦：不 await handle 也继续跑（ detached ）
```

spawn 的 Future 必须 `Send + 'static`：跨线程调度 + 独立生存期——**move 数据进任务，借用要用 scope 变体或 Arc**（对应 22 章线程的 move 教训，规则同源）。

## 23.4 select!：多路等一个

```rust
let winner = tokio::select! {
    r = fetch("快请求", 5) => r,           // 谁先完成走谁
    _ = fetch("慢请求", 100) => "被取消",
};
// 未选中的分支被 drop = 任务取消（取消是 async 的基础语义，见 23.7）

let maybe = timeout(Duration::from_millis(10), fetch("必超时", 500)).await;
// Err(Elapsed)：timeout 是 select 的成品封装
```

select 常驻循环做"事件泵"：消息 or 心跳 or 取消信号，谁来处理谁。

## 23.5 异步通道与锁（tokio::sync）

```rust
let (tx, mut rx) = tokio::sync::mpsc::channel::<u32>(8);   // 缓冲 8
tokio::spawn(async move {
    for i in 1..=5 { tx.send(i).await.unwrap(); }          // send 是 async：满则让出（背压！）
});
while let Some(i) = rx.recv().await { }                     // sender 全 drop → None
```

| 场景 | 用 std 的（22 章） | 用 tokio 的 |
|---|---|---|
| 通道 | `std::sync::mpsc`（阻塞） | `tokio::sync::mpsc`（`.await` 背压） |
| 锁 | `Mutex`（短临界区，**不可跨 await**） | `tokio::sync::Mutex`（可跨 await） |
| 定时/睡眠 | `thread::sleep`（阻塞！） | `tokio::time::sleep`（让出） |

**async 世界的铁律：永远不阻塞 worker**——std 的 sleep/锁/重 IO 都会占住线程拖慢所有任务。

## 23.6 阻塞与 CPU 密集的处置

```rust
// 阻塞调用（同步库、文件扫描）：丢进专门的阻塞线程池
let heavy = tokio::task::spawn_blocking(|| (1..=1000).sum::<u64>());
println!("{}", heavy.await.unwrap());

// 长计算：要么 spawn_blocking 分片，要么干脆 std::thread（22 章）独立跑完发消息
```

误把 `thread::sleep(10s)` 写进 async 函数 = 一个 worker 睡死 10 秒——高并发服务里这是事故级错误。

## 23.7 取消：drop 即取消（及陷阱）

select 走了快分支，慢分支的 Future 被 drop——`cancel-safe` 成为关键词：

- 已完成的副作用不会回滚；await 点之间的代码跑完才轮到取消；
- `select!` 循环里"取了消息没处理完就被另一分支打断"是经典 bug——处理逻辑放 select 分支体内、或队列操作设计成幂等；
- `tokio::time::timeout` 是安全取消的范本（被取消方只是不再被 poll）。

## 23.8 迷你 block_on：std-only 看穿魔法（原理课）

不依赖任何库，50 行写个单任务执行器——`Future` 的本质是 `poll`：

```rust
use std::future::Future;
use std::pin::Pin;
use std::task::{Context, Poll, RawWaker, RawWakerVTable, Waker};

fn block_on<F: Future>(mut fut: F) -> F::Output {
    fn noop(_: *const ()) {}
    fn clone(p: *const ()) -> RawWaker { RawWaker::new(p, &VTABLE) }
    static VTABLE: RawWakerVTable = RawWakerVTable::new(clone, noop, noop, noop);

    let waker = unsafe { Waker::from_raw(RawWaker::new(std::ptr::null(), &VTABLE)) };
    let mut cx = Context::from_waker(&waker);
    let mut fut = unsafe { Pin::new_unchecked(&mut fut) };
    loop {
        match fut.as_mut().poll(&mut cx) {
            Poll::Ready(v) => return v,
            Poll::Pending => continue,   // 真运行时这里会 park/换任务
        }
    }
}
```

结论：**Future = 被动轮询的状态机，Waker = "好了叫我"的回调，运行时 = 调度器 + IO/定时器事件源**。tokio 的多任务调度、work-stealing、epoll/IOCP 集成是把这三件事做到工业级。

## 23.9 生成器：async 的底层引擎

async/await 不是凭空设计的——它站在**生成器（Generator）**的肩膀上。理解生成器就理解了 async 状态机的本质。

### 生成器 = 可暂停的函数

生成器是一种可以在执行中"让出"（yield）、稍后从让出点恢复的函数。Rust 的生成器语法（nightly 特性）：

```rust
#![feature(generators, generator_trait)]
use std::ops::{Generator, GeneratorState};

let mut g = || {           // 一个生成器闭包
    let mut curr: u64 = 1;
    let mut next: u64 = 1;
    loop {
        let new_next = curr.checked_add(next);
        if let Some(n) = new_next {
            curr = next;
            next = n;
            yield curr;    // ← 在这里暂停，把 curr 交给调用方
        } else {
            return;        // 结束
        }
    }
};

loop {
    match g.resume() {     // 恢复执行
        GeneratorState::Yielded(v) => println!("{v}"),  // 拿到一个值
        GeneratorState::Complete(_) => break,            // 生成器结束
    }
}
// 输出：1 1 2 3 5 8 13 21 ...
```

`yield` 和 `await` 是同一族语义：**暂停当前函数、把值交出去、下次从暂停点恢复**。

### 编译器如何脱糖生成器

生成器的脱糖与闭包同构——编译器生成一个匿名结构体，跨 yield 存活的局部变量是它的字段：

```rust
// 源代码
let mut g = || {
    let mut curr: u64 = 1;
    let mut next: u64 = 1;
    loop {
        let new_next = curr.checked_add(next);
        if let Some(n) = new_next {
            curr = next;
            next = n;
            yield curr;
        } else { return; }
    }
};

// 编译器脱糖（示意——真实转换在 MIR 层完成，此处为教学模型）
enum __Gen {
    Start { curr: u64, next: u64 },
    Yield1 { curr: u64, next: u64 },
    Done,
}

impl Generator for __Gen {
    type Yield = u64;
    type Return = ();
    fn resume(mut self: Pin<&mut Self>) -> GeneratorState<u64, ()> {
        // 用 mem::replace 取出当前状态，匹配后推进
        match std::mem::replace(&mut *self, __Gen::Done) {
            __Gen::Start { curr, next }
            | __Gen::Yield1 { curr, next } => {
                if let Some(n) = curr.checked_add(next) {
                    *self = __Gen::Yield1 { curr: next, next: n };
                    GeneratorState::Yielded(curr)
                } else {
                    *self = __Gen::Done;
                    GeneratorState::Complete(())
                }
            }
            __Gen::Done => panic!("generator resumed after completion"),
        }
    }
}
```

关键观察：**`curr` 和 `next` 跨 yield 存活，所以必须是结构体字段**；`new_next` 不跨 yield，可以留在 `resume` 的栈帧里。多个 yield 点就引入状态枚举（`Start` / `Yield1` / `Yield2` / …）记录"上次执行到哪"。编译器自动管理"哪些变量要存、存到哪、恢复时怎么读"——这就是 async 状态机的原型。

### 自引用问题与 Pin

生成器（以及 async 块）有一个深层问题：**跨 yield 的借用**。如果生成器内部有一个变量 `local` 和指向它的引用 `ptr`，编译器脱糖后 `local` 和 `ptr` 是结构体的两个字段——`ptr` 指向 `local` 的内存地址。如果这个结构体被 move（比如从函数返回），`local` 的地址变了，但 `ptr` 的值没变——**悬垂指针**。

这就是**自引用类型（self-referential type）**问题。Rust 的解决方案是 `Pin`：

```rust
// Pin 的核心承诺：被 Pin 包裹的值不会被 move
let mut gen = /* 某个自引用生成器 */;
let mut pinned = Box::pin(gen);   // Pin<Box<Gen>>——堆上固定，不再移动
// pinned.as_mut().resume();      // 通过 Pin 调用 resume，安全
```

`Pin<P>` 是一个智能指针包装：它**承诺**指向的对象不会被 move。`Box::pin` 把值放到堆上——堆地址在 Box 活着期间不变，所以值不会被 move。`resume` 的 `self` 参数是 `Pin<&mut Self>` 而不是 `&mut Self`——这保证了 resume 被调用时，生成器已经固定。

async/await 的脱糖与生成器完全同构：`await` 就是 `yield`（让出），async 块捕获的变量和跨 await 存活的局部变量是状态机的字段，`Pin` 保证状态机不被移动。这就是为什么 `Future::poll` 的签名是 `fn poll(self: Pin<&mut Self>, ...)`——`Pin` 不是 async 的附属品，是**自引用状态机能安全存在的根基**。

## 23.10 生态速览

| 名字 | 是什么 |
|---|---|
| tokio | 默认运行时（本教程用）：调度 + 时间 + IO + sync |
| async-std / smol | 另一系运行时（API 近似 std） |
| futures crate | 工具箱（Stream、join、select 的通用版） |
| reqwest | HTTP 客户端（基于 hyper） |
| axum / actix-web | Web 框架 |
| sqlx | 异步数据库（编译期校验 SQL） |
| tracing | 结构化日志（async 友好的 span 传播） |

## 23.11 坑位清单

1. **忘 await = 白写**：`fetch("A", 30);` 不带 `.await` 只造 Future——编译器 `#[must_use]` 警告，别无视。
2. **async 里 thread::sleep 是事故**：占死 worker；`tokio::time::sleep` 才让出。同理锁内重活、`std::fs` 大文件 → spawn_blocking。
3. **guard 跨 await 编译错**：std::Mutex 的 guard 非 Send——换 tokio::sync::Mutex 或把临界区收窄到 await 之前。
4. **spawn 借用局部变量编译错**：`Send + 'static` 约束——move 或 Arc（22 章 move 教训的 async 版）。
5. **`async fn` 递归**：直接自引用编译错（无限大小）——`Box::pin` 包返回值。
6. **取消安全要审设计**：select 分支里的"读队列"必须幂等或先读后处理（23.7）。
7. **单线程运行时测出的顺序 ≠ 生产**：`#[tokio::test]` 默认单线程（current_thread），并发窗口的行为别依赖；多线程用 `#[tokio::test(flavor = "multi_thread")]`。

---

上一章：[22 并发](22-threads.md) · 下一章：[24 实战：迷你 grep](24-minigrep.md)
