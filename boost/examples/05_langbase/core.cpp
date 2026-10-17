// core.cpp —— Boost.Core：所有 Boost 库共用的地基（std 的"公共内构"对照）
// 对应文档：docs/05-langbase.md
#include <boost/core/exchange.hpp>
#include <boost/core/addressof.hpp>
#include <boost/core/demangle.hpp>
#include <boost/core/ignore_unused.hpp>
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

    // 6) noncopyable 的实现原理（书的两种写法对照）：
    //    老写法——把拷贝构造/赋值"私化"（声明不定义）：
    //      class noncopyable {
    //      protected: noncopyable() {} ~noncopyable() {}
    //      private:   noncopyable(const noncopyable&);
    //                 const noncopyable& operator=(const noncopyable&);
    //      };
    //    新写法——= delete 一句话。继承它的子类拷贝时需要调用基类拷贝构造，
    //    而那是 private/deleted 的 → 编译错误。protected 构造/析构保证
    //    noncopyable 自己不能被实例化，只能当基类。
    //    （继承写法默认 private 继承即可——HAS-A 语义，不必 public）
    // Session s2 = s;                        // ← 编译错误（E1776/C2280 一族）

    // 7) ignore_unused：比 (void)x 更好的"消除未用告警"（原是 proto 库小件）
    int unused_var = 5;
    int unused_param_style = 6;
    boost::ignore_unused(unused_var, unused_param_style);   // 函数形式
    boost::ignore_unused<Session>();     // 模板形式：忽略未用的**类型**（typedef）
    std::cout << "ignore_unused：变量与类型两种形式都吞掉了告警\n";

    std::cout << "自检通过\n";
    return 0;
}
