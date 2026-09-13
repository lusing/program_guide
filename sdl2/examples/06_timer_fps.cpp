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

