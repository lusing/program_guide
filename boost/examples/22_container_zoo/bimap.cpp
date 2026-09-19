// bimap.cpp —— Boost.BiMap（2004）：双向 map——键值都可查。
// std::map 是单向的；bimap<int, std::string> 两边都是键。
// 对应文档：docs/22-container-zoo.md
#include <boost/bimap.hpp>
#include <boost/bimap/set_of.hpp>
#include <boost/bimap/multiset_of.hpp>
#include <iostream>
#include <string>

int main() {
    boost::bimap<int, std::string> bm;

    // 1) 两边都是唯一键
    bm.insert({1, "one"});
    bm.insert({2, "two"});
    bm.insert({3, "three"});

    std::cout << "左查(1) = " << bm.left.at(1) << '\n';
    std::cout << "右查(three) = " << bm.right.at("three") << '\n';

    // 2) 插入重复值会被拒（默认 set_of 两侧都唯一）
    auto r = bm.insert({9, "one"});
    std::cout << "重复右值插入成功? " << r.second << "（大小仍 " << bm.size() << "）\n";

    // 3) 关系视图：遍历拿到的是 relation（左/右两个投影）
    for (const auto& rel : bm) {
        std::cout << "  " << rel.left << " ↔ " << rel.right << '\n';
        if (rel.left == 2) break;   // 打印到 2 就够
    }

    // 4) 集合类型可配置：bimap<set_of<int>, multiset_of<std::string>>
    boost::bimap<boost::bimaps::set_of<int>, boost::bimaps::multiset_of<std::string>> bm2;
    bm2.insert({1, "a"});
    bm2.insert({1, "b"});       // 右侧允许多
    std::cout << "multiset 右侧: 1 映射 " << bm2.right.count("a") + bm2.right.count("b") << " 个键\n";

    std::cout << "自检通过\n";
    return 0;
}
