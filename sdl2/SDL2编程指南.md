# SDL2 编程指南（Windows/MSVC + macOS/clang）

本指南按 `guide` 统一结构编写：教程文档 + 独立示例源码 + 双构建入口（
`run-all.sh` / `build.ps1`）一键编译运行验证。

示例本身是**跨平台代码**：只用 SDL2 公共 API，不碰任何 Win32 / Cocoa 头，
入口统一用 `SDL_MAIN_HANDLED` + `SDL_SetMainReady()` 自己接管 `main`。
正文里所有「实测输出」都取自 macOS（Darwin 23.6 x86_64，Apple clang 16.0.0，
SDL2 2.32.10）跑 `./run-all.sh` 生成的 `build/` 产物，逐字节可查。

## 目录

1. [环境准备](#环境准备)
2. [初始化与版本信息](#初始化与版本信息)
3. [窗口与渲染器](#窗口与渲染器)
4. [事件循环骨架](#事件循环骨架)
5. [Surface 与 Texture](#surface-与-texture)
6. [基础绘制 API](#基础绘制-api)
7. [计时与帧率](#计时与帧率)
8. [键盘输入状态](#键盘输入状态)
9. [音频回调模型](#音频回调模型)
10. [线程与互斥锁](#线程与互斥锁)
11. [C++ RAII 封装](#c-raii-封装)
12. [macOS 平台差异与坑位](#macos-平台差异与坑位)
13. [统一编译验证](#统一编译验证)

---

## 环境准备

**Windows / MSVC**

- SDL2：`G:\scoop\apps\sdl2\current`
- VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC`
- 教程目录：`G:\code\guide\sdl2`
- 编译：`cl.exe /std:c++20 /EHsc /utf-8`，链 `SDL2.lib`

**macOS / clang**

- SDL2：MacPorts `libsdl2`（2.32.10），装在 `/opt/local`
- 编译器：Apple clang（Xcode Command Line Tools）
- 配置：`sdl2-config --cflags --libs`，静态链接用 `--static-libs`
- 超时：MacPorts `coreutils` 提供 `gtimeout`

```bash
sudo port install libsdl2 coreutils
xcode-select --install
```

头文件与库的路径**不要手抄**：`sdl2-config` 的输出在本机是（留档 `build/toolchain.txt`）

<!-- 命令输出，非示例运行输出 -->
```text
-I/opt/local/include/SDL2 -D_THREAD_SAFE
-L/opt/local/lib -lSDL2
```

`run-all.sh` 用 `find_tool` 探测 `sdl2-config`，找不到就退回 `pkg-config sdl2`，
再找不到直接报「环境缺口」退出——不猜路径，也不假装通过。

---

## 初始化与版本信息

源码：`examples/01_init_version.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << '\n';
        return 1;
    }

    std::cout << "==== 01 开始 ====\n";
    SDL_version linked{};
    SDL_GetVersion(&linked);
    std::cout << "Linked SDL version: "
              << static_cast<int>(linked.major) << '.'
              << static_cast<int>(linked.minor) << '.'
              << static_cast<int>(linked.patch) << '\n';
    // SDL_WasInit 是「子系统是否已就绪」的事实查询，不依赖具体平台；
    // 版本号随安装的 SDL 变化，因此只在同一次全量里做「两遍一致」比对。
    std::cout << "videoReady=" << ((SDL_WasInit(SDL_INIT_VIDEO) & SDL_INIT_VIDEO) != 0)
              << ", timerReady=" << ((SDL_WasInit(SDL_INIT_TIMER) & SDL_INIT_TIMER) != 0) << '\n';
    std::cout << "==== 01 结束 ====\n";

    SDL_Quit();
    return 0;
}
```

实测输出（`build/shared/01_init_version.sec1`）：

```text
Linked SDL version: 2.32.10
videoReady=1, timerReady=1
```

要点：

- `SDL_MAIN_HANDLED` 告诉 SDL「主函数我自己管，别用宏把 `main` 改掉」，
  与之配套必须调 `SDL_SetMainReady()`。这样可执行文件用标准 `int main()`，
  也不必链接 `SDL2main`。
- `SDL_GetVersion()` 报的是**运行时**链接到的版本，可能和编译期头文件不一致；
  要拿编译期版本用 `SDL_VERSION()` / `SDL_COMPILEDVERSION`。

**坑位清单**

1. 定义了 `SDL_MAIN_HANDLED` 却同时链接 `SDL2main`：macOS 上 `SDL2main` 会把
   `main` 重命名并注入自己的入口，行为取决于链接顺序，别混用。
2. 用 `SDL_GetVersion()` 当编译期版本断言：装了新库旧头文件（或反过来）时
   两边不等，这不是 bug，是两套版本号的语义差别。

**下一章：[窗口与渲染器](#窗口与渲染器)**

---

## 窗口与渲染器

源码：`examples/02_window_renderer.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow(
        "SDL2 Window",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        640,
        360,
        SDL_WINDOW_HIDDEN
    );
    if (!window) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    // 先要硬件加速，拿不到再退到软件渲染器。
    // 这条降级不是给 macOS 打的补丁：无窗口会话（Linux CI、SSH、
    // SDL_VIDEODRIVER=dummy）下加速后端根本不存在，SDL_CreateRenderer 会直接
    // 返回 nullptr，报 "Couldn't find matching render driver"。
    // 用「创建失败就退一档」的事实判断来写，比用 #ifdef 跳过更有用——
    // 任何平台真的没有加速后端时都会走同一条路。
    Uint32 renderFlags = SDL_RENDERER_ACCELERATED;
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, renderFlags);
    bool fellBackToSoftware = false;
    if (!renderer) {
        SDL_ClearError();
        renderFlags = SDL_RENDERER_SOFTWARE;
        renderer = SDL_CreateRenderer(window, -1, renderFlags);
        fellBackToSoftware = true;
    }
    if (!renderer) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_RendererInfo info{};
    if (SDL_GetRendererInfo(renderer, &info) != 0) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_SetRenderDrawColor(renderer, 30, 30, 30, 255);
    int clearResult = SDL_RenderClear(renderer);
    SDL_RenderPresent(renderer);

    std::cout << "==== 02 开始 ====\n";
    std::cout << "videoDriver=" << SDL_GetCurrentVideoDriver() << '\n';
    std::cout << "rendererName=" << info.name << '\n';
    std::cout << "accelerated=" << ((info.flags & SDL_RENDERER_ACCELERATED) != 0)
              << ", fellBackToSoftware=" << fellBackToSoftware << '\n';
    std::cout << "clearResult=" << clearResult << '\n';
    std::cout << "==== 02 结束 ====\n";

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

实测：macOS 默认驱动（`cocoa`）——`build/shared/02_window_renderer.sec1`

```text
videoDriver=cocoa
rendererName=metal
accelerated=1, fellBackToSoftware=0
clearResult=0
```

同一个二进制在 `SDL_VIDEODRIVER=dummy` 下（无窗口会话）：

```text
videoDriver=dummy
rendererName=software
accelerated=0, fellBackToSoftware=1
clearResult=0
```

**这次 macOS 校验抓到的头号问题就在这里**：原版示例无条件要
`SDL_RENDERER_ACCELERATED`，在 `dummy` 下 `SDL_CreateRenderer` 返回 `nullptr`，
进程打印 `Couldn't find matching render driver` 后 `exit 1`。修法是「拿不到加速
就退到软件」——这不是给 macOS 打的补丁，任何没有加速后端的环境都走同一条路，
用事实判断写比用 `#ifdef` 跳过更结实。

**坑位清单**

3. 直接假设 `SDL_RENDERER_ACCELERATED` 一定成功：无窗口会话下必然失败，
   必须写软件降级分支（本例的 `fellBackToSoftware` 就是这段逻辑的可观测出口）。
4. 静态链接 SDL2 时忘了 frameworks：macOS 的 `libSDL2.a` 不带系统依赖，
   `libSDL2.a` 里的 Objective-C 符号（`objc_msgSend`、`_objc_sync_exit` 等）
   全部悬空，`ld: symbol(s) not found for architecture x86_64`。用
   `sdl2-config --static-libs` 取完整参数，别手工拼。
5. 把 `info.name` 写死进断言：macOS 是 `metal`，Windows 是 `direct3d*`，
   Linux 可能是 `opengl`；要断言就断言 `accelerated` 这类语义位。

**上一章：[初始化与版本信息](#初始化与版本信息)** ｜ **下一章：[事件循环骨架](#事件循环骨架)**

---

## 事件循环骨架

源码：`examples/03_event_loop_skeleton.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

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

    std::cout << "==== 03 开始 ====\n";
    std::cout << "loopTicks=" << ticks << ", running=" << running << '\n';
    std::cout << "==== 03 结束 ====\n";

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

实测输出：

```text
loopTicks=3, running=1
```

窗口用 `SDL_WINDOW_HIDDEN` 创建，既不抢焦点也不弹窗，回归脚本里能安静跑完。

**坑位清单**

6. 在纯 SSH（无 GUI 会话）里跑视频示例：macOS 的 `cocoa` 驱动拿不到
   WindowServer 连接时会失败。**本机始终在 GUI 会话中，这一条未实测**
   （属环境缺口，不是示例缺陷）；CI 请显式 `SDL_VIDEODRIVER=dummy`
   （已实测 10/10 通过）。
7. 靠 `SDL_QUIT` 事件退出循环：脚本环境里没人点关闭按钮，只能靠计数兜底；
   真实程序里两者都要有。

**上一章：[窗口与渲染器](#窗口与渲染器)** ｜ **下一章：[Surface 与 Texture](#surface-与-texture)**

---

## Surface 与 Texture

源码：`examples/04_texture_surface.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("Surface/Texture", 0, 0, 320, 240, SDL_WINDOW_HIDDEN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
    if (!window || !renderer) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_Surface* surface = SDL_CreateRGBSurfaceWithFormat(0, 64, 64, 32, SDL_PIXELFORMAT_RGBA32);
    if (!surface) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_FillRect(surface, nullptr, SDL_MapRGBA(surface->format, 255, 120, 0, 255));
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    if (!texture) {
        std::cerr << SDL_GetError() << '\n';
        SDL_FreeSurface(surface);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    Uint32 textureFormat = 0;
    int textureW = 0;
    int textureH = 0;
    if (SDL_QueryTexture(texture, &textureFormat, nullptr, &textureW, &textureH) != 0) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyTexture(texture);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    std::cout << "==== 04 开始 ====\n";
    // SDL_PIXELFORMAT_RGBA32 是「按本机字节序」的别名，不是固定内存布局：
    // 小端机（x86_64 / arm64 的 macOS、Linux、Windows）解析成 ABGR8888，
    // 大端机解析成 RGBA8888。要固定布局就用 *_8888 精确名。
    std::cout << "surfaceFormat=" << SDL_GetPixelFormatName(surface->format->format) << '\n';
    std::cout << "textureFormat=" << SDL_GetPixelFormatName(textureFormat)
              << ", textureSize=" << textureW << 'x' << textureH << '\n';
    std::cout << "==== 04 结束 ====\n";

    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

实测输出：

```text
surfaceFormat=SDL_PIXELFORMAT_ABGR8888
textureFormat=SDL_PIXELFORMAT_ABGR8888, textureSize=64x64
```

注意 `SDL_PIXELFORMAT_RGBA32` 被解析成了 `ABGR8888` —— 它是**按本机字节序**
的别名（`SDL_BYTEORDER == SDL_LIL_ENDIAN` 时等于 `ABGR8888`）。macOS 与
Windows 都是小端，所以两边结果一样；真要固定内存布局，写 `SDL_PIXELFORMAT_RGBA8888`
这类精确名。

**坑位清单**

8. 把 `SDL_PIXELFORMAT_RGBA32` / `ARGB32` 当固定通道顺序：它们是字节序相关
   别名，大端机上解析成另一个值；跨平台代码要显式写 `*_8888`。
9. Surface 与 Texture 的生命周期混淆：Surface 上传完就可以 `SDL_FreeSurface`，
   Texture 归渲染器管，必须 `SDL_DestroyTexture`；两者都要在 `SDL_Quit()` 之前释放。

**上一章：[事件循环骨架](#事件循环骨架)** ｜ **下一章：[基础绘制 API](#基础绘制-api)**

---

## 基础绘制 API

源码：`examples/05_draw_primitives.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("Draw", 0, 0, 320, 240, SDL_WINDOW_HIDDEN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
    if (!window || !renderer) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    int clearResult = SDL_RenderClear(renderer);

    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    int lineResult = SDL_RenderDrawLine(renderer, 10, 10, 300, 10);

    SDL_Rect rect{40, 40, 80, 60};
    SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);
    int fillResult = SDL_RenderFillRect(renderer, &rect);

    // SDL_RenderPresent 返回 void，成败只能看 SDL_GetError 有没有被写脏，
    // 所以先清一遍再调用——否则读到的是更早遗留的错误字符串。
    SDL_ClearError();
    SDL_RenderPresent(renderer);
    bool presentOk = SDL_GetError()[0] == '\0';

    std::cout << "==== 05 开始 ====\n";
    std::cout << "clearResult=" << clearResult
              << ", lineResult=" << lineResult
              << ", fillResult=" << fillResult
              << ", presentOk=" << presentOk << '\n';
    std::cout << "==== 05 结束 ====\n";

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

实测输出：

```text
clearResult=0, lineResult=0, fillResult=0, presentOk=1
```

**坑位清单**

10. `SDL_RenderPresent` 返回 `void`（这次写校验脚本时就被编译器抓到过：
    `cannot initialize a variable of type 'int' with an rvalue of type 'void'`）。
    要判成败只能 `SDL_ClearError()` → 调用 → 看 `SDL_GetError()` 是否为空；
    不先清，读到的是前面遗留的错误串。
11. `SDL_RenderDrawLine` / `RenderFillRect` 在失败时返回负数，但**不一定**设置
    错误串；批量绘制别指望逐个查错误，按批次返回值判断更实际。

**上一章：[Surface 与 Texture](#surface-与-texture)** ｜ **下一章：[计时与帧率](#计时与帧率)**

---

## 计时与帧率

源码：`examples/06_timer_fps.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_TIMER) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    const Uint32 frameTargetMs = 16;
    Uint32 frameBegin = SDL_GetTicks();

    SDL_Delay(5);

    Uint32 elapsed = SDL_GetTicks() - frameBegin;
    if (elapsed < frameTargetMs) {
        SDL_Delay(frameTargetMs - elapsed);
    }

    Uint32 frameTime = SDL_GetTicks() - frameBegin;

    // 区间内只放「跨机器都成立」的结论：补帧逻辑保证 frameTime >= 目标帧长。
    // 真实帧长与 fps 随负载波动（本机实测 17~19ms），放区间外只给人看，
    // 不参与字节比对——否则回归脚本会随机变红。
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

实测区间输出（稳定、参与字节比对）：

```text
frameTargetMs=16
frameTargetMet=1
```

区间外的观测行（`build/shared/06_timer_fps.run1`，值随机器波动）：

```text
[观测] frameTime(ms)=18, fps~=55.5556
```

**坑位清单**

12. 把实测帧长 / fps 当回归断言：本机连跑两次就是 17~19ms 的抖动，
    字节比对必然偶发失败。可验证的结论是「补帧后不快于目标帧长」这类
    **跨机器恒真**的命题，原始数值只做观测。
13. macOS 没有 GNU `timeout`，只有 MacPorts 的 `gtimeout`。验证脚本里
    探测顺序写成 `gtimeout` → `timeout`，并允许「都没有」时无上限运行，
    否则在 macOS 上整条回归链会因为命令找不到而 127 退出。

**上一章：[基础绘制 API](#基础绘制-api)** ｜ **下一章：[键盘输入状态](#键盘输入状态)**

---

## 键盘输入状态

源码：`examples/07_keyboard_state.cpp`

```cpp
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

    SDL_PumpEvents();
    int keyCount = 0;
    const Uint8* state = SDL_GetKeyboardState(&keyCount);
    bool leftPressed = state && state[SDL_SCANCODE_LEFT] != 0;

    std::cout << "==== 07 开始 ====\n";
    std::cout << "keyboard entries=" << keyCount << ", leftPressed=" << leftPressed << '\n';
    // 后台/无焦点进程的键盘状态全为 0：这不是平台差异，而是「没人按键」的
    // 事实。SDL_PumpEvents 只把窗口管理器送来的事件并入状态表，不会凭空
    // 造出按键——窗口未获焦点时收到的就是空表（entries 仍恒为 512）。
    std::cout << "stateAvailable=" << (state != nullptr) << '\n';
    std::cout << "==== 07 结束 ====\n";

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

实测输出：

```text
keyboard entries=512, leftPressed=0
stateAvailable=1
```

`entries` 恒为 `SDL_NUM_SCANCODES`（512），是数组长度而不是「按下的键数」。

**坑位清单**

14. 把 `leftPressed=0` 当成 macOS 拿不到键盘：那只是「没人按键」的事实。
    状态表来自窗口管理器送来的事件，后台进程收到的就是全 0；
    要断言就断言 `entries == 512` 与 `state != nullptr` 这类平台无关的量。
15. 忘了 `SDL_PumpEvents()`：`SDL_GetKeyboardState` 不会自己去收事件，
    不 pump 就永远读到上一次的状态。

**上一章：[计时与帧率](#计时与帧率)** ｜ **下一章：[音频回调模型](#音频回调模型)**

---

## 音频回调模型

源码：`examples/08_audio_callback.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <cmath>
#include <cstring>
#include <iostream>

struct ToneState {
    double phase = 0.0;
    double step = 2.0 * 3.141592653589793 * 440.0 / 48000.0;
};

void SDLCALL AudioCallback(void* userdata, Uint8* stream, int len) {
    auto* tone = static_cast<ToneState*>(userdata);
    std::memset(stream, 0, static_cast<size_t>(len));
    auto* out = reinterpret_cast<int16_t*>(stream);
    int sampleCount = len / static_cast<int>(sizeof(int16_t));
    for (int i = 0; i < sampleCount; ++i) {
        out[i] = static_cast<int16_t>(std::sin(tone->phase) * 2000.0);
        tone->phase += tone->step;
        if (tone->phase > 2.0 * 3.141592653589793) {
            tone->phase -= 2.0 * 3.141592653589793;
        }
    }
}

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_AUDIO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    ToneState tone{};
    SDL_AudioSpec desired{};
    desired.freq = 48000;
    desired.format = AUDIO_S16SYS;
    desired.channels = 1;
    desired.samples = 1024;
    desired.callback = AudioCallback;
    desired.userdata = &tone;

    SDL_AudioSpec obtained{};
    // requested vs obtained：驱动有权改 freq/channels/samples，
    // 回调里必须按 obtained 的参数算，不能假定 desired 被原样接受。
    SDL_AudioDeviceID dev = SDL_OpenAudioDevice(nullptr, 0, &desired, &obtained, 0);
    if (dev == 0) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    std::cout << "==== 08 开始 ====\n";
    std::cout << "deviceOpened=" << (dev > 0)
              << ", freq=" << obtained.freq
              << ", channels=" << static_cast<int>(obtained.channels)
              << ", samples=" << obtained.samples << '\n';
    std::cout << "==== 08 结束 ====\n";
    // 设备名取决于机器接了什么声卡，只做观测，不参与字节比对。
    std::cout << "[观测] 默认输出设备: " << SDL_GetAudioDeviceName(0, 0) << '\n';

    SDL_CloseAudioDevice(dev);
    SDL_Quit();
    return 0;
}
```

实测输出：

```text
deviceOpened=1, freq=48000, channels=1, samples=1024
```

观测行（设备名随机器变化）：

```text
[观测] 默认输出设备: Built-in Output
```

**坑位清单**

16. 假设 `obtained` 一定等于 `desired`：驱动有权改 `freq`/`channels`/`samples`。
    回调里的相位步进必须按 `obtained.freq` 算，写死 48000 在改了采样率的设备上
    音高就跑偏。
17. 把设备名写进断言：`Built-in Output` 这种名字取决于机器上插了什么，
    只做观测。
18. 在回调里做阻塞操作（加锁、分配、IO）：回调跑在 SDL 的音频线程上，
    超时会导致爆音。要传数据就用环形缓冲 + 原子下标。

**上一章：[键盘输入状态](#键盘输入状态)** ｜ **下一章：[线程与互斥锁](#线程与互斥锁)**

---

## 线程与互斥锁

源码：`examples/09_threads_mutex.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

struct Counter {
    SDL_mutex* mutex = nullptr;
    int value = 0;
};

int SDLCALL Worker(void* userdata) {
    auto* counter = static_cast<Counter*>(userdata);
    for (int i = 0; i < 1000; ++i) {
        SDL_LockMutex(counter->mutex);
        ++counter->value;
        SDL_UnlockMutex(counter->mutex);
    }
    return 0;
}

int main() {
    SDL_SetMainReady();
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

    std::cout << "==== 09 开始 ====\n";
    std::cout << "counter=" << counter.value << '\n';
    std::cout << "==== 09 结束 ====\n";

    SDL_DestroyMutex(counter.mutex);
    SDL_Quit();
    return 0;
}
```

实测输出：

```text
counter=2000
```

`counter=2000` 是**确定性**的：`SDL_WaitThread` 保证了 happens-before，
两线程各加 1000。这条能被放进字节比对区间，正是因为它不依赖调度顺序。

**坑位清单**

19. 用 `SDL_Delay` 等线程结束而不是 `SDL_WaitThread`：既没有同步语义，
    还会让结果依赖调度，`counter` 变成随机值。
20. 只 `SDL_WaitThread` 了创建成功的那一个：本例的失败分支两个都等，
    少等一个就会漏掉线程的返回状态、甚至悬空 mutex。

**上一章：[音频回调模型](#音频回调模型)** ｜ **下一章：[C++ RAII 封装](#c-raii-封装)**

---

## C++ RAII 封装

源码：`examples/10_raii_wrappers.cpp`

```cpp
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>
#include <memory>

struct WindowDeleter {
    void operator()(SDL_Window* p) const { SDL_DestroyWindow(p); }
};

struct RendererDeleter {
    void operator()(SDL_Renderer* p) const { SDL_DestroyRenderer(p); }
};

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    std::unique_ptr<SDL_Window, WindowDeleter> window(
        SDL_CreateWindow("RAII", 0, 0, 320, 240, SDL_WINDOW_HIDDEN)
    );
    if (!window) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    std::unique_ptr<SDL_Renderer, RendererDeleter> renderer(
        SDL_CreateRenderer(window.get(), -1, SDL_RENDERER_SOFTWARE)
    );
    if (!renderer) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    SDL_SetRenderDrawColor(renderer.get(), 20, 40, 60, 255);
    int clearResult = SDL_RenderClear(renderer.get());
    SDL_RenderPresent(renderer.get());

    std::cout << "==== 10 开始 ====\n";
    std::cout << "clearResult=" << clearResult << '\n';
    std::cout << "==== 10 结束 ====\n";

    // 必须在 SDL_Quit() **之前** 释放：unique_ptr 的析构发生在函数返回时，
    // 那时 SDL_Quit() 已经把视频子系统拆掉了，DestroyWindow/DestroyRenderer
    // 就成了「子系统已卸载后再调用」——当前版本的 SDL 会静默吞掉，但这是
    // 未定义行为范围，换实现/换平台就可能炸。RAII 的正确性是靠显式 reset
    // 保住的，不是靠 unique_ptr 本身。
    renderer.reset();
    window.reset();

    SDL_Quit();
    return 0;
}
```

实测输出：

```text
clearResult=0
```

**这次校验修掉的第二处真问题**：原版把 `SDL_Quit()` 写在最后，`unique_ptr`
的析构发生在函数返回时——也就是**子系统已经卸载之后**。用
`-fsanitize=address,undefined` 跑当下的 SDL 2.32.10 并不报错（它把这种调用
静默吞了），但这属于未定义行为范围，换实现或换平台就可能炸。RAII 在这里
保的是「不泄漏」，保不了「顺序对」，顺序得靠显式 `reset()`。

**坑位清单**

21. 以为 `unique_ptr` 自动解决了生命周期顺序：它只保证「最终会释放」，
    不保证「在 `SDL_Quit()` 之前释放」。凡是有全局 init/quit 语义的库
    （SDL、curl、OpenSSL…）都有这个坑。
22. 自定义 deleter 只处理非空指针还不够：`SDL_DestroyWindow(nullptr)` 虽是
    空操作，但顺序错误照样会踩到已卸载的子系统。

**上一章：[线程与互斥锁](#线程与互斥锁)** ｜ **下一章：[macOS 平台差异与坑位](#macos-平台差异与坑位)**

---

## macOS 平台差异与坑位

这一章是本次 macOS 兼容性校验的产物，全部结论来自本机实测
（Darwin 23.6 x86_64 / Apple clang 16.0.0 / SDL2 2.32.10）。

### 构建侧

| 主题 | Windows / MSVC | macOS / clang |
|---|---|---|
| 配置工具 | 手工指定 `include\SDL2` + `SDL2.lib` | `sdl2-config --cflags/--libs` |
| 静态链接 | `SDL2.lib` 自带依赖 | `libSDL2.a` 不带系统依赖，缺 frameworks 直接链接失败 |
| 视频驱动 | `windows` | `cocoa`（默认）/`dummy`（无窗口会话） |
| 硬件渲染器 | `direct3d*` | `metal`（SDL 2.32 起，`opengl` 仍可用） |
| 超时命令 | 无内置 | `gtimeout`（MacPorts coreutils），没有 GNU `timeout` |

`sdl2-config --static-libs` 的实际输出（这串就是 macOS 静态链接的正确答案）：

```text
-L/opt/local/lib /opt/local/lib/libSDL2.a -lm -Wl,-framework,CoreAudio
-Wl,-framework,AudioToolbox -Wl,-weak_framework,CoreHaptics
-Wl,-weak_framework,GameController -Wl,-framework,ForceFeedback -lobjc
-Wl,-framework,CoreVideo -Wl,-framework,Cocoa -Wl,-framework,Carbon
-Wl,-framework,IOKit -Wl,-weak_framework,QuartzCore -Wl,-weak_framework,Metal
```

少了它们，链接器会报一堆 Objective-C 符号缺失，最后一行是（实测留档
`build/static-link-missing-frameworks.err`）：

<!-- 链接器错误原文（反例记录），非示例运行输出 -->
```text
ld: symbol(s) not found for architecture x86_64
```

（上面这段是**实测的链接错误原文**，不是构造的示意。）

### 运行侧

- **渲染器降级**：`dummy` 驱动下 `SDL_RENDERER_ACCELERATED` 必然失败，报
  `Couldn't find matching render driver`。修法见第 3 章，示例 02 已改。
- **帧长抖动**：同一台机器连跑两次 `SDL_GetTicks()` 差值在 17~19ms 之间漂，
  不能做字节比对断言。
- **像素格式别名**：`SDL_PIXELFORMAT_RGBA32` 在小端机上解析为 `ABGR8888`；
  macOS 与 Windows 同为小端，这次没有差异，但别把它当固定布局。

### 本机无法验证、需真机确认的点

- **纯 SSH（无 GUI 会话）下 `cocoa` 驱动的行为**：推断 `SDL_Init(SDL_INIT_VIDEO)`
  会失败，但本机始终有 GUI 会话，造不出该场景。CI 请直接 `SDL_VIDEODRIVER=dummy`。
- **Windows/MSVC 实跑结果**：本机无 MSVC，`build.ps1` 只做了语法解析，
  判定逻辑与 `run-all.sh` 逐条对齐但未实跑。
- **Apple Silicon（arm64）**：本机为 x86_64，未做交叉验证。示例不含架构相关代码，
  理论上可直接编译，需真机确认。

**上一章：[C++ RAII 封装](#c-raii-封装)** ｜ **下一章：[统一编译验证](#统一编译验证)**

---

## 统一编译验证

macOS / Linux：

```bash
./run-all.sh            # 全部示例 × shared/static 双通道
./run-all.sh -v         # 附带每个示例的区间输出
./run-all.sh 02 06      # 只跑指定编号
./run-all.sh --one      # 只跑 shared 一条通道
```

Windows：

```powershell
.\build.ps1 -All
.\build.ps1 -File 06_timer_fps.cpp
.\build.ps1 -CompileOnly
.\build.ps1 -Clean
```

判定标准（两个入口共用，shell 版多一条双通道比对）：

1. 编译退出码 0，且编译期 stderr 为空（`-Wall -Wextra`，任何告警即失败）
2. 运行退出码 0
3. 运行 stderr 为空
4. stdout 里同时出现 `==== NN 开始 ====` 与 `==== NN 结束 ====`
5. 两标记之间的区间非空，且不含控制字符
6. 同一通道连跑两次，区间逐字节一致
7. **（仅 shell 版）** shared 与 static 两条通道的区间逐字节一致

第 7 条的存在理由：两个产物由同一份源码编译，比对不是为了验证两种语义，
而是检验**示例没有偷偷依赖动态库加载或安装前缀**。

示例输出里的 `==== NN 开始/结束 ====` 区间就是为这套判定准备的：区间内只放
**跨机器恒真**的事实（驱动名、渲染器名、返回码、`counter` 这类确定性结果），
会随机器/负载漂移的量（帧长、fps、声卡名）一律挪到区间外的 `[观测]` 行，
不参与字节比对。

本机实测结果：

```text
 通过 10  失败 0  （示例总数 10，通道 2 条）
```

`SDL_VIDEODRIVER=dummy` 下同样 10/10 通过。建议每次新增或修改示例后都执行
`./run-all.sh`，确保教程示例持续可编译、可运行、可比对。

**上一章：[macOS 平台差异与坑位](#macos-平台差异与坑位)**
