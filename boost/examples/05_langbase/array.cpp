// array.cpp —— Boost.Array：定长数组容器（std::array 的直系祖先，2001）
// 对应文档：docs/05-langbase.md
#include <boost/array.hpp>
#include <array>
#include <algorithm>
#include <iostream>
#include <numeric>

int main() {
    boost::array<int, 5> a{{3, 1, 4, 1, 5}};   // 双花括号：聚合初始化的 C++03 惯用法

    // 有 begin/end/size/swap——STL 容器的完整接口，但存储在栈上
    std::sort(a.begin(), a.end());
    std::cout << "排序后:";
    for (int x : a) std::cout << ' ' << x;
    std::cout << "\nsize=" << a.size() << " 求和=" << std::accumulate(a.begin(), a.end(), 0) << '\n';

    // 与 C 数组的互操作：data() 直接拿裸指针（无 NUL 终止，打印要带长度）
    boost::array<char, 4> buf{{'a', 'b', 'c', 'd'}};
    std::cout << "data 前 4 字节: ";
    std::cout.write(buf.data(), static_cast<std::streamsize>(buf.size()));
    std::cout << " 首元素 " << *buf.data() << '\n';

    // std::array 是它的直系后代（Nicolai Josuttis 把它带进了 TR1/C++11）。
    // 细节差异：std::array 的聚合初始化 C++11 后不需要双花括号
    std::array<int, 5> s{3, 1, 4, 1, 5};
    std::cout << "std::array 求和 = " << std::accumulate(s.begin(), s.end(), 0) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
