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

