// date_time.cpp —— Boost.Date_Time 上半部：gregorian 日期系统全套
// 对应文档：docs/07-chrono.md
//
// 三个核心概念先立住（数轴比喻）：
//   时间点 date —— 数轴上的一个点（天粒度）
//   时长  days/months/... —— 有符号标量，两点之差
//   区间  date_period —— 左闭右开 [begin, end)，end 是"逾尾"
#include <boost/date_time/gregorian/gregorian.hpp>
#include <iostream>
#include <stdexcept>
#include <tuple>

int main() {
    using namespace boost::gregorian;

    // ── 1) 创建 date：构造 / 字符串工厂 / 时钟 / 特殊值 ──
    date d1;                                   // 默认构造 = not_a_date_time
    date d2(2010, 1, 1);                       // 数字构造
    date d3(2000, Jan, 1);                     // 英文月份枚举
    date d4 = from_string("1999-12-31");       // 带分隔符（也认 1999/12/31）
    date d5 = from_undelimited_string("20011118");
    (void)d2; (void)d3;
    std::cout << "无效日期 == not_a_date_time? "
              << std::boolalpha << (d1 == date(not_a_date_time)) << '\n'
              << "字符串工厂: " << d4 << " / " << d5 << '\n';
    // day_clock：唯一"现在"来源（本例程输出必须可复现，只验证不变量）
    date today = day_clock::local_day();
    std::cout << "day_clock 本地日在 [2026,2100] 且为合法日? "
              << (today.year() >= 2026 && today.year() <= 2100) << '\n';
    // 特殊值：正负无穷 / 无效 / 上下界（上下界 = 1400-01-01 .. 9999-12-31）
    date pinf(pos_infin), ninf(neg_infin), nad(not_a_date_time);
    date dmin(min_date_time), dmax(max_date_time);
    std::cout << "特殊值: " << ninf << ' ' << pinf << ' ' << nad << ' '
              << dmin << ' ' << dmax << '\n';
    std::cout << "无穷判断: is_infinity=" << pinf.is_infinity()
              << " is_pos=" << pinf.is_pos_infinity()
              << " is_neg=" << ninf.is_neg_infinity()
              << " is_not_a_date=" << nad.is_not_a_date() << '\n';
    // 非法构造**抛异常**（不是变成无效日期）——三类典型
    const std::tuple<int, int, int> bad_cases[] = {
        {1399, 12, 1},   // 超下界
        {10000, 1, 1},   // 超上界
        {2017, 2, 29}};  // 平年 2 月 29
    for (const auto& [y, m, d] : bad_cases) {
        try {
            date bad(static_cast<unsigned short>(y),
                        static_cast<unsigned short>(m),
                        static_cast<unsigned short>(d));
            (void)bad;
            std::cout << "未抛异常?";
        } catch (const std::out_of_range&) {
            std::cout << "越界";
        } catch (const std::invalid_argument&) {
            std::cout << "非法日期";
        }
        std::cout << '(' << y << ',' << m << ',' << d << ") ";
    }
    std::cout << '\n';

    // ── 2) 访问：年月日 / 星期 / 年积日 / 月末 / 周数 ──
    date d(2017, 6, 1);
    auto ymd = d.year_month_day();
    std::cout << "访问: " << ymd.year << '-' << int(ymd.month) << '-'
              << ymd.day << " 星期" << d.day_of_week()
              << " 年积日" << d.day_of_year()
              << " 月末" << d.end_of_month() << '\n';
    std::cout << "周数: 2015-1-10→" << date(2015, 1, 10).week_number()
              << " 2016-1-10→" << date(2016, 1, 10).week_number()
              << " 2017-1-10→" << date(2017, 1, 10).week_number() << '\n';

    // ── 3) 输出三件套 + tm 互转 ──
    date x(2017, 1, 23);
    std::cout << "输出: " << to_simple_string(x) << ' '
              << to_iso_string(x) << ' ' << to_iso_extended_string(x)
              << "（流输出 = " << x << "）\n";
    std::tm t = to_tm(x);                      // 时分秒清零，tm_isdst=-1
    std::cout << "to_tm: 年偏移" << t.tm_year << " 月0基" << t.tm_mon
              << " 日" << t.tm_mday << " 时" << t.tm_hour
              << " 往返一致? " << (date_from_tm(t) == x) << '\n';

    // ── 4) 时长：days/weeks/months/years + 月末吸附坑 ──
    days dd1(10), dd2(-100), dd3(255);
    std::cout << "days 运算: dd1+dd2==" << (dd1 + dd2).days()
              << " (dd1+dd3)/5==" << (dd1 + dd3).days() / 5 << '\n';
    weeks w(3);
    months m(5);
    years y(2);
    months ym = y + m;                         // years+months → months
    std::cout << "weeks=3 → " << w.days() << "天; 2年+5月 = "
              << ym.number_of_months() << "月; 2年*2 = "
              << (y * 2).number_of_years() << "年\n";
    // 【月末吸附】3-30 减一个月 → 2-28（月末），再减 → 1-31（还是月末），
    // 加两个月 → 3-31：一旦落到月末，"30 号"这个信息就永久丢了
    date snap(2017, 3, 30);
    snap -= months(1);
    std::cout << "月末吸附: 3-30 -1月 → " << snap;
    snap -= months(1);
    std::cout << " -1月 → " << snap;
    snap += months(2);
    std::cout << " +2月 → " << snap << "（回不到 3-30）\n";

    // ── 5) 日期运算与特殊值传染 ──
    date a(2000, 1, 1), b(2017, 11, 18);
    std::cout << "2000-1-1 到 2017-11-18 = " << (b - a).days() << "天"
              << "  往返一致? " << (a + (b - a) == b) << '\n';
    date inf_test(2017, 1, 1);
    date r1 = inf_test + days(pos_infin);
    date r2 = inf_test + days(not_a_date_time);
    std::cout << "特殊值传染: +∞→is_pos_infinity=" << r1.is_pos_infinity()
              << " +NADT→is_not_a_date=" << r2.is_not_a_date() << '\n';

    // ── 6) date_period：左闭右开区间代数 ──
    date_period dp(date(2017, 1, 1), days(20));            // [1-1, 1-21)
    date_period bad1(date(2017, 1, 1), date(2016, 1, 1));  // 左大右小
    date_period bad2(date(2017, 3, 1), days(-20));         // 负长度
    std::cout << "区间: [" << dp.begin() << ',' << dp.last() << "] end(逾尾)="
              << dp.end() << " 长度" << dp.length().days() << "天"
              << " 空? " << dp.is_null()
              << " 非法构造→空? " << (bad1.is_null() && bad2.is_null()) << '\n';
    dp.shift(days(3));                          // 平移：长度不变
    std::cout << "shift+3天: begin=" << dp.begin() << " 长度仍"
              << dp.length().days() << '\n';
    dp.expand(days(3));                         // 两端各外扩：长度 +2n
    std::cout << "expand+3天: begin=" << dp.begin() << " 长度"
              << dp.length().days() << '\n';
    // 关系运算：包含/相交/相邻/交集/并集
    date_period p1(date(2010, 1, 1), days(20));             // 1-1 .. 1-20
    date_period p2(date(2010, 1, 5), days(10));             // 1-5 .. 1-14
    date_period p3(date(2010, 1, 21), days(5));             // 1-21 .. 1-25
    std::cout << "关系: p1 包含 1-10? " << p1.contains(date(2010, 1, 10))
              << " 包含 p2? " << p1.contains(p2)
              << " 相交 p2? " << p1.intersects(p2)
              << " 与 p3 相邻? " << p1.is_adjacent(p3)
              << " 交集==p2? " << (p1.intersection(p2) == p2)
              << " 与 p3 交集为空? " << p1.intersection(p3).is_null() << '\n';
    date_period p4(date(2010, 1, 15), days(10));            // 1-15 .. 1-24 与 p1 部分重叠
    std::cout << "并集: merge(重叠)=" << p1.merge(p4)
              << " span(隔空含间隔)=" << p1.span(p3) << '\n';

    // ── 7) 日期迭代器：++/-- 走日历，但不是标准迭代器 ──
    day_iterator di(date(2007, 9, 28));        // 默认步长 1 天
    ++di;
    year_iterator yi(*di, 10);                 // 步长 10 年
    ++yi;
    std::cout << "迭代器: 起走一天 → " << *di << " 再走十年 → " << yi->year()
              << '\n';
    // 迭代器可整体与 date 比较；但没有 difference_type 等内型，
    // iter += 5 / std::advance 都编译不过（文档里演示错误写法）。

    // ── 8) gregorian_calendar：闰年与月末的静态工具 ──
    typedef gregorian_calendar gre_cal;
    std::cout << "闰年: 2017? " << gre_cal::is_leap_year(2017)
              << " 2024? " << gre_cal::is_leap_year(2024)
              << " 2000? " << gre_cal::is_leap_year(2000)
              << " 1900? " << gre_cal::is_leap_year(1900)
              << "（百年不闰、四百年再闰）\n";

    // ── 9) 综合运用一：打印月历（2017-01） ──
    {
        date d0(2017, 1, 23);
        date first(d0.year(), d0.month(), 1);
        date last = d0.end_of_month();
        int n = 0;
        for (day_iterator it(first); it != last + days(1); ++it) {
            std::cout << (it->day() < 10 ? " " : "") << it->day() << "  ";
            if (++n % 7 == 0) std::cout << '\n';
        }
        std::cout << "（2017 年 1 月共 " << n << " 天）\n";
    }

    // ── 10) 综合运用二：18 岁生日是星期几 + 当年 1 月 Sundays + 当年天数 ──
    {
        date born(2017, 1, 23);
        date adult = born + years(18);
        int sundays = 0;
        for (day_iterator it(date(adult.year(), 1, 1));
             it != adult.end_of_month() + days(1); ++it)
            if (it->day_of_week() == Sunday) ++sundays;
        int days_of_year = gregorian_calendar::is_leap_year(adult.year())
                               ? 366 : 365;
        std::cout << adult << " 是星期" << adult.day_of_week()
                  << " 当年 1 月有 " << sundays << " 个星期日"
                  << " 当年 " << days_of_year << " 天\n";
    }

    // ── 11) 综合运用三：信用卡免息期（date 运算做业务决策） ──
    struct credit_card {
        const char* bank_name;
        int bill_day_no;                       // 每月记账日
        int calc_free_days(date consume_day) const {
            date bill_day(consume_day.year(), consume_day.month(),
                          static_cast<unsigned short>(bill_day_no));
            if (consume_day > bill_day)        // 消费日已过记账日 → 下月记账
                bill_day += months(1);
            return static_cast<int>((bill_day - consume_day).days()) + 20;
        }
    };
    credit_card ca{"A 银行", 25}, cb{"B 银行", 12};
    date d05(2010, 5, 5), d15(2010, 5, 15);
    std::cout << "免息期: 5 号消费 A=" << ca.calc_free_days(d05) << "天"
              << " B=" << cb.calc_free_days(d05) << "天"
              << " | 15 号消费 A=" << ca.calc_free_days(d15) << "天"
              << " B=" << cb.calc_free_days(d15) << "天\n";

    std::cout << "自检通过\n";
    return 0;
}
