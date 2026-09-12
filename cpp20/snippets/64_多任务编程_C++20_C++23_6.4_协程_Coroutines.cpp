#include <coroutine>
#include <iostream>

struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_always initial_suspend() { return {}; }
        std::suspend_always final_suspend() { return {}; }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}
    };
};

Task example() {
    std::cout << "Before suspend\n";
    co_await std::suspend_always{};
    std::cout << "After suspend\n";
}

int main() {
    auto task = example();
    std::cout << "Task created\n";
}
