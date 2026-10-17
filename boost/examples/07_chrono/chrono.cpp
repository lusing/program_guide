// chrono.cpp —— Boost.Chrono：duration / clock / time_point 深讲
// 对应文档：docs/07-chrono.md
//
// chrono 的世界观只有三个词：
//   duration  —— 数值 + 单位（单位是编译期分数 ratio）
//   clock     —— 纪元起点 + 走时精度 + now()
//   time_point—— 某 clock 的 duration 读数（"自纪元以来多久"）
#include <boost/chrono.hpp>
#include <chrono>
#include <iostream>
#include <thread>

int main() {
    namespace bc = boost::chrono;

    // ── 1) duration：数值+单位，单位错配编译期就炸 ──
    bc::seconds s(90);
    std::cout << "90 秒 = " << bc::duration_cast<bc::minutes>(s)
              << "(截断)\n";
    bc::milliseconds ms(1500);
    std::cout << "1500ms = " << bc::duration_cast<bc::seconds>(ms)
              << "(截断)\n";
    // 小单位 → 大单位：整数 rep 下无隐式转换（90 秒变 1.5 分钟会丢数据，
    // 库把它变成编译错误）；反向 大 → 小 可以隐式（1 分钟隐式变 60 秒）。
    bc::minutes m(2);
    bc::seconds s2 = m + s;                   // minutes 隐式折算成 seconds
    std::cout << "2 分钟 + 90 秒 = " << s2 << '\n';
    // 想要小数：rep 用 double
    bc::duration<double> frac = m + s;
    std::cout << "double rep 下 = " << bc::duration_cast<boost::chrono::duration<double, boost::ratio<60>>>(frac)
              << '\n';
    // count()：裸读计数
    std::cout << "count(): " << s2.count() << " 秒 = "
              << bc::duration_cast<bc::milliseconds>(s2).count() << " 毫秒\n";

    // ── 2) 截断三兄弟之外：floor / ceil / round（Boost 扩展） ──
    bc::seconds odd(3600 + 50);               // 1 小时 50 秒
    std::cout << "floor<minutes>=" << bc::floor<bc::minutes>(odd)
              << " ceil<minutes>=" << bc::ceil<bc::minutes>(odd)
              << " round<minutes>=" << bc::round<bc::minutes>(odd)
              << " round<hours>=" << bc::round<bc::hours>(odd) << '\n';

    // ── 3) 时钟族：两个标准 + 四个 Boost 扩展进程时钟 ──
    // system_clock：挂钟（会随 NTP 回拨）；steady_clock：单调；
    // process_real/user/system_cpu_clock、thread_clock：进程/线程 CPU 时间。
    auto steady_now = bc::steady_clock::now();
    auto sys_now = bc::system_clock::now();
    std::cout << "steady 读数非零? " << std::boolalpha
              << (steady_now.time_since_epoch().count() > 0)
              << "  system 秒数 > 17 亿? "
              << (bc::duration_cast<bc::seconds>(
                      sys_now.time_since_epoch()).count() > 1700000000LL)
              << '\n';
    // clock_string：问时钟"你叫什么、从哪起算"
    std::cout << "clock_string: system=" << bc::clock_string<bc::system_clock, char>::name()
              << " since " << bc::clock_string<bc::system_clock, char>::since()
              << " | steady="
              << bc::clock_string<bc::steady_clock, char>::since() << '\n';
    // 【实测坑·Windows 粒度】进程 CPU 时钟的度量粒度约 15.6ms（系统节拍），
    // 程序刚跑几条输出就查询，读数还是 0——先烧一段 CPU 再读才非零；
    // 且本机（MSVC 1.92 DLL）用户态时钟累积更慢，实际可靠的是 real 时钟。
    volatile double burn = 0;
    for (int i = 0; i < 1000000; ++i) burn += i * 0.5;
    (void)burn;
    auto cpu_now = bc::process_real_cpu_clock::now();
    std::cout << "进程实际时钟读数非零? "
              << (cpu_now.time_since_epoch().count() > 0) << '\n';

    // ── 4) time_point：点 + 时长 = 点；点 − 点 = 时长 ──
    auto t0 = bc::steady_clock::now();
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    auto t1 = bc::steady_clock::now();
    auto cost = bc::duration_cast<bc::milliseconds>(t1 - t0);
    std::cout << "耗时 " << cost.count() << "ms >= 50ms? " << (cost >= bc::milliseconds(50))
              << '\n';
    // system_clock 独有：与 time_t 互转（steady 没有"对应现实时刻"的语义）
    std::time_t tt = bc::system_clock::to_time_t(sys_now);
    std::cout << "to_time_t 往返一致? "
              << (bc::system_clock::from_time_t(tt) >= sys_now -
                                                    bc::seconds(1) &&
                  bc::system_clock::from_time_t(tt) <= sys_now + bc::seconds(1))
              << '\n';

    // ── 5) 流输出：duration 自带单位（chrono_io） ──
    std::cout << "格式化: " << bc::duration_cast<bc::milliseconds>(bc::seconds(3661))
              << " 与 " << bc::seconds(3661) << "（同计数不同单位）\n";

    // ── 6) 综合运用：steady_timer——书的写法，elapsed() 直回 duration ──
    class steady_timer {
        using clock = bc::steady_clock;
        using dur = bc::microseconds;
    public:
        steady_timer() { restart(); }
        void restart() { start_ = clock::now(); }
        dur elapsed() const {                  // 回 duration：自带单位可流输出
            return bc::round<dur>(clock::now() - start_);
        }
    private:
        clock::time_point start_ = clock::now();
    };
    steady_timer st;
    std::this_thread::sleep_for(std::chrono::milliseconds(15));
    std::cout << "steady_timer >= 15ms? " << (st.elapsed() >= bc::microseconds(15000))
              << '\n';

    std::cout << "自检通过\n";
    return 0;
}
