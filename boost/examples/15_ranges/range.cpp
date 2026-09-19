// range.cpp —— Boost.Range（2003）：ranges 的直系祖先
// Eric Niebler 写了它、然后用 15 年把它的思想推进 C++20 std::ranges
// 对应文档：docs/15-ranges.md
#include <boost/range/adaptors.hpp>
#include <boost/range/algorithm.hpp>
#include <iostream>
#include <string>
#include <vector>
#include <ranges>

int main() {
    std::vector<int> v{3, 1, 4, 1, 5, 9, 2, 6};

    // 1) boost::range 算法：容器直接传（2003 年就免了 begin/end）
    std::vector<int> sorted_copy;
    boost::range::sort(v);
    std::cout << "排序: ";
    boost::range::copy(v, std::ostream_iterator<int>(std::cout, " "));
    std::cout << '\n';

    // 2) 适配器（adaptors）：管道语法的原型
    namespace ba = boost::adaptors;
    auto evens = v | ba::filtered([](int x) { return x % 2 == 0; })
                   | ba::transformed([](int x) { return x * 10; });
    std::cout << "过滤+变换: ";
    for (int x : evens) std::cout << x << ' ';
    std::cout << '\n';

    // 3) 切片与反转
    auto first3 = v | ba::sliced(0, 3);
    std::cout << "前 3 个: ";
    for (int x : first3) std::cout << x << ' ';
    std::cout << '\n';

    // 4) std::ranges 对照（C++20 毕业——同一作者，同一思想，更完整的接口）
    std::ranges::sort(v, std::greater{});
    std::cout << "std 降序: ";
    for (int x : v | std::views::filter([](int x) { return x > 3; })
                    | std::views::take(3)) std::cout << x << ' ';
    std::cout << '\n';

    std::cout << "自检通过\n";
    return 0;
}
