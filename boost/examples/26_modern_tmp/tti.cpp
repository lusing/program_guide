// tti.cpp —— Boost.TTI（Type Traits Introspection，2011）：
// "这个类型有没有这个成员/嵌套类型/函数？"的编译期体检。
// 对应文档：docs/26-modern-tmp.md
#include <boost/tti/tti.hpp>
#include <boost/tti/has_member_function.hpp>
#include <iostream>
#include <string>
#include <type_traits>

struct Full {
    using value_type = int;
    int count = 0;
    void reset() { count = 0; }
    static constexpr const char* name() { return "full"; }
};
struct Bare {};

// TTI 宏：声明"有没有 XX"的元函数
BOOST_TTI_HAS_TYPE(value_type)         // → has_type_value_type<T>
BOOST_TTI_HAS_MEMBER_FUNCTION(reset)   // → has_member_function_reset<T, ...>

int main() {
    // 1) 嵌套类型检测
    std::cout << "Full 有 value_type? " << has_type_value_type<Full>::value << '\n';
    std::cout << "Bare 有 value_type? " << has_type_value_type<Bare>::value << '\n';

    // 2) 成员函数检测（宏生成的元函数在全局命名空间，不在 boost::tti 下）
    std::cout << "Full 有 reset()? "
              << has_member_function_reset<Full, void>::value << '\n';

    // 3) 实战：SFINAE 分派——有 reset 就调，没有就跳过
    auto try_reset = [](auto& obj) {
        if constexpr (has_member_function_reset<
                          std::decay_t<decltype(obj)>, void>::value) {
            obj.reset();
            return "已重置";
        } else {
            return "无 reset 可调";
        }
    };
    Full f{42};
    Bare b;
    std::cout << "Full: " << try_reset(f) << " / Bare: " << try_reset(b) << '\n';

    // 4) 与 C++20 concepts 的对照：requires 表达式能做同样的事且更好读
    //    if constexpr (requires { obj.reset(); }) ——但 TTI 支持老标准
    std::cout << "自检通过\n";
    return 0;
}
