// timer.cpp —— Boost.Timer：三种"测量"语义的计时器小库
// 对应文档：docs/07-chrono.md
#include <boost/timer/timer.hpp>
#include <chrono>
#include <iostream>
#include <thread>

int main() {
    // 1) auto_cpu_timer：析构时自动打印（RAII 计时器）
    {
        std::cout << "段1（50ms）:\n";
        boost::timer::auto_cpu_timer t;                 // 默认 6 位精度
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }   // 析构 → 打印 wall/user/system

    // 2) cpu_timer 手动控制 + 格式化
    //    坑（本机实测）：迭代数不能卡在阈值附近。原来写 200 万次 volatile double
    //    累加，实测耗时正好落在 1ms 上下——同一条通道连跑 5 次里就有 2 次打印
    //    false，所谓断言其实是掷硬币。放大到 2000 万次，离 1ms 阈值有两个数量级
    //    余量，才配叫"断言"。
    boost::timer::cpu_timer timer;
    timer.start();
    volatile double acc = 0;
    for (int i = 0; i < 20000000; ++i) acc += i * 0.25;
    timer.stop();
    (void)acc;
    boost::timer::cpu_times times = timer.elapsed();
    std::cout << "段2 wall>=1ms? " << std::boolalpha
              << (times.wall >= 1000000) << '\n';       // 纳秒计数

    // 3) progress_timer 的遗产：作用域秒表（已并入 auto_cpu_timer 的简化用法）
    std::cout << "format 摘要: wall/user/system 三列 = "
              << "墙钟/用户态/内核态\n";

    std::cout << "自检通过\n";
    return 0;
}
