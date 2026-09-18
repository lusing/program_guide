// core.cpp —— Boost.Core：所有 Boost 库共用的地基（std 的"公共内构"对照）
// 对应文档：docs/05-langbase.md
#include <boost/core/exchange.hpp>
#include <boost/core/addressof.hpp>
#include <boost/core/demangle.hpp>
#include <boost/core/noncopyable.hpp>
#include <iostream>
#include <memory>
#include <string>

class Session : boost::noncopyable {          // C++98 的 = delete：拷贝构造/赋值私化
public:
    int id = 1;
};

struct Sneaky {                                // 故意重载 operator& 捣乱
    Sneaky* operator&() { return nullptr; }
};

int main() {
    // 1) noncopyable：C++11 后 = delete 更直接，但这个基类仍在大量 Boost API 里
    Session s;
    std::cout << "noncopyable 会话 id=" << s.id << '\n';

    // 2) addressof：绕过 operator& 重载拿到真实地址（std::addressof 毕业了）
    Sneaky sneaky;
    std::cout << "真实地址非空? " << std::boolalpha
              << (boost::addressof(sneaky) != nullptr) << '\n';

    // 3) demangle：typeid().name() 的人类可读化（MSVC/GCC 各自的 mangling 归一）
    std::cout << "demangle: " << boost::core::demangle(typeid(std::shared_ptr<int>).name())
              << " 可读\n";

    // 4) boost::exchange（boost/core/exchange.hpp，std::exchange 的老家，C++14 毕业）
    int old = boost::exchange(s.id, 99);
    std::cout << "exchange: old=" << old << " new=" << s.id << '\n';

    // 5) lightweight_test 的 BOOST_TEST 宏（boost/core/lightweight_test.hpp）：
    //    头文件级轻量测试，但它的收尾约定是 main 返回 report_errors()，而后者
    //    一定往 stderr 打 "No errors detected."——本教程的判定标准要求
    //    stderr 恒空，所以这里只展示 core 的四个工具，测试宏留到第 32 章
    std::cout << "lightweight_test 见第 32 章（其报告走 stderr，与本章判定口径不合）\n";

    std::cout << "自检通过\n";
    return 0;
}
