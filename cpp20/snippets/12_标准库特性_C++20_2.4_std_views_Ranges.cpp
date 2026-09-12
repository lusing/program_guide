#include <ranges>
#include <vector>

auto numbers = std::views::iota(1, 10);
auto even = numbers | std::views::filter([](int n) { return n % 2 == 0; });
auto squared = even | std::views::transform([](int n) { return n * n; });

for (int n : squared) {
    std::cout << n << " "; // 4 16 36 64
}

// 管道语法
auto result = std::views::iota(1, 100)
    | std::views::filter([](int n) { return n % 3 == 0; })
    | std::views::transform([](int n) { return n * 2; });

// 常用视图
std::vector v = {1, 2, 3, 4, 5};

auto reversed = v | std::views::reverse;
auto sliced = v | std::views::drop(1) | std::views::take(2);
auto unique = v | std::views::unique;
