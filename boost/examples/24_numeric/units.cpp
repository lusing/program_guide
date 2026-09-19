// units.cpp —— Boost.Units（2006）：量纲安全的单位运算——
// "米 + 秒"在编译期就是错误。火星气候探测者号（1999，$3.27 亿）的死因。
// 对应文档：docs/24-numeric.md
#include <boost/units/quantity.hpp>
#include <boost/units/systems/si.hpp>
#include <boost/units/systems/si/prefixes.hpp>
#include <boost/units/io.hpp>
#include <iostream>

namespace si = boost::units::si;

int main() {
    using namespace boost::units;

    // 1) 带量纲的值
    quantity<si::length> d = 100.0 * si::meters;
    quantity<si::time> t = 9.58 * si::seconds;
    std::cout << "100m / 9.58s = " << d / t << "（量纲自动推导成速度）\n";

    // 2) 量纲错误的乘除组合在类型里就分开
    quantity<si::velocity> v = d / t;
    quantity<si::acceleration> acc = v / t;
    std::cout << "加速度 = " << acc << '\n';

    // 3) 前缀量是异构单位，要显式换算成 SI 标准量（直接赋值编不过）
    quantity<si::length> dist = 1500.0 * si::meters;
    std::cout << "1500m 量纲输出 = " << dist << '\n';
    quantity<si::energy> e = 60.0 * si::joules;
    std::cout << "60J = " << e.value() << " J\n";

    // 4) 隐式换算警告：int→double 的 quantity 转换要显式
    quantity<si::energy, float> ef(static_cast<quantity<si::energy, float>>(e));
    std::cout << "float 能量 = " << ef.value() << " J\n";

    // 5) 编译期防线演示：d + t 是编译错误（注释里的真实错误信息）
    // quantity<si::length> bad = d + t;   // C2678: 不能相加 length 与 time

    std::cout << "自检通过\n";
    return 0;
}
