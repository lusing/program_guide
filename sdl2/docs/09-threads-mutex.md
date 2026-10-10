# 09 · 线程与互斥锁：让 `counter=2000` 成为确定性断言

> 对应示例：[examples/09_threads_mutex.cpp](../examples/09_threads_mutex.cpp)

并发程序的输出天生不确定，因此"把多线程写进可逐字节比对的回归"本身就是一门手艺：**同步做对了，结果反而是恒定的**。本章示例起两个线程，各自给同一个计数器加 1000，join 之后打印 `counter=2000`——这个数字在两平台、两通道、连跑两遍下都一模一样。它靠的不是运气，而是 `SDL_WaitThread` 提供的 happens-before。

## 9.0 本章示例的骨架

```cpp
// ═══ 9.0 骨架：入口仪式三行 + 只开 TIMER，不碰 VIDEO ═══
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

// ……（Counter 结构体见 9.1，Worker 线程函数见 9.2）……

int main() {
    SDL_SetMainReady();
```

骨架见 [01 章](01-init-version.md)。这里要先把一条流传很广的说法纠正掉：**SDL2 的线程不需要任何子系统位**，`SDL_CreateThread` 与 `SDL_INIT_TIMER` 之间没有关系。`SDL.h` 里 `SDL_Init` 的文档原文：

> The file I/O (for example: SDL_RWFromFile) and threading (SDL_CreateThread) subsystems are initialized by default.

本机实测（补充实验，不在 `examples/` 里；这段把本章的锁+线程+join 三步在三种初始化状态下各跑一遍）：

```cpp
// ═══ 9.0b 补充实验：三种初始化状态下同一段线程代码 ═══
static void run(const char* label, Uint32 flags) {
    if (flags != 1u) {           // 1 == 哨兵：这一次不调 SDL_Init
        if (SDL_Init(flags) != 0) { std::printf("%s: SDL_Init failed\n", label); return; }
    }
    C c{SDL_CreateMutex(), 0};
    SDL_Thread* t = SDL_CreateThread(W, "w", &c);   // W 里加锁累加 100 次，return 7
    int status = -1;
    SDL_WaitThread(t, &status);
    std::printf("%s: value=%d status=%d\n", label, c.v, status);
    SDL_DestroyMutex(c.m);
}
```

<!-- 补充实验的手工输出，非 run-all.sh 产物 -->
```text
no-SDL-init      : value=100 status=7
SDL_INIT_TIMER   : value=100 status=7
SDL_INIT_VIDEO   : value=100 status=7
```

三行完全一致——线程、锁、join 在**根本没调 `SDL_Init`** 的进程里就工作了。那本章示例为什么还开 `SDL_INIT_TIMER`？两个理由，都与线程无关：一是本例的等待路径上可能用到 `SDL_Delay`（06 章），二是全书示例统一都有一次合法的 `SDL_Init` + 失败即退，读者复制骨架时不会拿到一个"看起来不需要初始化"的例外。真正硬要求 `SDL_INIT_TIMER` 的只有 `SDL_AddTimer`。

## 9.1 共享状态：把锁和它保护的数据放在一起

```cpp
// ═══ 9.1 结构体封装：mutex 与 value 的关系写在类型里 ═══
struct Counter {
    SDL_mutex* mutex = nullptr;
    int value = 0;
};
```

SDL 的同步原语是一套 C 句柄：`SDL_mutex`、`SDL_sem`（信号量）、`SDL_cond`（条件变量）。本例只用到互斥锁，但组织方式值得学：**锁放进被保护数据所在的 struct**，而不是散落全局——读代码的人一眼知道"`value` 由 `mutex` 保护"。C++ 项目里等价的做法是把锁和值包进一个类，`value` 设 private。

`SDL_CreateMutex()` 创建的锁**是可重入的**（头文件原话："SDL mutexes are reentrant"）：同一线程重复 `SDL_LockMutex` 合法，但必须解锁同样次数。这条性质因后端实现而异的风险主要在别的库上，SDL 已明确承诺——不过"能重入"不等于"该重入"，靠重入绕过设计通常是死锁的前奏。

## 9.2 线程函数：签名、`SDLCALL` 与 Windows 的那个宏

```cpp
// ═══ 9.2 线程函数：int fn(void*)，返回交给 SDL_WaitThread ═══
int SDLCALL Worker(void* userdata) {
    auto* counter = static_cast<Counter*>(userdata);
    for (int i = 0; i < 1000; ++i) {
        SDL_LockMutex(counter->mutex);
        ++counter->value;
        SDL_UnlockMutex(counter->mutex);
    }
    return 0;
}
```

签名是 `int (SDLCALL *)(void*)`（`SDL_ThreadFunction`）：返回值不是装饰，它由 `SDL_WaitThread(thread, &status)` 的 `status` 取出；`SDLCALL` 与 08 章的回调同理——调用发生在 SDL 的胶水代码里，Windows 上调用约定不一致会栈错。

`SDL_CreateThread(fn, name, data)` 三个参数在 **Windows 上其实是四个**：`SDL_thread.h` 用宏把调用展开成

```cpp
// ═══ 9.2b Windows 上的真实调用（宏展开，不写在源码里） ═══
#define SDL_CreateThread(fn, name, data) SDL_CreateThread(fn, name, data, \
    (pfnSDL_CurrentBeginThread)SDL_beginthread, (pfnSDL_CurrentEndThread)SDL_endthread)
```

原因是 SDL 在 Windows 上编成 DLL：如果由 `SDL2.dll` 自己创建线程，新线程只初始化了 SDL 那份 CRT，调用方程序的 CRT（`errno`、`locale`、C++ 异常状态等）就是未初始化的。SDL 的解法是**总是用调用方的 `_beginthreadex`/`_endthreadex`**，把这些函数指针作为额外参数传进去。所以：写三参数形式（宏会处理），别手搓五参数；这也是"在 worker 里用 `std::cout` 于 Windows 上要谨慎"的深层原因之一。

## 9.3 创建、失败清理与 join

```cpp
// ═══ 9.3 创建两个 worker：建锁 → 建线程 → 失败也要 join → 成功才继续 ═══
    if (SDL_Init(SDL_INIT_TIMER) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    Counter counter{};
    counter.mutex = SDL_CreateMutex();
    if (!counter.mutex) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    SDL_Thread* t1 = SDL_CreateThread(Worker, "worker-1", &counter);
    SDL_Thread* t2 = SDL_CreateThread(Worker, "worker-2", &counter);
    if (!t1 || !t2) {
        std::cerr << SDL_GetError() << '\n';
        if (t1) SDL_WaitThread(t1, nullptr);
        if (t2) SDL_WaitThread(t2, nullptr);
        SDL_DestroyMutex(counter.mutex);
        SDL_Quit();
        return 1;
    }

    SDL_WaitThread(t1, nullptr);
    SDL_WaitThread(t2, nullptr);
```

- **`SDL_Init(SDL_INIT_TIMER)`**：与线程**无关**（9.0 的补充实验实测：不初始化也能建线程/锁并正确 join）。这里开 TIMER 只是全书统一的骨架写法，本例并不需要定时器。
- **失败分支把两个都等**：`t1` 成功、`t2` 失败时，`t1` 仍在跑并持有 `counter.mutex` 的引用。如果直接 `SDL_DestroyMutex` 走人，就是"在别的线程还锁着的时候销毁锁"——未定义行为。`SDL_WaitThread(t1, nullptr)` 先把活着的收尾，再拆锁。这段是本例里最容易被"优化掉"的六行。
- **`SDL_WaitThread` 才是 join**：它等线程结束、回收其 `SDL_Thread` 资源，并建立 happens-before（线程内对共享数据的写在返回后对调用方可见）。第二个参数传 `nullptr` 表示不取返回值。不 join 的替代品是 `SDL_DetachThread`（fire-and-forget），detach 之后**不能**再 `SDL_WaitThread`，也别指望数据可见性。

## 9.4 打印为什么集中在主线程

```cpp
// ═══ 9.4 join 之后读共享数据：这一次读不需要锁 ═══
    std::cout << "==== 09 开始 ====\n";
    std::cout << "counter=" << counter.value << '\n';
    std::cout << "==== 09 结束 ====\n";

    SDL_DestroyMutex(counter.mutex);
    SDL_Quit();
    return 0;
}
```

`build/shared/09_threads_mutex.run1`：

```text
==== 09 开始 ====
counter=2000
==== 09 结束 ====
```

两个 worker 各加 1000，`SDL_WaitThread` 保证两次加都完成且可见，所以 `2000` 是**确定性结论**，符合进比对区间的标准（06 章的方法论）。如果反过来把 `std::cout` 放进 worker：`std::ostream` 本身不是线程安全的（并发写同一 `std::cout` 是数据竞争，多数实现加锁但仍可能交错），区间内容随调度变化，回归立刻随机红。本例的写法是这条纪律的直接产物：**并发只干活，输出集中在 join 之后由主线程做**。

`SDL_DestroyMutex` 也在 join 之后——与 9.3 失败分支同一个理由。

## 9.5 锁之外：什么时候用信号量/条件变量，什么时候别用 SDL

| 需求 | SDL 原语 | 备注 |
|---|---|---|
| 互斥访问一小段状态 | `SDL_CreateMutex` + `SDL_LockMutex`/`SDL_UnlockMutex` | 锁不是计数器；临界区越短越好 |
| 不阻塞地试一下 | `SDL_TryLockMutex` | 返回 `0` / `SDL_MUTEX_TIMEDOUT`（=1）/ `-1`，**判失败不能用 `< 0`** |
| 计数资源、限流 | `SDL_CreateSemaphore` + `SDL_SemWait`/`SDL_SemPost` | 音频环形缓冲的空满通知常用它 |
| 等待条件成立 | `SDL_CreateCond` + `SDL_CondWait`/`SDL_CondBroadcast` | 必须搭配 mutex，且要 `while` 循环防虚假唤醒 |

另一个务实建议：**纯 C++ 逻辑（不涉及 SDL 句柄）可以直接用 `std::thread`/`std::mutex`**，工具链支持完整。SDL 线程 API 的价值在于跨 ABI 一致、能带 `SDLCALL` 入口、以及 Windows 上那套 CRT 交接（9.2）——需要这些时才用 SDL 的。但**别混用两种句柄**：`SDL_WaitThread` 只认 `SDL_CreateThread` 造出来的线程。

## 坑位清单

29. **用 `SDL_Delay` 等线程结束而不是 `SDL_WaitThread`**：睡眠没有同步语义，既不等结束也不建立可见性，`counter` 变成依赖调度的随机值——本例连跑两遍的区间一致性（判定第 6 条）第一个不过。
30. **创建失败分支只 `SDL_WaitThread` 了成功的那一半，或者干脆不等就 `SDL_DestroyMutex`**：`t2` 创建失败时 `t1` 还在跑且可能持有锁，销毁仍被引用的 mutex 是未定义行为。正确形状就是 9.3 里那段：两个都判空、都等，再拆锁。
31. **把 `SDL_TryLockMutex` 的失败当负数判**：它返回 `0`（拿到锁）、`SDL_MUTEX_TIMEDOUT`（= **1**，正数，拿不到）或 `-1`（真错误）。用 `if (SDL_TryLockMutex(m) < 0)` 判失败的代码会把"锁被占着"误读成成功。另外非属主线程 `SDL_UnlockMutex` 是明确未定义行为——锁必须谁锁谁解。

---

上一章：[08 · 音频回调模型：desired/obtained 与打开后的暂停态](08-audio-callback.md) ｜ 下一章：[10 · C++ RAII 封装：不泄漏不等于顺序对](10-raii-wrappers.md) ｜ 返回：[README](../README.md)
