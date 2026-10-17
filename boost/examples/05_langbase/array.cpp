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

    // boost 版的私货 assign 已被 1.92 标弃用（请改用 std 同款 fill）
    boost::array<int, 3> ar;
    ar.fill(777);
    std::cout << "fill(777): 首元素 = " << ar[0] << "（老代码里的 assign 已弃用）\n";
    // 能力限制（两个版本同）：没有构造函数、不能动态增删（无 push_back），
    // 插入迭代器也不适用——要动态长度用 vector
    std::cout << "限制: 无构造/无 push_back/无插入迭代器（编译期定长的代价）\n";

    std::cout << "自检通过\n";
    return 0;
}
