// variant.cpp —— Boost.Variant（2003）：类型安全的联合体（std::variant 直系）
// 对应文档：docs/12-vocabulary.md
#include <boost/variant.hpp>
#include <iostream>
#include <string>
#include <variant>

struct Visitor : boost::static_visitor<void> {
    Visitor() = default;
    void operator()(int v) const { std::cout << "  int = " << v << '\n'; }
    void operator()(const std::string& v) const { std::cout << "  str = " << v << '\n'; }
    void operator()(double v) const { std::cout << "  dbl = " << v << '\n'; }
};

int main() {
    // 1) 装不同类型 + 访问：static_visitor 是编译期穷尽分派
    boost::variant<int, std::string, double> v = 10;
    boost::apply_visitor(Visitor{}, v);
    v = std::string("boost");
    boost::apply_visitor(Visitor{}, v);
    v = 3.14;
    boost::apply_visitor(Visitor{}, v);

    // 2) which()：当前活性成员的下标
    std::cout << "当前活性下标 = " << v.which() << "（double 是 2）\n";

    // 3) get 的越界：抛异常而不是 UB
    try {
        boost::get<int>(v);
    } catch (const boost::bad_get&) {
        std::cout << "get<int> 失败抛 bad_get（不是 UB）\n";
    }

    // 4) std 对照（C++17 毕业）：std::visit + 重载 lambda 惯用法
    std::variant<int, std::string> sv = std::string("std");
    std::visit([](auto&& x) { std::cout << "  std::visit: " << x << '\n'; }, sv);

    // 5) 递归变体（std::variant 做不到自引用，boost 版靠 forward 声明）
    //    表达式树的经典构造法，见文档 12.5
    std::cout << "递归变体见文档（std 需要包裹结构体间接递归）\n";

    std::cout << "自检通过\n";
    return 0;
}
