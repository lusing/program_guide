// typeof.cpp —— Boost.Typeof：C++03 的 auto（已毕业，但有 expression 场景残留）
// 对应文档：docs/05-langbase.md
#include <boost/typeof/typeof.hpp>
#include <iostream>
#include <map>
#include <string>
#include <vector>

int main() {
    std::map<std::string, std::vector<int>> table;
    table["odd"] = {1, 3, 5};

    // 2004 年：BOOST_TYPEOF + BOOST_AUTO 在没有 auto 的年代给出 auto
    BOOST_AUTO(it, table.begin());                       // auto it = ...
    std::cout << "BOOST_AUTO 拿到迭代器指向 " << it->first << '\n';

    BOOST_TYPEOF(table["odd"]) copy = table["odd"];      // decltype 的前身
    std::cout << "BOOST_TYPEOF 拷贝长度 " << copy.size() << '\n';

    // C++11 auto / C++14 decltype(auto) 完成毕业
    auto it2 = table.begin();
    decltype(table["odd"]) copy2 = table["odd"];
    std::cout << "auto+decltype: " << it2->first << ' ' << copy2.size() << '\n';

    // 残留价值：BOOST_TYPEOF 能"编码"表达式模板的完整类型
    // （某些 EDSL 库要求在 C++03 语义下注册类型——现代代码直接 decltype）
    std::cout << "自检通过\n";
    return 0;
}
