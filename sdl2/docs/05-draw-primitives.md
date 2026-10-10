# 05 · 基础绘制 API：返回 void 的 Present 怎么判成败

> 对应示例：[examples/05_draw_primitives.cpp](../examples/05_draw_primitives.cpp)

渲染器就绪后，绘制 API 是一小组"设状态 → 画几何 → 呈现"的调用：点、线、矩形，以及它们的批量化版本。这一章的看点不在"会画几个图形"，而在**这套 API 的返回值设计参差不齐**：`SDL_RenderClear` 返回 `int`，`SDL_RenderPresent` 返回 `void`。本次校验写脚本时正好被这条绊了一次（`cannot initialize a variable of type 'int' with an rvalue of type 'void'`），于是本例顺手把"给 void 函数判成败"的标准做法固化了下来。

## 5.0 本章示例的骨架

```cpp
// ═══ 5.0 骨架：VIDEO 子系统 + 窗口与软件渲染器成对建、成对退 ═══
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
```

骨架三行的来历见 [01 章](01-init-version.md)，窗口与渲染器的参数语义见 [02 章](02-window-renderer.md)。本章把两件事合并成一行 `if (!window || !renderer)`：两个对象谁都没建成都要走同一条清理路，而 `SDL_DestroyRenderer(nullptr)`/`SDL_DestroyWindow(nullptr)` 都是空操作，所以不必分层判断。位置参数这里直接传 `0, 0`（02 章表格里"普通整数 = 显式坐标"那一行），因为本章根本不上屏。

## 5.1 绘制状态是"当前颜色"，不是每次调用传参

```cpp
// ═══ 5.1 状态机式绘制：颜色先设进去，后续图元沿用 ═══
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    int clearResult = SDL_RenderClear(renderer);

    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    int lineResult = SDL_RenderDrawLine(renderer, 10, 10, 300, 10);

    SDL_Rect rect{40, 40, 80, 60};
    SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);
    int fillResult = SDL_RenderFillRect(renderer, &rect);
```

`SDL_SetRenderDrawColor(renderer, r, g, b, a)` 是**渲染器状态**，设置一次、后续所有图元都用它——这一点和 04 章 Surface 侧的 `SDL_MapRGBA`（算出一个具体像素值交给这一次调用）是两种模型。另外还有 `SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND)`，透明叠加要显式打开（默认 `SDL_BLENDMODE_NONE`，半透明颜色会直接盖上去而不是混合）。

坐标是**设备像素**，原点左上，`SDL_Rect{x, y, w, h}` 是左上角加宽高（不是两个角）。`SDL_RenderClear` 用当前绘制颜色清**整个当前绘制目标**，通常是一帧的开始；`SDL_RenderDrawLine` 是整数端点的线段。

## 5.2 批量化：一次调用一批，返回值只判"这批有没有启动"

同一族 API 都成对存在，单发版和批量版：

| 单发 | 批量 | 备注 |
|---|---|---|
| `SDL_RenderDrawPoint` | `SDL_RenderDrawPoints`、`SDL_RenderDrawPointsF` | 批量传 `const SDL_Point*, int count` |
| `SDL_RenderDrawLine` | `SDL_RenderDrawLines` | 折线：相邻点相连 |
| `SDL_RenderDrawRect` | `SDL_RenderDrawRects` | 空心矩形 |
| `SDL_RenderFillRect` | `SDL_RenderFillRects` | 实心矩形 |
| — | `SDL_RenderGeometry` | 2.0.18+，顶点+UV+颜色一次提交三角形列表 |

批量版省的是调用开销（每次单发在硬件后端上都要走一遍提交路径），`*_F` 后缀浮点版走亚像素坐标，只在支持的后端上有效——不支持时 SDL 退化成取整，不会报错。这也是要**先查 `SDL_RendererInfo.flags` 的 `SDL_RENDERER_TARGETTEXTURE`、再谈离屏**的同一类纪律：能力问 API，别问传说。

## 5.3 `SDL_RenderPresent` 返回 void：判成败的标准三步

```cpp
// ═══ 5.3 给返回 void 的调用判成败：清错误 → 调用 → 看错误串是否被写脏 ═══
    SDL_ClearError();
    SDL_RenderPresent(renderer);
    bool presentOk = SDL_GetError()[0] == '\0';
```

`SDL_RenderPresent` 没有返回值（01 章的错误串约定在这里兑现）：

1. `SDL_ClearError()` 先把遗留错误串擦干净——**不做这一步，`SDL_GetError()` 读到的是更早的失败**，判定必然失真；
2. 调用；
3. `SDL_GetError()[0] == '\0'` 判空串：非空即这次留下了错。

`SDL_GetError()` 返回的是静态缓冲区指针，所以判"是否为空"读首字符即可，不需要也不该长期持有那个 `const char*`。

## 5.4 输出为什么是四个返回码

```cpp
// ═══ 5.4 区间内只放返回码：跨后端、跨平台都恒真 ═══
    std::cout << "==== 05 开始 ====\n";
    std::cout << "clearResult=" << clearResult
              << ", lineResult=" << lineResult
              << ", fillResult=" << fillResult
              << ", presentOk=" << presentOk << '\n';
    std::cout << "==== 05 结束 ====\n";
```

`build/shared/05_draw_primitives.run1`：

```text
==== 05 开始 ====
clearResult=0, lineResult=0, fillResult=0, presentOk=1
==== 05 结束 ====
```

四个量分别对应 5.1 的三次返回 `int` 的调用（`0` = 成功）和 5.3 那次 `void` 调用的错误串判定（`1` = 干净）。本例窗口是 `SDL_WINDOW_HIDDEN`，屏幕上什么都看不见，但**绘制管线照样跑通**——这也是它能同时在 `cocoa`/`metal` 与 `dummy`/`software` 下产出同一份输出的原因（02 章的双输出对照同理）。想验证"真的画出来了"，只能人眼看：把 `HIDDEN` 换成 `SDL_WINDOW_SHOWN`，能看见深灰底上的一条红线和一块绿矩形。

```cpp
// ═══ 5.4b 收尾：渲染器 → 窗口 → 子系统，销毁全部在 SDL_Quit 之前 ═══
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

销毁顺序与创建顺序相反（02 章 2.4 的那条规则），`SDL_Quit()` 排在最后一行——它是"子系统拆掉、之后任何 SDL API 都不许再碰"的截止线（10 章整章讲这条线在 RAII 下怎么守住）。

## 5.5 一帧的完整形状

把 03/05 两章合起来就是 SDL2 的主循环骨架，后面章节不再重复：

```cpp
// ═══ 5.5 主循环骨架（本例把一帧摊平成顺序调用；真实程序把它放进 03 章的循环里） ═══
    while (running) {
        while (SDL_PollEvent(&e) == 1) { /* 输入 */ }
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);        /* 帧起：清屏 */
        /* ...画图元、SDL_RenderCopy 贴纹理... */
        SDL_RenderPresent(renderer);      /* 帧止：呈现，返回 void */
    }
```

`SDL_RenderClear` 不会因为 `Present` 而自动执行——**忘了清屏就是上一帧残留 + 新内容叠加**，动画程序里表现为拖影。硬件后端 + `SDL_RENDERER_PRESENTVSYNC` 时帧率由刷新率封顶；没拿到 vsync（软件后端、`dummy`）就要自己按 06 章补帧。

## 坑位清单

14. **`SDL_RenderPresent` 返回 `void`，却拿返回值判成败**：这次写校验脚本时被编译器当场抓住（`cannot initialize a variable of type 'int' with an rvalue of type 'void'`）。判它只能 `SDL_ClearError()` → 调用 → 查 `SDL_GetError()` 是否为空；**不先清，读到的是前面遗留的错误串**，判定必然不可信。
15. **给每个绘制调用都查一遍错误串**：`SDL_RenderDrawLine`/`SDL_RenderFillRect` 等失败时返回负数，但**不一定**设置错误串（后端只在部分路径上报错）。批量绘制看每批返回值、失败再查错误，比逐条查既便宜又可靠。
16. **以为 `SDL_RenderPresent` 会顺带清屏**：`SDL_RenderClear` 必须每帧显式调用，否则上一帧残留和新内容叠加（动画里就是拖影）。同理，透明叠加要显式 `SDL_SetRenderDrawBlendMode(..., SDL_BLENDMODE_BLEND)`，默认 `NONE` 是直接覆盖。

---

上一章：[04 · Surface 与 Texture：像素在 CPU 还是在 GPU](04-surface-texture.md) ｜ 下一章：[06 · 计时与帧率：哪些数字能进字节比对](06-timer-fps.md) ｜ 返回：[README](../README.md)
