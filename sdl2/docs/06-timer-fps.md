# 06 · 计时与帧率：哪些数字能进字节比对

> 对应示例：[examples/06_timer_fps.cpp](../examples/06_timer_fps.cpp)

SDL2 的计时 API 很薄：一个单调毫秒钟、一个睡眠函数，帧率控制全靠你自己把它们拼起来。本章的示例只有 38 行，但它承担本教程最重要的一条方法论：**同一个程序里，哪些量是"跨机器恒真的事实"、哪些是"随负载漂移的观测"**，以及为什么这个区分决定了回归能不能长期绿。本次 macOS 校验在这段代码上动过刀——原版把 `frameTime` 和 `fps` 当主输出，连跑两次 16~19ms 的抖动让字节比对随机变红。

## 6.0 本章示例的骨架

```cpp
// ═══ 6.0 骨架：只要 TIMER——计时子系统不碰窗口，也就不需要 VIDEO ═══
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_TIMER) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }
```

骨架见 [01 章](01-init-version.md)。本章是全书唯一一个**完全不建窗口**的示例，所以 `SDL_VIDEODRIVER=dummy` 与否对它毫无影响——它压根不问视频后端（09 章的线程示例同理）。

顺手把"要不要开 TIMER"这件事说清：本机实测，**不 `SDL_Init` 也能用 `SDL_GetTicks`/`SDL_Delay`**——第一次取 ticks 时计时基准会懒启动（那次调用返回 0，之后照常给增量），`SDL_Delay` 本身只是 sleep。但显式开 `SDL_INIT_TIMER` 才是正规写法：`SDL_timer.h` 对 `SDL_AddTimer` 明确写着 "If you use this function, you must pass SDL_INIT_TIMER to SDL_Init()"，而且懒启动意味着你的第一个时间读数没有意义。反过来，别把这一位当成线程的前置条件，01 章 1.2 已用头文件与实测把它否掉了。

## 6.1 单调钟：`SDL_GetTicks` 与它的 32 位回绕

```cpp
// ═══ 6.1 计时子系统与单调毫秒钟 ═══
    if (SDL_Init(SDL_INIT_TIMER) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    const Uint32 frameTargetMs = 16;
    Uint32 frameBegin = SDL_GetTicks();
```

`SDL_GetTicks()` 返回"自 SDL 计时子系统初始化以来经过的毫秒"，类型是 **`Uint32`**——49.7 天后回绕归零（头文件在 2.0.18 起明确不推荐它，推荐 `SDL_GetTicks64()`）。

有意思的是回绕对**减法**几乎无害：`now - start` 用无符号算术，只要时间跨度不超过约 24.8 天就能得到正确差值。真正会炸的是**比较**（`if (SDL_GetTicks() > deadline)`）——回绕瞬间条件恒假。所以工程习惯是：

- 算差值：`Uint32` 的 `a - b` 可以用，但长期运行的程序请换 `SDL_GetTicks64()`；
- 判超时：写 `now - start < timeout`（差值形式），而不是 `now < deadline`；
- 别把 `SDL_GetTicks64()` 和 `SDL_GetTicks()` 混在一个表达式里比较，一个是 64 位单调值、一个会回绕。

## 6.2 睡眠：`SDL_Delay` 是"至少"，不是"恰好"

```cpp
// ═══ 6.2 补帧的标准形状 ═══
    SDL_Delay(5);

    Uint32 elapsed = SDL_GetTicks() - frameBegin;
    if (elapsed < frameTargetMs) {
        SDL_Delay(frameTargetMs - elapsed);
    }

    Uint32 frameTime = SDL_GetTicks() - frameBegin;
```

`SDL_Delay(ms)` 保证**不短于** `ms`，实际值取决于系统定时器粒度（几毫秒的超出很常见），而且它期间不处理事件——长 `SDL_Delay` 会让窗口"僵住"（系统可能判定无响应），所以真实程序里要么切成小片、要么改用 `SDL_WaitEventTimeout`（03 章）把睡眠和等事件合并。

本例的"帧"其实是一次工作（`SDL_Delay(5)` 假装渲染耗时 5ms）加一次补齐：`elapsed < 16` 就再睡到 16ms。这是无 vsync 场景（软件后端、`dummy` 驱动）的最低限度帧率控制——有 vsync 时 `SDL_RenderPresent` 自己会卡住节奏，`SDL_RENDERER_PRESENTVSYNC` 拿不拿得到要看 02 章的 `info.flags` 复查。

## 6.3 区间里放结论，区间外放数字

```cpp
// ═══ 6.3 可验证的是「补帧逻辑保证 frameTime >= 目标帧长」这条结论 ═══
    std::cout << "==== 06 开始 ====\n";
    std::cout << "frameTargetMs=" << frameTargetMs << '\n';
    std::cout << "frameTargetMet=" << (frameTime >= frameTargetMs) << '\n';
    std::cout << "==== 06 结束 ====\n";

    double fps = frameTime > 0 ? 1000.0 / frameTime : 0.0;
    std::cout << "[观测] frameTime(ms)=" << frameTime << ", fps~=" << fps << '\n';

    SDL_Quit();
    return 0;
}
```

这是本教程所有示例共用的输出协议（判定细节在 [12 章](12-verification.md)）：

- **`==== 06 开始/结束 ====` 之间**只进跨机器恒真的量：常量 `frameTargetMs=16`，以及 `frameTargetMet`——由 6.2 的补齐逻辑保证成立（`SDL_Delay` 只会多睡不会少睡，所以 `frameTime >= 16` 是**结构性**结论）。
- **区间外的 `[观测]` 行**放会漂移的原始数字：本机四轮跑出 `frameTime(ms)=18 / 16 / 20 / 18`（两条通道各连跑两遍），对应 `fps~=55.5556 / 62.5 / 50 / 55.5556`。它们给人看，不参与逐字节比对。

`build/shared/06_timer_fps.run1`（区间两行 + 区间外一行观测）：

```text
==== 06 开始 ====
frameTargetMs=16
frameTargetMet=1
==== 06 结束 ====
[观测] frameTime(ms)=18, fps~=55.5556
```

顺带一提 `fps` 那行的 `frameTime > 0 ? ... : 0.0`：不是防御性废话，`SDL_GetTicks()` 分辨率是毫秒，一帧如果落在同一毫秒内 `frameTime` 就是 0，除零得到 `inf` 打印出去，下次比对的字符串形态都不确定。**观测值本身也要确定**，才谈得上"给人看"。

## 6.4 帧率控制的三档，按可得性排序

| 手段 | 前提 | 特点 |
|---|---|---|
| `SDL_RENDERER_PRESENTVSYNC` | 请求得到且后端接受（`ACCELERATED` 位会否掉无窗口会话，见 02 章） | 最省心，节奏由显示器给，代价是输入延迟与"掉帧即半帧" |
| `SDL_Delay` / 补齐（本例） | 只要计时子系统 | 平台无关、可验证，精度受系统定时器粒度限制 |
| 自写定时器回调 `SDL_AddTimer` | 独立线程回调 | 回调不能直接画窗口（09/10 章的线程纪律），只适合报时 |

真实项目通常是"请求 vsync，拿不到就用第 2 档兜底"，与 02 章渲染器降级同一条思路：**问 API 要事实，不靠 `#ifdef` 猜平台**。

## 坑位清单

17. **把实测帧长 / fps 当回归断言**：同一台机器连跑几次就是 16~19ms 的抖动（本教程实录：原版 `06` 就是这么写的，字节比对随机变红）。能进区间的是"补帧后不快于目标帧长"这类**跨机器恒真**的命题，原始数值挪到区间外只做观测。
18. **`SDL_GetTicks()` 的回绕当理论问题**：`Uint32` 49.7 天归零。差值用无符号减法尚且安全，`SDL_GetTicks() > deadline` 这类**比较**在回绕点必然出错；长期运行的程序请换 `SDL_GetTicks64()`，且不要与 32 位版混着比。
19. **macOS 没有 GNU `timeout`**：只有 MacPorts 的 `gtimeout`。验证脚本的探测顺序要写成 `gtimeout` → `timeout`，并允许"都没有"时不设上限运行，否则整条回归链会因为命令找不到而以 127 退出（`run-all.sh` 已按此实现）。

---

上一章：[05 · 基础绘制 API：返回 void 的 Present 怎么判成败](05-draw-primitives.md) ｜ 下一章：[07 · 键盘输入状态：状态表、PumpEvents 与那个 512](07-keyboard-state.md) ｜ 返回：[README](../README.md)
