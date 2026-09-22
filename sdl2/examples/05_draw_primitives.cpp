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

