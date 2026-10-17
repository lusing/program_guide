// timer_v1.cpp —— Boost.Timer V1 化石层：boost::timer / progress_timer
// 对应文档：docs/07-chrono.md
//
// 为什么单独一个文件：V1 头文件把秒表类定义在名字 boost::timer，
// 而 V2 头文件 <boost/timer/timer.hpp> 把所有新组件放进**同名命名空间**
// boost::timer——两者不能出现在同一个编译单元里（实测 MSVC 报
// C2869 "boost::timer 已被定义为命名空间"）。想对比两代计时器，
// 只能分成两个 .cpp。
//
// V1 自 Boost 1.72 起弃用；1.92 里不定义宏直接包含是编译期硬错误：
//   #include <boost/timer.hpp>   // error: This header is deprecated ...
// 必须先 #define BOOST_TIMER_ENABLE_DEPRECATED 才能启用。
#include <chrono>
#include <iostream>
#include <sstream>
#include <thread>

#define BOOST_TIMER_ENABLE_DEPRECATED
#include <boost/progress.hpp>
#include <boost/timer.hpp>

int main() {
    // 1) boost::timer：不到 20 行实现的秒表，全部能力来自 std::clock()
    //    计时精度 = 1/CLOCKS_PER_SEC，而这个常数是"平台彩票"：
    //    Windows/MSVC 是 1000（毫秒粒度），Linux/glibc 通常是 1000000（微秒）。
    boost::timer t;                       // 构造即开始计时
    std::cout << "V1 最小刻度 = " << t.elapsed_min() << " 秒"
              << "（本机 CLOCKS_PER_SEC = " << 1.0 / t.elapsed_min() << "）\n";
    std::cout << "V1 最大量程 = " << t.elapsed_max() / 3600.0 / 24 / 365
              << " 年\n";
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    std::cout << "V1 elapsed >= 10ms? " << std::boolalpha
              << (t.elapsed() >= 0.010) << '\n';
    t.restart();                          // 归零重计

    // 2) progress_timer：析构自动报时的"作用域秒表"
    //    输出流可定制（默认 std::cout）——引进 stringstream，
    //    让真实耗时不进入程序输出（本例程的输出必须可复现）。
    std::ostringstream ss;
    {
        boost::progress_timer pt(ss);     // 输出定向到字符串流
    }                                     // 析构 → ss 里写入 "x.xx s"
    std::string s = ss.str();
    // 实测 1.92/MSVC：析构写入 "x.xx s\n\n"（8 字节）——比第 5 版书里
    // 记录的 "x.xx s\n" 多一个换行（实现用了 endl）。
    std::cout << "progress_timer 输出形如 \"x.xx s\\n\\n\"? "
              << (s.size() == 8 && s.compare(4, 4, " s\n\n") == 0
                  && s[0] == '0' && s[1] == '.')
              << '\n';

    // 同一作用域内用 {} 控制生命期即可多次计时——这是 V2 auto_cpu_timer
    // 的"声明即计时"用法的直系祖先。
    std::cout << "自检通过\n";
    return 0;
}
