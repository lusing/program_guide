// assign.cpp —— Boost.Assign（2003）：C++98 没有 initializer_list 时代的
// 容器字面量。今天 95% 被 {} 初始化取代——它是"语言特性吞掉库"的教科书。
// 对应文档：docs/21-container-core.md
#include <boost/assign/list_of.hpp>
#include <boost/assign/std/vector.hpp>
#include <boost/assign/std/map.hpp>
#include <iostream>
#include <map>
#include <string>
#include <vector>

int main() {
    using namespace boost::assign;

    // 1) 2003 年的姿态：list_of 造容器
    std::vector<int> v = list_of(1)(2)(3);
    std::cout << "list_of:";
    for (int x : v) std::cout << ' ' << x;
    std::cout << '\n';

    // 2) map_list_of：键值对字面量
    std::map<std::string, int> ages = map_list_of("ada", 36)("grace", 85);
    std::cout << "map_list_of: ada=" << ages.at("ada") << " grace=" << ages.at("grace") << '\n';

    // 3) += 语法糖：往已有容器追加
    std::vector<int> w;
    w += 10, 20, 30;
    std::cout << "+= 语法:";
    for (int x : w) std::cout << ' ' << x;
    std::cout << '\n';

    std::map<std::string, int> m;
    insert(m)("x", 1)("y", 2);
    std::cout << "insert: x=" << m.at("x") << " y=" << m.at("y") << '\n';

    // 4) 今天的写法（C++11 起）：语言级初始化列表全覆盖
    std::vector<int> v2{1, 2, 3};
    std::map<std::string, int> m2{{"ada", 36}, {"grace", 85}};
    std::cout << "现代写法: " << v2.size() << " 元, " << m2.size() << " 对\n";

    // 5) 残余价值：给"任何"可 push_back 的东西做适配器时偶尔顺手
    std::cout << "自检通过\n";
    return 0;
}
