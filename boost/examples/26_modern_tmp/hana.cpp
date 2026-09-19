// hana.cpp —— Boost.Hana（2015）：类型与值的统一元编程——
// "编译期 STL"：类型也能装进"容器"做算法。
// 对应文档：docs/26-modern-tmp.md
#include <boost/hana.hpp>
#include <iostream>
#include <string>
#include <type_traits>

namespace hana = boost::hana;
// 注：hana 的 "_s" 字面量在本机 c++latest 下与标准库新字面量撞车（找不到
// 运算符），改用 BOOST_HANA_STRING 宏构造编译期字符串——语义相同

// 编译期与运行期的统一：tuple 里既有类型又有值
struct Cat { std::string name; };
struct Dog { std::string name; };

int main() {
    // 1) hana::tuple：异构容器（值的部分）
    auto animals = hana::make_tuple(BOOST_HANA_STRING("cat"),
                                    BOOST_HANA_STRING("dog"),
                                    BOOST_HANA_STRING("bird"));
    std::cout << "动物数 = " << hana::length(animals) << '\n';
    std::cout << "有 dog? " << hana::contains(animals, BOOST_HANA_STRING("dog")) << '\n';

    // 2) 类型元编程：hana::tuple_t 装类型
    auto types = hana::tuple_t<int, float, double>;
    std::cout << "类型数 = " << hana::length(types) << '\n';
    constexpr bool has_float = hana::contains(types, hana::type_c<float>);
    std::cout << "有 float? " << has_float << '\n';

    // 3) 编译期算法：transform/filter 在 tuple 上直接跑
    auto sizes = hana::transform(types, [](auto t) {
        return hana::sizeof_(t);
    });
    static_assert(hana::at_c<0>(sizes) == sizeof(int));
    std::cout << "transform 取 sizeof OK\n";

    auto big = hana::filter(types, [](auto t) {
        return hana::sizeof_(t) >= hana::size_c<8>;
    });
    std::cout << "≥8 字节的类型数 = " << hana::length(big) << '\n';

    // 4) 结构体反射式访问：accessors（配合 BOOST_HANA_ADAPT_STRUCT 见文档）
    auto pairs = hana::make_map(hana::make_pair(BOOST_HANA_STRING("x"), 3),
                                hana::make_pair(BOOST_HANA_STRING("y"), 4));
    std::cout << "map 里 x = " << hana::at_key(pairs, BOOST_HANA_STRING("x")) << '\n';

    // 5) 编译期 if：if_ 让分支在类型上选择
    auto which = hana::if_(hana::true_c, "真分支", "假分支");
    std::cout << "if_ = " << which << '\n';

    std::cout << "自检通过\n";
    return 0;
}
