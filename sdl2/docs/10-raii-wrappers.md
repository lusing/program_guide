# 10 · C++ RAII 封装：不泄漏不等于顺序对

> 对应示例：[examples/10_raii_wrappers.cpp](../examples/10_raii_wrappers.cpp)

SDL 是 C API，返回裸句柄，销毁函数各自不同——这正是 C++ 智能指针的标准用武之地。本章示例给窗口和渲染器各配一个 `unique_ptr` + 自定义 deleter。它也是本次 macOS 校验**修掉的第二处真问题**：原版把 `SDL_Quit()` 写在函数末尾，`unique_ptr` 的析构发生在函数返回时，也就是**子系统已经卸载之后**再去 `DestroyWindow`。当时的 SDL 静默吞下了这种调用，ASan/UBSan 也没报错，但它落在未定义行为的范围里——换实现、换平台就是雷。

## 10.0 本章示例的骨架

```cpp
// ═══ 10.0 骨架：入口仪式三行 + <memory> + VIDEO 子系统 ═══
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>
#include <memory>

// ……（两个 deleter 结构体见 10.1）……

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
```

骨架见 [01 章](01-init-version.md)。本章比前面多一个头：`<memory>` 提供 `std::unique_ptr`。`SDL_MAIN_HANDLED` 在这里还有一层额外意义——`SDL_Quit()` 必须显式写在函数末尾（而不是靠某个包装对象的析构），10.4 的正题就落在这个顺序上。

## 10.1 deleter 只是薄薄一层

```cpp
// ═══ 10.1 自定义 deleter：一个只有 operator() 的结构体 ═══
struct WindowDeleter {
    void operator()(SDL_Window* p) const { SDL_DestroyWindow(p); }
};

struct RendererDeleter {
    void operator()(SDL_Renderer* p) const { SDL_DestroyRenderer(p); }
};
```

`unique_ptr<T, D>` 要求 `D` 可默认构造、`operator()` 接受 `T*`。deleter 里**不要判空**、不要加日志、不要抛异常——析构路径上抛异常等于 `std::terminate`。`SDL_DestroyWindow(nullptr)`/`SDL_DestroyRenderer(nullptr)` 都是直接返回的空操作（04 章已经利用过这条），所以不判空既安全又少一层噪音。

## 10.2 包装点：从创建那一行开始拥有

```cpp
// ═══ 10.2 用创建函数的返回值直接构造智能指针，中间不留裸指针窗口期 ═══
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
```

关键在**构造即接管**：`SDL_CreateWindow(...)` 的结果直接进 `unique_ptr` 的构造函数，没有"拿到裸指针但还没交给所有者"的中间地带。写成 `SDL_Window* raw = SDL_CreateWindow(...); unique_ptr<...> p(raw);` 之间的每一行提前 `return` 都是一次泄漏。

第二条 `if (!renderer)` 分支里只 `SDL_Quit()` 没有手动销毁 window——`unique_ptr` 已经接手了，这是 RAII 买到的东西：错误路径不再需要重复清理代码。02/04 章那种手写四五行阶梯式清理的写法，在 C++ 里都可以收敛成这样。

## 10.3 用法与前面几章一致

```cpp
// ═══ 10.3 .get() 把裸指针交给 C API：拥有权仍在智能指针手里 ═══
    SDL_SetRenderDrawColor(renderer.get(), 20, 40, 60, 255);
    int clearResult = SDL_RenderClear(renderer.get());
    SDL_RenderPresent(renderer.get());

    std::cout << "==== 10 开始 ====\n";
    std::cout << "clearResult=" << clearResult << '\n';
    std::cout << "==== 10 结束 ====\n";
```

`build/shared/10_raii_wrappers.run1`：

```text
==== 10 开始 ====
clearResult=0
==== 10 结束 ====
```

给 C API 传指针一律用 `.get()`，拥有权不外借（更不能用 `.release()` 然后把裸指针交给 SDL——SDL 的 API 全都是"不接管拥有权"的）。

## 10.4 全章的正题：显式 `reset()` 才保住顺序

```cpp
// ═══ 10.4 顺序靠显式 reset 保住，不靠析构时机 ═══
    renderer.reset();
    window.reset();

    SDL_Quit();
    return 0;
}
```

`unique_ptr` 保证的是**"最终会释放"**，不是**"在某个时刻之前释放"**。默认析构点在函数返回时，而 `SDL_Quit()` 早在返回之前就拆掉了视频子系统——顺序成了：

1. `SDL_Quit()`：卸载子系统；
2. 函数 `return`：`renderer`/`window` 析构，调用 `SDL_DestroyRenderer` / `SDL_DestroyWindow`。

也就是"对已卸载的子系统调用其 API"。当下的 SDL 2.32.10 里这类调用被静默忽略（本机用 `-fsanitize=address,undefined` 跑过，未报错），但**"当前实现不报"不是"合法"**：SDL 的文档没有承诺卸载后调用这些函数的行为，换后端实现或换平台就可能炸。修法就是 10.4 这两行——把释放时机**写进控制流**，`SDL_Quit()` 成为所有 SDL 句柄的截止线（01 章 1.5 节预告过的就是这条纪律）。

顺带一个真实约束：`SDL_DestroyWindow` 会连带处理挂在它上面的渲染资源，不同后端的具体行为是实现细节。所以"先 renderer 后 window"这个倒序不是审美问题，是让每一层资源都由自己的销毁函数收尾，别依赖连带清理。

## 10.5 什么时候这个模式不够用

- **值语义句柄不适用**：`SDL_AudioDeviceID` 是 `Uint32`（08 章），`unique_ptr` 的模板参数得是指针。这类句柄要么写个小 scope guard（构造持有、析构 `SDL_CloseAudioDevice`），要么用 `std::experimental::scope_guard` 类工具手写一个。
- **deleter 需要上下文时**：`SDL_DestroyTexture` 不需要渲染器，但队列式音频、`SDL_GPU`（SDL3）之类的 API 销毁时要带上父对象。deleter 变成有状态的函数对象，`unique_ptr` 的尺寸随之增加——依然可行，只是别默认它是零成本。
- **跨线程交接所有权**：SDL 的窗口/渲染器不是线程安全的（09 章 9.5 的纪律），别把 `unique_ptr<SDL_Renderer, ...>` `std::move` 进 worker 线程去画。

## 坑位清单

32. **以为 `unique_ptr` 自动解决了生命周期顺序**：它只保证"最终释放"，不保证"在 `SDL_Quit()` 之前释放"。本例原样就是这个 bug（校验时实测修掉），当前 SDL 静默吞掉但不等于合法。凡是带全局 init/quit 语义的库（SDL、curl、OpenSSL）都有这个坑，一律在 `*_Quit`/`*_cleanup` **之前**显式 `reset()`。
33. **只给 deleter 加判空就当安全**：`SDL_DestroyWindow(nullptr)` 确实是空操作，但顺序错了照样踩已卸载的子系统；判空解决"重复释放"，解决不了"时机不对"。反过来说，deleter 里加日志/抛异常会让析构路径变成 `std::terminate` 的入口。
34. **把拥有权交给 C API**：SDL 的所有 `Create*`/`Destroy*` 都不接管拥有权，传 `.get()` 就好；用 `.release()` 交出去等于放弃了 RAII，早退分支立刻泄漏。值句柄（`SDL_AudioDeviceID`）另写 scope guard，别硬塞进 `unique_ptr`。

---

上一章：[09 · 线程与互斥锁：让 `counter=2000` 成为确定性断言](09-threads-mutex.md) ｜ 下一章：[11 · 平台差异：macOS 与 Windows 的构建和运行分野](11-platform-macos.md) ｜ 返回：[README](../README.md)
