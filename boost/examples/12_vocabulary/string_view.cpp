// string_view.cpp —— Boost 的 string_view（std::string_view 的直系祖先）
// 对应文档：docs/12-vocabulary.md
#include <boost/utility/string_view.hpp>
#include <iostream>
#include <string>
#include <string_view>

int main() {
    // 1) 不拥有字符串的"窗口"：零拷贝切片与查找
    std::string url = "https://codeberg.org/lusing/programming";
    boost::string_view sv(url);                        // 指过去，不拷贝

    boost::string_view scheme = sv.substr(0, sv.find("://"));
    boost::string_view host   = sv.substr(8, sv.find('/', 8) - 8);
    std::cout << "scheme = " << scheme << " host = " << host << '\n';

    // 2) 从字面量直接构造（不分配）
    boost::string_view lit = "constexpr 字面量";
    std::cout << "字面量长度 = " << lit.size() << '\n';

    // 3) remove_prefix/suffix：解析器式的游标推进
    boost::string_view path = sv;
    path.remove_prefix(sv.find('/', 8));               // 剥掉 scheme+host
    std::cout << "路径 = " << path << '\n';

    // 4) std 对照（C++17 毕业，接口几乎一致）
    std::string_view ssv = url;
    std::cout << "std 版 starts_with https? "
              << ssv.starts_with("https") << '\n';     // starts_with 是 C++20 补的

    // 5) 悬垂警告：view 不延长底层寿命——这是它唯一的坑
    // auto dangling = std::string("tmp").substr(0, 2); 后接 string_view 就是经典事故
    std::cout << "记：view 无所有权，函数返回 view 要确保底座活着\n";

    std::cout << "自检通过\n";
    return 0;
}
