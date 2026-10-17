// local_time.cpp —— Boost.Date_Time 的第三层：local_time 时区与夏令时
// 对应文档：docs/07-chrono.md
//
// date_time 处理时区的三板斧：
//   posix_time_zone —— 用 POSIX TZ 串描述时区（不依赖任何数据文件）
//   local_date_time —— 带"时区标签"的时刻；内部统一存 UTC
//   tz_database     —— CSV 时区数据库（date_time_zonespec.csv，在源码树
//                      libs/date_time/data/ 下，收录全球时区名）
// 本例程输出必须可复现 → 只用固定时刻 + 固定时区串。
#include <boost/date_time/local_time/local_time.hpp>
#include <iostream>

int main() {
    using namespace boost::local_time;
    using namespace boost::posix_time;
    using namespace boost::gregorian;

    // ── 1) posix_time_zone：一行 TZ 串就是完整时区定义 ──
    // 格式："缩写 偏移 [夏令时缩写[偏移][,起始规则[/时刻],结束规则[/时刻]]]"
    //
    // 【实测坑·符号方向】Boost 的 TZ 串偏移符号与 POSIX 标准**相反**
    // （官方文档原话："PST-8 ... eight hours west of GMT"）。POSIX 里
    // TZ=CST-8 表示 UTC+8（西为正），Boost 里 CST-8 会被当成 UTC-8。
    // 在 Boost 里写时区：东区用 +，西区用 -。照抄系统 TZ 环境变量必踩坑。
    time_zone_ptr shz(new posix_time_zone("CST+8"));        // 北京：无夏令时
    time_zone_ptr sfz(new posix_time_zone(                  // 旧金山：3 月第 2 个
        "PST-8PDT,M3.2.0,M11.1.0"));                        // 周日 2:00 起夏令时
    std::cout << "时区: " << shz->std_zone_abbrev()
              << " 偏移=" << shz->base_utc_offset() << " 有夏令时? "
              << std::boolalpha << shz->has_dst()
              << " | " << sfz->std_zone_abbrev() << " 有夏令时? " << sfz->has_dst()
              << "（夏令时名=" << sfz->dst_zone_name() << "）\n";

    // ── 2) local_date_time：内部统一存 UTC，展示按区换算 ──
    // 从 UTC ptime 构造最无歧义（另一种构造用本地墙钟三件套 + 是否夏令时
    // 标志，标错了直接抛异常——见第 4 段）。
    ptime utc_start(date(2014, 3, 6), hours(8));            // UTC 08:00
    local_date_time bj(utc_start, shz);                     // = 北京 16:00
    std::cout << "北京时刻: " << bj
              << "（utc_time() 回读一致? " << (bj.utc_time() == utc_start)
              << "）\n";

    // ── 3) 跨时区换算：北京 → 旧金山（书里的飞行例） ──
    // 从北京 16:00 起飞，飞 12 小时，落地时当地几点？
    local_date_time arrive = bj + hours(12);                // 内部仍按 UTC 走
    local_date_time sf = arrive.local_time_in(sfz);         // 换算到旧金山时区
    std::cout << "飞行: 起飞 " << bj << " → 落地(北京时间) " << arrive
              << " → 落地(当地时间) " << sf << '\n';
    std::cout << "落地是否夏令时? " << sf.is_dst()
              << "（3 月 6 日在 3 月第 2 个周日之后? "
              << (date(2014, 3, 6) > date(2014, Mar, 9)) << "→否）\n";

    // ── 3.5) 夏令时切换日的"幽灵时刻"：2014-03-09 02:30 在旧金山不存在
    //    （规则 M3.2.0 默认 02:00 起跳到 03:00，墙钟上没有 02:xx）。
    //    用"本地墙钟三件套 + dst 标志"构造：时刻落在跳跃区间 → 构造被拒
    //    （EXCEPTION_ON_ERROR 抛异常；NOT_DATE_TIME_ON_ERROR 得无效值）。
    bool rejected = false;
    try {
        local_date_time ghost(date(2014, 3, 9),
                              time_duration(2, 30, 0), sfz,
                              local_date_time::NOT_DATE_TIME_ON_ERROR);
        rejected = ghost.is_not_a_date_time();   // 没抛但产出无效值
    } catch (const std::exception&) {
        rejected = true;                          // 或直接抛 bad_offset 等
    }
    std::cout << "幽灵时刻 2014-03-09 02:30 被拒? " << rejected << '\n';
    // 对照：同一天 01:30（跳跃前）是合法的冬令时时刻
    local_date_time real(date(2014, 3, 9), time_duration(1, 30, 0), sfz,
                         false);                 // dst=false（冬令时）
    std::cout << "跳跃前 01:30 合法? " << !real.is_not_a_date_time()
              << " 缩写=" << real.zone_abbrev(false) << '\n';

    // ── 4) local_time_period：带时区区间（与 time_period 同款代数） ──
    local_time_period workday(bj, hours(9));                // 北京工作日 9h
    std::cout << "区间: [" << workday.begin() << " .. "
              << workday.last() << "] 长度 "
              << workday.length() << '\n';

    // ── 5) 格式化 facet：date/ptime/local_time 三种 facet 各管一层 ──
    // facet 装进 locale 再 imbue 到流；格式串是 strftime 风格。
    {
        date_facet* df = new date_facet("%Y 年 %m 月 %d 日");
        std::cout.imbue(std::locale(std::locale::classic(), df));
        std::cout << "facet 日期: " << date(2014, 11, 3) << '\n';

        time_facet* tf =
            new time_facet("%Y 年 %m 月 %d 日 %H 点 %M 分 %S%F 秒");
        std::cout.imbue(std::locale(std::locale::classic(), tf));
        std::cout << "facet 时刻: "
                  << ptime(date(2014, 11, 3),
                           hours(21) + minutes(50) + millisec(100)) << '\n';

        local_time_facet* lf = new local_time_facet("%Y-%m-%d %H:%M %Z");
        std::cout.imbue(std::locale(std::locale::classic(), lf));
        std::cout << "facet 本地: " << bj << '\n';
        std::cout.imbue(std::locale::classic());            // 还原，别影响后续
    }

    std::cout << "自检通过\n";
    return 0;
}
