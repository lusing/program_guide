#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("Keyboard", 0, 0, 320, 240, SDL_WINDOW_HIDDEN);
    if (!window) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    SDL_PumpEvents();
    int keyCount = 0;
    const Uint8* state = SDL_GetKeyboardState(&keyCount);
    bool leftPressed = state && state[SDL_SCANCODE_LEFT] != 0;
    std::cout << "keyboard entries=" << keyCount << ", leftPressed=" << leftPressed << '\n';

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}

