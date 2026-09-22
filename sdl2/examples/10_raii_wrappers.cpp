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

