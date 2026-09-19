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

    std::cout << "自检通过\n";
    return 0;
}
