// integer.cpp —— Boost.Integer：定宽整数与整数工具（cstdint 的补强）
// 对应文档：docs/05-langbase.md
#include <boost/integer.hpp>
#include <boost/integer/integer_mask.hpp>
#include <boost/integer/static_log2.hpp>
#include <cstdint>
#include <iostream>

int main() {
    // 1) 按数值范围选最小类型：uint_value_t<V>::least = 能装下 V 的最小无符号
    using hold_200k = boost::uint_value_t<200000>::least;   // 20 万 → uint32_t
    std::cout << "装下 200000 的最小无符号: " << sizeof(hold_200k) * CHAR_BIT << " 位\n";

    using fast_8 = boost::int_t<8>::fast;                    // "至少 8 位且最快"
    std::cout << "最快 8 位有符号: " << sizeof(fast_8) * CHAR_BIT << " 位\n";

    // 2) 精确宽度（这部分 <cstdint> 有了，但"取最小/最快"的元编程选择器没有）
    static_assert(std::is_same_v<boost::uint_t<16>::exact, std::uint16_t>,
                  "精确 16 位");

    // 3) 位掩码与静态 log2：位运算配置代码的老朋友
    //    注意：high_bit_fast 的类型可能是 unsigned char——值 8 会打成退格符，
    //    打印前要 cast（本教程"无控制字符"判定专治这种幺蛾子）
    std::cout << "1<<3 = 0x" << std::hex
              << static_cast<unsigned>(boost::high_bit_mask_t<3>::high_bit_fast)
              << std::dec << " log2 向下取整(1000) = "
              << boost::static_log2<1000>::value << '\n';

    std::cout << "自检通过\n";
    return 0;
}
