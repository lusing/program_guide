// integer.cpp —— Boost.Integer（2001）：整数类型的三件套（书 ch9.2）
//   ① <boost/cstdint.hpp>  精确宽度整型（现已并入 std，含 least/fast 语义）
//   ② integer_traits       编译期极值（std::numeric_limits 的强化版）
//   ③ <boost/integer.hpp>  按位宽/按值域自动选型的模板类
// 对应文档：docs/24-numeric.md
#include <boost/cstdint.hpp>
#include <boost/integer.hpp>
#include <boost/integer_traits.hpp>
#include <boost/type_index.hpp>
#include <iostream>
#include <limits>

template <typename T>
std::string tname() {
    return boost::typeindex::type_id<T>().pretty_name();
}

int main() {
    // ── 1) cstdint：精确宽度整型的命名律 ──
    //   int8_t / int_least32_t / int_fast16_t / uintmax_t ...
    //   least = "至少 N 位"里最小的；fast = 最快；裸类型 = 恰好 N 位
    std::cout << "宽度: int8=" << sizeof(boost::int8_t)
              << " int_fast16=" << sizeof(boost::int_fast16_t)
              << " int_least32=" << sizeof(boost::int_least32_t)
              << "（本机 fast16 取的是最快不最小的宽度）\n";
    std::cout << "intmax 能装 uint32 相加? "
              << (boost::intmax_t(boost::uint32_t(0xFFFFFFFF))
                  + boost::intmax_t(boost::uint32_t(0xFFFFFFFF)) > 0) << '\n';
    // 极值三问（std::numeric_limits 同款——C++11 后两者等价）
    std::cout << "int8 最大 = " << int(+std::numeric_limits<boost::int8_t>::max())
              << " uintmax 最大存在? "
              << std::numeric_limits<boost::uintmax_t>::is_signed << "（0=无符号）\n";

    // ── 2) integer_traits：编译期常量版极值（C++11 前 numeric_limits 不是
    //     constexpr，泛型代码里用不了；它补上 const_min/const_max）──
    std::cout << "integer_traits: short 范围 = "
              << boost::integer_traits<short>::const_min << "..."
              << boost::integer_traits<short>::const_max
              << " bool const_min = "
              << boost::integer_traits<bool>::const_min << '\n';

    // ── 3) int_t<N>/uint_t<N>：按**位宽**要类型（不必是 8 的倍数！）──
    using u15 = boost::uint_t<15>::fast;       // 能装 15 位的最快无符号
    using i32700 = boost::int_max_value_t<32700>::fast;   // 能装下 32700 的
    using ineg = boost::int_min_value_t<-33000>::fast;    // 能装下 -33000 的
    using u33000 = boost::uint_value_t<33000>::fast;      // 无符号装 33000
    std::cout << "按需选型: 15 位 → " << tname<u15>() << '(' << sizeof(u15) * 8
              << " 位)  ≤32700 → " << tname<i32700>()
              << "  ≥-33000 → " << tname<ineg>()
              << "  u33000 → " << tname<u33000>() << '\n';
    std::cout << "（编译期选好 = 运行期零开销；比手挑类型可移植）\n";

    std::cout << "自检通过\n";
    return 0;
}
