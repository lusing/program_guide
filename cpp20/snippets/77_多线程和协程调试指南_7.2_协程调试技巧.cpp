#include <coroutine>
#include <iostream>
#include <stacktrace>

struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_always initial_suspend() { return {}; }
        std::suspend_always final_suspend() { return {}; }
        void unhandled_exception() {
            std::cout << "Exception: " << std::current_exception().what() << "\n";
            std::terminate();
        }
        void return_void() {}
    };
};

Task traced_coroutine() {
    std::cout << "Stack trace at start:\n";
    auto trace = std::stacktrace::current();
    for (const auto& frame : trace) {
        std::cout << "  " << frame << "\n";
    }

    co_await std::suspend_always{};

    std::cout << "Stack trace after suspend:\n";
    auto trace2 = std::stacktrace::current();
    for (const auto& frame : trace2) {
        std::cout << "  " << frame << "\n";
    }
}
