#include <generator>
#include <iostream>
#include <variant>

// 带错误处理的生成器
using GenResult = std::variant<int, std::string>;

std::generator<GenResult> monitored_generator(bool fail) {
    std::cout << "Generator starting\n";
    co_yield 1;
    std::cout << "Yielded 1\n";

    co_yield 2;
    std::cout << "Yielded 2\n";

    if (fail) {
        std::cout << "Generator failing\n";
        co_yield std::string("error");
    }

    std::cout << "Generator ending\n";
}

void debug_generator() {
    std::cout << "=== Working generator ===\n";
    for (int val : std::generator<int>{[]() -> std::generator<int>::promise_type {
        co_yield 1;
        co_yield 2;
        co_yield 3;
    }()}) {
        std::cout << "Got: " << val << "\n";
    }

    std::cout << "=== Failed generator ===\n";
    for (GenResult r : monitored_generator(true)) {
        if (std::holds_alternative<int>(r)) {
            std::cout << "Got: " << std::get<int>(r) << "\n";
        } else {
            std::cout << "Error: " << std::get<std::string>(r) << "\n";
        }
    }
}
