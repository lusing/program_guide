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

