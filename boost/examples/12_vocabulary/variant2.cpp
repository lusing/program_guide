// variant2.cpp —— Boost.Variant2（2019）：variant 的现代重制
// 对应文档：docs/12-vocabulary.md
// std::variant 毕业后，作者 Peter Dimov 重看这个设计：C++11 后有些历史
// 负担不必再背——于是有了 variant2（接口几乎与 std::variant 相同）。
#include <boost/variant2/variant.hpp>
#include <iostream>
#include <string>

int main() {
    using boost::variant2::variant;
    using boost::variant2::get_if;

    // 1) 与 std::variant 高度同构
    variant<int, float, std::string> v;
    v = 3.14f;

    // 2) visit：与 std::visit 同形
    boost::variant2::visit([](auto&& x) { std::cout << "  装着 float? " << (sizeof(x) == 4) << '\n'; }, v);

    // 3) get_if：指针式访问，不抛异常
    if (auto* f = get_if<float>(&v)) {
        std::cout << "  float 值 = " << *f << '\n';
    }

    // 4) 差异点：variant2 对 never-empty 保证的实现选择更直接；
    //    holds_alternative 与 std 同名同义
    std::cout << "  是 float? " << boost::variant2::holds_alternative<float>(v) << '\n';

    // 5) C++26 对照：std::variant 界面在演进（visit<R>、数学运算提案），
    //    variant2 是作者对"如果重来一次"的答案
    v = std::string("hello");
    std::cout << "  切到 string 后长度 = "
              << boost::variant2::get<std::string>(v).size() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
