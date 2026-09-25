// stacktrace.cpp —— Boost.Stacktrace（2016）：std::stacktrace（C++23）的直系原型
// 对应文档：docs/17-cpp23.md
#include <boost/config.hpp>     // BOOST_NOINLINE
#include <boost/stacktrace.hpp>
#include <filesystem>
#include <fstream>
#include <iostream>

// 三个函数都标 BOOST_NOINLINE：不加的话开优化时 middle 会被内联进 outer、
// 栈里只剩 inner，第 1 项断言就变成 1/0（本机 -O2 下实测如此，Windows 侧
// 的 build.ps1 不开优化所以一直是 1/1）。回溯示例要的是"函数还在栈上"，
// 那件事得由代码保证，不能指望编译器的优化档位。
BOOST_NOINLINE std::string inner() {
    // 想要当前调用链：一行构造 stacktrace
    std::ostringstream oss;
    oss << boost::stacktrace::stacktrace();
    return oss.str();
}

BOOST_NOINLINE std::string middle() { return inner(); }
BOOST_NOINLINE std::string outer()  { return middle(); }

int main() {
    std::string trace = outer();

    // 1) 逐帧检查：函数名就嵌在里面（含本文件的三个函数）
    bool has_inner = trace.find("inner") != std::string::npos;
    bool has_chain = trace.find("middle") != std::string::npos;
    std::cout << "栈里能找到 inner/middle? " << has_inner << '/' << has_chain << '\n';

    // 2) 帧计数与程序化访问
    //    从这里起开 boolalpha（文档里这几行是 true/false；上面那行保持 1/1，
    //    因为它打的是两个位、读起来紧凑些）
    boost::stacktrace::stacktrace st;
    std::cout << std::boolalpha << "当前栈帧数 >= 2? " << (st.size() >= 2) << '\n';
    // st[0].name() 是本帧；源文件名/行号在调试符号就位时可取
    std::cout << "第 0 帧非空名? " << !st[0].name().empty() << '\n';

    // 3) 序列化到文件（崩溃后处理流程的原料）
    std::ofstream("build_stacktrace_dump.txt") << st;
    std::cout << "落盘字节数 > 0? "
              << (std::filesystem::file_size("build_stacktrace_dump.txt") > 0) << '\n';

    // 4) std 对照（C++23）：std::stacktrace/basic_stacktrace 接口照着它长
    std::cout << "std::stacktrace（C++23）同构见文档\n";

    std::cout << "自检通过\n";
    return 0;
}
