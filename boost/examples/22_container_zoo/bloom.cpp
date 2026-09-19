// bloom.cpp —— Boost.BloomFilter（1.89 新入库）：概率集合成员查询。
// "可能在内/一定不在内"的 O(1) 判断——缓存穿透防护、爬虫去重的标准件。
// 对应文档：docs/22-container-zoo.md
#include <boost/bloom/filter.hpp>
#include <iostream>
#include <string>

int main() {
    // 1) 基本用法：容量 + 误判率
    boost::bloom::filter<std::string, 1024> bf;   // 1024 位过滤器

    bf.insert("apple");
    bf.insert("banana");
    bf.insert("cherry");

    std::cout << "apple 一定在或可能在? " << bf.may_contain("apple") << '\n';
    std::cout << "banana 可能在? " << bf.may_contain("banana") << '\n';
    std::cout << "durian 一定不在（如果答否）? " << !bf.may_contain("durian") << '\n';

    // 2) 概率语义：小额数据下三个成员全命中，未插入的大概率返回否
    int hits = 0;
    for (const char* w : {"apple", "banana", "cherry", "durian", "elephant", "fig"}) {
        if (bf.may_contain(w)) ++hits;
    }
    std::cout << "6 个词命中 " << hits << " 个（3 个真成员 + 误判）\n";

    // 3) 特性：不删除、不枚举、空间恒定——只换"快+省"
    std::cout << "位图大小恒定 1024 位 = " << sizeof(bf) << " 字节量级\n";

    std::cout << "自检通过\n";
    return 0;
}
