# 07 · 时间与日历：date_time / chrono / ratio / timer 四兄弟

> 对应示例：`examples/07_chrono/`（4 个例程）

时间的库分两层：**物理层**（多久——duration/clock）和**日历层**（哪天——date/calendar）。Boost 在两层都先行：`chrono`/`ratio` 定义了物理层的现代范式（C++11 毕业），`date_time` 的日历运算等了 19 年才在 C++20 `std::chrono` 里毕业。

| 库 | 层 | std 对应 | 血缘 |
|---|---|---|---|
| Boost.Chrono | 物理 | `std::chrono`（C++11） | 直系 |
| Boost.Ratio | 编译期有理数 | `std::ratio`（C++11） | 直系 |
| Boost.Date_Time | 日历 | C++20 chrono 日历 | 半系（API 重设计） |
| Boost.Timer | 人体工学 | 无 | ⭐ 小而常用 |

## 7.1 Boost.Date_Time（2001）：日历运算的老王

```cpp
using namespace boost::gregorian;
date release(2026, Sep, 19);
date deadline = release + date_duration(30);      // +30 天，自动跨月
date_period sprint(release, deadline);            // 区间
sprint.length().days();                           // 30
end_of_year.day_of_week();                        // 周几

using namespace boost::posix_time;
ptime t(release, time_duration(14, 30, 0));       // 日期 + 时刻
ptime later = t + hours(3) + minutes(45);
(later - t).total_seconds();                      // 13500
```

运行输出（`date_time.cpp`）：

```text
发布日 2026-Sep-19 截止 2026-Oct-19
迭代周期 30 天
年底是周Thu（0=周日）
3 小时 45 分 = 13500 秒
std::chrono +30 天 = 2026-10-19
weekday = Mon
```

Gregorian（公历）+ posix_time（微秒时刻）的组合覆盖了绝大多数业务需求：日期加减、区间、周末/节假日判断（`nth_day_of_the_week_in_month` 算"第 N 个星期几"）、闰年全对。

**毕业档案**：C++20 `std::chrono` 终于有了日历（`year_month_day`、`weekday`、`month_day_last`...），但 **API 是重新设计的**（`sys_days + days{30}` vs `date + date_duration(30)`）——这是"半系毕业"：思想直系、接口换代。**2026 选型**：新代码日历用 C++20 chrono；要时区完整支持看 Boost 之外的 Howard Hinnant `date` 库（tz 数据库的参考实现）；Boost.Date_Time 的残余场景是老代码和"月末钳制"等个别方便语义。

> 实测坑：`using namespace boost::gregorian` 和 `using namespace std::chrono` 同时开，`days` 直接二义（两边都有）——混用两套时间库时名字要全限定。

## 7.2 Boost.Chrono（2008）：物理层的现代范式

```cpp
boost::chrono::seconds s(90);
boost::chrono::duration_cast<boost::chrono::minutes>(s);     // 截断转换
auto start = boost::chrono::steady_clock::now();
auto elapsed = boost::chrono::steady_clock::now() - start;   // steady：测耗时的唯一正解
```

运行输出（`chrono.cpp`）：

```text
90 秒 = 1 分钟(截断)
1500ms = 1 秒(截断)
耗时 >= 50ms? true
Unix 时间戳(秒) > 17 亿? true
进程时钟读数非零? true
格式化: 3661000 milliseconds
```

三个刻进肌肉的记忆点：

1. **duration 是"数值+单位"**：`seconds(90)` 和 `minutes(1)` 是不同类型，隐式不丢精度才能转，要截断必须 `duration_cast` 显式声明——单位错配在编译期被抓。
2. **测耗时只用 `steady_clock`**：`system_clock` 是挂钟（NTP 会回拨，测出负时长）。
3. **Boost 独有的进程时钟**：`process_real_cpu_clock` / `process_user_cpu_clock` / `process_system_cpu_clock`——std::chrono 没有对应物，测 CPU 时间（而非墙钟）至今仍要靠它或平台 API。

**毕业档案**：`std::chrono`（C++11，直系），且 std 版在 C++20 长出了日历和时区。Boost 版的残余价值就是上面第 3 点和 `chrono_io` 的 `duration` 流输出。

## 7.3 Boost.Ratio（C++11 同船毕业的地基）

`std::chrono::milliseconds` 为什么能"零开销换算单位"？因为单位比是**编译期分数**——`ratio` 就是那个分数：

```cpp
using half  = boost::ratio<1, 2>;
boost::ratio_add<half, ratio<1, 3>>;       // 5/6（编译期加法+约分）
boost::ratio_less<half, ratio<1, 3>>;      // false
using fortnight = boost::ratio<14*24*3600, 1>;   // 自定义单位
```

运行输出（`ratio.cpp`）：

```text
half = 1/2
ratio<6,12> 约分 = 1/2
1/2+1/3 = 5/6
1/2*1/3 = 1/6
1/2 < 1/3 ? false
fortnight = 1209600 秒的倍数
kilo = 1000  milli = 1/1000
```

**毕业档案**：`std::ratio`（C++11，直系）。几乎不会直接用——它的存在感全在 `chrono` 的单位定义里。单独使用场景：编译期单位制运算（物理仿真里 kg·m/s² 的类型追踪）。

## 7.4 Boost.Timer：RAII 计时器

```cpp
{
    boost::timer::auto_cpu_timer t;        // 析构自动打印
    do_work();
}
boost::timer::cpu_timer timer; timer.start(); ...; timer.stop();
timer.elapsed().wall;                      // 纳秒计数的墙钟
```

运行输出（`timer.cpp`，**wall 数值随机器与运行浮动**）：

```text
段1（50ms）:
 0.059365s wall, 0.000000s user + 0.000000s system = 0.000000s CPU (n/a%)
段2 wall>=1ms? true
```

`auto_cpu_timer` 是"这个函数到底多慢"的一行答案（RAII，忘不了打印）。std 没有对应物——`<chrono>` + `<format>` 自己拼五十行才有同等输出。**⭐ 2026 年仍是趁手小工具**，尤其 `cpu_times` 的 wall/user/system 三分（进程 CPU 时间）比 std 里任何现成件都全。

---


> 上一章：[06 · 正则与随机](06-regex-random.md) ｜ 下一章：[08 · 无序与哈希](08-unordered.md) ｜ 返回：[README](../README.md)
