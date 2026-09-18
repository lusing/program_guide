// utility.cpp —— Boost.Utility：杂物间里的传家宝
// 对应文档：docs/05-langbase.md
// 这个库是"一堆小工具后来各自毕业"的活化石陈列柜。
#include <boost/utility.hpp>
#include <boost/utility/swap.hpp>
#include <boost/utility/string_view.hpp>
#include <iostream>
#include <memory>
#include <string>
#include <utility>

struct Conn {
    int fd = -1;
};

// 1) boost::swap：C++98 时代的"找得到成员 swap 的 swap"（std::swap 毕业了）
int take_over(Conn& c) {
    int old = c.fd;
    c.fd = -1;
    return old;
}

int main() {
    Conn c{7};
    std::cout << "take_over 拿到 fd=" << take_over(c) << " 留下 fd=" << c.fd << '\n';

    int x = 1, y = 2;
    boost::core::invoke_swap(x, y);   // boost::swap 已弃用，继任者是 core 里的它
    std::cout << "swap 后 x=" << x << " y=" << y << '\n';

    // 3) string_view 在这里住过（C++17 std::string_view 毕业，第 12 章展开）
    boost::string_view sv = "string_view 住在 utility 里";
    std::cout << sv.substr(0, 11) << "... 长度 " << sv.size() << '\n';

    // 4) in_place_factory：就地构造的先驱（std::in_place_type 毕业了），
    //    至今仍是 boost::optional/vector 就地构造的接口（第 12/21 章见）
    std::cout << "in_place 家族见 optional/container 章\n";

    std::cout << "自检通过\n";
    return 0;
}
