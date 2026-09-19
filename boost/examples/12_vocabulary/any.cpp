// any.cpp —— Boost.Any（2001）：类型擦除的值语义容器（std::any 直系）
// 对应文档：docs/12-vocabulary.md
#include <boost/any.hpp>
#include <iostream>
#include <any>
#include <string>

int main() {
    // 1) 装任何可拷贝类型，按值语义管理
    boost::any a = 42;
    a = std::string("hello");
    a = 3.14;

    // 2) 取回：any_cast——类型不对抛异常
    try {
        std::cout << "double = " << boost::any_cast<double>(a) << '\n';
        boost::any_cast<int>(a);                       // 装的是 double，取 int 失败
    } catch (const boost::bad_any_cast&) {
        std::cout << "any_cast<int> 失败抛 bad_any_cast\n";
    }

    // 3) 指针形式：不抛异常，类型不符返回 nullptr
    if (auto* d = boost::any_cast<double>(&a)) {
        std::cout << "指针式取回 = " << *d << '\n';
    }

    // 4) 查询与清空
    std::cout << "有值? " << !a.empty() << " 类型 = " << a.type().name() << '\n';
    a.clear();
    std::cout << "reset 后有值? " << !a.empty() << '\n';

    // 5) std 对照（C++17 毕业，接口逐字对应）
    std::any sa = std::string("std");
    std::cout << "std 版长度 = " << std::any_cast<std::string>(sa).size() << '\n';

    // 6) 与 variant 的边界：any 是开放的（任何类型），variant 是封闭的
    //    （列出成员）。配置值、消息载荷用 any；穷尽分派用 variant。
    std::cout << "选型：开放载荷 any / 封闭分派 variant\n";

    std::cout << "自检通过\n";
    return 0;
}
