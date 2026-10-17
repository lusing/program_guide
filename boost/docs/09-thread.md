# 09 · 多线程第一课：Boost.Thread

> 对应示例：`examples/09_thread/thread.cpp`

Boost.Thread（2003）在 C++ 没有任何线程支持的年代提供了跨平台并发原语，2005 年进 TR1、2011 年毕业为 `std::thread` 全家（thread/mutex/future/async）。它是"Boost 影响标准"路线图上最重要的一站——**现代 C++ 并发的整个词汇表都是它定型的**。

## 9.1 基本面 + 独门绝技：外部中断

```cpp
boost::thread worker([] { ... });       // launch
worker.join();                          // 等待

// 独门：std::thread 做不到的外部取消
sleeper.interrupt();                    // 主线程发起
boost::this_thread::interruption_point();  // 工作线程在安全点检查
// → 抛 boost::thread_interrupted，栈正常展开（RAII 全部生效）
```

运行输出（`thread.cpp`）：

```text
  工作线程跑在另一个核上
  7 的平方 = 49
  长任务被外部中断（std::thread 做不到）
  条件满足， waiter 继续
  jthread 收到 stop_request，自行退出
  硬件并发数 = 20（0 表示探测失败）
  thread_guard<detach> 析构时 detach（不等待）
  at_thread_exit：线程退出前执行登记的清理
  call_once：初始化只发生一次
  有界缓冲(容 2)生产 6 消费 6 无丢失（最后一批 = 6）
  线程组 4 线程合计 = 40
自检通过
```

输出后六行是书 ch12.2 后半的进阶件：**`hardware_concurrency()`** 问可并发线程数（探测失败给 0）；**`thread_guard<策略>`**——析构时按策略处理线程（`join_if_joinable` 默认 / `detach`），比 jthread 的"只会 join"多一档选择；**`at_thread_exit(f)`** 登记线程退出前的清理钩子（线程被强杀或进程 exit 时不会调用）；**`call_once`**——多线程只初始化一次（**实测坑：`boost::once_flag` 必须 `BOOST_ONCE_INIT` 初始化**，裸默认构造的静态对象在 Windows 上内部状态未清零，call_once 永久卡死；std::once_flag 没这个问题）；**有界缓冲区**是条件变量的正典用法（书 buffer 例的骨架）；**`thread_group`** 批量 create/join——简版线程池。

> 实测坑（死锁排查实录）：第一版有界缓冲写成"覆写式单槽 + 容量 2"——生产者会在消费者取走前覆写未消费的货，货品丢失 → 消费者最后一趟永远等不到货 → 死锁，六条判定里报"超过 60 秒未结束"。正典写法是**计数**（放货 +1 / 取货 -1，容量约束作用在计数上），谁也不覆盖谁。排查路径：最小复现 → 换 std 原语（排除库问题）→ 逐步收窄到逻辑本身。


**中断的设计哲学**：不是 kill（不安全），是"在检查点抛异常"——异常安全的老传统直接迁移到线程取消。C++20 把这套语义标准化为 `std::jthread` + `std::stop_token`（协作取消），思想完全同源：

```cpp
std::jthread jt([](std::stop_token st) {
    while (!st.stop_requested()) { ... }   // 检查点
});
jt.request_stop();                          // = boost 的 interrupt()
// 析构自动 join —— jthread 的 j 就是 RAII
```

## 9.2 同步原语

例程覆盖了 `mutex` + `condition_variable` 的等待/通知模式（带谓词的 `cv.wait(lk, pred)` 防虚假唤醒）。Boost.Thread 还有一批 std 没有或很晚才有的件：`shared_mutex`（读写锁，C++17 毕业）、`barrier`/`latch`（C++20 毕业）、`fiber` 相关入口（第 16 章）。

## 9.3 毕业档案

| | |
|---|---|
| **std 对应** | `<thread>`/`<mutex>`/`<condition_variable>`/`<future>`（C++11），`shared_mutex`（C++17），`jthread`/`stop_token`/`semaphore`/`latch`/`barrier`（C++20） |
| **血缘** | 直系（词汇表级影响） |
| **std 没收的** | 外部中断（`interrupt`/`interruption_point`）——最接近的 std 是协作式 stop_token，语义弱一档 |

> **实测坑（重要）**：`boost/thread.hpp` 伞形头会拉进 `future.hpp`，后者在 `/std:c++latest`（C++26 草案档，MSVC 19.51）下直接语法冲突编不过。绕法：用细分头（`thread.hpp`/`mutex.hpp`/`condition_variable.hpp`），future 用 std。老库撞上新语言档的典型现场。

**2026 选型**：并发新代码全部 std（`std::jthread` 是默认答案）；boost 版仅维护老代码时出现。

---


> 上一章：[08 · 无序与哈希](08-unordered.md) ｜ 下一章：[10 · 原子操作](10-atomic.md) ｜ 返回：[README](../README.md)
