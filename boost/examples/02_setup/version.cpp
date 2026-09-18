// version.cpp —— 摸清环境：Boost 版本 / 编译器 / 标准档位 / 标准头可用性
// 对应文档：docs/02-setup.md
#include <boost/version.hpp>
#include <print>
#include <string_view>

// 把 _MSVC_LANG 的数值翻译成标准名。
// /std:c++latest 下 MSVC 报 202400（C++26 草案档），比正式值更新。
constexpr std::string_view lang_name(long v) {
    switch (v) {
        case 201103L: return "C++11";
        case 201402L: return "C++14";
        case 201703L: return "C++17";
        case 202002L: return "C++20";
        case 202302L: return "C++23";
        default:      return "C++26 草案（/std:c++latest）";
    }
}

int main() {
    std::print("Boost {}.{}.{}\n", BOOST_VERSION / 100000,
               BOOST_VERSION / 100 % 1000, BOOST_VERSION % 100);
    std::print("MSVC {}.{}\n", _MSC_VER / 100, _MSC_VER % 100);
    std::println("标准档位: {}", lang_name(_MSVC_LANG));

    // __has_include 探一下本教程后面要用到的标准头——
    // Boost 与 std 的"毕业对照"要两边都能跑，先确认 std 侧的弹药充足
#if __has_include(<format>)
    std::println("<format>   有  C++20 std::format");
#endif
#if __has_include(<print>)
    std::println("<print>    有  C++23 std::print");
#endif
#if __has_include(<expected>)
    std::println("<expected> 有  C++23 std::expected");
#endif
#if __has_include(<mdspan>)
    std::println("<mdspan>   有  C++23 std::mdspan");
#endif
    std::println("自检通过");
    return 0;
}
