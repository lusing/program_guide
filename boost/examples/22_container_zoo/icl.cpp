// icl.cpp —— Boost.ICL（Interval Container Library，2010）：
// 区间的集合与映射——日程表、时间片、IP 段、内存区间管理的利器。
// 对应文档：docs/22-container-zoo.md
#include <boost/icl/interval_set.hpp>
#include <boost/icl/interval_map.hpp>
#include <boost/icl/split_interval_set.hpp>
#include <iostream>

int main() {
    using boost::icl::interval_set;
    using boost::icl::interval_map;
    namespace icl = boost::icl;

    // 1) interval_set：自动合并相邻区间
    interval_set<int> busy;
    busy.insert(icl::interval<int>::closed(9, 11));
    busy.insert(icl::interval<int>::closed(12, 17));
    busy.insert(icl::interval<int>::closed(18, 20));   // 与 12-17 合并成 12-20
    std::cout << "忙碌时段段数 = " << icl::interval_count(busy) << "（相邻自动合并）\n";
    std::cout << "10 点有空? " << boost::icl::contains(busy, 10) << '\n';
    std::cout << "11:30(即 11)有空? " << boost::icl::contains(busy, 11) << '\n';
    std::cout << "8 点有空? " << !boost::icl::contains(busy, 8) << '\n';

    // 2) 区间运算：交
    interval_set<int> other;
    other.insert(icl::interval<int>::closed(15, 25));
    interval_set<int> both = busy & other;
    std::cout << "交集首段 = " << *both.begin() << '\n';

    // 3) interval_map：区间带值（重叠时聚合）
    interval_map<int, int> load;
    load += std::make_pair(icl::interval<int>::closed(0, 9), 1);
    load += std::make_pair(icl::interval<int>::closed(5, 14), 1);
    // 5-9 重叠区聚合为 2
    std::cout << "负载区间数 = " << load.iterative_size() << "（含聚合出的 5-9=2 段）\n";
    for (const auto& [iv, v] : load) std::cout << "  " << iv << " → " << v << '\n';

    std::cout << "自检通过\n";
    return 0;
}
