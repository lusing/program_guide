#include <coroutine>
#include <iostream>
#include <atomic>

struct Task {
    std::atomic<bool> started{false};
    std::atomic<bool> completed{false};

    struct promise_type {
        Task get_return_object() {
            return Task{
                .started = false,
                .completed = false
            };
        }
        std::suspend_always initial_suspend() { return {}; }
        std::suspend_always final_suspend() { return {}; }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}

        void resume() {
            // 协程恢复逻辑
        }
    };
};

Task monitorable_coroutine(int id) {
    auto task = co_await std::suspend_always{};
    task.started = true;
    std::cout << "Coroutine " << id << " started\n";

    co_await std::suspend_always{};
    task.completed = true;
    std::cout << "Coroutine " << id << " completed\n";
}
