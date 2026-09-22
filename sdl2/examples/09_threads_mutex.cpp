#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <iostream>

struct Counter {
    SDL_mutex* mutex = nullptr;
    int value = 0;
};

int SDLCALL Worker(void* userdata) {
    auto* counter = static_cast<Counter*>(userdata);
    for (int i = 0; i < 1000; ++i) {
        SDL_LockMutex(counter->mutex);
        ++counter->value;
        SDL_UnlockMutex(counter->mutex);
    }
    return 0;
}

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_TIMER) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    Counter counter{};
    counter.mutex = SDL_CreateMutex();
    if (!counter.mutex) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    SDL_Thread* t1 = SDL_CreateThread(Worker, "worker-1", &counter);
    SDL_Thread* t2 = SDL_CreateThread(Worker, "worker-2", &counter);
    if (!t1 || !t2) {
        std::cerr << SDL_GetError() << '\n';
        if (t1) SDL_WaitThread(t1, nullptr);
        if (t2) SDL_WaitThread(t2, nullptr);
        SDL_DestroyMutex(counter.mutex);
        SDL_Quit();
        return 1;
    }

    SDL_WaitThread(t1, nullptr);
    SDL_WaitThread(t2, nullptr);

    std::cout << "==== 09 开始 ====\n";
    std::cout << "counter=" << counter.value << '\n';
    std::cout << "==== 09 结束 ====\n";

    SDL_DestroyMutex(counter.mutex);
    SDL_Quit();
    return 0;
}

