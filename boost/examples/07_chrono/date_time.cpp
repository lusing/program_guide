// date_time.cpp —— Boost.Date_Time：日历运算的大库（C++20 chrono 日历的先行者）
// 对应文档：docs/07-chrono.md
#include <boost/date_time/gregorian/gregorian.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <chrono>
#include <iostream>

int main() {
    using namespace boost::gregorian;

    // 1) 日历日期运算：这是它 2001 年就做到、std 直到 C++20 才有的能力
    date release(2026, Sep, 19);
    date deadline = release + date_duration(30);        // +30 天
    std::cout << "发布日 " << release << " 截止 " << deadline << '\n';

    date_period sprint(release, deadline);
    std::cout << "迭代周期 " << sprint.length().days() << " 天\n";

    // 月末/月末问题：12 月 31 日 + 2 月（跨月运算不 panic，会抛异常或回退到月末）
    date end_of_year(2026, Dec, 31);
    std::cout << "年底是周" << end_of_year.day_of_week() << "（0=周日）\n";

    // 2) 时长与时刻：posix_time（微秒精度）
    using namespace boost::posix_time;
    ptime t(release, time_duration(14, 30, 0));         // 2026-09-19 14:30:00
    ptime later = t + hours(3) + minutes(45);
    time_duration diff = later - t;
    std::cout << "3 小时 45 分 = " << diff.total_seconds() << " 秒\n";

    // 3) 对应的 C++20 chrono（日历部分终于毕业）
    //    注意 days 二义性：gregorian 的 using 与 std::chrono::days 撞名，要限定
    using namespace std::chrono;
    year_month_day ymd{year{2026}, September, day{19}};
    sys_days sd = ymd;
    auto advanced = sd + std::chrono::days{30};
    std::cout << "std::chrono +30 天 = " << year_month_day{advanced} << '\n';
    std::cout << "weekday = " << weekday{advanced} << '\n';

    std::cout << "自检通过\n";
    return 0;
}
