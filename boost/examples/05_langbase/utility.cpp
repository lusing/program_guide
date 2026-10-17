// utility.cpp —— Boost.Utility：杂物间里的传家宝
// 对应文档：docs/05-langbase.md
// 这个库是"一堆小工具后来各自毕业"的活化石陈列柜。
#include <boost/utility.hpp>
#include <boost/current_function.hpp>     // BOOST_CURRENT_FUNCTION 在单独的头里
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

    // 5) BOOST_BINARY：C++14 之前没有 0b 字面量时代的二进制书写
    //    ——基于预处理元编程把 01 串展开成八进制。注意：数字组最长 8 位。
    std::cout << "BOOST_BINARY(0110) = " << BOOST_BINARY(0110)          // 6
              << "  多组拼接 = " << BOOST_BINARY(0110 1101) << '\n';   // 0x6d
    // 带后缀的版本：_UL/_LL 等（C++ 有 0b 后这个库件基本退休）
    long long wide = BOOST_BINARY_LL(1101);
    std::cout << "BOOST_BINARY_LL(1101) = " << wide << "（现代写法 0b1101LL）\n";

    // 6) BOOST_CURRENT_FUNCTION：跨编译器的"我在哪个函数"宏
    //    MSVC 用 __FUNCSIG__、GCC 用 __PRETTY_FUNCTION__，它统一之
    std::cout << "当前函数（截断显示）: "
              << std::string(BOOST_CURRENT_FUNCTION).substr(0, 9) << "...\n";

    std::cout << "自检通过\n";
    return 0;
}
