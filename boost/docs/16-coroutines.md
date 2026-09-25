# 16 · 协程时代：context / coroutine / coroutine2 / cobalt / fiber

> 对应示例：`examples/16_coroutines/`（5 个例程）

C++20 协程不是从天上掉下来的——语言级的 `co_await` 背后是 **Boost.Context 十几年打磨的栈切换技术**和一族库对"协程该怎么用"的持续探索。本章五个库是一条清晰的技术谱系：地基（context）→ 元老（coroutine）→ 现代版（coroutine2）→ 用户态线程（fiber）→ C++20 挂载点（cobalt）。

```
Boost.Context（2009）        汇编级栈切换，一切的物理基础
   ├── Boost.Coroutine（2012）   旧版栈协程（push/pull 双管道）
   │     └── Boost.Coroutine2（2015）现代重制
   ├── Boost.Fiber（2015）       + 调度器 = 用户态线程
   └── Boost.Cobalt（2022）      × C++20 co_await = 异步的糖衣
                ↘ C++20 协程（语言级，无栈）+ std::generator（C++23）
```

**先立分界线：有栈 vs 无栈**。Boost 这族全是**有栈**协程——每个协程有自己的栈，可以在**任意深度的普通函数里**挂起；C++20 `co_await` 是**无栈**的——挂起只能发生在协程函数自身。有栈换来的自由代价是每次切换要换整个栈（几十纳秒+缓存扰动），无栈则近乎零开销。

## 16.1 Boost.Context：栈切换本身

地基的官方封装是 `continuation` + `callcc`（call-with-current-continuation，向 Scheme 致敬）：

```cpp
boost::context::continuation c = boost::context::callcc(
    [](boost::context::continuation&& main) {
        // ① 运行在新栈上
        main = std::move(main).resume();   // ② 切回主栈
        // ④ 被恢复后继续
        return std::move(main);            // ⑤ 结束
    });
// ③ 主栈继续
c = std::move(c).resume();                 // 恢复协程
```

运行输出（`context.cpp`）：

```text
checkpoint 顺序走完 = 3（3 表示全部执行）
协程已结束（continuation 为空）? 0
自检通过
```

底下是 `make_fcontext`/`jump_fcontext`（每个平台一段手写汇编，x64 上就是存取 RSP/RBX/RBP/R12-R15 那几个寄存器）。**你几乎不会直接用它**——但 coroutine/fiber/cobalt 三家的栈都从这里来。

## 16.2 Boost.Coroutine（旧版）与 16.3 Coroutine2（现代版）

两代的用户界面都是 **push/pull 双管道**：

```cpp
// pull：协程产出（生成器）
coroutine<int>::pull_type fib([](coroutine<int>::push_type& out) {
    // 往 out 里 push，控制权交还主循环
});
// push：协程消费
coroutine<std::string>::push_type writer([](pull_type& in) { ... });
writer("hello");
```

运行输出（`coroutine.cpp`）：

```text
平方序列: 1 4 9 16 25
  收到: hello
  收到: coroutine
  收到: world
自检通过
```

运行输出（`coroutine2.cpp`）：

```text
斐波那契: 0 1 1 2 3 5 8 13
1..100 求和 = 5050
分界线：有栈（coroutine2）vs 无栈（C++20 co_await）
自检通过
```

**选型**：新代码一律 Coroutine2（Coroutine 是 C++03 时代的，1.92 已标弃用趋势）。**毕业档案**：生成器用途毕业为 `std::generator`（C++23，无栈）；**双向管道（进一个出一个的 `pull<T(U)>`）std 没有**——不过实测发现 coroutine2 的这个形式在本机 `/std:c++latest` 下有编译冲突（和 09 章 future.hpp 同类问题），例程里回避了。

## 16.4 Boost.Fiber：用户态线程

Fiber = **有栈协程 + 调度器 + 全套同步原语**。API 与 `std::thread` 同构，切换成本却是线程的千分之一：

```cpp
boost::fibers::fiber f([]{ ... });       // 就像 thread
boost::this_fiber::yield();              // 主动让出
boost::fibers::buffered_channel<int> ch(16);   // fiber 家的 channel
for (int v : ch) sum += v;               // 消费到 close
```

运行输出（`fiber.cpp`）：

```text
4 个 fiber 结果 = 100 200 300 400
channel 传值求和 = 55（1+4+9+16+25）
自检通过
```

**定位**：十万级并发 IO 的第三条路——thread（内核调度，重）、async/callback（轻但难写）、fiber（轻且好写）。`work_stealing` 调度器可以多核并行。游戏引擎（如 Unigine）、高性能网关在用。std 无对应，也没有路线图——**fiber 的生态位在 C++ 标准外**。

## 16.5 Boost.Cobalt：C++20 协程时代的 asio 糖衣

C++20 的 `co_await` 语法有了，但把现成异步库（asio）接到协程上仍要写完成令牌样板——Cobalt（2022）把这层糖包好：

```cpp
boost::cobalt::task<int> add_later(int a, int b) {
    co_await boost::asio::steady_timer(...).async_wait(boost::cobalt::use_op);
    co_return a + b;
}
auto [r1, r2] = co_await boost::cobalt::join(add_later(1, 2), add_later(3, 4));
boost::cobalt::run(main_task());
```

运行输出（`cobalt.cpp`）：

```text
co_await 加法 = 42
并发: 3 & 7
自检通过
```

**std 对照**：C++20 没有标准的执行器/任务模型（P2300 `std::execution` 是 C++26 的故事，见 18 章）——在那之前，asio + cobalt 就是 C++ 协程异步的成熟答案。⭐

> **实战实录（这个例程代价最大）**：scoop 的预编译发行版**没有** `boost_cobalt` 库。打通的路：把它 7 个非 io 源文件直接编进例程（`build.ps1` 的 `extra_srcs` 机制）；必须去掉 `BOOST_ALL_DYN_LINK`（cobalt 头的 dllimport 声明会和静态编入的符号打架，C4273）；必须 `BOOST_ALL_NO_LIB`（自动链接找的静态名也不存在）；库源码单独用 `/w` 静音编译（库自身的 C4458 不该由例程的零告警标准背锅）。四步缺一不可——这正是"预编译发行版没带某个库"时的完整求生手册。

---


> 上一章：[15 · 范围与迭代器](15-ranges.md) ｜ 下一章：[17 · C++23 波次](17-cpp23.md) ｜ 返回：[README](../README.md)
