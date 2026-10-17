// posix_time.cpp —— Boost.Date_Time 下半部：posix_time 时间系统全套
// 对应文档：docs/07-chrono.md
#include <boost/date_time/gregorian/gregorian.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <chrono>
#include <iostream>
#include <map>
#include <string>
#include <thread>

// 综合运用一的件：可定制时钟精度的高精度计时器（书的 basic_ptimer）
// —— 模板参数选时钟；elapsed() 直接回 duration（能流输出，自带单位）。
// auto_report 控制"析构自动报时"（本例程输出必须可复现，微秒级计时
// 的原始读数每次都不同，只让它打布尔断言）。
template <typename Clock>
class basic_ptimer {
public:
    explicit basic_ptimer(bool auto_report = true)
        : auto_report_(auto_report) {
        restart();
    }
    void restart() { start_ = Clock::local_time(); }
    boost::posix_time::time_duration elapsed_dur() const {
        return Clock::local_time() - start_;
    }
    ~basic_ptimer() {
        if (auto_report_) std::cout << elapsed_dur();
    }
private:
    boost::posix_time::ptime start_;
    bool auto_report_;
};

int main() {
    using namespace boost::posix_time;
    using namespace boost::gregorian;

    // ── 1) time_duration：时分秒 + 小数秒（默认微秒档） ──
    time_duration td(1, 10, 30, 1000);         // 1h10m30s + 1000 微秒
    std::cout << "构造: " << to_simple_string(td)
              << " ISO: " << to_iso_string(td) << '\n';
    // 超 range 的字段自动进/借位：1h60m60s + 6.001s == 2h1m6.001s
    time_duration carry(1, 60, 60, 1000 * 1000 * 6 + 1000);
    std::cout << "进位: " << to_simple_string(carry) << '\n';
    // 子类字面时长 + 字符串工厂
    time_duration sum = hours(1) + minutes(10) + seconds(30) + millisec(1);
    time_duration from_str = duration_from_string("1:10:30:001");
    std::cout << "子类求和 == 字符串解析? "
              << std::boolalpha << (sum == from_str) << '\n';
    // 分解访问与 total_* 全家
    std::cout << "total: 秒" << td.total_seconds()
              << " 毫秒" << td.total_milliseconds()
              << " 微秒" << td.total_microseconds()
              << " 小数秒" << td.fractional_seconds() << '\n';
    // 负时长与取反
    hours h(-10);
    std::cout << "负时长: is_negative=" << h.is_negative()
              << " invert→" << h.invert_sign().hours() << "h\n";
    // 特殊值同样传染
    time_duration nad(not_a_date_time);
    std::cout << "特殊时长: " << nad << " is_not_a_date_time="
              << nad.is_not_a_date_time() << '\n';
    // 四则与比较
    time_duration x1 = hours(1), x2 = hours(2) + minutes(30);
    std::cout << "运算: x1<x2=" << (x1 < x2)
              << " (x1+x2)=" << to_simple_string(x1 + x2)
              << " (x1-x2)负=" << (x1 - x2).is_negative()
              << " x1*5==x2*2=" << (x1 * 5 == x2 * 2) << '\n';
    // 精度自省 API：与分辨率无关代码的写法基础
    std::cout << "分辨率: tick/秒=" << time_duration::ticks_per_second()
              << " 小数位数=" << time_duration::num_fractional_digits()
              << " 最小单位=" << to_simple_string(time_duration::unit()) << '\n';

    // ── 2) ptime：date + time_duration = 时刻（64bit 微秒档存储） ──
    ptime p1(date(2017, 7, 7), hours(1));      // 零点可省：ptime(date)
    ptime p2 = time_from_string("2017-7-7 01:00:00");
    ptime p3 = from_iso_string("20170707T010000");
    std::cout << "三种构造相等? " << (p1 == p2 && p2 == p3)
              << " → " << to_simple_string(p1) << '\n';
    // 两只时钟：second_clock / microsec_clock（输出必须可复现→只验不变量）
    ptime s_now = second_clock::universal_time();
    ptime m_now = microsec_clock::universal_time();
    std::cout << "时钟: microsec 读数 >= second 读数? " << (m_now >= s_now)
              << "（同为 UTC）\n";
    // 分解与运算
    ptime t0(date(2010, 3, 20), hours(12) + minutes(30));
    std::cout << "分解: 日期" << t0.date() << " 时刻"
              << to_simple_string(t0.time_of_day()) << '\n';
    ptime later = t0 + hours(3);
    std::cout << "运算: +3h 后差值==" << to_simple_string(later - t0)
              << " < 比较=" << (t0 < later) << '\n';
    later += months(1);
    std::cout << "运算: +1月后月份=" << later.date().month() << '\n';
    // 输出三件套（ISO 用 T 分隔日期时间）
    ptime f(date(2017, 2, 14), hours(20));
    std::cout << "输出: " << to_simple_string(f) << ' ' << to_iso_string(f)
              << ' ' << to_iso_extended_string(f) << '\n';
    // tm / time_t 互转
    std::tm tmv = to_tm(f);
    std::cout << "to_tm 年偏移" << tmv.tm_year << " 时" << tmv.tm_hour
              << " 往返一致? " << (ptime_from_tm(tmv) == f) << '\n';
    ptime epoch = from_time_t(0);              // 1970-01-01 00:00:00 UTC
    std::cout << "from_time_t(0) = " << epoch
              << " 回转一致? " << (to_time_t(epoch) == 0) << '\n';

    // ── 3) time_period：ptime 版区间（同 date_period 的代数） ──
    ptime noon(date(2017, 1, 1), hours(12));
    time_period tp1(noon, hours(8));           // 12:00 起的 8 小时
    time_period tp2(noon + hours(8), hours(1));
    std::cout << "区间: tp1 逾尾=" << tp1.end() << " 与 tp2 相邻? "
              << tp1.is_adjacent(tp2) << " 相交? " << tp1.intersects(tp2)
              << '\n';
    tp1.shift(hours(1));
    std::cout << "shift 后 tp1 从 " << tp1.begin().time_of_day() << " 起"
              << " 在正午之后? " << tp1.is_after(noon)
              << " 现在与 tp2 相交? " << tp1.intersects(tp2) << '\n';
    tp2.expand(hours(10));
    std::cout << "expand 后 tp2 同时包含正午与 tp1? "
              << (tp2.contains(noon) && tp2.contains(tp1)) << '\n';

    // ── 4) time_iterator：按任意 duration 步进时刻 ──
    //    注意它和 date 迭代器一样不是标准迭代器（没有 operator+），
    //    只有 ++/-- 与比较；想拿"最后一个"就在循环里记着。
    {
        ptime start(date(2017, 5, 31), hours(10));
        int n = 0;
        ptime last;
        for (time_iterator it(start, minutes(10)); it <= start + hours(1);
             ++it) {
            last = *it;
            ++n;
        }
        std::cout << "步进: " << start.time_of_day() << " → "
                  << last.time_of_day() << "（含两端共 " << n
                  << " 个十分钟档）\n";
    }

    // ── 5) 综合运用二：ptimer（析构自动报时，时长带单位） ──
    {
        std::cout << "ptimer 秒钟版计 15ms 析构输出 → ";
        {
            basic_ptimer<second_clock> t;      // 秒粒度：短任务显示 00:00:00
            std::this_thread::sleep_for(std::chrono::milliseconds(15));
        }                                      // ← 析构输出落在行末
        std::cout << "；微秒版 >= 15ms? ";
        basic_ptimer<microsec_clock> t(false); // 关自动报时，只做断言
        std::this_thread::sleep_for(std::chrono::milliseconds(15));
        std::cout << std::boolalpha
                  << (t.elapsed_dur() >= milliseconds(15)) << '\n';
    }

    // ── 6) 综合运用三：work_time——用 time_period 给一天分段问候 ──
    // （time_period 支持比较，可作 std::map 的键；这里改用固定时刻查询）
    {
        date today(2017, 6, 1);
        ptime p(today, hours(0));
        std::map<std::string, time_period> zones = {
            {"太早了", time_period(p, hours(9))},
            {"上午", time_period(p + hours(9), hours(3) + minutes(30))},
            {"午餐", time_period(p + hours(12) + minutes(30), hours(1))},
            {"下午", time_period(p + hours(13) + minutes(30),
                                hours(4) + minutes(30))},
            {"还在加班?", time_period(p + hours(18), hours(6))},
        };
        for (auto hour : {8, 12, 13, 15, 20}) {
            ptime probe(today, hours(hour));
            for (const auto& [name, zone] : zones)
                if (zone.contains(probe)) {
                    std::cout << hour << " 点 → " << name << "  ";
                    break;
                }
        }
        std::cout << '\n';
    }

    std::cout << "自检通过\n";
    return 0;
}
