#include <coroutine>
#include <iostream>
#include <chrono>

#ifdef DEBUG_CORO
    #define CORO_TRACE(msg) \
        std::cout << "[" << std::this_thread::get_id() << "] " \
                  << __func__ << ": " << msg << "\n"
#else
    #define CORO_TRACE(msg) ((void)0)
#endif

struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_always initial_suspend() {
            CORO_TRACE("initial_suspend");
            return {};
        }
        std::suspend_always final_suspend() noexcept {
            CORO_TRACE("final_suspend");
            return {};
        }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}
    };
};

Task debug_coroutine(int id) {
    CORO_TRACE("Coroutine started");
    co_await std::suspend_always{};
    CORO_TRACE("After first suspend");
    co_await std::suspend_always{};
    CORO_TRACE("Coroutine completed");
}
