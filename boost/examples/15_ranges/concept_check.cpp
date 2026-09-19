// concept_check.cpp —— Boost.ConceptCheck（2000）：concepts 的库级先驱
// 对应文档：docs/15-ranges.md
// C++20 concepts 是语言特性；2000 年 Boost 用模板技巧做到了"约束报错
// 可读"的一半——检查发生在实例化点，错误信息里是概念名不是模板天书。
#include <boost/concept_check.hpp>
#include <iostream>
#include <list>
#include <vector>

// 库作者姿势：函数模板声明"我对参数的概念要求"
template <typename Iter>
typename std::iterator_traits<Iter>::value_type
sum_range(Iter first, Iter last) {
    BOOST_CONCEPT_ASSERT((boost::InputIterator<Iter>));   // 不满足就在这里报错
    typename std::iterator_traits<Iter>::value_type total{};
    for (; first != last; ++first) total += *first;
    return total;
}

// requires 子句（C++20）：同一件事的语言级形态——更早（声明点）、更清晰
template <typename Iter>
    requires std::input_iterator<Iter>
auto sum_range_cxx20(Iter first, Iter last) {
    typename std::iterator_traits<Iter>::value_type total{};
    for (; first != last; ++first) total += *first;
    return total;
}

int main() {
    std::vector<int> v{1, 2, 3, 4, 5};
    std::list<double> l{1.5, 2.5};

    std::cout << "vector 求和 = " << sum_range(v.begin(), v.end()) << '\n';
    std::cout << "list 求和 = " << sum_range(l.begin(), l.end()) << '\n';
    std::cout << "C++20 requires: " << sum_range_cxx20(v.begin(), v.end()) << '\n';

    // 概念检查的真正价值在"错误信息"：把 sum_range 模板传一个 int*
    // 退化输入……概念检查给出的是"InputIterator 概念不满足"而不是
    // 五页模板天书。C++20 之前，这一半体验弥足珍贵。

    std::cout << "自检通过\n";
    return 0;
}
