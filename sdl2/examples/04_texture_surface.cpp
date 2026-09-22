#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("Surface/Texture", 0, 0, 320, 240, SDL_WINDOW_HIDDEN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
    if (!window || !renderer) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_Surface* surface = SDL_CreateRGBSurfaceWithFormat(0, 64, 64, 32, SDL_PIXELFORMAT_RGBA32);
    if (!surface) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_FillRect(surface, nullptr, SDL_MapRGBA(surface->format, 255, 120, 0, 255));
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    if (!texture) {
        std::cerr << SDL_GetError() << '\n';
        SDL_FreeSurface(surface);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    Uint32 textureFormat = 0;
    int textureW = 0;
    int textureH = 0;
    if (SDL_QueryTexture(texture, &textureFormat, nullptr, &textureW, &textureH) != 0) {
        std::cerr << SDL_GetError() << '\n';
        SDL_DestroyTexture(texture);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    std::cout << "==== 04 开始 ====\n";
    // SDL_PIXELFORMAT_RGBA32 是「按本机字节序」的别名，不是固定内存布局：
    // 小端机（x86_64 / arm64 的 macOS、Linux、Windows）解析成 ABGR8888，
    // 大端机解析成 RGBA8888。要固定布局就用 *_8888 精确名。
    std::cout << "surfaceFormat=" << SDL_GetPixelFormatName(surface->format->format) << '\n';
    std::cout << "textureFormat=" << SDL_GetPixelFormatName(textureFormat)
              << ", textureSize=" << textureW << 'x' << textureH << '\n';
    std::cout << "==== 04 结束 ====\n";

    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}

