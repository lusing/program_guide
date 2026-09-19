// safe_numerics.cpp —— Boost.SafeNumerics（2017）：把算术 UB 变成
// 编译期错误或运行期异常——"有符号溢出是无声的 bug"这件事的解毒剂。
// 对应文档：docs/24-numeric.md
#include <boost/safe_numerics/safe_integer.hpp>
#include <boost/safe_numerics/exception.hpp>
#include <iostream>

int main() {
    using namespace boost::safe_numerics;

    // 1) 内置类型：溢出是 UB（实际常表现为回绕）
    std::int8_t raw = 100;
    raw += 100;                                  // 有符号溢出：UB！
    std::cout << "int8 原生 100+100 = " << (int)raw << "（UB 现场，碰巧回绕）\n";

    // 2) safe<int8_t>：运行期抛异常
    try {
        safe<std::int8_t> s = 100;
        s += 100;
        std::cout << "不会到这\n";
    } catch (const std::exception&) {
        std::cout << "safe 溢出被抓住（positive_overflow）\n";
    }

    // 3) 能在编译期证明安全的场景：报编译错误
    // safe<std::int8_t> x = 200;   // 编译错误：字面量直接超范围
    //（教程不真编它——整个文件要过编译）

    // 4) 正常运算无额外负担的用法（宽松模式可换策略）
    safe<int> a = 1'000'000;
    safe<int> b = a * 2;
    std::cout << "安全范围內: 1000000×2 = " << b << '\n';

    // 5) 除零也有守卫
    try {
        safe<int> z = 0;
        safe<int> r = 10 / z;
        (void)r;
    } catch (const std::exception&) {
        std::cout << "除零被抓住（divide_by_zero）\n";
    }

    std::cout << "自检通过\n";
    return 0;
}
