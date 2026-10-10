# 04 · Surface 与 Texture：像素在 CPU 还是在 GPU

> 对应示例：[examples/04_texture_surface.cpp](../examples/04_texture_surface.cpp)

SDL2 有两套像素世界，新手把它们混成一个正是各种"贴图黑块""颜色反了"的根源：**`SDL_Surface` 是 CPU 内存里的一块像素缓冲，`SDL_Texture` 是渲染器（也就是后端）持有的纹理资源**。本章示例走完一条最小通路——在 CPU 里造一张 64×64 的纯色 Surface，填色，上传成 Texture，再把两者的真实格式查出来打印。查出来的格式和源码里写的格式**名字不一样**，这正是本章最有价值的一课。

## 4.0 本章示例的骨架

```cpp
// ═══ 4.0 骨架：入口仪式三行 + 只开 VIDEO ═══
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

骨架见 [01 章](01-init-version.md)。本章示例只要 `SDL_INIT_VIDEO`——Surface 那半边（`SDL_CreateRGBSurfaceWithFormat`、`SDL_FillRect`）纯粹是 CPU 内存操作，不开任何子系统也能跑；是**上传成 Texture** 这一步才需要视频子系统与渲染器，于是整个示例的子系统位就由它决定。

## 4.1 为什么需要渲染器在手

```cpp
// ═══ 4.1 软件渲染器：本章不关心快，只关心上传通路 ═══
    SDL_Window* window = SDL_CreateWindow("Surface/Texture", 0, 0, 320, 240, SDL_WINDOW_HIDDEN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
    if (!window || !renderer) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }
```

`SDL_CreateTextureFromSurface` 的第一个参数就是渲染器——纹理是**渲染器的资源**，不是全局的。所以 Surface→Texture 这条链必然要有 02 章那两个对象打底。

这里请求的是 `SDL_RENDERER_SOFTWARE` 而不是"先加速再退档"：本章要验证的是像素搬运通路，软件后端反而让两平台的输出更一致。顺带看一眼这段错误分支的写法：条件合并成 `!window || !renderer`，清理却照常两行顺序调用——SDL 的 `SDL_DestroyRenderer(nullptr)` / `SDL_DestroyWindow(nullptr)` 都是直接返回的空操作，不必逐层判空。

## 4.2 CPU 侧：`SDL_Surface` 与它的 format/pitch

```cpp
// ═══ 4.2 造一张 CPU 像素缓冲：WithFormat 只给格式，不手工拼掩码 ═══
    SDL_Surface* surface = SDL_CreateRGBSurfaceWithFormat(0, 64, 64, 32, SDL_PIXELFORMAT_RGBA32);
    if (!surface) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_FillRect(surface, nullptr, SDL_MapRGBA(surface->format, 255, 120, 0, 255));
```

三个细节：

- **第一个参数 `flags` 传 `0`**：它是 SDL 1.2 时代遗留的表面标志位，2.x 里基本没有可选行为，写 `0` 就是"SDL 自己 `malloc` 像素内存"。**用别人的内存**要走另一条 API：`SDL_CreateRGBSurfaceWithFormatFrom(pixels, w, h, depth, pitch, format)`，它不持有那块缓冲，`SDL_FreeSurface` 也不会替你 `free`（提前释放原缓冲就是悬空指针）。
- **`SDL_CreateRGBSurfaceWithFormat` 优于 `SDL_CreateRGBSurface`**：后者要你自己填四个通道掩码（`rmask/gmask/bmask/amask`），那是 SDL 1.2 的遗风且极易写错字节序；前者只要一个 `SDL_PIXELFORMAT_*`，掩码由格式表推。
- **`SDL_MapRGBA(surface->format, r, g, b, a)` 属于 Surface，不属于渲染器**：它把 RGBA 四分量按这块 `format` 的掩码与位移打包成一个 `Uint32` 像素值，喂给 `SDL_FillRect`/`SDL_PixelFormat` 系操作。渲染器那侧对应的是 `SDL_SetRenderDrawColor(renderer, r, g, b, a)`，两组 API 不能换着用——把 `SDL_MapRGBA` 的结果当颜色传给渲染器是典型的"哪都对不上"。
- **`SDL_FillRect(surface, nullptr, pixel)` 的 `nullptr` 矩形 = 整个 Surface**，与渲染器侧 `SDL_RenderFillRect` 必须给矩形不同。

`surface->pitch` 是**一行的字节数**，不一定等于 `w × 字节/像素`（后端会按对齐加宽）。任何手动逐像素读写都得按 `pitch` 走行，不能按 `w*4`——`SDL_LockSurface` 之后手写循环最容易在这儿越界。

## 4.3 上传：Surface 交出去，Texture 归渲染器

```cpp
// ═══ 4.3 上传：一次拷贝，从此与 Surface 再无关系 ═══
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    if (!texture) {
        std::cerr << SDL_GetError() << '\n';
        SDL_FreeSurface(surface);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }
```

`SDL_CreateTextureFromSurface` 做的是**一次性格式转换 + 拷贝**：按渲染器支持的格式重建像素，交给后端。返回后 Texture 与 Surface 完全独立，改 Surface 不会改到 Texture。

需要持续改像素的内容（视频帧、程序化纹理）不该反复走这条 API，正确姿势是 `SDL_CreateTexture(renderer, format, SDL_TEXTUREACCESS_STREAMING, w, h)` + 每帧 `SDL_UpdateTexture` 或 `SDL_LockTexture`；`SDL_TEXTUREACCESS_TARGET` 则是渲染目标（离屏渲染，本章不展开）。三种访问模式一旦定下就不能改。

## 4.4 查格式：`SDL_QueryTexture` 与那个"名字不一样"的坑

```cpp
// ═══ 4.4 查纹理真实身份：格式、访问模式、尺寸 ═══
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
    std::cout << "surfaceFormat=" << SDL_GetPixelFormatName(surface->format->format) << '\n';
    std::cout << "textureFormat=" << SDL_GetPixelFormatName(textureFormat)
              << ", textureSize=" << textureW << 'x' << textureH << '\n';
    std::cout << "==== 04 结束 ====\n";
```

`SDL_QueryTexture(texture, &format, &access, &w, &h)` 五个参数都是出参，不想要哪个传 `nullptr`（本例不查 access）。实测输出（`build/shared/04_texture_surface.run1`）：

```text
==== 04 开始 ====
surfaceFormat=SDL_PIXELFORMAT_ABGR8888
textureFormat=SDL_PIXELFORMAT_ABGR8888, textureSize=64x64
==== 04 结束 ====
```

源码里写的是 `SDL_PIXELFORMAT_RGBA32`，打印出来却是 `SDL_PIXELFORMAT_ABGR8888`——**`*_RGBA32` / `*_ARGB32` 不是固定内存布局，而是"按本机字节序"的别名**：`SDL_BYTEORDER == SDL_LIL_ENDIAN` 时 `SDL_PIXELFORMAT_RGBA32` 就是 `ABGR8888`，大端机上才是 `RGBA8888`。`SDL_GetPixelFormatName()` 报的是解析后的精确名，于是别名的真身被摊在光下。

macOS 与 Windows 都是小端，本教程两个平台这条输出一致；但跨到大端目标（老 PowerPC/部分嵌入式 ABI）时，同一份代码的内存布局会变。要**固定布局**（比如喂给手写 shader、或跟别的库对协议），必须写精确名 `SDL_PIXELFORMAT_RGBA8888`，或者按 `SDL_BYTEORDER` 显式选。

## 4.5 两套生命周期：一次对齐

```cpp
// ═══ 4.5 释放：Surface 归你，Texture 归渲染器，两者都在 SDL_Quit 之前 ═══
    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

记法一句话：**谁造的用谁的销毁函数**——`SDL_CreateRGBSurfaceWithFormat` → `SDL_FreeSurface`；`SDL_CreateTextureFromSurface`/`SDL_CreateTexture` → `SDL_DestroyTexture`。顺序上按"资源 → 渲染器 → 窗口 → 子系统"倒着拆（10 章会把这条纪律做成 RAII，并且会看到把它弄错的实际代价）。

## 坑位清单

11. **把 `SDL_PIXELFORMAT_RGBA32` / `ARGB32` 当固定通道顺序**：它们是字节序相关别名，小端解析成 `ABGR8888`（本例实测输出就是证据），大端解析成另一个值。跨平台或对协议的代码要写 `*_8888` 精确名，别用 `32` 结尾的别名。
12. **Surface / Texture 生命周期混淆**：上传完 Surface 就可以 `SDL_FreeSurface`（Texture 不依赖它），Texture 归渲染器管，必须 `SDL_DestroyTexture`；两者都要在 `SDL_Quit()` 之前释放。反过来的错误也常见——`SDL_FreeSurface` 去销毁 Texture，或以为销毁渲染器会替自己收回 Surface。
13. **手动读写像素时按 `w*4` 跳行**：`surface->pitch` 是一行字节数，可能大于 `w × 每像素字节`（对齐补白）。逐行拷贝/锁定后写像素一律按 `pitch` 步进；`SDL_MapRGBA` 的产物只属于 Surface 侧，渲染器侧要用 `SDL_SetRenderDrawColor`。

---

上一章：[03 · 事件循环骨架：PollEvent 与"没人点关闭"的退出](03-event-loop.md) ｜ 下一章：[05 · 基础绘制 API：返回 void 的 Present 怎么判成败](05-draw-primitives.md) ｜ 返回：[README](../README.md)
