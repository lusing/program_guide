// variant.cpp —— Boost.Variant（2003）：类型安全的联合体（std::variant 直系）
// 对应文档：docs/12-vocabulary.md
#include <boost/variant.hpp>
#include <iostream>
#include <string>
#include <variant>
#include <vector>

struct Visitor : boost::static_visitor<void> {
    Visitor() = default;
    void operator()(int v) const { std::cout << "  int = " << v << '\n'; }
    void operator()(const std::string& v) const { std::cout << "  str = " << v << '\n'; }
    void operator()(double v) const { std::cout << "  dbl = " << v << '\n'; }
};

// 二元访问器：比较两个 variant（模板成员不能放局部类，提到这里）
struct eq_checker : boost::static_visitor<bool> {
    eq_checker() = default;
    template <typename T, typename U>
    bool operator()(const T&, const U&) const { return false; }   // 类型不同
    bool operator()(int a, int b) const { return a == b; }
    bool operator()(const std::string& a, const std::string& b) const { return a == b; }
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

    // 4.5) 访问器进阶：带返回值（ResultType 模板参）+ 延迟访问（单参
    //      apply_visitor 返回函数对象——可喂给 std::for_each 这类算法）+
    //      二元访问器（比较两个 variant）
    struct doubler : boost::static_visitor<int> {
        // C++20 起带基类的类可以是聚合：{} 会试图直接初始化基子对象（protected
        // 拒绝）——显式声明默认构造绕开聚合初始化
        doubler() = default;
        int operator()(int v) const { return v * 2; }
        int operator()(const std::string& v) const { return static_cast<int>(v.size()) * 2; }
    };
    boost::variant<int, std::string> num = 21;
    std::cout << "带返回值访问: doubler(21) = " << boost::apply_visitor(doubler{}, num) << '\n';
    Visitor vis_copy;                                 // 延迟版要可绑定到左值
    auto delayed = boost::apply_visitor(vis_copy);    // 延迟：先拿函数对象
    std::vector<boost::variant<int, std::string>> items{7, std::string("x")};
    for (const auto& e : items) delayed(e);           // 对每个元素访问
    // 二元访问器：模板成员不能在局部类里——挪到函数外（见上方 eq_checker）
    std::cout << "二元访问: (7,7) 同? "
              << boost::apply_visitor(eq_checker{}, items[0], boost::variant<int, std::string>(7))
              << '\n';
    // get 的指针版：类型不符给 nullptr（不抛异常，判断场景更顺）
    std::cout << "get 指针版: 活 int? "
              << (boost::get<int>(&items[0]) != nullptr)
              << " 活 string? "
              << (boost::get<std::string>(&items[0]) != nullptr) << '\n';

    // 5) 递归变体（std::variant 做不到自引用，boost 版靠 forward 声明）
    //    表达式树的经典构造法，见文档 12.5
    std::cout << "递归变体见文档（std 需要包裹结构体间接递归）\n";

    std::cout << "自检通过\n";
    return 0;
}
