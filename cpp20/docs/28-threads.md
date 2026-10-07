# 28 · 并发 I：线程与锁

> 对应示例：`examples/28_threads/`

## 28.1 心智模型：并发、并行与数据竞争

**并发**（concurrency）= 任务在时间上交错推进；**并行**（parallelism）= 任务在多核上同时跑。多线程代码两者都占：写并发结构，机器并行执行。

一切纪律的源头是**数据竞争（data race）的定义**：两个线程同时访问同一内存位置、至少一个是写、且无同步——**程序瞬间进入未定义行为**。不是"可能算错"，是编译器优化可以把整个程序变成任何东西。并发正确性的全部工作，就是保证"共享可变状态的每次访问都被同步住"。

什么时候值得多线程：**IO 密集**（等待重叠——网络请求不必排队）与 **CPU 密集**（分核计算）。单线程毫秒级的活，加线程纯增复杂度——**先测量再并发**（第 35 章实战会真用上这笔账）。

## 28.2 jthread 与协作式取消

```cpp
std::jthread worker{[](std::stop_token st) {
    while (!st.stop_requested()) {
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    std::println("worker：收到停止请求，退出");
}};
std::this_thread::sleep_for(std::chrono::milliseconds(30));
worker.request_stop();  // jthread 析构时自动 join
```

`std::jthread`（C++20）= thread + 两个救命默认：**析构自动 join**（老 std::thread 析构时没 join 直接 std::terminate——无数崩溃的来源）、**内置 stop_token 协作取消**。新代码一律 jthread，没有理由再裸用 thread。（`sleep_for` 吃的是 chrono duration——`5ms` 字面量等时间工具在第 31 章。）

**为什么"停止"是请求而不是强杀**：线程可能在持锁/半写状态，外部强杀（如老平台的 TerminateThread）会留下毒死的锁和撕烂的数据。协作式取消 = 主线程 `request_stop()`（把 flag 置位），工作线程**自己选择安全的位置**检查 `st.stop_requested()` 后退出。取消点放在循环头部/长任务边界。

## 28.3 mutex 与 lock_guard：保护共享数据

```cpp
std::mutex counter_mtx;
long long counter = 0;

void bump(int times) {
    for (int i = 0; i < times; ++i) {
        std::lock_guard lock{counter_mtx};  // RAII 锁：构造即加，析构即解
        ++counter;
    }
}
// 4 线程 × 100'000 次 → counter = 400000（assert 验证）
```

四线程各加十万次，没有锁会怎样？实测不会是 40 万——`++counter` 是"读-改-写"三步，两个线程交错执行就互相覆盖（丢更新）。`std::mutex` 是互斥量：一次只放一个线程进去。**`std::lock_guard`（RAII）**负责加锁/解锁的配对——函数无论怎么退出（return/异常）锁都会释放，第 11 章的心法直接迁移到并发。

设计观：**锁保护的是数据，不是代码段**。想清楚"这把锁守卫哪个变量"，守卫范围（临界区）越小越好——锁里只放必须原子的一小段，慢活（IO、打印）搬出去。

## 28.4 锁的全家福：lock_guard / unique_lock / scoped_lock / shared_lock

四种 RAII 锁各管一摊，按需选型：

| 锁 | 特长 | 适用 |
|---|---|---|
| `lock_guard` | 最轻：构造加锁、析构解锁，别无所求 | 绝大多数临界区 |
| `unique_lock` | 可中途 unlock/再 lock、可移动转移、能限时试锁 | 条件变量的 wait；需要"先造对象后上锁" |
| `scoped_lock` | **一次锁多把**，内部死锁避免算法 | 要同时碰两把锁的数据 |
| `shared_lock` | 上的是**共享**锁（读锁），配 shared_mutex | 读多写少场景（28.7） |

`unique_lock` 的三段用法（示例 28.4 实测）：

```cpp
std::unique_lock deferred{m, std::defer_lock};  // 先造锁对象、先不上锁
deferred.try_lock();                            // 非阻塞试锁（争不到立刻回 false）
std::unique_lock timed{tm, std::defer_lock};    // tm 是 std::timed_mutex
timed.try_lock_for(100ms);                      // 限时等锁：普通 mutex 没有这个接口
```

**defer_lock 的用武之地**：锁的持有顺序要运行时才定得下来（比如"两边都要锁，先锁余额小的那个"）；或者锁住之前还要做点准备工作。`owns_lock()` 随时查状态。`unique_lock` 还能**移动**——把"持有这把锁"的事实当作返回值交接给上一层（`scoped_lock` 不行）。

**timed_mutex 是独立类型**：想要 `try_lock_for`/`try_lock_until` 得一开始就用 `std::timed_mutex`——普通 `std::mutex` 只有非阻塞的 `try_lock`。这是"超时能力不是白来的"在类型系统里的体现。

锁的**粒度**是设计问题不是语法问题：太粗（一把大锁管全部）并行度归零，太细（满地小锁）死锁与遗漏齐飞。经验起点：**一个不变量一把锁**——哪些数据必须"一起变"，就共用同一把锁。

## 28.5 条件变量：等通知的正式姿势

```cpp
std::queue<int> channel;
std::mutex channel_mtx;
std::condition_variable cv;
bool done = false;

void producer(int count) {
    for (int i = 1; i <= count; ++i) {
        {
            std::lock_guard lock{channel_mtx};
            channel.push(i);
        }
        cv.notify_one();
    }
    {
        std::lock_guard lock{channel_mtx};
        done = true;
    }
    cv.notify_all();
}

int consume_all() {
    int sum = 0;
    while (true) {
        std::unique_lock lock{channel_mtx};
        cv.wait(lock, [] { return !channel.empty() || done; });  // 谓词防虚假唤醒
        while (!channel.empty()) {
            sum += channel.front();
            channel.pop();
        }
        if (done) {
            break;
        }
    }
    return sum;  // 1+2+…+10 = 55
}
```

生产者-消费者是并发世界的 Hello World。`std::condition_variable` 解决"消费者如何等货"：`wait(lock, 谓词)` 原子地"解锁+睡眠"，被 notify 后醒来、**重新加锁、再检查谓词**。三个必背细节：

- **谓词不可省**：没有谓词的裸 `wait` 会被**虚假唤醒**（spurious wakeup，OS 允许无理由叫醒你）坑到——谓词循环是官方姿势，本例 `!channel.empty() || done`；
- **改条件前先拿锁**：producer 在锁内改 channel/done，锁外 notify（notify 不需要锁，锁内 notify 是性能浪费）；
- **结束要有协议**：`done` 标志让消费者知道"不会再有货了"，否则永远等——生产者收尾 notify_all 唤醒所有等待者。

`unique_lock` 比 lock_guard 贵一点但支持中途解锁——condition_variable 的 wait 需要这种控制力，这是它俩的分工线。

**可中断的等待**：`std::condition_variable_any`（任何锁类型都能配的万能版）有一个独门重载——wait 挂上 stop_token，**stop 一请求就醒**，不需要任何人 notify：

```cpp
std::condition_variable_any cv_any;
std::jthread sleeper{[&](std::stop_token st) {
    std::unique_lock lock{m};
    bool stopped = cv_any.wait(lock, st, [] { return false; });  // 谓词恒假：只有 stop 能唤醒
    // stopped == true
}};
sleeper.request_stop();  // 睡着的线程立刻醒来退出
```

后台线程"睡到有活干或被取消"的正式写法——老代码里手搓 bool 标志 + notify_all 的补丁可以退役了。

## 28.6 死锁：双锁的顺序陷阱

两个线程各持一把锁、互相等对方的那把——永久卡死。事故构造：

```cpp
// 线程 A                     // 线程 B
lock(mtx1);                   lock(mtx2);
lock(mtx2);  // 等 B 放       lock(mtx1);  // 等 A 放 → 死锁
```

三道防线任选其一：**全局锁序**（所有代码按同一顺序拿锁——mtx1 永远先于 mtx2）；**std::scoped_lock**（C++17）一次锁多把，内部用死锁避免算法；**尽量单锁**（重新划分数据，让一把锁管完）。临界区里调用"未知代码"（回调、虚函数）是死锁温床——锁里只做确定的事。

示例 28.6 实测的正是第二道防线：**两个账户对向转账**，线程 1 锁 (a, b)、线程 2 锁 (b, a)——顺序完全相反，靠 scoped_lock 一次拿两把，500 笔对冲转账跑完总额分毫不动：

```cpp
void transfer(Account& from, Account& to, long long amount, int times) {
    for (int i = 0; i < times; ++i) {
        std::scoped_lock both{from.m, to.m};  // 不分先后，一把抓
        from.balance -= amount;
        to.balance += amount;
    }
}
```

更深的防线是**设计层面**：定义锁的层级（"持有上层锁时不许再去拿下层锁"）、限制每线程同时至多持一把锁、把接口设计成不需要两把锁（第 14 章提过的"用值传递换掉共享"）。这些纪律在代码评审里比在调试器里便宜得多——死锁不崩溃、不报错，只是安安静静地挂死。

## 28.7 读写锁：shared_mutex，读共享、写独占

一份数据**读远多于写**（配置表、路由表、缓存）时，普通 mutex 太浪费：读和读之间根本没有冲突，却被拦成单行道。`std::shared_mutex`（C++17）提供两档锁：

- **写者**走老路：`std::unique_lock` 独占，谁都不许进；
- **读者**走新档：`std::shared_lock` 共享，**多个读者可以同时持有**。

```cpp
class Table {
public:
    void rewrite() {                      // 写者：独占
        std::unique_lock writer{mtx_};
        for (int& v : data_) v *= 2;
    }
    long checksum() const {               // 读者：共享，可多读者同进
        std::shared_lock reader{mtx_};
        /* 累加 data_ */
    }
private:
    mutable std::shared_mutex mtx_;
    std::vector<int> data_{1, 2, 3};
};
```

示例 28.7 的验证思路：写者整表翻倍 10 次，4 个读者各取 100 次快照——每次读到的必须是一个**合法的完整快照**（6×2^k），任何撕裂值都过不了 assert。读写锁的正确性就是这么验的：不验"读者并发了几个"（那是性能），验"读到的从来不是半成品"（这才是正确性）。

三个使用注意：

- **读多写少才值得**：shared_mutex 自己更贵（要簿记读者数），写多读少时反而比 mutex 慢；
- **写者可能饿死**：读者源源不断地共享进，写者可能一直等不到独占的机会——标准不规定公平策略，读侧压大时要测；
- **不能递归上读锁**：同一线程锁两次 shared 是自找死锁——这不是 recursive_mutex。

进阶姿势是**双检缓存**（先 shared 快查，未命中换 unique 慢造，造之前再查一遍——两个线程可能同时都未命中），以及用 shared_mutex 保护 `shared_ptr` 指向的**不可变快照**（写者造新快照、原子换指针，读者拿旧快照随便用）——后者正是 29 章 atomic\<shared_ptr\> 的用武之地。

## 28.8 初始化的线程安全：call_once、magic static 与 thread_local

三个"看着要竞争、其实标准已经护住"的位置：

**一次性初始化**用 `std::call_once`：多个线程同时首调，标准保证函数体只执行一次、其余线程等它完成：

```cpp
std::once_flag flag;      // 和 call_once 配对的标志位
int init_runs = 0;
// 4 个线程都执行：
std::call_once(flag, [] { ++init_runs; });   // init_runs == 1
```

**局部 static 初始化**（magic static）自带同样的保证（C++11 起）：并发首调也只初始化一次——所以"函数内的 static 缓存"不需要再包 call_once，包了是白费：

```cpp
const std::vector<int>& magic_table() {
    static const std::vector<int> table = [] { /* 只跑一次 */ return std::vector<int>{1,2,3}; }();
    return table;
}
```

**每线程一份数据**用 `thread_local`：每个线程看到自己的实例，互不可见、天然无竞争：

```cpp
thread_local int tls_visits = 0;   // 4 线程各自加 100 次，无需任何锁
++tls_visits;                      // 加的是"我"的那份
```

经典用途：每线程的随机数引擎、缓存、累加器（先各自累加，最后一次性归并——29 章分段求和的 partial 槽位就是它的手稿）。注意 thread_local 变量**在线程结束时析构**，取它的地址传给别的线程是悬垂的开始。

顺带认识 `std::recursive_mutex`（同一线程可以重复加锁）——教程立场：它是**设计坏味道的止痛药**。需要递归锁，多半是"锁里调了自己也要锁的函数"，正确解法是收窄临界区、把"需要锁的部分"提成内部无锁的私有函数，而不是换一把更宽容的锁。

## 28.9 坑位清单

1. **忘 join/detach**：std::thread 析构时仍 joinable → terminate。jthread 免疫此坑——这是它存在的理由。
2. **锁里调未知代码**：回调再拿别的锁→死锁，或慢函数拖长临界区。锁内只碰已知数据。
3. **条件变量裸 wait**：虚假唤醒+错过 notify（先改条件后 wait 的窗口）。谓词版 wait 一站解决。
4. **按引用捕获局部变量给线程**：`[&]` 捕的变量函数返回就死，线程还在用——悬垂。传值捕获或用 jthread 参数按值传。
5. **detach 的滥用**：detach 后线程生死不可知，清理顺序无保证——教程立场：**不 detach**，要么 join 要么让 jthread 管。
6. **以为 atomic 一把梭**：下一章展开——atomic 单变量够用，**复合不变量仍要锁**（"a==b"两个变量各自 atomic 也不行）。
7. **unique_lock 与 lock_guard 混着选型**：wait 要 unique_lock（它要中途解锁）；普通临界区 lock_guard 更轻——不是"新一点的总更好"。
8. **普通 mutex 上调 try_lock_for**：编译错——限时等锁是 timed_mutex 的接口。要超时能力，类型先选对。
9. **同线程重复上读锁**：shared_mutex 的读锁不可递归——第二个 shared_lock 就可能永久等待。递归需求去查设计，别查锁。
10. **锁的全序没写下来**：多锁程序的"拿锁顺序"是团队约定，新人不知道就埋雷。scoped_lock 是机械防线，锁序文档是制度防线，两个都要。
11. **thread_local 的地址跨线程传**：每线程一份≠共享数据，把它的地址发给别的线程，人家读到的既不是你的也不是自己的。归并时传**值**。
12. **靠 recursive_mutex 掩盖锁粒度问题**：能重复进锁≠锁用对了。先把临界区收窄，递归锁留作最后手段。

---

上一章：[27 预处理器](27-preproc.md) · 下一章：[29 并发 II](29-atomic.md)
