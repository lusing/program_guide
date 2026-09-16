# 20 · 并发 II：原子操作与同步原语

> 对应示例：`examples/20_atomic/`

## 20.1 atomic：免锁的原子计数

```cpp
std::atomic<long long> hits{0};

void click(int times) {
    for (int i = 0; i < times; ++i) {
        hits.fetch_add(1, std::memory_order_relaxed);  // 计数不需要同步序
    }
}
// 4 线程 × 100'000 → hits = 400000（assert 验证）
```

第 19 章用 mutex 保住了 `++counter`，但"一个整数的读改写"其实有更轻的武器：`std::atomic<T>` 的 `fetch_add` 是**单条原子指令**（lock xadd），不可分割、无锁、比 mutex 快一个量级（mutex 要进内核或 CAS 循环）。四线程十万次累加，atomic 版实测轻松跑赢。

选型决策表（上一章欠的账）：

| 场景 | 武器 |
|---|---|
| 单个数值/指针/标志的读改写 | **atomic** |
| 复合不变量（多个变量要一起变） | **mutex** |
| "等条件成立再继续" | 条件变量 / latch / barrier |
| 限流 N 个并发 | semaphore |

`operator` 糖也认一下：`hits += 1` / `++hits`（fetch_add）、`hits.load()`（读）、`hits.store(x)`（写）。**读写都要走 atomic** 才算数——一边 atomic 一边裸读，竞争照旧。

## 20.2 内存序：点到为止的一节

`fetch_add(1, std::memory_order_relaxed)` 尾巴上那串是什么？**内存序（memory order）**——多核各自缓存的重排规则。CPU 和编译器都会重排指令（性能命脉），内存序约定"哪些重排不许越过哪些操作"：

| 序 | 含义 | 用于 |
|---|---|---|
| `relaxed` | 只保证**本操作原子**，不管顺序 | 计数器、统计 |
| `acquire/release` | 配对建立"先行发生"（发布/获取） | 锁的实现、标志位通知 |
| `seq_cst`（默认） | 全局总序，最直观也最保守 | 拿不准时的默认 |

本教程的立场只有一句：**不懂就写默认（不标内存序）**。默认 seq_cst 最多慢一点，永远正确；手写非默认序一旦理解有偏差，就是极难复现的并发 bug。relaxed 计数器是"确定只数数、不护别的数据"时的白名单例外。

## 20.3 latch：一次性发令枪

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

## 20.4 barrier：可复用的集合点

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

同家族的 `std::counting_semaphore`/`binary_semaphore`（C++20）认识即可：限制"N 个并发名额"（连接池上限 5、生产者-消费者的缓冲区容量）——`acquire()` 占名额、`release()` 还名额。

## 20.5 并行算法：execution::par

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

## 20.6 坑位清单

1. **复合操作误用 atomic**：`if (a.load() == 0) a.store(1);` 两步之间存在窗口——"检查再设置"要用 `compare_exchange_weak`（CAS 循环骨架：`int expected = 0; while (!a.compare_exchange_weak(expected, 1)) {}`）。
2. **内存序乱用**：非默认序是给实现锁/无锁结构的人用的。业务代码一律默认；唯一白名单是纯计数的 relaxed。
3. **par 算法里加锁**：每元素抢一把 mutex，并行白干还退化。并行段内用 atomic 或分块私有化（20.3 模式）。
4. **latch/barrier 计数写错**：N 对不上（某线程没 arrive）→ 永久等待。用 `arrive_and_wait` 的地方别只写 `wait`。
5. **false sharing（伪共享）**：两个线程各写各自变量，但变量在同一缓存行（64 字节）→ 缓存线乒乓，性能塌方。分块写入（20.3 的 partial 切法天然规避）比交错写（`partial[i * stride]`）友好——深优化的冷知识，遇到"多线程反而变慢"先想起它。
6. **atomic 不是免费的 vector**：`std::atomic<std::vector<int>>` 不存在（不可平凡拷贝）。容器并发要用锁或线程私有+归并。
