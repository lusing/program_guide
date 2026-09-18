// predef.cpp —— Boost.Predef：编译器/系统/架构/标准库的版本探测（Config 的现代继任者）
// 对应文档：docs/05-langbase.md
#include <boost/predef.h>
#include <iostream>

int main() {
    // 每个探测宏都是 版本号整数（0 = 不存在）：
    // 版本编码为 (M*100 + m)*100 + p，配 *_VERSION_NUMBER 宏可拆解
    std::cout << "Windows? " << std::boolalpha << BOOST_OS_WINDOWS << '\n';
    std::cout << "x86-64? " << BOOST_ARCH_X86_64 << '\n';
    std::cout << "MSVC? " << BOOST_COMP_MSVC
              << " 检测" << (BOOST_COMP_MSVC ? "到" : "不到") << '\n';

    // 版本比较是它比"手写宏探测"高明的地方：
#if BOOST_COMP_MSVC >= BOOST_VERSION_NUMBER(19, 30, 0)
    std::cout << "MSVC >= 19.30：C++20 协程支持可用\n";
#endif

#if BOOST_COMP_CLANG
    std::cout << "这是 clang\n";
#elif BOOST_COMP_GNUC
    std::cout << "这是 gcc\n";
#elif BOOST_COMP_MSVC
    std::cout << "这是 MSVC\n";
#else
    std::cout << "其他编译器\n";
#endif

    std::cout << "自检通过\n";
    return 0;
}
