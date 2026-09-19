// dynamic_bitset.cpp —— Boost.DynamicBitset（2001）：任意长位集。
// std::bitset<N> 是编译期定长——运行期才知道长度（哈希指纹、布隆过滤、
// 集合论运算）就得用它。
// 对应文档：docs/22-container-zoo.md
#include <boost/dynamic_bitset.hpp>
#include <iostream>
#include <string>

int main() {
    // 1) 运行期定长
    boost::dynamic_bitset<> flags(8);
    flags.set(1);
    flags.set(3);
    flags.set(5);
    std::cout << "位集 = " << flags << "（高位在左）\n";
    std::cout << "1/3/5 位置位? " << flags.test(1) << flags.test(3) << flags.test(5) << '\n';

    // 2) 位运算全家桶
    boost::dynamic_bitset<> mask(8);
    mask.set(1); mask.set(3);
    auto and_ = flags & mask;
    std::cout << "AND = " << and_ << " count = " << and_.count() << '\n';
    auto or_ = flags | mask;
    std::cout << "OR  = " << or_ << '\n';
    auto flip = ~flags;
    std::cout << "NOT = " << flip << '\n';

    // 3) 移位（位图式集合运算）
    boost::dynamic_bitset<> shifted = flags << 2;
    std::cout << "左移 2 = " << shifted << '\n';

    // 4) 从字符串构造 + 序列化
    boost::dynamic_bitset<> from_str(std::string("10110010"));
    std::cout << "字符串来 = " << from_str << " 个数 = " << from_str.count() << '\n';

    // 5) 查找：第一个 1 的位置
    std::cout << "flags 第一个 1 在 " << flags.find_first() << '\n';
    std::cout << "下一个 1 在 " << flags.find_next(1) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
