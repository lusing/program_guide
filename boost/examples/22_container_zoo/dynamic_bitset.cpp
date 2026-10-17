// dynamic_bitset.cpp —— Boost.DynamicBitset（2001）：任意长位集。
// std::bitset<N> 是编译期定长——运行期才知道长度（哈希指纹、布隆过滤、
// 集合论运算）就得用它。注意：它**不是容器**（没有迭代器），只有下标。
// 对应文档：docs/22-container-zoo.md
#include <boost/dynamic_bitset.hpp>
#include <boost/utility/binary.hpp>    // BOOST_BINARY（见第 5 章）
#include <iostream>
#include <string>

int main() {
    // ── 1) 构造全家（长度是运行期值）──
    boost::dynamic_bitset<> a(10, BOOST_BINARY(10101));  // 10 位，值 10101
    boost::dynamic_bitset<> b(std::string("0100"));      // 只认 std::string
    boost::dynamic_bitset<> c(0x16, BOOST_BINARY(10101));// 22 位
    std::cout << "构造: " << a << ' ' << b << ' ' << c
              << "（第 0 位在**最右边**，stream 输出高位在左）\n";

    // ── 2) 内存模型：按 Block 存储 ──
    std::cout << "块大小: " << c.num_blocks() << " 块 × "
              << sizeof(boost::dynamic_bitset<>::block_type) * 8 << " 位（"
              << c.size() << " 位只需 " << c.num_blocks() << " 块）\n";

    // ── 3) 位运算全家 + 集合语义 ──
    boost::dynamic_bitset<> s1(5, BOOST_BINARY(10101));
    boost::dynamic_bitset<> s2(5, BOOST_BINARY(10010));
    std::cout << "位运算: 并|" << (s1 | s2) << " 交&" << (s1 & s2)
              << " 差-" << (s1 - s2) << " 异或^" << (s1 ^ s2) << '\n';
    // 位运算就是集合运算；子集判定有专门的函数
    boost::dynamic_bitset<> sub(5, BOOST_BINARY(101));
    std::cout << "子集: {101} ⊆ {10101}? " << sub.is_subset_of(s1)
              << " 真子集? " << sub.is_proper_subset_of(s1) << '\n';

    // ── 4) 逐位访问：test/set/reset/flip + 计数 ──
    std::cout << "访问: test(0)=" << s1.test(0) << " count=" << s1.count()
              << " any=" << s1.any() << " none=" << s1.none() << '\n';
    s1.set(1, 1);                      // set(pos, value)
    s1.reset();
    s1.flip(3);
    std::cout << "清零+翻位后: " << s1 << " count=" << s1.count() << '\n';

    // ── 5) 增长：push_back 顶位；append 追加一整块 ──
    boost::dynamic_bitset<> grow(5, BOOST_BINARY(01001));
    grow.push_back(true);              // 最高位添 1
    std::cout << "push_back 后: " << grow << " 值="
              << grow.to_ulong() << '\n';
    grow.append(BOOST_BINARY(101));    // 追加**整块**（64 位）——小心！
    std::cout << "append 后长度 = " << grow.size()
              << "（+block_size 而不是 +3 位）\n";

    // ── 6) 转换与溢出 ──
    boost::dynamic_bitset<> small(std::string("1010"));
    std::cout << "to_ulong = " << small.to_ulong() << '\n';
    // to_ulong 的合同：**有效位**（非零最高位）不超过 unsigned long 宽度才
    // 行——grow 有 38 位但高位全 0，照样能转（本机 ulong 32 位）
    std::cout << "38 位但高位全 0 → to_ulong = " << grow.to_ulong() << '\n';
    bool overflowed = false;
    try {
        boost::dynamic_bitset<> big(40);
        big.set(35);                   // 有效位在第 35 位 > 32 位宽
        big.to_ulong();
    } catch (const std::overflow_error&) {
        overflowed = true;
    }
    std::cout << "有效位超宽抛 overflow_error? " << overflowed
              << "（保险走 to_string）\n";
    std::string dumped;
    boost::to_string(grow, dumped);
    std::cout << "to_string 长度 = " << dumped.size() << '\n';

    // ── 7) 查找：find_first / find_next（返回下标不是迭代器）──
    // 【书里的警告亲测】BOOST_BINARY 单组最长 8 位：写成 0010010001（10 位
    // 一组）直接 C1009 宏嵌套爆炸。空格分组，每组 ≤8 位。
    boost::dynamic_bitset<> probe(10, BOOST_BINARY(00100100 01));
    std::cout << "位 1 位置: first=" << probe.find_first()
              << " next=" << probe.find_next(probe.find_first())
              << "（找不到给 npos）\n";

    // ── 8) 综合运用：筛法求 50 以内质数（书 ch7 例）──
    {
        const int n = 50;
        boost::dynamic_bitset<> sieve(n);
        sieve.set();                                    // 全置 1（假设都是质数）
        for (auto i = sieve.find_next(1);               // 从 2 开始
             i != boost::dynamic_bitset<>::npos;
             i = sieve.find_next(i))
            for (auto j = sieve.find_next(i);           // 划掉 i 的倍数
                 j != boost::dynamic_bitset<>::npos;
                 j = sieve.find_next(j))
                if (j % i == 0) sieve[j] = 0;
        std::cout << "50 以内质数(" << sieve.count() << " 个):";
        for (auto i = sieve.find_next(1);
             i != boost::dynamic_bitset<>::npos;
             i = sieve.find_next(i))
            std::cout << ' ' << i;
        std::cout << '\n';
    }

    std::cout << "自检通过\n";
    return 0;
}
