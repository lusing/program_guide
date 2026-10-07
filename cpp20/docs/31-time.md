# 31 · 时间：chrono 的 duration、时钟、日历与格式化

> 对应示例：`examples/31_time/`

## 31.1 心智模型三件套

chrono 库（`<chrono>`）全部建立在三个概念上：

| 概念 | 是什么 | 类型 |
|---|---|---|
| **duration** | 一段时间：刻数 + 单位 | `duration<Rep, Period>` |
| **time_point** | 一个时刻：某时钟的纪元 + 偏移量 | `time_point<Clock, Duration>` |
| **clock** | 计时基准：纪元（起点）+ 节拍（精度） | `system_clock` 等 |

"9 点 15 分"是 time_point，"开了 45 分钟会"是 duration——分清这两个，chrono 的一半坑就没了。另一个支柱是并发：`sleep_for(100ms)`、锁的 `try_lock_for` 都吃 duration（第 28 章早就在用了）。

## 31.2 duration 与 ratio：类型里带着单位

```cpp
std::chrono::duration<int, std::milli> d1{500};   // 500 毫秒：刻数 int，单位 1/1000 秒
auto d2 = 45min;                                  // 字面量（31.3），等价 duration<long long, ratio<60>>
```

`duration<Rep, Period>` 的 Period 是 `std::ratio<分子, 分母>`——**单位在类型里**，`milliseconds` 和 `seconds` 是不同类型。预定义全家（`nanoseconds` 到 `hours`）覆盖常规需求，自定义单位也一行的事：

```cpp
using Lesson = std::chrono::duration<double, std::ratio<2700>>;   // 45 分钟一节的"课时"
```

转换规则记住一条：**细化自动、粗化显式**。秒→毫秒（乘得多）编译器自动放行；毫秒→秒（要除、可能丢精度）必须 `duration_cast` 明示同意：

```cpp
using namespace std::chrono;
minutes m = 90s;                            // 编译错！粗化不自动
minutes m2 = duration_cast<minutes>(90s);   // 1 分钟（余数被截断）
milliseconds ms = 2s;                       // 自动：2000ms ✓
```

整数 duration 保证能存 ±292 年；`duration<double>`（浮点刻数）则没有精度换取的表示限制——统计耗时用 `duration<double>` 最省心。

## 31.3 字面量：1h / 30min / 45s / 100ms

```cpp
using namespace std::chrono_literals;   // C++14 起（按需引入，别放头文件里）
auto t = 1h + 23min + 45s;              // 5025s——加法自动向最细单位对齐
auto half = 1.5h;                       // 浮点刻数也合法
```

后缀全家：`h`、`min`、`s`、`ms`、`us`、`ns`。从此 API 里不再出现裸的 `int milliseconds` 参数——单位进类型，"这个 1000 是毫秒还是秒"的千古悬案从根上消灭。

## 31.4 三只钟：测时只准用 steady_clock

| 时钟 | 语义 | 用途 |
|---|---|---|
| `system_clock` | **墙钟**：现实世界时间，可被 NTP 回拨/跳变 | 取日历时间、转 `time_t` |
| `steady_clock` | **单调钟**：只往前走，永不回拨 | **测耗时的唯一选择** |
| `high_resolution_clock` | 通常是上面两者之一的别名 | 别用（哪个的别名是实现定义） |

`static_assert(steady_clock::is_steady)` 恒真；system_clock 则不保证。测耗时用 system_clock 的下场：程序跑着跑着 NTP 一校时，耗时算出负数或零。计时惯用法（第 35 章实战就这么测）：

```cpp
using clock = std::chrono::steady_clock;
auto start = clock::now();
// ... 被测代码 ...
auto elapsed = std::chrono::duration<double>(clock::now() - start);   // 浮点秒
std::println("耗时 {:.3f}s", elapsed.count());
```

跨钟转换有 `clock_cast`（C++20）；`system_clock::to_time_t` 则是通往 C 时代 `<ctime>` 的桥。

## 31.5 日历（C++20）：year / month / day 是类型

C++20 给 chrono 配了整套日历类型，运算直达语义层：

```cpp
using namespace std::chrono;
year_month_day release{2026y / September / 28d};     // 2026-09-28（字面量 2026y、September）
sys_days sd{release};                                // 日历 → 系统天数（可加减、可格式化）
sd + weeks{1};                                       // 一周后：周/日是精确单位，sys_days 上随便加
release + months{3};                                 // 三个月后：月份运算要在日历类型上做！
weekday{sd};                                         // 星期几（{:%A} 打印 Monday）
year_month_day{year{2026} / February / last};        // 2026 年 2 月最后一天：02-28
```

组合语法 `y / m / d` 的顺序随便换（`January/1/2026y` 也行），`last` 是月末占位符——"每月最后一天"这种 cron 式表达第一次成为一等公民。`year_month_day::ok()` 能查出 2025-02-30 这类非法日期。

**月份加法的类型陷阱**（实测踩过）：`sys_days + months{3}` 能编译能跑，但 `months` 作为 duration 的单位是**平均月（30.44 天）**——`2026-09-28` 加出来是 `2026-12-28 07:27:18`，凭空多出一段时分秒。"三个月后"要写 `year_month_day + months{3}`（日历语义、月末自动 clamp），**年月加减永远在日历类型上做**。

## 31.6 时区（C++20）：zoned_time

```cpp
using namespace std::chrono;
auto tp = sys_days{2026y / January / 15} + 12h;      // 一个固定时刻（UTC）
zoned_time tokyo{"Asia/Tokyo", tp};                  // 挂上时区就是当地时间
zoned_time ny{"America/New_York", tp};               // 同一时刻的纽约说法
std::println("{}", tokyo);                           // 2026-01-15 21:00:00 GMT+9（Windows 实测）
```

时区数据来自 IANA tzdb（Windows 上由 MSVC 的转换层提供，缩写打出来是 `GMT+9` 风格而非 `+09:00`——跨平台输出的"样子"有差异，时刻本身没有）。`current_zone()` 是本机时区。教学要点：**同一 time_point + 不同时区 = 同一时刻的不同表述**，不存在"转换丢时刻"。部署注意目标机器要有 tzdb。

## 31.7 chrono 与 format：直接打印

C++20 起 duration 与日历类型都有 formatter（格式语法详见第 33 章，这里只看 chrono 的用法）：

```cpp
std::print("{:%Y-%m-%d}", sys_days{2026y / 9 / 28d});   // 2026-09-28
std::print("{:%S}", 4567ms);                             // 04.567（总秒数含毫秒）
std::println("{}", 45min);                               // 45min——自带单位！
```

`hh_mm_ss` 把 duration 拆成时分秒三件：`hh_mm_ss hms{4567ms}` 得 `hours()==0、minutes()==0、seconds()==4、subseconds()==567ms`（整体打印 `00:00:04.567`）。**别再手写 `count()` 后拼单位**——直接打印 duration，单位是类型的一部分。chrono 的格式说明符只认 `%` 系（`%S`、`%Y`…）——写 `{:.2f}` 这类普通精度语法会在**编译期**被 format 串检查拒掉（C7595），非法格式活不到运行时。

## 31.8 坑位清单

1. **用 system_clock 测耗时**：NTP 校时让耗时报负数/零——测量一律 `steady_clock`。
2. **粗化转换被拒还嫌编译器烦**：`minutes m = 90s` 编译错是**保护你**——丢 30 秒的转换要 `duration_cast` 明示；`90s / 1min`（整数除法 = 1）与 `duration_cast` 等价地截断。
3. **不同钟的 time_point 混算**：`steady_clock::now()` 与 `system_clock::now()` 相减是编译错（类型不同）——这是特性；确要跨钟用 `clock_cast`。
4. **`count()` 打印裸数字**：`"耗时 " + std::to_string(d.count())` 丢了单位——直接 `print("{}", d)`（输出带单位）或用 `duration<double>` 后注明秒。
5. **`sys_days + months` 按平均月漂移**：months 是"平均月 30.44 天"的 duration，加在 sys_days 上凭空多出 07:27:18——月份加减要在 `year_month_day` 上做；日历类型加法的月末 clamp 也要检查（`January/31 + months{1}` 的结果可能不 `ok()`）。
6. **时区显示依赖运行环境**：IANA tzdb 不在机器上 → 抛异常；跨机器跑输出前先确认数据源。
7. **`high_resolution_clock` 想当然**：它是不是 steady 的是实现定义——写代码时直接选 steady 或 system，绕开它。

---

上一章：[30 协程](30-coroutines.md) · 下一章：[32 流 I/O](32-streams.md)
