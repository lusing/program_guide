// version.cpp —— 摸清环境：Boost 版本 / 编译器 / 标准档位 / 标准头可用性
// 对应文档：docs/02-setup.md
// 编译器与标准档位的宏三家各说各话，只能逐个认领：
//   MSVC     _MSC_VER / _MSVC_LANG（__cplusplus 默认不报真值，要 /Zc:__cplusplus）
//   clang    __clang_major__ / __cplusplus
//   GCC      __GNUC__ / __cplusplus
// 写成条件编译而不是"统一用 __cplusplus"：MSVC 不带 /Zc:__cplusplus 时
// __cplusplus 恒为 199711，拿它判档位会永远停在 C++98。
#include <boost/version.hpp>
#include <print>
#include <string_view>

constexpr long lang_ver() {
#if defined(_MSC_VER) && !defined(__clang__)
    return _MSVC_LANG;
#else
    return __cplusplus;
#endif
}

// 把档位数值翻译成标准名。
// /std:c++latest 下 MSVC 报 202400（C++26 草案档），比正式值更新。
constexpr std::string_view lang_name(long v) {
    switch (v) {
        case 201103L: return "C++11";
        case 201402L: return "C++14";
        case 201703L: return "C++17";
        case 202002L: return "C++20";
        case 202302L: return "C++23";
        case 202400L: return "C++26 草案（MSVC /std:c++latest）";
        default:      return "C++26 草案或更新";
    }
}

int main() {
    std::print("Boost {}.{}.{}\n", BOOST_VERSION / 100000,
               BOOST_VERSION / 100 % 1000, BOOST_VERSION % 100);
#if defined(_MSC_VER) && !defined(__clang__)
    std::print("MSVC {}.{}\n", _MSC_VER / 100, _MSC_VER % 100);
#elif defined(__clang__)
    std::print("Clang {}.{}.{}\n", __clang_major__, __clang_minor__,
               __clang_patchlevel__);
#elif defined(__GNUC__)
    std::print("GCC {}.{}.{}\n", __GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
#else
    std::print("未知编译器\n");
#endif
    std::println("标准档位: {}", lang_name(lang_ver()));

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
