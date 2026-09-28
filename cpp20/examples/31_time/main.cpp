#include <chrono>
#include <format>
#include <print>
#include <thread>

// 31 时间：chrono 的 duration、时钟、日历与格式化 —— 单位进类型

using namespace std::chrono;
using namespace std::chrono_literals;

int main() {
    // ═══ 31.1 duration：刻数 + 单位，字面量直接写 ═══
    auto meeting = 1h + 23min + 45s;                     // 加法向最细单位对齐
    std::println("1h+23min+45s = {}（{} 秒）", meeting, meeting / 1s);

    // 细化自动、粗化显式：转换规则的全部内容
    milliseconds fine = 2s;                              // 自动：秒→毫秒 ✓
    std::println("2s 细化成毫秒 = {}", fine);
    minutes coarse = duration_cast<minutes>(90s);        // 粗化必须 duration_cast（余数截断）
    std::println("90s 粗化成分钟 = {}（余 {} 被截断）", coarse, 90s % 1min);
    std::println("90s / 1min = {}（整数除法，等价截断）", 90s / 1min);

    using Lesson = duration<double, std::ratio<2700>>;   // 自定义单位：45 分钟一节的“课时”
    std::println("2700s = {:.2f} 课时", Lesson{2700s}.count());

    // ═══ 31.2 时钟：测耗时只准用 steady_clock ═══
    static_assert(steady_clock::is_steady, "steady_clock 保证单调");
    std::println("steady_clock 单调 = {}", steady_clock::is_steady);
    auto start = steady_clock::now();
    std::this_thread::sleep_for(10ms);                   // 真睡 10ms（并发章的老朋友）
    duration<double> elapsed = steady_clock::now() - start;
    std::println("睡 10ms 实测 >= 10ms：{}", elapsed >= 10ms);   // 只断言关系，不断言具体值

    // ═══ 31.3 日历（C++20）：year/month/day 是类型，last 是月末 ═══
    constexpr year_month_day release{2026y / September / 28d};
    sys_days sd{release};
    std::println("发布日 = {}，是 {:%A}", release, weekday{sd});
    std::println("一周后 = {}（sys_days + weeks 是精确天数，随便加）", sd + weeks{1});
    // 月份运算要在日历类型上做：sys_days + months 会按“平均月 30.44 天”漂移出 07:27:18！
    std::println("三个月后 = {}（year_month_day + months）", release + months{3});
    std::println("2026 年 2 月最后一天 = {}", year_month_day{year{2026} / February / last});
    constexpr year_month_day bad{2025y / February / 30d};
    std::println("2025-02-30 合法吗：{}", bad.ok());      // 日历类型自己会查

    // ═══ 31.4 时区（C++20）：同一时刻的不同说法 ═══
    auto tp = sys_days{2026y / January / 15} + 12h;      // 固定时刻（冬令时无夏令时歧义）
    zoned_time tokyo{"Asia/Tokyo", tp};
    zoned_time berlin{"Europe/Berlin", tp};
    zoned_time ny{"America/New_York", tp};
    std::println("同一时刻  东京：{}", tokyo);            // Windows 的时区缩写是 GMT+9 风格
    std::println("同一时刻  柏林：{}", berlin);
    std::println("同一时刻 纽约：{}", ny);

    // ═══ 31.5 格式化：chrono 类型直接进 print/format ═══
    std::println("{:%Y-%m-%d}（自定义格式串）", sd);
    std::println("4567ms 按秒打印 {:%S}，按分秒打印 {:%M:%S}", 4567ms, 4567ms);
    hh_mm_ss hms{4567ms};                                // 拆成时分秒三件
    std::println("hh_mm_ss{{4567ms}} = {}（{} 时 {} 分 {} 秒 + {}）",
                 hms, hms.hours(), hms.minutes(), hms.seconds(), hms.subseconds());
    std::println("duration 自带单位：{} / {} / {}", 45min, 1.5h, duration<double>{90s});

    std::println("自检通过");
}
