# 03 · 事件循环骨架：PollEvent 与"没人点关闭"的退出

> 对应示例：[examples/03_event_loop_skeleton.cpp](../examples/03_event_loop_skeleton.cpp)

02 章把窗口和渲染器立起来了，但它一帧都不响应：没有事件循环，窗口就只是一块画布（在 `HIDDEN` 状态下连画布都看不见）。本章写 SDL2 程序的主干——**收事件 → 决策 → 干活**的循环，以及自动化验证特有的那道题：**脚本环境里没人点关闭按钮，循环靠什么退出**。

## 3.0 本章示例的骨架

```cpp
// ═══ 3.0 骨架：入口仪式三行 + VIDEO|EVENTS 子系统位 ═══
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }
```

骨架三行见 [01 章](01-init-version.md)。本章的子系统位是 `SDL_INIT_VIDEO | SDL_INIT_EVENTS`——`VIDEO` 本身已蕴含 `EVENTS`（01 章 1.2 的蕴含表），显式写出来是为了让"这个示例要吃事件"在初始化那一行就可见。3.2 会回到这段代码讲 `SDL_Event` 的取用。

## 3.1 主干：双层循环的两种职责

```cpp
// ═══ 3.1 事件循环主干：外层管帧，内层排空队列 ═══
    bool running = true;
    int ticks = 0;
    while (running && ticks < 3) {
        SDL_Event e{};
        while (SDL_PollEvent(&e) == 1) {
            if (e.type == SDL_QUIT) {
                running = false;
            }
        }
        SDL_Delay(1);
        ++ticks;
    }
```

**外层 `while (running)` 是"帧"**：一轮迭代 = 处理一次输入 + 更新一次状态 + 呈现一帧（本例的"帧"只是计数）。**内层 `while (SDL_PollEvent(&e) == 1)` 是"排空队列"**：`SDL_PollEvent` 每次取出队首一条事件并返回 1，队列空时返回 0。只 `if` 不 `while` 的写法每帧最多消费一条事件，鼠标快速移动时输入会明显滞后一帧以上——这是新手最常见的结构性错误。

两个语义细节值得钉牢：

- `SDL_PollEvent` **自带 pump**：它内部会先调用 `SDL_PumpEvents()`，把窗口系统送来的原始输入折进事件队列，所以事件循环里不必额外 pump（07 章直接用键盘状态表时才需要手动 pump）。
- 取到的事件**已经出队**，不会再被第二个消费者看到。所以"一处 `SDL_PollEvent` 消费全部事件、再分发给业务"是标准形态；同一进程里开多个 `PollEvent` 消费者会互相偷事件。

## 3.2 `SDL_Event` 是一个 union，`type` 决定读哪个成员

```cpp
// ═══ 3.2 初始化子系统时就声明要吃事件（VIDEO 已蕴含 EVENTS，显式写是给人读的） ═══
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }
```

`SDL_Event` 是 56 字节的 union，`e.type` 决定哪个成员有效：

| `type` | 有效成员 | 关键字段 |
|---|---|---|
| `SDL_QUIT` | `e.quit` | 用户点关闭、`SDL_QuitRequested()` 发出 |
| `SDL_WINDOWEVENT` | `e.window` | `e.window.event`：`SDL_WINDOWEVENT_RESIZED`/`SHOWN`/`HIDDEN`/`FOCUS_LOST`… |
| `SDL_KEYDOWN` / `SDL_KEYUP` | `e.key` | `keysym.scancode`（物理位置，平台无关）、`keysym.sym`（逻辑键名，受布局影响） |
| `SDL_MOUSEMOTION` / `SDL_MOUSEBUTTONDOWN` | `e.motion` / `e.button` | `x`/`y`/`state`/`button` |
| `SDL_APP_WILL_TERMINATE` 等 | `e.common` | 移动端/桌面生命周期信号 |

处理链的标准写法是 `switch (e.type)`，而不是逐个 `if` 比较——事件类型是位散布的整数，`switch` 编译器可跳表。本例只关心 `SDL_QUIT`，一条 `if` 足够。

`scancode` 与 `keycode` 的区别值得单独记一句：**布局无关的判断（比如"WASD 那四个键位"）用 scancode，字符语义（比如"复制粘贴"）用 sym**。07 章的状态表就是按 scancode 索引的。

## 3.3 退出条件必须双保险：`SDL_QUIT` 或计数

回到本章的正题。`running` 只会被 `SDL_QUIT` 置假，而 `SDL_QUIT` 只有两种来源：用户点窗口关闭按钮，或程序自己 `SDL_PushEvent`/`SDL_QuitRequested()`。回归脚本里两者都不会发生——更何况窗口是 `SDL_WINDOW_HIDDEN` 建的，**根本没有按钮可点**。

所以本例的第二条退出条件是 `ticks < 3`：跑满三轮自动收工。`SDL_Delay(1)` 夹在中间，让空转的一轮不至于把 CPU 打满（不加 delay 也不加 vsync 的纯 `while` 轮询，单核 100% 是最常见的"我的程序怎么这么热"来源）。

这条双保险的前提是窗口本身也按"脚本能安静跑完"的方式建：

```cpp
// ═══ 3.3 窗口只为事件队列存在：HIDDEN + 失败即退，销毁留给 3.4 之后 ═══
    SDL_Window* window = SDL_CreateWindow(
        "Event Loop",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        320,
        240,
        SDL_WINDOW_HIDDEN
    );
    if (!window) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }
```

注意这里的失败分支只调了 `SDL_Quit()`，没有 `SDL_DestroyWindow`——因为 `window == nullptr`，没东西可销毁。02 章 2.2 那段渲染器失败的分支里先 `SDL_DestroyWindow(window)` 再 `SDL_Quit()`，差别就来自"此刻手上还有没有活着的东西"。

真实程序两条都要留：`SDL_QUIT` 负责"用户想走"，另一条负责"该做的活做完了"。只写 `while (running)` 的循环，在没有窗口管理器的环境里就是无限循环。

## 3.4 实测输出：`running=1` 不是 bug，是这条分支的证据

```cpp
// ═══ 3.4 循环结束后才打印：三个量都是确定性的 ═══
    std::cout << "==== 03 开始 ====\n";
    std::cout << "loopTicks=" << ticks << ", running=" << running << '\n';
    std::cout << "==== 03 结束 ====\n";

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

`build/shared/03_event_loop_skeleton.run1`：

```text
==== 03 开始 ====
loopTicks=3, running=1
==== 03 结束 ====
```

`loopTicks=3` 证明循环真的转了三轮而不是零轮；`running=1` 证明退出**是被计数兜底救下来的**，而不是某条 `SDL_QUIT` 恰好路过。这两个量在任何机器、任何驱动下都成立，正是字节比对区间要的东西。反过来，如果哪天有人把窗口改成 `SDL_WINDOW_SHOWN` 并手动点了关闭，`running` 会变 0，回归就会红——这条输出的价值就在这儿：它把"退出路径"变成可观测的事实。

## 3.5 三种收事件的姿势，怎么选

| API | 行为 | 适用 |
|---|---|---|
| `SDL_PollEvent` | 非阻塞，取一条；空则返回 0 | 主循环（本例） |
| `SDL_WaitEvent` | 阻塞直到有事件 | 事件驱动的 UI、无帧率的工具程序（省电） |
| `SDL_WaitEventTimeout(&e, ms)` | 阻塞至多 ms | 想要"没消息就睡，有消息立刻干"的循环 |
| `SDL_PeepEvents` | 批量取/查/删，可带类型区间过滤 | 需要多消费者或按类型分拣的引擎 |

`SDL_WaitEventTimeout` 是"轮询 + `SDL_Delay`"的正规替代：不空转、延迟又低。本例用 `PollEvent + Delay(1)`，是因为要演示**固定三轮**的可验证结构——`WaitEvent` 在无事件环境里会一直阻塞，脚本只能靠外层超时（12 章）兜住。

## 坑位清单

8. **只靠 `SDL_QUIT` 退出循环**：脚本/CI/无窗口会话里没人点关闭按钮（本例窗口还是 `HIDDEN` 建的，压根没有按钮）。退出条件要双保险：`SDL_QUIT` 管用户，计数或任务完成度管无人值守。
9. **`if (SDL_PollEvent(&e))` 单条消费**：一帧只处理一条事件，鼠标移动一快输入就滞后、`SDL_WINDOWEVENT_RESIZED` 可能被积压到下一帧。外层帧循环、内层 `while (... == 1)` 排空才是标准结构。
10. **纯 SSH（无 GUI 会话）下跑视频示例**：macOS 的 `cocoa` 驱动拿不到 WindowServer 连接时会失败。**本机始终在 GUI 会话中，这一条未实测**（属环境缺口，不是示例缺陷）；CI 请显式 `SDL_VIDEODRIVER=dummy`（本教程已实测 10/10 通过）。

---

上一章：[02 · 窗口与渲染器：加速后端拿不到怎么办](02-window-renderer.md) ｜ 下一章：[04 · Surface 与 Texture：像素在 CPU 还是在 GPU](04-surface-texture.md) ｜ 返回：[README](../README.md)
