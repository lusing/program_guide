# SDL2 编程指南（Windows + MSVC）

本指南按 `guide` 统一结构编写：教程文档 + 独立示例源码 + `build.ps1` 一键编译验证。  
示例目录：`examples/`，构建入口：`build.ps1`。

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
12. [统一编译验证](#统一编译验证)

---

## 环境准备

- SDL2：`G:\scoop\apps\sdl2\current`
- VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC`
- 教程目录：`G:\code\guide\sdl2`

本目录使用 `cl.exe` + `SDL2.lib` 编译示例，不依赖 C# 或 .NET 工程。

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

    SDL_version linked{};
    SDL_GetVersion(&linked);
    std::cout << "Linked SDL version: "
              << static_cast<int>(linked.major) << '.'
              << static_cast<int>(linked.minor) << '.'
              << static_cast<int>(linked.patch) << '\n';

    SDL_Quit();
    return 0;
}
```

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

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_SetRenderDrawColor(renderer, 30, 30, 30, 255);
    SDL_RenderClear(renderer);
    SDL_RenderPresent(renderer);

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

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

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

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

    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

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
    SDL_RenderClear(renderer);

    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    SDL_RenderDrawLine(renderer, 10, 10, 300, 10);

    SDL_Rect rect{40, 40, 80, 60};
    SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);
    SDL_RenderFillRect(renderer, &rect);

    SDL_RenderPresent(renderer);

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

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
    double fps = frameTime > 0 ? 1000.0 / frameTime : 0.0;
    std::cout << "frameTime(ms)=" << frameTime << ", fps~=" << fps << '\n';

    SDL_Quit();
    return 0;
}
```

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
    std::cout << "keyboard entries=" << keyCount << ", leftPressed=" << leftPressed << '\n';

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

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
    SDL_AudioDeviceID dev = SDL_OpenAudioDevice(nullptr, 0, &desired, &obtained, 0);
    if (dev == 0) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    SDL_CloseAudioDevice(dev);
    SDL_Quit();
    return 0;
}
```

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
    std::cout << "counter=" << counter.value << '\n';

    SDL_DestroyMutex(counter.mutex);
    SDL_Quit();
    return 0;
}
```

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
    SDL_RenderClear(renderer.get());
    SDL_RenderPresent(renderer.get());

    SDL_Quit();
    return 0;
}
```

---

## 统一编译验证

在本目录执行：

```powershell
cd G:\code\guide\sdl2
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 03_event_loop_skeleton.cpp
```

清理：

```powershell
.\build.ps1 -Clean
```

建议每次新增或修改示例后都执行 `-All`，确保教程示例持续可编译。

