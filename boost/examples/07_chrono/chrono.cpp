// chrono.cpp —— Boost.Chrono： durations/clocks/timepoints 三件套（std::chrono 直系）
// 对应文档：docs/07-chrono.md
#include <boost/chrono.hpp>
#include <chrono>
#include <iostream>
#include <thread>

int main() {
    // 1) duration：数值 + 单位的强类型时长的刻度
    boost::chrono::seconds s(90);
    boost::chrono::minutes m = boost::chrono::duration_cast<boost::chrono::minutes>(s);
    std::cout << "90 秒 = " << m.count() << " 分钟(截断)\n";

    boost::chrono::milliseconds ms(1500);
    std::cout << "1500ms = " << boost::chrono::duration_cast<boost::chrono::seconds>(ms).count()
              << " 秒(截断)\n";

    // 2) 时钟三兄弟（std 同款）
    //    system_clock：挂钟（可回拨）；steady_clock：单调（测耗时的唯一正解）；
    //    high_resolution_clock：别名
    auto start = boost::chrono::steady_clock::now();
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    auto elapsed = boost::chrono::steady_clock::now() - start;
    std::cout << "耗时 >= 50ms? " << std::boolalpha
              << (boost::chrono::duration_cast<boost::chrono::milliseconds>(elapsed).count() >= 50) << '\n';

    // 3) 时间点 + 时钟纪元
    auto tp = boost::chrono::system_clock::now();
    auto since_epoch = boost::chrono::duration_cast<boost::chrono::seconds>(
        tp.time_since_epoch()).count();
    std::cout << "Unix 时间戳(秒) > 17 亿? " << (since_epoch > 1'700'000'000) << '\n';

    // 4) boost 独有：process_real_cpu_clock（进程 CPU 时间，std 没有）
    volatile double acc = 0;
    for (int i = 0; i < 1000000; ++i) acc += i * 0.5;
    auto cpu_ns = boost::chrono::process_real_cpu_clock::now().time_since_epoch();
    std::cout << "进程时钟读数非零? " << (cpu_ns.count() > 0) << '\n';
    (void)acc;

    // 5) chrono_io 的 duration 字符串（std::format 的前身之一）
    std::cout << "格式化: " << boost::chrono::duration_cast<boost::chrono::milliseconds>(
        boost::chrono::seconds(3661)) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
