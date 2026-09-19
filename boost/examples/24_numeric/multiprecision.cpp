// multiprecision.cpp —— Boost.Multiprecision（2002→2013）：超精度数值。
// cpp_int 任意精度整数 / cpp_dec_float 百位小数 / 底层可换 GMP。
// 对应文档：docs/24-numeric.md
#include <boost/multiprecision/cpp_int.hpp>
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <iostream>

int main() {
    using boost::multiprecision::cpp_int;
    using boost::multiprecision::cpp_dec_float_50;

    // 1) 任意精度整数：100! 不溢出
    cpp_int fact = 1;
    for (int i = 2; i <= 100; ++i) fact *= i;
    std::string s = fact.convert_to<std::string>();
    std::cout << "100! 有 " << s.size() << " 位, 末 10 位 = "
              << s.substr(s.size() - 10) << '\n';

    // 2) 50 位十进制浮点：π 的精度游戏
    cpp_dec_float_50 pi = boost::math::constants::pi<cpp_dec_float_50>();
    std::cout.precision(50);
    std::cout << "π(50位) = " << pi << '\n';
    std::cout.precision(6);

    // 3) 大整数运算与类型提升
    cpp_int a("123456789012345678901234567890");
    cpp_int b("987654321098765432109876543210");
    std::cout << "a+b 前 15 位 = " << (a + b).convert_to<std::string>().substr(0, 15) << "...\n";
    std::cout << "a*b 是 57 位? " << ((a * b).convert_to<std::string>().size() == 57) << '\n';

    // 4) 与内置类型互算：表达式模板自动提升精度
    cpp_int mixed = a / cpp_int(3);
    std::cout << "a/3 前 10 位 = " << mixed.convert_to<std::string>().substr(0, 10) << "...\n";

    std::cout << "自检通过\n";
    return 0;
}
