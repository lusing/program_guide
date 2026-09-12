#include <coroutine>

// C++23 协程改进
struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_never initial_suspend() { return {}; }
        std::suspend_never final_suspend() noexcept { return {}; }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}
    };
};

// co_await 改进
Task foo() {
    co_await std::suspend_never{};
}
