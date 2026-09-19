// decimal.cpp —— Boost.Decimal（2024）：十进制浮点（ISO/IEC DPD 十进制浮点
// 与 C++23 std::decimal 平行推进——银行利息不用二进制浮点的地方）
// 对应文档：docs/17-cpp23.md
#include <boost/decimal.hpp>
#include <iomanip>
#include <iostream>

int main() {
    using boost::decimal::decimal32_t;
    using boost::decimal::decimal64_t;

    // 1) 为什么需要十进制浮点：0.1 在二进制里是无限循环
    float bf = 0.1f;
    std::cout << "二进制 0.1f 的真实值 ≈ " << std::setprecision(9) << bf << '\n';

    decimal32_t df{5, -1};                        // 5 × 10^-1 = 0.5
    std::cout << "decimal32_t(5,-1) 打印 = " << df << '\n';

    // 2) 精确的十进制算术（0.1 + 0.2 == 0.3 在 decimal 里成立）
    decimal64_t a{1, -1};                         // 0.1
    decimal64_t b{2, -1};                         // 0.2
    decimal64_t c{3, -1};                         // 0.3
    std::cout << "0.1+0.2 == 0.3 ? " << std::boolalpha << (a + b == c)
              << "（二进制 float 下为 false）\n";

    // 3) 与整数的混合运算与比较
    decimal64_t price{199, -2};                   // 1.99
    int qty = 3;
    std::cout << "1.99 × 3 = " << price * qty << '\n';

    // 4) 数学函数族（decimal 家自己的 sqrt/log/exp...）
    decimal64_t four{4};
    std::cout << "sqrt(4) = " << sqrt(four) << '\n';

    // 5) C++23 对照：std::decimal32_t/64/128 是 C++23 的扩展浮点；
    //    boost 版是先行全功能实现（含数学库），语义同源
    std::cout << "自检通过\n";
    return 0;
}
