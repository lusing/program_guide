// mp11.cpp —— Boost.Mp11（2015）：列表上的函数式元编程——现代 TMP 的事实
// 标准。比 MPL 简单一个数量级：一个别名模板 + 一行推导。
// 对应文档：docs/26-modern-tmp.md
#include <boost/mp11.hpp>
#include <iostream>
#include <type_traits>

namespace mp = boost::mp11;

// 变体模板：类型列表 → sizeof 常量列表（mp11 的 bind 系不能直接表达
// "对 T 取 sizeof"，变参 lambda 是 C++20 的顺手姿势）
template <typename List> struct size_of_list;
template <typename... Ts>
struct size_of_list<mp::mp_list<Ts...>> {
    using type = mp::mp_list<std::integral_constant<std::size_t, sizeof(Ts)>...>;
};

int main() {
    using L = mp::mp_list<int, float, double, char>;

    // 1) 基本变换：mp_transform = map
    using Pointers = mp::mp_transform<std::add_pointer_t, L>;
    static_assert(std::is_same_v<mp::mp_at_c<Pointers, 0>, int*>);
    std::cout << "mp_transform OK（第 0 个变 int*）\n";

    // 2) 过滤：mp_copy_if = filter
    using Floats = mp::mp_copy_if<L, std::is_floating_point>;
    static_assert(mp::mp_size<Floats>::value == 2);
    std::cout << "mp_copy_if OK（浮点数 2 个）\n";

    // 3) 折叠：mp_fold = reduce——把常量列表折成一个值
    using Cnts = mp::mp_list<std::integral_constant<int, 1>,
                             std::integral_constant<int, 2>,
                             std::integral_constant<int, 3>>;
    using Sum = mp::mp_fold<Cnts, std::integral_constant<int, 0>, mp::mp_plus>;
    static_assert(Sum::value == 6);
    std::cout << "mp_fold 求和 = " << Sum::value << '\n';

    // 4) 查找与索引
    using Idx = mp::mp_find<L, double>;
    static_assert(Idx::value == 2);
    std::cout << "double 的下标 = " << Idx::value
              << " mp_size = " << mp::mp_size<L>::value << '\n';
    static_assert(mp::mp_contains<L, char>::value);
    std::cout << "mp_contains<char> OK\n";

    // 5) 按 sizeof 排序：先映射成尺寸常量，再 mp_sort + mp_less
    using Sizes = size_of_list<L>::type;
    using SortedSizes = mp::mp_sort<Sizes, mp::mp_less>;
    static_assert(mp::mp_front<SortedSizes>::value == sizeof(char));
    std::cout << "按 sizeof 排序后最小 = char 的大小 OK\n";

    // 6) 生成：mp_repeat
    using Zeros = mp::mp_repeat<mp::mp_list<int>, mp::mp_int<3>>;
    static_assert(mp::mp_size<Zeros>::value == 3);
    std::cout << "mp_repeat 生成 3 元列表 OK\n";

    std::cout << "自检通过\n";
    return 0;
}
