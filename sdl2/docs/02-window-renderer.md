# 02 · 窗口与渲染器：加速后端拿不到怎么办

> 对应示例：[examples/02_window_renderer.cpp](../examples/02_window_renderer.cpp)

窗口 + 渲染器是 SDL2 图形侧的最小组合，也是本次 macOS 校验**抓到头号问题**的地方：原版示例无条件要 `SDL_RENDERER_ACCELERATED`，在无窗口会话下 `SDL_CreateRenderer()` 返回 `nullptr`，进程打印 `Couldn't find matching render driver` 后 `exit 1`。本章先把两个对象的参数语义讲透，再回到这段降级逻辑——它最后的写法比"给 macOS 打补丁"结实得多，而且同一份二进制在两种环境下各跑各的路径，两条路都有实测输出。

## 2.0 本章示例的骨架

```cpp
// ═══ 2.0 骨架：入口仪式三行 + 只开 VIDEO 子系统 ═══
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }
```

三行入口仪式（`SDL_MAIN_HANDLED` + `SDL_SetMainReady()` + 标准 `int main()`）在 [01 章](01-init-version.md)逐行讲过，本章及后续每一章的示例都以它开头，后文不再重复解释。**每章只有 `SDL_Init` 的子系统位不同**——这里是 `SDL_INIT_VIDEO`，06/09 章是 `SDL_INIT_TIMER`，08 章是 `SDL_INIT_AUDIO`。子系统位决定 SDL 去探测哪些后端，也决定了失败信息出现在哪一行。

失败即 `return 1` 是本章所有示例的统一约定：不 `SDL_Quit()`，因为一个子系统都没起来，没什么可拆的。

## 2.1 建窗口：位置常量与"默认就被显示"的陷阱

```cpp
// ═══ 2.1 窗口：位置用平台无关的常量，状态显式 HIDDEN ═══
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
```

六个参数依次是标题、x、y、宽、高、标志位。位置这两个参数不是像素坐标，而是一类特殊常量：

| 写法 | 语义 |
|---|---|
| `SDL_WINDOWPOS_CENTERED` | 该轴居中（等价于 `SDL_WINDOWPOS_CENTERED_DISPLAY(0)`，即第 0 块显示器） |
| `SDL_WINDOWPOS_UNDEFINED` | 交给窗口管理器决定 |
| 普通整数（如本例 03/04 章传的 `0, 0`） | 显式坐标 |

标志位里最容易踩的是**默认可见**：SDL 的文档措辞是"未设置 `SDL_WINDOW_HIDDEN` 时窗口被隐式显示"。回归脚本要的恰恰是相反的行为——不抢焦点、不弹窗、安静跑完——所以本教程所有示例都显式传 `SDL_WINDOW_HIDDEN`。常用标志一览：

| 标志 | 用途 |
|---|---|
| `SDL_WINDOW_HIDDEN` / `SDL_WINDOW_SHOWN` | 初始可见性；后续用 `SDL_ShowWindow`/`SDL_HideWindow` 切 |
| `SDL_WINDOW_BORDERLESS` | 无边框 |
| `SDL_WINDOW_RESIZABLE` | 允许用户拉伸；配合渲染器要自己处理尺寸变化 |
| `SDL_WINDOW_ALLOW_HIGHDPI` | 高 DPI 下可绘制尺寸 ≠ 逻辑尺寸（见 2.5 的坑） |
| `SDL_WINDOW_FULLSCREEN_DESKTOP` | 桌面分辨率全屏 |

## 2.2 拿渲染器：先要加速，拿不到退一档

```cpp
// ═══ 2.2 事实判断式的降级：不是 #ifdef，而是"创建失败就退一档" ═══
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
```

`SDL_CreateRenderer(window, index, flags)` 三个参数各有讲究：

- **`index = -1`** 是"随便给我个合适的"。填 `0` 不是"最优"，而是"该平台枚举出的第 0 个驱动"——不同平台/不同 SDL 版本的枚举顺序不一样，写死数字等于把可移植性交给运气。
- **`flags`** 是需求，不是保证：`SDL_RENDERER_ACCELERATED`（硬件后端）、`SDL_RENDERER_SOFTWARE`（CPU 后端）、`SDL_RENDERER_PRESENTVSYNC`（`SDL_RenderPresent` 与刷新率同步）、`SDL_RENDERER_TARGETTEXTURE`（支持离屏目标纹理）。位之间是 **AND** 关系——全满足才给创建，否则返回 `nullptr`。
- **失败要 `SDL_ClearError()` 再重试**：第一次失败的错误串（`Couldn't find matching render driver`）留在缓冲区里，不清就直接重试，第二次即便成功，后面读 `SDL_GetError()` 还会读到那句旧错——本教程 01/05 章讲的"成功不清空"约定在这里落地。

为什么用"创建失败就退一档"而不是 `#ifdef __APPLE__`：无窗口会话（`SDL_VIDEODRIVER=dummy`、Linux CI、SSH）在任何操作系统上都没有加速后端，`#ifdef` 按操作系统分支恰好分错维度。事实判断让**任何**没有加速后端的环境都走同一条路——这也让降级本身可验证：`fellBackToSoftware` 就是这段逻辑的可观测出口（2.5 的两份实测输出正好各走一条分支）。

## 2.3 问它到底是什么：`SDL_GetRendererInfo`

```cpp
// ═══ 2.3 查询渲染器身份：名字随平台变，flags 才是语义位 ═══
    SDL_RendererInfo info{};
    if (SDL_GetRendererInfo(renderer, &info) != 0) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }
```

`SDL_RendererInfo` 里 `name` 是后端名，`flags` 是**实际拿到的**能力位，`num_texture_formats`/`texture_formats` 是该后端支持的像素格式，`max_texture_size` 是上限。断言只写 `flags` 语义位、永不写 `name`（`name` 只做观测）——理由见坑位清单第 7 条。

另外别把 `SDL_GetRendererInfo`（问已存在的渲染器）和 `SDL_GetRenderDriverInfo(i, &info)`（枚举第 i 个后端，创建之前问）混用：后者用来回答"这台机器上有什么可选"，配合 `SDL_GetNumRenderDrivers()` 才是完整一轮探测。

## 2.4 绘制、呈现与销毁顺序

```cpp
// ═══ 2.4 一帧的最小闭环：设色 → 清屏 → 呈现 ═══
    SDL_SetRenderDrawColor(renderer, 30, 30, 30, 255);
    int clearResult = SDL_RenderClear(renderer);
    SDL_RenderPresent(renderer);
```

```cpp
// ═══ 2.4b 销毁顺序与创建顺序相反：渲染器 → 窗口 → 子系统 ═══
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

`SDL_RenderClear` 清的是**当前绘制目标**的后端缓冲，`SDL_RenderPresent` 把后端缓冲推到屏幕；两者之间没有"自动清屏"，双缓冲由渲染器管。注意 `SDL_RenderPresent` 返回 `void`——本例这里不看它的返回值，判成败靠错误串（05 章把这套写全）。

## 2.5 两份实测输出：同一份二进制，两条分支

下面那两份输出是本章示例的这段代码打的——四个量全部来自前面小节留下的变量，没有一个是现算的：

```cpp
// ═══ 2.5 观测点的取材：驱动名、渲染器身份、语义位、返回码 ═══
    std::cout << "==== 02 开始 ====\n";
    std::cout << "videoDriver=" << SDL_GetCurrentVideoDriver() << '\n';
    std::cout << "rendererName=" << info.name << '\n';
    std::cout << "accelerated=" << ((info.flags & SDL_RENDERER_ACCELERATED) != 0)
              << ", fellBackToSoftware=" << fellBackToSoftware << '\n';
    std::cout << "clearResult=" << clearResult << '\n';
    std::cout << "==== 02 结束 ====\n";
```

默认（macOS，`cocoa` 驱动，`build/shared/02_window_renderer.run1`）：

```text
==== 02 开始 ====
videoDriver=cocoa
rendererName=metal
accelerated=1, fellBackToSoftware=0
clearResult=0
==== 02 结束 ====
```

同一个产物加 `SDL_VIDEODRIVER=dummy`（无窗口会话，`build/dummy-driver-02.out`）：

```text
==== 02 开始 ====
videoDriver=dummy
rendererName=software
accelerated=0, fellBackToSoftware=1
clearResult=0
==== 02 结束 ====
```

四行对照读：`videoDriver` 来自 `SDL_GetCurrentVideoDriver()`，回答"SDL 这次挑了哪个视频后端"（macOS 默认 `cocoa`，Windows 默认 `windows`）；`rendererName` 在两条分支上分别是 `metal`（SDL 2.32 起 macOS 的硬件后端，`opengl` 仍可选）与 `software`；`accelerated` 是 `info.flags & SDL_RENDERER_ACCELERATED` 的语义位，`fellBackToSoftware` 是 2.2 那段降级的旗标——**两份输出的差异全部由代码里的事实判断产生，没有任何平台分支**。`clearResult=0` 两边一致，说明软件后端照样能清屏呈现，只是慢。

`SDL_WINDOW_ALLOW_HIGHDPI` 是这里唯一要补的尺寸课：带上它之后，可绘制尺寸（drawable）可能是逻辑尺寸的 2 倍，绘制坐标按 drawable 算。本教程示例一律不开 HighDPI，尺寸语义保持"1 单位 = 1 设备像素"，读输出时不会被两套坐标干扰。

## 坑位清单

4. **无条件要 `SDL_RENDERER_ACCELERATED`**：`dummy` 驱动下必然失败（`Couldn't find matching render driver`），`SDL_CreateRenderer` 返回 `nullptr`。必须写"拿不到加速就退软件"的事实降级，并留一个可观测出口（本例的 `fellBackToSoftware`）。
5. **只请求 `SDL_RENDERER_ACCELERATED` 却指望自带 vsync**：位之间是 **AND 语义**（11 章实测矩阵：`dummy` 下 `ACCELERATED` 与 `ACCELERATED|PRESENTVSYNC` 都返回 `nullptr` + `Couldn't find matching render driver`），而没请求的位也不会白给——只传 `ACCELERATED` 时 `SDL_GetRendererInfo` 回来的 `flags` 是 `10`（`ACCELERATED|TARGETTEXTURE`，不含 `PRESENTVSYNC`），`SDL_RenderPresent` 就不会阻塞。vsync 要显式请求，然后用 `info.flags & SDL_RENDERER_PRESENTVSYNC` 复查**实际拿到了**什么。
6. **`SDL_CreateRenderer` 的 index 写死 `0`**：`-1` 才是"任选"；`0` 是"该平台枚举出的第 0 个驱动"，跨平台/跨 SDL 版本含义不同，等于把可移植性交给枚举顺序。
7. **把 `SDL_RendererInfo.name` 写进断言**：macOS 是 `metal`，Windows 是 `direct3d`/`direct3d11`，Linux 常见 `opengl`。断言只写 `accelerated` 这类语义位，名字做观测打印。

---

上一章：[01 · 初始化与版本：把入口权拿回自己手里](01-init-version.md) ｜ 下一章：[03 · 事件循环骨架：PollEvent 与"没人点关闭"的退出](03-event-loop.md) ｜ 返回：[README](../README.md)
