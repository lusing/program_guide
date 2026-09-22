#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << '\n';
        return 1;
    }

    std::cout << "==== 01 开始 ====\n";
    SDL_version linked{};
    SDL_GetVersion(&linked);
    std::cout << "Linked SDL version: "
              << static_cast<int>(linked.major) << '.'
              << static_cast<int>(linked.minor) << '.'
              << static_cast<int>(linked.patch) << '\n';
    // SDL_WasInit 是「子系统是否已就绪」的事实查询，不依赖具体平台；
    // 版本号随安装的 SDL 变化，因此只在同一次全量里做「两遍一致」比对。
    std::cout << "videoReady=" << ((SDL_WasInit(SDL_INIT_VIDEO) & SDL_INIT_VIDEO) != 0)
              << ", timerReady=" << ((SDL_WasInit(SDL_INIT_TIMER) & SDL_INIT_TIMER) != 0) << '\n';
    std::cout << "==== 01 结束 ====\n";

    SDL_Quit();
    return 0;
}

