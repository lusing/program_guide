# 07 · 键盘输入状态：状态表、PumpEvents 与那个 512

> 对应示例：[examples/07_keyboard_state.cpp](../examples/07_keyboard_state.cpp)

03 章的事件队列回答"发生了什么"（一条条按键消息），本章的**键盘状态表**回答"现在按着什么"。两条通路共用同一个数据源，用途完全不同：事件适合处理"按下这一刻"，状态表适合每帧轮询"按住不放"（移动、蓄力、连发）。示例只有 36 行，但它把三个最容易误解的点摊开了：状态表要手动 pump、`entries` 不是按下键数、以及"全 0"在无焦点进程里是事实而不是 bug。

## 7.0 本章示例的骨架

```cpp
// ═══ 7.0 骨架：VIDEO|EVENTS + 一个 HIDDEN 窗口，只为让事件泵有落脚点 ═══
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("Keyboard", 0, 0, 320, 240, SDL_WINDOW_HIDDEN);
    if (!window) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }
```

骨架见 [01 章](01-init-version.md)，窗口参数的语义见 [02 章](02-window-renderer.md)。本章没有渲染器：状态表是 SDL 内部维护的一份数组，不需要任何绘制后端。窗口在这里的作用只有一个——让 `SDL_PumpEvents()` 有处可问（macOS 上事件源是 Cocoa 的窗口服务器，没有窗口时 `SDL_Init(SDL_INIT_VIDEO)` 本身就可能失败）。

## 7.1 状态表：一张按 scancode 索引的字节数组

```cpp
// ═══ 7.1 先 pump 再取表：SDL_GetKeyboardState 自己不收事件 ═══
    SDL_PumpEvents();
    int keyCount = 0;
    const Uint8* state = SDL_GetKeyboardState(&keyCount);
    bool leftPressed = state && state[SDL_SCANCODE_LEFT] != 0;
```

`SDL_GetKeyboardState(&num_keys)` 返回 SDL **内部持有的**那张表（`SDL_NUM_SCANCODES` 个 `Uint8`），不要 `free`、也不要在 pump 之前指望它是新鲜的：

- 下标是 `SDL_Scancode`（物理键位，`SDL_SCANCODE_LEFT = 80`），不是 `SDL_Keycode`。布局无关的键位判断一律用 scancode；要字符语义（`A`/`复制`）请走 03 章的 `SDL_KEYDOWN` 事件里的 `keysym.sym`。
- 值是该键的当前状态（非 0 即按下）。表由事件泵维护——**`SDL_GetKeyboardState` 不会自己去收事件**，所以标准顺序是 `SDL_PumpEvents()` → 取表 → 读。在 03 章的主循环里 `SDL_PollEvent` 已经顺带 pump 了，本例没有事件循环，所以 pump 要自己写。
- 修饰键另有快捷路：`SDL_GetModState()` 返回 `KMOD_LSHIFT`/`KMOD_CTRL`/`KMOD_ALT` 等位掩码，比手查左右 Shift 的 scancode 省事。

`out_numkeys` 这个参数的语义最容易读错：它给的是**表的长度**（`SDL_NUM_SCANCODES`，恒为 512），不是"当前按下的键数"。想数有几个键被按下得自己遍历。

## 7.2 输出里为什么同时打印"按下状态"和"表可用性"

```cpp
// ═══ 7.2 断言平台无关的量：表在不在、长度对不对 ═══
    std::cout << "==== 07 开始 ====\n";
    std::cout << "keyboard entries=" << keyCount << ", leftPressed=" << leftPressed << '\n';
    std::cout << "stateAvailable=" << (state != nullptr) << '\n';
    std::cout << "==== 07 结束 ====\n";

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

`build/shared/07_keyboard_state.run1`：

```text
==== 07 开始 ====
keyboard entries=512, leftPressed=0
stateAvailable=1
==== 07 结束 ====
```

三行里 `entries=512` 和 `stateAvailable=1` 是**平台无关的确定性断言**：任何平台上表都是 512 项、初始化视频子系统后取表必然成功。`leftPressed=0` 则只是"此刻没人按左方向键"这个事实——本例窗口以 `SDL_WINDOW_HIDDEN` 创建，没有焦点、也没有输入源，收到的自然是空表。

这条区分值得说透：**后台/无焦点进程的键盘状态全为 0，不是"macOS 拿不到键盘"**。`SDL_PumpEvents` 只把窗口管理器送来的事件并入状态表，窗口没拿到焦点时 WM 压根不发键事件，于是表全 0。把它当成平台差异去"修"，方向从一开始就错了——要断言就断言 `entries` 与 `state != nullptr`。

顺带一个 macOS 特有的现实：即便窗口有焦点，`state` 表反映的也只是本进程收到的事件；系统级快捷键（Mission Control、Cmd-Tab）被窗口管理器截走后不会投给应用。想做全局热键得走平台原生 API 或辅助功能通道，那不是 SDL 的职责范围（本教程不展开，也**未在本机实测**）。

## 7.3 状态表 vs 事件：怎么选

| 需求 | 用什么 | 理由 |
|---|---|---|
| 按住持续移动、蓄力、连发 | `SDL_GetKeyboardState` | 每帧读一次，天然表达"当前" |
| 一次按下触发一次动作（跳跃、打开菜单） | `SDL_KEYDOWN` 事件 | 事件保证不漏、不重复；状态表要自己写边沿检测 |
| 文本输入 | `SDL_TEXTINPUT` 事件 | 状态表拿不到字符，输入法/布局都对不上 |
| 只看修饰键 | `SDL_GetModState` | 位掩码，免去左右区分 |

边沿检测若坚持用状态表，标准做法是每帧存一份上一帧的副本再比较——但除非有特殊理由，"动作类"输入用事件更省事，也自动吃到了系统重复按键（`e.key.repeat` 可以区分首按与重复）。

## 7.4 无头注入：事件队列能喂，状态表喂不动

`SDL_PushEvent` 是公共 API 里唯一的"自己造事件"通道，也是无人值守验证输入路径的正道。但**它只喂事件队列，不喂状态表**——本教程在 `cocoa` 驱动 + `dummy` 驱动下各实测一次，结论一致：

```cpp
// ═══ 7.4 注入实测（这段是本章的补充实验，不在 examples/ 里） ═══
    SDL_Event e{};
    e.type = SDL_KEYDOWN;
    e.key.keysym.scancode = SDL_SCANCODE_LEFT;
    e.key.keysym.sym = SDLK_LEFT;
    int pushRC = SDL_PushEvent(&e);      // 实测 = 1（成功入队）
    SDL_PumpEvents();
    const Uint8* st = SDL_GetKeyboardState(nullptr);
    // 随后 SDL_PollEvent 取到这条 SDL_KEYDOWN（实测 polledKeydown=1），
    // 但 st[SDL_SCANCODE_LEFT] 依然是 0（实测）。
```

原因在 SDL 的内部分工：状态表由驱动投递按键的那条内部路径（`SDL_SendKeyboardKey`）维护，`SDL_PushEvent` 只往队列里塞一条消息，不重放这条内部路径。推论很实用：**要测"按下会发生什么"用 `SDL_PushEvent` + 事件处理；要测状态表本身，只能靠真键盘**。把注入当成"模拟按住"来验 `SDL_GetKeyboardState`，会得到一个恒 0 的假阴性。

## 坑位清单

20. **把 `leftPressed=0` 当成 macOS 拿不到键盘**：那只是"没人按键"的事实。状态表来自窗口管理器送来的事件，窗口未获焦点（本例还是 `HIDDEN`）收到的就是全 0；要断言就断言 `entries == 512` 与 `state != nullptr` 这类平台无关的量。
21. **忘了 `SDL_PumpEvents()`**：`SDL_GetKeyboardState` 不会自己去收事件，不 pump 读到的是上一次泵之后的陈旧状态。在 03 章的循环里由 `SDL_PollEvent` 代劳，脱离事件循环单独查表就必须自己 pump。
22. **把 `out_numkeys` 当"按下的键数"**：它是数组长度（`SDL_NUM_SCANCODES` = 512）。另外返回的指针是 SDL 内部表，别 `delete[]`；下标用 `SDL_Scancode`，用 `SDL_Keycode` 去索引会静默读错行（两个枚举的取值并不相同）。
23. **用 `SDL_PushEvent` 注入按键去"模拟按住"**：实测（`cocoa` 与 `dummy` 两种驱动结果相同）注入的 `SDL_KEYDOWN` 能被 `SDL_PollEvent` 取到（`polledKeydown=1`），但 `state[SDL_SCANCODE_LEFT]` 仍是 `0`——状态表由 SDL 内部的驱动投递路径维护，公共注入通道不碰它。据此断言状态表会得到恒 0 的假阴性；验状态表只能靠真实键盘。

---

上一章：[06 · 计时与帧率：哪些数字能进字节比对](06-timer-fps.md) ｜ 下一章：[08 · 音频回调模型：desired/obtained 与打开后的暂停态](08-audio-callback.md) ｜ 返回：[README](../README.md)
