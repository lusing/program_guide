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

    // 区间内只放「跨机器都成立」的结论：补帧逻辑保证 frameTime >= 目标帧长。
    // 真实帧长与 fps 随负载波动（本机实测 17~19ms），放区间外只给人看，
    // 不参与字节比对——否则回归脚本会随机变红。
    std::cout << "==== 06 开始 ====\n";
    std::cout << "frameTargetMs=" << frameTargetMs << '\n';
    std::cout << "frameTargetMet=" << (frameTime >= frameTargetMs) << '\n';
    std::cout << "==== 06 结束 ====\n";

    double fps = frameTime > 0 ? 1000.0 / frameTime : 0.0;
    std::cout << "[观测] frameTime(ms)=" << frameTime << ", fps~=" << fps << '\n';

    SDL_Quit();
    return 0;
}

