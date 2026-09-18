// type_traits.cpp —— Boost.TypeTraits：类型内省（std::type_traits 的直系祖先）
// 对应文档：docs/05-langbase.md
// 2000 年诞生，是"用模板元编程回答类型问题"这门手艺的开山之作。
#include <boost/type_traits.hpp>
#include <boost/utility/enable_if.hpp>   // enable_if 的老家
#include <concepts>
#include <iostream>
#include <string>
#include <type_traits>
#include <vector>

// 1) 经典用途：SFINAE 按类型特征分派（C++98 时代唯一手段）
template <typename T>
typename boost::enable_if<boost::is_integral<T>, std::string>::type
describe(T) { return "整数"; }

template <typename T>
typename boost::enable_if<boost::is_class<T>, std::string>::type
describe(T) { return "类类型"; }

// 2) trait 变换：decay/remove_reference/conditional
template <typename T>
void probe(T&& x) {
    using D = typename boost::decay<T>::type;
    std::cout << "  衰变后是否 vector: " << std::boolalpha
              << boost::is_same<D, std::vector<int>>::value << '\n';
    (void)x;
}

int main() {
    std::cout << describe(42) << '\n';
    std::cout << describe(std::string("s")) << '\n';

    std::cout << "is_same 检查: " << boost::is_same<int, std::int32_t>::value << '\n';
    std::cout << "is_pointer 检查: " << boost::is_pointer<int*>::value << '\n';

    probe(std::vector<int>{});
    probe(3.14);

    // std 版（C++11 毕业）：_v/_t 便捷形式（boost 版大部分也有）
    std::cout << "std 版: " << std::boolalpha
              << std::is_integral_v<long> << ' '
              << std::is_same_v<std::decay_t<int&>, int> << '\n';

    // C++20 concepts 是"问答"的新形态：从"查询特征+enable_if 分派"
    // 变成"直接声明要求"——但 trait 本身仍是 concepts 的原料
    auto is_vec = []<typename T>(T) constexpr { return std::same_as<T, std::vector<int>>; };
    std::cout << "concepts 时代: lambda 检查 vector = " << is_vec(std::vector<int>{}) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
