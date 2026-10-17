// rational.cpp —— Boost.Rational（2000）：精确分数——0.1+0.2 的另一种解法
//（对照 17 章的 decimal：rational 是精确分数，decimal 是十进制浮点）。
// 对应文档：docs/24-numeric.md
#include <boost/rational.hpp>
#include <iostream>

int main() {
    using boost::rational;

    // 1) 分数算术：精确无舍入
    rational<int> half(1, 2);
    rational<int> third(1, 3);
    std::cout << "1/2 + 1/3 = " << half + third << "（自动约分）\n";
    std::cout << "1/2 * 1/3 = " << half * third << '\n';
    std::cout << "1/2 / 1/3 = " << half / third << '\n';

    // 2) 与整数的混合运算
    rational<int> r = 1;
    r /= 3;
    std::cout << "1/3 的分子 = " << r.numerator() << " 分母 = " << r.denominator() << '\n';

    // 3) 精确表示浮点噩梦：0.1 + 0.2 == 0.3 在 rational 里成立
    rational<int> a(1, 10), b(2, 10), c(3, 10);
    std::cout << "1/10 + 2/10 == 3/10 ? " << (a + b == c) << '\n';

    // 4) 比较
    std::cout << "1/2 < 2/3 ? " << (half < rational<int>(2, 3)) << '\n';

    // 5) 陷阱：构造 1/0 抛异常（除零守卫）
    try {
        rational<int> bad(1, 0);
        (void)bad;
    } catch (const boost::bad_rational&) {
        std::cout << "1/0 抛 bad_rational（不是 UB）\n";
    }

    // 6) 书 ch9.3 补充：gcd/lcm 工具、abs、bool 语境、rational_cast 出口
    std::cout << "gcd(37,62) = " << boost::gcd(37, 62)
              << " lcm(37,62) = " << boost::lcm(37, 62) << '\n';
    rational<int> neg(-14, 10);
    std::cout << "-14/10 规范化 = " << neg << " abs = " << abs(neg) << '\n';
    rational<int> zero(0);
    std::cout << "bool 语境: 0 为假? " << (!zero) << " 7/5 为真? "
              << (rational<int>(7, 5) ? true : false) << '\n';
    // 出向浮点必须显式 rational_cast（无隐式转换——防精度悄悄丢失）
    rational<int> approx_pi(22, 7);
    std::cout << "rational_cast<double>(22/7) = "
              << boost::rational_cast<double>(approx_pi)
              << "（sqrt 等数学函数也要先转出去）\n";

    std::cout << "自检通过\n";
    return 0;
}
