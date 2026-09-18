// functional.cpp —— Boost.Functional：工厂与适配器老兵
// 对应文档：docs/04-function.md
#include <boost/functional/factory.hpp>
#include <boost/functional/value_factory.hpp>
#include <boost/functional/overloaded_function.hpp>
#include <iostream>
#include <memory>
#include <string>

struct Widget {
    std::string tag;
    int id;
    Widget(std::string t, int i) : tag(std::move(t)), id(i) {}
};

int    as_int(int x)      { return x; }
double as_double(double x) { return x * 1.5; }

int main() {
    // 1) value_factory：直接产出值
    boost::value_factory<Widget> vf;
    Widget w = vf("value", 1);
    std::cout << "value_factory: " << w.tag << w.id << '\n';

    // 2) factory：产出指针（配智能指针删除器即完整工厂）
    boost::factory<Widget*> pf;
    std::unique_ptr<Widget> up(pf("ptr", 2));
    std::cout << "factory: " << up->tag << up->id << '\n';

    // 3) overloaded_function：把多个不同签名的函数静态分派成一个可调用物
    boost::overloaded_function<int(int), double(double)> of(as_int, as_double);
    std::cout << "overloaded(int 10) = " << of(10) << '\n';
    std::cout << "overloaded(double 10) = " << of(10.0) << '\n';
    // C++ 标准至今没有对应物；通用替代是 if constexpr 手写或 variant 访问

    std::cout << "自检通过\n";
    return 0;
}
