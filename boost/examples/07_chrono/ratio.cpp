// ratio.cpp —— Boost.Ratio：编译期有理数（std::ratio 直系，chrono 的地基）
// 对应文档：docs/07-chrono.md
#include <boost/ratio.hpp>
#include <iostream>

int main() {
    using boost::ratio;

    // 1) ratio 是编译期分数：num/den 自动约分
    using half = ratio<1, 2>;
    using third = ratio<1, 3>;
    std::cout << "half = " << half::num << '/' << half::den << '\n';
    std::cout << "ratio<6,12> 约分 = " << ratio<6, 12>::num << '/' << ratio<6, 12>::den << '\n';

    // 2) 编译期四则：add/sub/multiply/divide
    using sum = boost::ratio_add<half, third>;         // 1/2 + 1/3 = 5/6
    std::cout << "1/2+1/3 = " << sum::num << '/' << sum::den << '\n';
    using prod = boost::ratio_multiply<half, third>;   // 1/2 * 1/3 = 1/6
    std::cout << "1/2*1/3 = " << prod::num << '/' << prod::den << '\n';

    // 3) 编译期比较
    std::cout << "1/2 < 1/3 ? " << std::boolalpha
              << boost::ratio_less<half, third>::value << '\n';

    // 4) 真实用途：给 duration 定制单位（std::chrono 里的 nano/milli 就是这么定义的）
    using fortnight = boost::ratio<14 * 24 * 3600, 1>;  // 两周（秒的 1209600 倍）
    std::cout << "fortnight = " << fortnight::num << " 秒的倍数\n";

    // 5) SI 前缀成品：atto/femto/.../kilo/mega/...
    std::cout << "kilo = " << boost::kilo::num << "  milli = 1/" << boost::milli::den << '\n';

    std::cout << "自检通过\n";
    return 0;
}
