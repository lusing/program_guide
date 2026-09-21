# 10 · 原子操作：Boost.Atomic

> 对应示例：`examples/10_atomic/atomic.cpp`

Boost.Atomic（2009）把 C++ 内存模型（C++11 才进语言）提前做成了库。`std::atomic` 是它的直系毕业生，连教学顺序都一样：先 RMW，再 CAS，再内存序。

## 10.1 三层递进

```cpp
// 1) RMW：读-改-写原子操作
boost::atomic<int> a{10};
a.fetch_add(5);                                  // +5，返回旧值

// 2) CAS：无锁数据结构的基石
int expected = 15;
a.compare_exchange_strong(expected, 20);         // 期望 15 就换成 20

// 3) 内存序：同步语义的刻度
a.store(100, boost::memory_order_relaxed);       // 只保原子性
ready.store(true, boost::memory_order_release);  // 发布
ready.load(boost::memory_order_acquire);         // 订阅
```

运行输出（`atomic.cpp`，计数与 CAS 结果全部确定）：

```text
fetch_add 前值 = 10 现值 = 15
CAS(15→20) 成功? true 现值 = 20
relaxed 读回 = 100
消费者看到 payload = 42（acquire/release 保证）
4 线程 ×10000 计数 = 40000（一个不丢）
double 原子 lock-free? true
std 版同构: 2
atomic_ref 作用后普通变量 = 7
自检通过
```

三个必懂的概念（例程逐一实证）：

1. **acquire/release 建立跨线程 happens-before**：生产者先写 `payload`（普通写）再 release-store `ready`；消费者 acquire-load `ready` 为真后，`payload == 42` **有保证**——这是所有"标志位 + 数据"模式（双检锁、RCU、消息传递）的脊梁。
2. **计数用 `relaxed` 就够**：4 线程各 10000 次 `fetch_add(1, relaxed)` 结果恒 40000——原子性由 RMW 保证，内存序只在**要建立顺序**时才花钱。
3. **`is_lock_free()`**：原子不必然无锁（超过机器字宽的类型会退化为内部锁）——设计无锁结构前先问。

## 10.2 boost 版的增量

- **`boost::atomic_ref`**：把**已存在的普通变量**临时按原子访问（例程演示改 `plain`）——C++20 `std::atomic_ref` 毕业回声；
- **`boost::atomic_flag`**：保证无锁的最小原语（自旋锁原料）；
- **等待/通知**（`wait`/`notify_one`/`notify_all`）：C++20 std 版同款毕业。

**毕业档案**：`std::atomic` 全家（C++11 直系 + C++20 wait/notify、`std::atomic_ref`、`std::atomic<std::shared_ptr>`）。**2026 新代码用 std。** boost 版的残余场景：老代码、以及需要 `BOOST_ATOMIC_` 兼容宏的老标准支持。

---


> 上一章：[09 · 多线程第一课](09-thread.md) ｜ 下一章：[11 · 错误处理基石](11-error.md) ｜ 返回：[README](../README.md)
