# 01 · 初始化与版本：把入口权拿回自己手里

> 对应示例：[examples/01_init_version.cpp](../examples/01_init_version.cpp)

SDL2 是一门 C API，没有构造函数替你做事：程序第一件事是**宣告入口主权**、**申请需要的子系统**、**确认自己链接到了哪份 SDL**。本章的示例只有 28 行，但它一次性定下本教程全书的四条规矩——入口自己管、子系统按需开、错误只信 `SDL_GetError()`、可验证的输出要划区间。后面 9 章的每个示例都是这四条的展开。

## 1.1 三行入口仪式：`SDL_MAIN_HANDLED` / `#include <SDL.h>` / `SDL_SetMainReady()`

```cpp
// ═══ 1.1 入口仪式：三行，缺一不可 ═══
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
```

为什么要这三行，得从 SDL 的一个"贴心"设计说起：**不定义 `SDL_MAIN_HANDLED` 时，`SDL.h` 里有 `#define main SDL_main`**——你的 `main` 被改名，真正的入口换成了 SDL 自带的 `SDL2main`：

| 写法 | 真实入口 | 要链接 | 适用 |
|---|---|---|---|
| 默认（`SDL_main` 宏） | `SDL2main` 提供：Windows 是 `WinMain`、macOS 是 Cocoa 启动壳 | `-lSDL2main -lSDL2` | 图形程序想要"平台帮我处理好一切" |
| `SDL_MAIN_HANDLED` + `SDL_SetMainReady()` | 标准 `int main()` | 只 `-lSDL2` | 单文件跨平台示例、需要 stdout/退出码的自动化验证 |

本教程选第二条：一个 `.cpp` 在 Windows/MSVC 与 macOS/Linux/clang 上都是同一个 `int main()`，`./run-all.sh` 才能直接拿到 stdout、stderr 和退出码做逐字节比对（判定协议见 [12 章](12-verification.md)）。

代价就是那句 `SDL_SetMainReady()`。它不是形式——`SDL2main` 原本还负责告诉 SDL"主线程已经就绪"（macOS 上尤其关系到 Cocoa 与主线程绑定），你绕过它，就得自己补这一句，否则某些平台上 `SDL_Init()` 的行为不可靠。

## 1.2 子系统按需申请：`SDL_Init` 的位标志语义

```cpp
// ═══ 1.2 只开要用的子系统，失败就退出 ═══
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << '\n';
        return 1;
    }
```

`SDL_Init()` 接受的是**位掩码**，不是枚举，多个子系统用 `|` 合并：

| 标志 | 管什么 | 蕴含关系 |
|---|---|---|
| `SDL_INIT_TIMER` | `SDL_GetTicks`/`SDL_GetTicks64`/`SDL_Delay`/`SDL_AddTimer` | — |
| `SDL_INIT_AUDIO` | 音频设备枚举与打开 | — |
| `SDL_INIT_VIDEO` | 窗口、渲染器、事件泵 | 自动初始化 `SDL_INIT_EVENTS` |
| `SDL_INIT_JOYSTICK` / `SDL_INIT_GAMECONTROLLER` | 手柄 | 前者蕴含 EVENTS，后者蕴含 JOYSTICK |
| `SDL_INIT_EVERYTHING` | 上面全部 | — |

蕴含关系值得记：`SDL_Init(SDL_INIT_VIDEO)` 之后 `SDL_PollEvent` 就能用，不必再 `| SDL_INIT_EVENTS`（03 章仍显式写上，是为了让"这个程序要吃事件"这件事在代码里可读）。

**线程不在任何子系统位下**，这一条要专门说，因为网上大量 SDL2 教程（以及 SDL 1.2 的文档）会说"`SDL_CreateThread` 之前必须 `SDL_Init(SDL_INIT_TIMER)`"。SDL2 的 `SDL.h` 在 `SDL_Init` 的文档里把它否定得很清楚：

> The file I/O (for example: SDL_RWFromFile) and threading (SDL_CreateThread) subsystems are initialized by default.

本机实测同样如此：完全不调 `SDL_Init`，`SDL_CreateMutex`/`SDL_CreateThread`/`SDL_WaitThread` 照样正确工作（09 章有这段补充实验）。`SDL_INIT_TIMER` 真正被**明确要求**的地方只有一处——`SDL_AddTimer`（`SDL_timer.h` 里那句 "If you use this function, you must pass SDL_INIT_TIMER to SDL_Init()"）。

至于要不要图省事全开 `SDL_INIT_EVERYTHING`——不建议。初始化不是免费的：视频子系统要向 WindowServer/桌面合成器建立连接，音频子系统可能独占设备，手柄子系统要枚举输入设备。在无窗口会话里，"多开的子系统"直接把整个进程变成启动失败。**开最小集合 + 失败就退**是本章示例的做法，也是后面每一章的写法。

## 1.3 版本有两个：运行期的和编译期的

```cpp
// ═══ 1.3 区间开头与运行期链接版本：SDL_GetVersion 读的是进程里真正那份库 ═══
    std::cout << "==== 01 开始 ====\n";
    SDL_version linked{};
    SDL_GetVersion(&linked);
    std::cout << "Linked SDL version: "
              << static_cast<int>(linked.major) << '.'
              << static_cast<int>(linked.minor) << '.'
              << static_cast<int>(linked.patch) << '\n';
```

`SDL_GetVersion()` 填的是**运行时链接到的那份库**的版本。它和编译期头文件的版本是两码事，后者由宏给出：`SDL_MAJOR_VERSION`/`SDL_MINOR_VERSION`/`SDL_PATCHLEVEL`，或整数的 `SDL_COMPILEDVERSION`（= `SDL_VERSIONNUM(x,y,z)`）。

两者什么时候会不等？动态链接 + 换机器/换安装前缀——本机实测就是这种组合：头文件与 `.dylib` 都来自 MacPorts 的 `libsdl2`，所以本次打印 `2.32.10`；把 `libSDL2-2.0.0.dylib` 换成另一份，打印立刻变，而 `SDL_COMPILEDVERSION` 纹丝不动。

```cpp
// ═══ 1.4 WasInit 是事实查询：位与运算，不看返回值大小 ═══
    std::cout << "videoReady=" << ((SDL_WasInit(SDL_INIT_VIDEO) & SDL_INIT_VIDEO) != 0)
              << ", timerReady=" << ((SDL_WasInit(SDL_INIT_TIMER) & SDL_INIT_TIMER) != 0) << '\n';
```

`SDL_WasInit(0)` 返回当前**全部**已初始化位；`SDL_WasInit(X) & X` 就是"X 是否就绪"的布尔查询。这个断言跨平台恒真（版本号随安装变化，所以只写"两遍一致"级别的可比性，见 12 章），因此它和 `Linked SDL version` 一起进了比对区间。

顺带说清 `SDL_WasInit` 的一个用法边界：它能证明子系统**开过**，不能证明**可用**——视频子系统初始化成功不代表拿得到加速后端（02 章的 `fellBackToSoftware` 就是在补这一课）。

## 1.5 收尾：`SDL_Quit()` 是所有析构的截止线

```cpp
// ═══ 1.5 先打印后退出：SDL_Quit 拆掉全部子系统 ═══
    std::cout << "==== 01 结束 ====\n";

    SDL_Quit();
    return 0;
}
```

`SDL_Quit()` 卸载本进程内所有 SDL 子系统，之后任何 SDL API 都不该再被调用。本例没有对象要销毁，所以顺序无所谓；但只要有窗口/渲染器/纹理/设备句柄，它们必须**全部**在 `SDL_Quit()` 之前销毁——[10 章](10-raii-wrappers.md)的 `unique_ptr` 踩的就是这条线（那也是本次 macOS 校验实际修掉的两处真问题之一）。

还有一条纪律藏在上面这段里：**所有可验证的输出都在 `SDL_Quit()` 之前写完**。子系统拆掉后再打印不迟，但那时如果还想查 `SDL_GetError()`，字符串可能已经被卸载流程改写过——把观测点放在拆伙之前，回归结果才稳定。

## 1.6 错误处理约定：SDL 不返回错误码，只留一句话

本章示例里唯一的错误分支是 `SDL_Init` 那三行，它示范了 SDL 的通用约定：

- **`SDL_GetError()` 返回一块进程/线程局部的静态缓冲区指针**，不要 `delete`、不要长期持有（下次失败就会覆盖它）、也不要假设内容稳定可比对。
- **成功调用不会清空它**。也就是说：`SDL_GetError()` 非空 ≠ 刚才那次调用失败，可能是更早遗留的。要判"这次干不干净"，标准三步是 `SDL_ClearError()` → 调用 → 看 `SDL_GetError()` 是否为空串——[05 章](05-draw-primitives.md) 里给返回 `void` 的 `SDL_RenderPresent` 判成败用的正是这套。
- 绝大多数 API 的失败信号是"返回 `nullptr` / 负数 / 0"，错误细节再查 `SDL_GetError()`。两者要一起判，缺一不可。

## 1.7 构建与实测输出

单文件编译（macOS，参数全部来自 `sdl2-config`，不手抄路径）：

```bash
clang++ -std=c++20 -Wall -Wextra -O1 $(sdl2-config --cflags) \
    examples/01_init_version.cpp -o /tmp/01 $(sdl2-config --libs)
/tmp/01
```

实测输出（`build/shared/01_init_version.run1`，shared/static 两条通道逐字节一致）：

```text
==== 01 开始 ====
Linked SDL version: 2.32.10
videoReady=1, timerReady=1
==== 01 结束 ====
```

四行里没有一个是"这台机器才成立"的量：版本行只要求同一次全量里两跑一致，`videoReady`/`timerReady` 是恒真断言。这就是本教程判定协议的取样标准——**区间内只放跨机器恒真的事实**（详见 [12 章](12-verification.md)）。

## 坑位清单

1. **定义了 `SDL_MAIN_HANDLED` 却同时链接 `SDL2main`**：macOS 上 `SDL2main` 会把 `main` 重命名并注入自己的入口，最终行为取决于链接顺序，表现是"有时候能跑"。两条路只能选一条：用宏就链 `SDL2main`，`SDL_MAIN_HANDLED` 就只链 `SDL2` 并自己调 `SDL_SetMainReady()`。
2. **用 `SDL_GetVersion()` 当编译期版本断言**：它报的是运行时那份库。装了新库留旧头文件（或反过来）时两边不等，这不是 bug，是两套版本号的语义差别——编译期用 `SDL_COMPILEDVERSION`，运行期用 `SDL_GetVersion()`，需要"至少某版本"的运行时开关请用 `SDL版本 >= x` 判运行期值。
3. **把 `SDL_GetError()` 当"本次调用失败"的证据**：成功路径不清空错误串，读到的是历史遗留。判成败要"返回值 + 先 `SDL_ClearError()` 再查错误"两条一起用；另外那个返回的 `const char*` 是静态缓冲区，复制走再存。

---

上一章：[README · SDL2 编程指南](../README.md) ｜ 下一章：[02 · 窗口与渲染器：加速后端拿不到怎么办](02-window-renderer.md) ｜ 返回：[README](../README.md)
