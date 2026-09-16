# 19 · 并发 I：线程与锁

> 对应示例：`examples/19_threads/`

## 19.1 心智模型：并发、并行与数据竞争

**并发**（concurrency）= 任务在时间上交错推进；**并行**（parallelism）= 任务在多核上同时跑。多线程代码两者都占：写并发结构，机器并行执行。

一切纪律的源头是**数据竞争（data race）的定义**：两个线程同时访问同一内存位置、至少一个是写、且无同步——**程序瞬间进入未定义行为**。不是"可能算错"，是编译器优化可以把整个程序变成任何东西。并发正确性的全部工作，就是保证"共享可变状态的每次访问都被同步住"。

什么时候值得多线程：**IO 密集**（等待重叠——网络请求不必排队）与 **CPU 密集**（分核计算）。单线程毫秒级的活，加线程纯增复杂度——**先测量再并发**（第 24 章实战会真用上这笔账）。

## 19.2 jthread 与协作式取消

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

`std::jthread`（C++20）= thread + 两个救命默认：**析构自动 join**（老 std::thread 析构时没 join 直接 std::terminate——无数崩溃的来源）、**内置 stop_token 协作取消**。新代码一律 jthread，没有理由再裸用 thread。

**为什么"停止"是请求而不是强杀**：线程可能在持锁/半写状态，外部强杀（如老平台的 TerminateThread）会留下毒死的锁和撕烂的数据。协作式取消 = 主线程 `request_stop()`（把 flag 置位），工作线程**自己选择安全的位置**检查 `st.stop_requested()` 后退出。取消点放在循环头部/长任务边界。

## 19.3 mutex 与 lock_guard：保护共享数据

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

四线程各加十万次，没有锁会怎样？实测不会是 40 万——`++counter` 是"读-改-写"三步，两个线程交错执行就互相覆盖（丢更新）。`std::mutex` 是互斥量：一次只放一个线程进去。**`std::lock_guard`（RAII）**负责加锁/解锁的配对——函数无论怎么退出（return/异常）锁都会释放，第 08 章的心法直接迁移到并发。

设计观：**锁保护的是数据，不是代码段**。想清楚"这把锁守卫哪个变量"，守卫范围（临界区）越小越好——锁里只放必须原子的一小段，慢活（IO、打印）搬出去。

## 19.4 条件变量：等通知的正式姿势

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

## 19.5 死锁：双锁的顺序陷阱

两个线程各持一把锁、互相等对方的那把——永久卡死。事故构造（认识长相，示例未真跑）：

```cpp
// 线程 A                     // 线程 B
lock(mtx1);                   lock(mtx2);
lock(mtx2);  // 等 B 放       lock(mtx1);  // 等 A 放 → 死锁
```

三道防线任选其一：**全局锁序**（所有代码按同一顺序拿锁——mtx1 永远先于 mtx2）；**std::scoped_lock`**（C++17）一次锁多把，内部用死锁避免算法：`std::scoped_lock both{mtx1, mtx2};`；**尽量单锁**（重新划分数据，让一把锁管完）。临界区里调用"未知代码"（回调、虚函数）是死锁温床——锁里只做确定的事。

## 19.6 坑位清单

1. **忘 join/detach**：std::thread 析构时仍 joinable → terminate。jthread 免疫此坑——这是它存在的理由。
2. **锁里调未知代码**：回调再拿别的锁→死锁，或慢函数拖长临界区。锁内只碰已知数据。
3. **条件变量裸 wait**：虚假唤醒+错过 notify（先改条件后 wait 的窗口）。谓词版 wait 一站解决。
4. **按引用捕获局部变量给线程**：`[&]` 捕的变量函数返回就死，线程还在用——悬垂。传值捕获或用 jthread 参数按值传。
5. **detach 的滥用**：detach 后线程生死不可知，清理顺序无保证——教程立场：**不 detach**，要么 join 要么让 jthread 管。
6. **以为 atomic 一把梭**：下一章展开——atomic 单变量够用，**复合不变量仍要锁**（"a==b"两个变量各自 atomic 也不行）。
