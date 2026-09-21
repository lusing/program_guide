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

运行输出（`thread.cpp`，打印全部经 join 定序，输出确定）：

```text
  工作线程跑在另一个核上
  7 的平方 = 49
  长任务被外部中断（std::thread 做不到）
  条件满足， waiter 继续
  jthread 收到 stop_request，自行退出
自检通过
```

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
