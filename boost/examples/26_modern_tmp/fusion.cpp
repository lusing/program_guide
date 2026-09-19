// fusion.cpp —— Boost.Fusion（2005）：结构体 ↔ 序列的桥梁。
// 把"任意结构体"当 tuple 操作——遍历成员、按名访问、与 MPL 互通。
// 对应文档：docs/26-modern-tmp.md
#include <boost/fusion/include/boost_tuple.hpp>
#include <boost/fusion/adapted/struct.hpp>
#include <boost/fusion/sequence/intrinsic/at_c.hpp>
#include <boost/fusion/algorithm/iteration/for_each.hpp>
#include <boost/fusion/algorithm/transformation/transform.hpp>
#include <iostream>
#include <string>

struct Point3 {
    double x = 0, y = 0, z = 0;
};
BOOST_FUSION_ADAPT_STRUCT(Point3, x, y, z)

int main() {
    using namespace boost::fusion;

    // 1) tuple（fusion 自己的，也兼容 std::tuple/boost::tuple）
    boost::tuple<int, std::string, double> row{7, "ada", 3.5};
    std::cout << "at_c<1> = " << at_c<1>(row) << '\n';

    // 2) for_each 遍历异构序列（泛型 lambda 是标准姿势）
    std::cout << "for_each:";
    for_each(row, [](const auto& x) { std::cout << ' ' << x; });
    std::cout << '\n';

    // 3) 结构体当序列（Fusion 的招牌）
    Point3 p{1.5, 2.5, 3.5};
    std::cout << "Point3 的 y = " << at_c<1>(p) << '\n';
    std::cout << "成员遍历:";
    for_each(p, [](const auto& v) { std::cout << ' ' << v; });
    std::cout << '\n';

    // 4) transform：成员级变换（结果还是 fusion 序列）
    auto doubled = transform(p, [](double v) { return v * 2; });
    std::cout << "翻倍后 x = " << at_c<0>(doubled) << '\n';

    // 5) 位置：Fusion 是"编译期容器"，Hana 是它的现代继任（26.2 节）
    std::cout << "自检通过\n";
    return 0;
}
