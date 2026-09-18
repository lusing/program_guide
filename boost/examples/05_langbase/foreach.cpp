// foreach.cpp —— Boost.Foreach：C++03 的 range-for（2011 年毕业的最干脆案例）
// 对应文档：docs/05-langbase.md
#include <boost/foreach.hpp>
#include <iostream>
#include <map>
#include <string>
#include <vector>

int main() {
    std::vector<int> v{1, 2, 3};
    std::map<std::string, int> ages{{"ada", 36}, {"grace", 85}};

    // BOOST_FOREACH：引用声明直接写在宏参数里
    BOOST_FOREACH (int x, v) {
        std::cout << x << ' ';
    }
    std::cout << '\n';

    // 反向遍历：BOOST_REVERSE_FOREACH
    BOOST_REVERSE_FOREACH (int x, v) {
        std::cout << x << ' ';
    }
    std::cout << '\n';

    // map 的 pair 也能直接吃
    BOOST_FOREACH (auto& kv, ages) {
        std::cout << kv.first << '=' << kv.second << ' ';
    }
    std::cout << '\n';

    // C++11 range-for 完成毕业——语法糖的终极形态
    for (auto& kv : ages) {
        std::cout << kv.second << ';';
    }
    std::cout << '\n';
    // C++17 结构化绑定再进一步
    for (auto& [name, age] : ages) {
        std::cout << name << age;
    }
    std::cout << '\n';

    std::cout << "自检通过\n";
    return 0;
}
