#include <concepts>
#include <print>
#include <string>
#include <type_traits>
#include <vector>

// 14 概念：给模板参数立规矩

// ═══ 14.1 自定义 concept：requires 表达式 ═══
template <typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::convertible_to<T>;  // 要求 a+b 存在且结果能转回 T
};

// ═══ 14.2 用概念约束模板 ═══
template <Addable T>  // 写法一：直接当约束
T sum_all(const std::vector<T>& xs) {
    T total{};
    for (const T& v : xs) {
        total = total + v;
    }
    return total;
}

template <typename T>
    requires std::is_arithmetic_v<T>  // 写法二：requires 子句
T half(T v) {
    return v / 2;
}

// ═══ 14.3 约束重载：按能力分派（形参必须完全一致，包含排序才生效）═══
template <typename T>
    requires std::integral<T>
const char* kind(const T&) {
    return "整数";
}

template <typename T>
    requires std::floating_point<T>
const char* kind(const T&) {
    return "浮点";
}

template <typename T>
const char* kind(const T&) {
    return "其他（兜底）";
}

int main() {
    std::vector<int> nums{1, 2, 3, 4};
    std::vector<std::string> words{"a", "b"};
    std::vector<double> ratios{0.5, 1.5};
    std::println("sum(int) = {}", sum_all(nums));        // 10
    std::println("sum(string) = {}", sum_all(words));    // ab：string 也满足 +
    std::println("sum(double) = {}", sum_all(ratios));  // 2

    std::println("half(9) = {}，half(2.5) = {}", half(9), half(2.5));  // 4 / 1.25

    std::println("kind(42) = {}", kind(42));        // 整数
    std::println("kind(1.5) = {}", kind(1.5));      // 浮点
    std::println("kind('c') = {}", kind('c'));      // 整数！char 是整数类型
    std::println("kind(vector) = {}", kind(nums));  // 兜底

    // ═══ 14.4 编译期检查：static_assert 验证概念 ═══
    static_assert(Addable<int>);
    static_assert(Addable<std::string>);
    // static_assert(Addable<std::vector<int>>);  // 编译失败：vector 没有 +
    std::println("自检通过");
}
