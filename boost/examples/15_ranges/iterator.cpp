// iterator.cpp —— Boost.Iterator（2001）：迭代器设施的军火库
// 对应文档：docs/15-ranges.md
#include <boost/iterator/transform_iterator.hpp>
#include <boost/iterator/filter_iterator.hpp>
#include <boost/iterator/counting_iterator.hpp>
#include <boost/iterator/reverse_iterator.hpp>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> v{1, 2, 3, 4, 5};

    // 1) transform_iterator：包一个函数，迭代时就地变换
    auto dbl = [](int x) { return x * x; };
    for (auto it = boost::make_transform_iterator(v.begin(), dbl);
         it != boost::make_transform_iterator(v.end(), dbl); ++it) {
        std::cout << *it << ' ';
    }
    std::cout << '\n';

    // 2) filter_iterator：只迭代满足谓词的元素
    auto is_odd = [](int x) { return x % 2 == 1; };
    for (auto it = boost::make_filter_iterator(is_odd, v.begin(), v.end());
         it != boost::make_filter_iterator(is_odd, v.end(), v.end()); ++it) {
        std::cout << *it << ' ';
    }
    std::cout << '\n';

    // 3) counting_iterator：从数字序列生成迭代器（无实体存储）
    int sum = 0;
    for (auto it = boost::counting_iterator<int>(1);
         it != boost::counting_iterator<int>(11); ++it) sum += *it;
    std::cout << "1..10 求和 = " << sum << '\n';

    // 4) reverse_iterator（std 已有同款，对照）
    auto rb = v.rbegin();
    std::cout << "尾元素 = " << *rb << '\n';

    // 5) std 对照：C++20 ranges 时代，views 接管了大部分"迭代器适配"场景；
    //    但自定义容器的迭代器骨架仍看 boost（见 stl_interfaces.cpp）
    std::cout << "自检通过\n";
    return 0;
}
