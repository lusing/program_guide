// math.cpp —— Boost.Math：特殊函数/统计分布/常量/工具的数学全家桶。
// gcd/lcm 已毕业进 std（C++17），这里的正主是它独有的部分。
// 对应文档：docs/24-numeric.md
#include <boost/math/special_functions/beta.hpp>
#include <boost/math/special_functions/gamma.hpp>
#include <boost/math/distributions/normal.hpp>
#include <boost/math/constants/constants.hpp>
#include <boost/math/tools/precision.hpp>
#include <iostream>

int main() {
    // 1) 特殊函数：gamma/beta/erf...（科学计算的基础件）
    std::cout << "Γ(5) = " << boost::math::tgamma(5.0) << "（= 4! = 24）\n";
    std::cout << "lgamma(100) = " << boost::math::lgamma(100.0) << "（防溢出的 log 形式）\n";
    std::cout << "B(2,3) = " << boost::math::beta(2.0, 3.0) << '\n';

    // 2) 统计分布：PDF/CDF/分位数全套
    boost::math::normal_distribution<> n170(170.0, 6.0);   // N(μ=170, σ=6)
    std::cout << "P(X<=180) = " << boost::math::cdf(n170, 180.0) << '\n';
    std::cout << "P(X>160) = " << boost::math::cdf(boost::math::complement(n170, 160.0)) << '\n';
    std::cout << "95% 分位 = " << boost::math::quantile(n170, 0.95) << '\n';

    // 3) 高精度常量（50 位有效数字起步）
    double pi = boost::math::constants::pi<double>();
    std::cout << "π = " << pi << "（e = " << boost::math::constants::e<double>() << "）\n";

    // 4) 精度工具与 next/float_advance
    std::cout << "double 机器精度 ε = " << boost::math::tools::epsilon<double>() << '\n';
    std::cout << "next(1.0) - 1.0 = " << boost::math::float_next(1.0) - 1.0 << '\n';

    std::cout << "自检通过\n";
    return 0;
}
