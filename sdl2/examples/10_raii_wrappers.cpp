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

