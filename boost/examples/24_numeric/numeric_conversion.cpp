// numeric_conversion.cpp —— Boost.NumericConversion（numeric/conversion）：
// 范围检查的数值转换——numeric_cast 的老家（负值转无符号的千年坑）。
// 对应文档：docs/24-numeric.md
#include <boost/numeric/conversion/cast.hpp>
#include <boost/numeric/conversion/bounds.hpp>

#include <iostream>

int main() {
    // 1) 病灶：负数转无符号是"合法的 UB 式陷阱"（回绕成天文数字）
    int neg = -1;
    unsigned int raw = static_cast<unsigned int>(neg);
    std::cout << "原生 cast(-1 → unsigned) = " << raw << "（静默回绕）\n";

    // 2) numeric_cast：超范围直接抛异常
    try {
        auto guarded = boost::numeric_cast<unsigned int>(neg);
        (void)guarded;
    } catch (const boost::numeric::negative_overflow&) {
        std::cout << "numeric_cast 抓住负溢出\n";
    }
    try {
        auto big = boost::numeric_cast<std::int8_t>(200);
        (void)big;
    } catch (const boost::numeric::positive_overflow&) {
        std::cout << "numeric_cast 抓住正溢出\n";
    }

    // 3) 合法转换照常工作
    auto ok = boost::numeric_cast<std::int8_t>(100);
    std::cout << "合法转换 100 → int8 = " << (int)ok << '\n';

    // 4) bounds：任意数值类型的极限（<limits> 的友好版）
    std::cout << "int8 最高 = " << (int)boost::numeric::bounds<std::int8_t>::highest()
              << " float 最低 = " << boost::numeric::bounds<float>::lowest() << '\n';

    // 5) converter 策略类：溢出行为可定制（换成静默截断/饱和等），
    //    库作者把"转换"本身抽象成策略对象——见库文档 converter 一节
    std::cout << "自检通过\n";
    return 0;
}
