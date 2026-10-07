# 29 · 并发 II：原子、同步原语与任务

> 对应示例：`examples/29_atomic/`

## 29.1 atomic：免锁的原子计数

```cpp
std::atomic<long long> hits{0};

void click(int times) {
    for (int i = 0; i < times; ++i) {
        hits.fetch_add(1, std::memory_order_relaxed);  // 计数不需要同步序
    }
}
// 4 线程 × 100'000 → hits = 400000（assert 验证）
```

第 28 章用 mutex 保住了 `++counter`，但"一个整数的读改写"其实有更轻的武器：`std::atomic<T>` 的 `fetch_add` 是**单条原子指令**（lock xadd），不可分割、无锁、比 mutex 快一个量级（mutex 要进内核或 CAS 循环）。四线程十万次累加，atomic 版实测轻松跑赢。

选型决策表（上一章欠的账）：

| 场景 | 武器 |
|---|---|
| 单个数值/指针/标志的读改写 | **atomic** |
| 复合不变量（多个变量要一起变） | **mutex** |
| "等条件成立再继续" | 条件变量 / latch / barrier |
| 限流 N 个并发 | semaphore（29.6） |

`operator` 糖也认一下：`hits += 1` / `++hits`（fetch_add）、`hits.load()`（读）、`hits.store(x)`（写）。**读写都要走 atomic** 才算数——一边 atomic 一边裸读，竞争照旧。

## 29.2 内存序：release/acquire 的"发布-获取"

`fetch_add(1, std::memory_order_relaxed)` 尾巴上那串是什么？**内存序（memory order）**——多核各自缓存的重排规则。CPU 和编译器都会重排指令（性能命脉），内存序约定"哪些重排不许越过哪些操作"：

| 序 | 含义 | 用于 |
|---|---|---|
| `relaxed` | 只保证**本操作原子**，不管顺序 | 计数器、统计 |
| `acquire/release` | 配对建立"先行发生"（发布/获取） | 锁的实现、标志位通知 |
| `seq_cst`（默认） | 全局总序，最直观也最保守 | 拿不准时的默认 |

release/acquire 不是抽象概念，它有一个精确的契约：**同一家 atomic 变量上，release 写 与之后的 acquire 读 配成一对，前者之前的所有写，对后者之后都可见**。示例 29.2 用一个普通变量实证：

```cpp
int payload = 0;                  // 普通变量：没有任何原子性
std::atomic<bool> ready{false};

// 线程 A（生产者）
payload = 42;                                 // ①
ready.store(true, std::memory_order_release); // ② 发布：① 不许重排到 ② 之后

// 线程 B（消费者）
while (!ready.load(std::memory_order_acquire)) { }  // ③ 获取：与 ② 配对
// 此刻读 payload，标准硬保证是 42——不是运气
```

把 ②/③ 换成 relaxed，`payload == 42` 就**不再是保证**（可能读到旧值 0——虽然很少发生，但那是调度运气不是正确性）。这就是"relaxed 只管本操作原子、不管顺序"的实例化。反过来，`std::mutex` 之所以能护住整片临界区，正是因为 unlock/load 内部就是 release、lock 内部就是 acquire——你每一章都在用这对配对，只是现在见到了它的素颜。

本教程的立场依旧只有一句：**不懂就写默认（不标内存序）**。默认 seq_cst 最多慢一点，永远正确；手写非默认序一旦理解有偏差，就是极难复现的并发 bug。两个白名单例外：纯计数的 relaxed（29.1）、以及看得懂上面这对发布-获取之后的显式 acquire/release（它是读懂数据结构实现的地基）。

## 29.3 CAS 与自旋锁：atomic 的进阶两招

**CAS（compare-and-exchange）**是"检查再设置"的原子化，一切无锁结构的地基：

```cpp
std::atomic<int> value{0};
// 想原子地 +1，但 fetch_add 管不到的复杂场景都用这个骨架：
int expected = value.load();
while (!value.compare_exchange_weak(expected, expected + 1)) {
    // 失败：expected 已被刷新成"现场值"，带着新情报再试
}
// 4 线程 × 50'000 → 200000（示例实测，一次不丢）
```

两个背下来的细节：**expected 按引用传入，失败时被更新为现场值**（所以循环里不用重新 load）；**weak 允许伪失败**（明明相等也可能报失败——省一条指令），恰好被循环消化，所以循环骨架一律用 weak、单次尝试用 strong。坑位清单第 1 条的"检查再设置两步窗口"（`if (a.load()==0) a.store(1)`）的正解就是它。

**自旋锁**用 `std::atomic_flag`——标准库里**唯一保证免锁**的原生类型：

```cpp
class Spinlock {
public:
    void lock()   { while (flag_.test_and_set(std::memory_order_acquire)) {} }
    void unlock() { flag_.clear(std::memory_order_release); }
private:
    std::atomic_flag flag_{};   // C++20 起默认构造即清除态
};

Spinlock spin;
std::lock_guard lock{spin};    // 满足 BasicLockable 就能套 RAII 壳
```

抢不到锁就原地转圈（不睡眠、不让出 CPU）——**只配极短的临界区**（几十纳秒级、争用低、核多），比如无锁结构的内部小段。临界区一长或核数一少，自旋就是烧 CPU 的行为艺术；拿不准就用 mutex，它会在合适的时候让出（"先自旋一下再睡眠"的混合策略正是多数 mutex 的实现）。

**`std::atomic<std::shared_ptr<T>>`**（C++20）认识一下：指针连同引用计数**整体原子替换**，读者 load 到的要么是完整旧快照、要么是完整新快照——28.7 说的"写者造新快照、原子换指针"的正规实现（示例里用特性宏探测，标准库没提供就跳过——atomic_flag 之外连 atomic 都不保证免锁，这个特化内部多半也是加锁的，但语义是原子的）。

真正的**无锁数据结构**（无锁栈/队列/链表）是 CAS + 内存回收 + ABA 问题的深水区——ABA 指"值从 A 变 B 又变回 A，CAS 察觉不到中途的变化"，工业级解法要带版本号或用 hazard pointer。本教程的边界：会 CAS 循环、懂自旋锁的适用面；无锁结构用成熟库（TBB folly 的 MPMC 队列）而不是手写。

## 29.4 latch：一次性发令枪

```cpp
constexpr int workers = 4;
std::vector<long long> partial(workers, 0);
std::latch go{1};  // 单格闩：主线程 count_down 后全员放行
std::vector<std::jthread> team;
for (int w = 0; w < workers; ++w) {
    team.emplace_back([&, w] {
        go.wait();  // 等发令枪
        for (int i = w * 250'000 + 1; i <= (w + 1) * 250'000; ++i) {
            partial[w] += i;  // 各写各的槽位：无竞争
        }
    });
}
go.count_down();  // 砰！
for (auto& t : team) {
    t.join();
}
long long total = std::accumulate(partial.begin(), partial.end(), 0LL);
// 分段总和 = 500000500000
```

`std::latch`（C++20）是**倒计数门闩**：构造给 N 格，`count_down()` 减一格，`wait()` 堵到归零——**一次性**（归零即永开，不能重置）。两个经典用法：发令枪（N=1，如示例——四段求和同时起跑，测的是"公平起跑"）；全员到齐（N=workers，主线程 wait 到大家就位）。

这个示例还藏着并行计算的标准分工模式：**各写各的槽位**（`partial[w]` 每个 worker 独占一格，零竞争零锁），最后主线程归并——比"共享一个总和上锁/原子"快得多（无争用、无原子总线流量）。

## 29.5 barrier：可复用的集合点

```cpp
std::vector<int> slots{1, 2, 3, 4};
std::barrier phase_done{4};  // 可复用：每轮全员到齐才进下一轮
std::vector<std::jthread> team;
for (int w = 0; w < 4; ++w) {
    team.emplace_back([&, w] {
        for (int round = 0; round < 2; ++round) {
            slots[w] *= 10;
            phase_done.arrive_and_wait();  // 本轮干完，等全体到齐
        }
    });
}
// 两轮后: 100 200 300 400
```

`std::barrier`（C++20）= latch 的循环赛版：`arrive_and_wait()` 到齐自动放行**并重置**，进入下一轮。多阶段流水（迭代算法、逐帧仿真）的分阶段同步就是它。与 latch 的分工：**一次性用 latch，多轮用 barrier**。

## 29.6 信号量：名额与容量

`std::counting_semaphore`（C++20）管的是**计数名额**：`acquire()` 占一个（不够就等）、`release()` 还一个。与 mutex 的本质差别：**不绑定身份**（谁都能 release，不必是锁它的人）、**有记忆**（没人等时 release，名额留着——下一次 acquire 直接过；条件变量的 notify 没人听就丢了）。`binary_semaphore` 是 `counting_semaphore<1>` 的别名，常当"一次性信号灯"用。

经典用法是**有界缓冲**（生产者-消费者的容量版）——示例 29.6 实测：2 格缓冲过 10 件货：

```cpp
std::counting_semaphore<2> empty_slots{2};   // 空位数：初始 2 格全空
std::counting_semaphore<2> filled_slots{0};  // 有货数：初始 0
std::mutex buffer_mtx;                       // 缓冲本体仍归 mutex 管
std::queue<int> buffer;

// 生产者
empty_slots.acquire();               // 先占空位（满了等消费者腾）
{ std::lock_guard lock{buffer_mtx}; buffer.push(i); }
filled_slots.release();              // 宣布有货

// 消费者（镜像）
filled_slots.acquire();              // 等货（空了等生产者投）
{ std::lock_guard lock{buffer_mtx}; v = buffer.front(); buffer.pop(); }
empty_slots.release();               // 腾出空位
```

一对信号量管"容量在两侧摆动"，mutex 只管缓冲数据结构本身——职责干净地分开了。同族还有 `try_acquire()`（非阻塞）与 `try_acquire_for(50ms)`（限时）——给"等不到就降级/报错"的场景留的逃生口。

## 29.7 并行算法：execution::par

```cpp
std::vector<int> big(1'000'000, 1);
std::atomic<long long> par_sum{0};
std::for_each(std::execution::par, big.begin(), big.end(),
              [&](int v) { par_sum += v; });  // par_sum = 1000000
```

C++17 起，STL 算法带**执行策略**参数（`<execution>`）：`std::execution::par` 让 for_each/sort/count_if 等自动分核并行，一行改写。三大纪律：

- **谓词必须线程安全**（会被多线程同时调）——本例累加必须走 atomic 而不是裸 `long long`；
- `par` 版对异常、对迭代器类别有要求（forward 以上）；
- 小数据量别加 par（线程分派开销比串行还贵）——**先 seq 后测，有量再 par**。

`par_unseq`（向量化的无序执行）认识名词即可。这是"不写线程代码的并行"——把并行决策交给库，是并发的最高性价比形态。

**但"交给库"意味着结果不由你定。** `par` 的语义是"**允许**并行"，不是"保证并行"——标准允许实现直接串行跑完（只要语义对）。macOS 上实测就是这样（2026-09-17）：

| 实现 | `par` 的表现 |
|---|---|
| 系统自带 Apple clang 14（libc++ 14000） | `<execution>` 里**根本没有 `par`**（`no member named 'execution' in namespace 'std'`） |
| MacPorts `clang++-mp-23` + `-fexperimental-library` | 能编能跑，但**退化成串行** —— 该 libc++ 选的后端是 `_LIBCPP_PSTL_BACKEND_STD_THREAD`，而 libc++ 的 `backends/std_thread.h` 是**桩实现**（头文件自己写着 "for testing purposes only"），其 `__for_each` 只在当前线程跑完 |

测法是**在并行算法体里数线程 id**（`std::this_thread::get_id()` 记进加锁的 `std::set`，最后看有几个不同 id）：`for_each(par)`/`transform(par)`/`sort(par)`/`reduce(par)`/`reduce(par_unseq)` 五条、400 万元素，全部只有 **1 个线程**（`hardware_concurrency = 4`）。

所以：**要真并行就自己开线程**（本章 29.1–29.5 就是），`par` 当"可以一行改写的语义糖"来用；换平台前实测一把再决定要不要依赖它。本章 29.7 的示例只断言 `par_sum == 1000000`，不依赖线程数——两条编译通道输出逐字节一致，正是因为这里没赌实现行为。

## 29.8 任务：async 与 future——线程的高层替身

线程（第 28 章）与任务（`<future>`）是并发的两种姿势，**任务 = 返回值通道 + 自动同步**：

| | 线程 | 任务 |
|---|---|---|
| 传结果 | 共享变量 + 自己加锁 | **future.get() 直取**（通道自带保护） |
| 等完成 | `join()` | `fut.get()`（阻塞到值就位） |
| 出异常 | 线程内抛出 → **整个进程 terminate** | 异常存进通道，get() 时**在调用方重抛** |
| 适用 | 长生命期、循环型工作 | "算个值，回头取"的一次性工作 |

```cpp
auto fut = std::async(std::launch::async, [] { return 2000 + 11; });
int result = fut.get();          // 2011——get 阻塞到结果就位
```

`std::async` 像异步函数调用：接收可调用与参数，返回 `std::future<T>` 句柄。启动策略：`std::launch::async`（立刻新线程）、`std::launch::deferred`（**惰性**——get() 时才在当前线程执行）、默认 `async|deferred`（运行时自选）。

任务一族还有两个：**`std::promise`/`std::future`** 是裸的数据通道（promise `set_value` 投递、future `wait`/`get` 接收，可跨线程当条件变量的安全替代）；**`std::packaged_task`** 把可调用打包成"稍后执行、经 future 取果"的包装（能装进容器批量调度——29.9 的线程池就是这么用的）。层级关系：async 是"打包 + 调度"全代办的最高层。

**async 最大的坑**：`std::async(...)` 的返回值 future **必须接住**——临时 future 一析构就**阻塞等待任务跑完**，`std::async(f);`（丢弃返回值）实际是同步调用，还白白开了线程。

通道还有两个常用细节：

- **`shared_future`**：`fut.share()` 之后可以被多次 get（多个消费者等同一个值）——普通 future 的 get 是"取走"语义，第二次是 UB；
- **`wait_for(50ms)`**：限时等待，返回 ready/timeout/deferred。示例实测用它验证"沉默的通道 50ms 必然超时"——顺手撞出一个冷知识：**promise 析构本身也算投递**，孤儿 future 立刻变 ready，get() 抛 `future_error`（broken_promise）。想让 wait_for 真超时，promise 得活着。

## 29.9 线程池：并发工具箱的压轴组装

线程池解决"每个任务开一条线程太贵"的问题：**固定一组工人，共享一个任务队列**，任务提交与执行解耦——线程创建的开销摊薄到全部任务上，还能天然限流（工人就 N 个）。CiA 把它放在"高级线程管理"，Joshi 用了整章——但核心实现就 30 行，前面所有章节的工具刚好各就各位：

```cpp
class ThreadPool {
public:
    explicit ThreadPool(int workers) {
        for (int i = 0; i < workers; ++i) {
            workers_.emplace_back([this] {
                for (;;) {
                    std::function<void()> job;
                    {
                        std::unique_lock lock{jobs_mtx_};
                        jobs_cv_.wait(lock, [this] { return stopping_ || !jobs_.empty(); });
                        if (stopping_ && jobs_.empty()) return;
                        job = std::move(jobs_.front());
                        jobs_.pop();
                    }
                    job();               // 锁外执行：任务爱跑多久跑多久
                }
            });
        }
    }
    ~ThreadPool() {
        { std::lock_guard lock{jobs_mtx_}; stopping_ = true; }
        jobs_cv_.notify_all();
        for (auto& w : workers_) w.join();
    }
    std::future<int> submit(std::function<int()> f) {
        // packaged_task 只能移动，而 function 要求可拷贝——藏进 shared_ptr 再包
        auto task = std::make_shared<std::packaged_task<int()>>(std::move(f));
        std::future<int> receipt = task->get_future();
        { std::lock_guard lock{jobs_mtx_}; jobs_.emplace([task] { (*task)(); }); }
        jobs_cv_.notify_one();
        return receipt;
    }
private:
    std::vector<std::jthread> workers_;   // 若靠 jthread 自动收尾，它必须是最后声明的成员
    std::queue<std::function<void()>> jobs_;
    std::mutex jobs_mtx_;
    std::condition_variable jobs_cv_;
    bool stopping_ = false;
};
```

逐件对账：工人是 **jthread**（28.2）、取货靠 **条件变量 + 谓词**（28.5 的 while 循环正是 wait 谓词版的手写展开）、结果走 **packaged_task + future**（29.8）、异常经通道在调用方重抛（29.8）。两个实现要点：

- **`job()` 在锁外执行**——任务里跑什么、跑多久都不该堵住别的工人取货（28.3"临界区越小越好"的并发版）；
- **成员声明顺序是生死攸关的**：成员按声明的**逆序**析构，若不写析构里的显式 join 而指望 jthread 自动收，`workers_` 必须是**最后**声明的成员——否则队列和条件变量先死，工人们还在摸已经不存在的锁。示例在析构里显式 join（顺便把"排干队列再退"的语义写明白），双重保险。

示例 29.9 实测：3 个工人接 6 个"算平方"的任务，**按提交顺序收货**（future.get() 的顺序决定输出顺序，与哪个工人先抢到任务无关——输出确定性就是这么保住的）；再投一个会抛异常的任务，异常从 worker 线程穿过通道在主线程被 catch。

池的进一步演化（认识名词即可）：**work stealing**（每工人自己的本地队列，闲的从别人队尾偷活，负载均衡）、**优先级队列**（高优先级插队，同优先级内用序号保 FIFO 防饿死）、**动态伸缩**（按利用率加减工人）。以及 29.7 说过的心法：`std::async` 没有提供"在哪个池上跑"的参数——想要可控的池，就得像这样自己造。

## 29.10 坑位清单

1. **复合操作误用 atomic**：`if (a.load() == 0) a.store(1);` 两步之间存在窗口——"检查再设置"要用 CAS 循环（29.3 的骨架：`int expected = 0; while (!a.compare_exchange_weak(expected, 1)) {}`）。
2. **内存序乱用**：非默认序是给实现锁/无锁结构的人用的。业务代码一律默认；白名单是纯计数 relaxed 与看得懂的 acquire/release 配对。
3. **par 算法里加锁**：每元素抢一把 mutex，并行白干还退化。并行段内用 atomic 或分块私有化（29.4 模式）。
4. **latch/barrier 计数写错**：N 对不上（某线程没 arrive）→ 永久等待。用 `arrive_and_wait` 的地方别只写 `wait`。
5. **false sharing（伪共享）**：两个线程各写各自变量，但变量在同一缓存行（64 字节）→ 缓存线乒乓，性能塌方。分块写入（29.4 的 partial 切法天然规避）比交错写（`partial[i * stride]`）友好——深优化的冷知识，遇到"多线程反而变慢"先想起它。
6. **atomic 不是免费的 vector**：`std::atomic<std::vector<int>>` 不存在（不可平凡拷贝）。容器并发要用锁或线程私有+归并。
7. **丢弃 async 的 future**：临时 future 析构时阻塞等任务完——`std::async(f);` 变伪装的同步调用。永远 `auto fut = std::async(...)`。
8. **future.get() 调两次**：get 是"取走"语义，第二次调 UB（shared_future 才可多次）——get 过的 future 只剩析构一件事可做。
9. **promise 死了 future 还在等**：promise 析构会向通道投递 broken_promise——future 立即就绪，get() 抛 future_error（示例实测）。「永远等不到」的通道不存在；wait_for 想真超时，promise 必须活着。
10. **信号量当 mutex 用**：semaphore 不绑身份、release 可以来自任何线程——配对出错就是超发名额。护数据用 mutex，管名额/容量才用 semaphore。
11. **自旋锁套长临界区**：核少/临界区长时自旋烧 CPU 还不如 mutex；单核机器上自旋等待者甚至可能挡住持锁者运行。默认 mutex，测量后才换自旋。
12. **线程池成员顺序**：靠 jthread 自动 join 的池，workers_ 必须最后声明（成员逆序析构）——否则工人摸已死的锁。显式 join 是更稳的写法。
13. **任务输出顺序当线程执行顺序**：池的输出确定性来自"按 future 收货"，不是"任务恰好按序跑"。要顺序就按提交序收，别指望调度。

---

上一章：[28 并发 I](28-threads.md) · 下一章：[30 协程](30-coroutines.md)
