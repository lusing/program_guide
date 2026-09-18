// tuple.cpp —— Boost.Tuple：异构定长容器（std::tuple 的直系祖先，2002）
// 对应文档：docs/05-langbase.md
#include <boost/tuple/tuple.hpp>
#include <boost/tuple/tuple_comparison.hpp>
#include <iostream>
#include <string>

int main() {
    // 1) 构造与取值：get<N>() 是自由函数（std::tuple 相同）
    boost::tuple<int, std::string, double> item{1, "ada", 3.14};
    std::cout << "id=" << boost::get<0>(item)
              << " name=" << boost::get<1>(item)
              << " score=" << boost::get<2>(item) << '\n';

    // 2) make_tuple + tie：解包的祖师爷
    auto t = boost::make_tuple(7, std::string("x"));
    int a; std::string b;
    boost::tie(a, b) = t;                 // 一行解包（C++17 结构化绑定是它的续集）
    std::cout << "tie 解包: " << a << ',' << b << '\n';

    // 3) 比较运算：字典序（tie 实现的经典应用——结构体比较一行搞定）
    auto k1 = boost::make_tuple(1, std::string("a"));
    auto k2 = boost::make_tuple(1, std::string("b"));
    std::cout << "k1 < k2 ? " << std::boolalpha << (k1 < k2) << '\n';

    // 4) 对应的 std 版（C++11 毕业）+ C++17 结构化绑定
    std::tuple<int, std::string, double> s{2, "grace", 2.71};
    auto [id, name, score] = s;
    std::cout << "结构化绑定: " << id << ',' << name << ',' << score << '\n';

    // 5) std 独有而 boost 版没有的：tuple_size/tuple_element 元编程接口
    std::cout << "std::tuple_size = " << std::tuple_size_v<decltype(s)> << '\n';

    std::cout << "自检通过\n";
    return 0;
}
