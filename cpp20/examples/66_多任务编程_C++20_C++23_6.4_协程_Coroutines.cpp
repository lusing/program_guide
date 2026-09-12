#include <generator>
#include <ranges>
#include <iostream>

std::generator<int> numbers() {
    for (int i = 1; i <= 10; ++i) {
        co_yield i;
    }
}

int main() {
    // 使用 views 进行组合
    auto evens = numbers()
        | std::views::filter([](int n) { return n % 2 == 0; })
        | std::views::transform([](int n) { return n * n; });

    for (int n : evens) {
        std::cout << n << " ";
    }
    // 输出: 4 16 36 64 100
}

