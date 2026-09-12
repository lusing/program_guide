// 定义概念
#include <concepts>

template<typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::same_as<T>;
};

// 使用概念约束模板
template<Addable T>
T add(T a, T b) {
    return a + b;
}

// 更多示例
template<typename T>
concept Numeric = std::is_arithmetic_v<T>;

template<Numeric T>
T multiply(T a, T b) {
    return a * b;
}

// 部分排序
template<typename T>
void process(T value) requires(std::is_integral_v<T>) {
    std::cout << "Integer: " << value << "\n";
}

template<typename T>
void process(T value) requires(std::is_floating_point_v<T>) {
    std::cout << "Floating point: " << value << "\n";
}
