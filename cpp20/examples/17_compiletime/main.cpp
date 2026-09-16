#include <array>
#include <print>
#include <string>
#include <string_view>
#include <type_traits>

// 17 编译期编程：constexpr、if constexpr、变参模板、fold

// ═══ 17.1 constexpr 函数：同一份代码，两个世界都能跑 ═══
constexpr unsigned long long factorial(unsigned n) {
    unsigned long long r = 1;
    for (unsigned i = 2; i <= n; ++i) {
        r *= i;
    }
    return r;
}

// ═══ 17.2 consteval：只许编译期执行 (C++20) ═══
consteval int compile_time_square(int v) {
    return v * v;
}

// ═══ 17.3 if constexpr：编译期剪枝，未选中的分支不实例化 ═══
template <typename T>
std::string describe(const T& value) {
    if constexpr (std::is_arithmetic_v<T>) {
        return "数值: " + std::to_string(value);
    } else if constexpr (std::is_convertible_v<T, std::string_view>) {
        return "文本: " + std::string(value);
    } else {
        return "其他类型";
    }
}

// ═══ 17.4 变参模板 + fold 表达式 ═══
template <typename... Ts>
auto sum_all(Ts... values) {
    return (values + ...);  // 一元右折叠：((v1+v2)+v3)…
}

template <typename... Ts>
bool all_small(int limit, Ts... values) {
    return ((values < limit) && ...);  // 逻辑与折叠
}

int main() {
    // 编译期常量 + static_assert 当"免费单测"
    static_assert(factorial(10) == 3'628'800ULL);
    constexpr auto fact5 = factorial(5);
    int runtime_n = 6;  // 运行期输入也能调同一函数
    std::println("5! = {}，运行期 6! = {}", fact5, factorial(runtime_n));

    // consteval 结果能当数组长度
    constexpr int side = 12;
    std::array<int, compile_time_square(side)> table{};
    std::println("表格长度 = {}", table.size());  // 144

    std::println("{}", describe(3.14));
    std::println("{}", describe(std::string("文本")));
    struct Point {
        int x;
        int y;
    };
    std::println("{}", describe(Point{1, 2}));

    std::println("sum_all = {}", sum_all(1, 2, 3, 4.5));    // 10.5
    std::println("all_small = {}", all_small(3, 1, 2, 3));  // false
    std::println("自检通过");
}
