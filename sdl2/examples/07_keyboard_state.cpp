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

    std::cout << "==== 07 开始 ====\n";
    std::cout << "keyboard entries=" << keyCount << ", leftPressed=" << leftPressed << '\n';
    // 后台/无焦点进程的键盘状态全为 0：这不是平台差异，而是「没人按键」的
    // 事实。SDL_PumpEvents 只把窗口管理器送来的事件并入状态表，不会凭空
    // 造出按键——窗口未获焦点时收到的就是空表（entries 仍恒为 512）。
    std::cout << "stateAvailable=" << (state != nullptr) << '\n';
    std::cout << "==== 07 结束 ====\n";

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}

