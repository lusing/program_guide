// config.cpp —— Boost.Config：150+ 库的可移植性地基
// （你通常不会直接用它，但你用的每个 Boost 头都在用它）
// 对应文档：docs/05-langbase.md
#include <boost/config.hpp>
#include <iostream>

int main() {
    // 1) 平台/编译器身份（Boost.Config 的探测宏）
    std::cout << "编译器=" << BOOST_COMPILER << '\n';
    std::cout << "标准库=" << BOOST_STDLIB << '\n';
    std::cout << "平台=" << BOOST_PLATFORM << '\n';

    // 2) 特性探测宏：命名规则 BOOST_NO_CXXNN_特性 = 没有；BOOST_HAS_XXX = 平台提供。
    //    这些宏只在预处理阶段有意义，得用 #if 分支探测
#if defined(BOOST_NO_CXX11_VARIADIC_MACROS)
    std::cout << "变参宏: 无\n";
#else
    std::cout << "变参宏: 有\n";
#endif
#if defined(BOOST_HAS_THREADS)
    std::cout << "线程支持: 有\n";
#else
    std::cout << "线程支持: 无\n";
#endif
#if defined(BOOST_NO_EXCEPTIONS)
    std::cout << "异常: 关闭（嵌入式/内核场景）\n";
#else
    std::cout << "异常: 开启\n";
#endif

    // 3) 写可移植库的实战模式：C++17 if constexpr + 探测宏组合
    //    （"有 charconv 就用它，没有就 lexical_cast"这类降级策略的骨架）
#if defined(BOOST_NO_CXX20_HDR_SPAN)
    bool span_header = false;
#else
    bool span_header = true;
#endif
    std::cout << "span 头可用(Boost 视角): " << std::boolalpha << span_header << '\n';

    std::cout << "自检通过\n";
    return 0;
}
