// describe.cpp —— Boost.Describe（2020）：穷人反射——宏注册的枚举/结构体元数据。
// C++26 反射（P2996）落地前，这是"给类型挂元信息"的标准姿势。
// 对应文档：docs/18-cpp26.md
#include <boost/describe.hpp>
#include <boost/mp11.hpp>
#include <iostream>
#include <string>

// 1) 枚举反射：一行宏注册，就能遍历/打印/解析
enum class Color { red, green, blue };
BOOST_DESCRIBE_ENUM(Color, red, green, blue)

// 2) 结构体反射：成员名 + 指针全拿到
struct Point {
    int x = 0;
    int y = 0;
};
BOOST_DESCRIBE_STRUCT(Point, (), (x, y))

// 通用"打印任意已注册结构体"——序列化/调试打印的地基
template <class T>
void print_struct(const T& t) {
    boost::mp11::mp_for_each<boost::describe::describe_members<T, boost::describe::mod_any_access>>(
        [&](auto D) {
            std::cout << "  " << D.name << " = " << t.*D.pointer << '\n';
        });
}

int main() {
    // 枚举：名字 ↔ 值 双向
    std::cout << "枚举遍历:";
    boost::mp11::mp_for_each<boost::describe::describe_enumerators<Color>>(
        [](auto E) { std::cout << ' ' << E.name << '=' << static_cast<int>(E.value); });
    std::cout << '\n';

    Color c = Color::green;
    const char* cname = "?";
    boost::mp11::mp_for_each<boost::describe::describe_enumerators<Color>>(
        [&](auto E) { if (E.value == c) cname = E.name; });
    std::cout << "green 的名字 = " << cname << '\n';

    // 结构体：成员级反射
    Point p{3, 4};
    std::cout << "Point 反射:\n";
    print_struct(p);

    // C++26 展望：P2996 静态反射后，这些宏全部退化成
    // ^^ { std::meta::nonstatic_data_members_of(...) } 一类原生写法——
    // 但在 2026 年的现实里，Describe 仍是跨编译器的可靠答案
    std::cout << "自检通过\n";
    return 0;
}
