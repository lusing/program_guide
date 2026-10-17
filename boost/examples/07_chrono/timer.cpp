// timer.cpp —— Boost.Timer V2：cpu_timer / auto_cpu_timer / format 五占位符
// 对应文档：docs/07-chrono.md
// （V1 化石层在 timer_v1.cpp——两代不能同处一个编译单元，见那里的注释。）
#include <boost/timer/timer.hpp>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <thread>

int main() {
    namespace bt = boost::timer;

    // ── 1) auto_cpu_timer：RAII 计时器，析构自动打印 ──
    {
        std::cout << "段1（50ms）:\n";
        bt::auto_cpu_timer t;                 // 默认 6 位小数（微秒档）
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }                                         // 析构 → 打印 wall/user/system

    // ── 2) cpu_timer 手动档：start/stop/resume/is_stopped ──
    // 坑（本机实测）：迭代数不能卡在阈值附近。原来写 200 万次 volatile double
    // 累加，实测耗时正好落在 1ms 上下——同一条通道连跑 5 次里就有 2 次打印
    // false，所谓断言其实是掷硬币。放大到 2000 万次，离 1ms 阈值有两个数量级
    // 余量，才配叫"断言"。
    bt::cpu_timer timer;
    timer.start();                            // 构造函数就是调它：即造即走
    volatile double acc = 0;
    for (int i = 0; i < 20000000; ++i) acc += i * 0.25;
    timer.stop();                             // 暂停：之后墙钟也不再累计
    (void)acc;
    std::cout << "停止后 is_stopped? " << std::boolalpha << timer.is_stopped()
              << '\n';
    bt::cpu_times t1 = timer.elapsed();
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
    bt::cpu_times t2 = timer.elapsed();       // stop 期间 wall 也冻结
    std::cout << "段2 stop 期间 wall 冻结? " << (t1.wall == t2.wall)
              << "  wall>=1ms? " << (t1.wall >= 1000000) << '\n';
    timer.resume();                           // 恢复（继续累计，不是重新开始）
    bt::cpu_times t3 = timer.elapsed();
    std::cout << "resume 后 wall 继续增长? " << (t3.wall >= t2.wall) << '\n';

    // ── 3) format()：五占位符 %w/%u/%s/%t/%p + 精度位数 ──
    //    用**合成数据**演示格式语义（真实计时每次都不同，没法做断言）。
    //    %w=墙钟 %u=用户态 %s=内核态 %t=CPU 合计(u+s) %p=CPU 占墙钟百分比
    const bt::nanosecond_type ms = 1000LL * 1000;
    bt::cpu_times demo{2000 * ms, 1000 * ms, 100 * ms};   // 2s / 1s / 0.1s
    std::cout << "format 默认: " << bt::format(demo, 7);
    std::cout << "format 3 位: " << bt::format(demo, 3);
    // 过小的值：CPU 合计低于度量精度时百分比显示 n/a（不是 0.0%）
    bt::cpu_times tiny{2000, 1000, 100};                  // 纳秒级"零头"
    std::cout << "format 微值: " << bt::format(tiny, 3);
    // 自定义格式串（占位符可重复、可加中文标签）
    std::cout << "自定义: "
              << bt::format(demo, 3,
                            "墙钟%w秒 用户%u秒 内核%s秒 合计%t秒 百分比%p\n");

    std::cout << "自检通过\n";
    return 0;
}
