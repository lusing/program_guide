# 07 · 时间与日历：date_time / chrono / ratio / timer 四兄弟

> 对应示例：`examples/07_chrono/`（7 个例程：timer / timer_v1 / date_time / posix_time / local_time / chrono / ratio）

时间的库分两层：**物理层**（多久——duration/clock）和**日历层**（哪天——date/calendar）。Boost 在两层都先行：`chrono`/`ratio` 定义了物理层的现代范式（C++11 毕业），`date_time` 的日历运算等了 19 年才在 C++20 `std::chrono` 里毕业。

| 库 | 层 | std 对应 | 血缘 |
|---|---|---|---|
| Boost.Chrono | 物理 | `std::chrono`（C++11） | 直系 |
| Boost.Ratio | 编译期有理数 | `std::ratio`（C++11） | 直系 |
| Boost.Date_Time | 日历 | C++20 chrono 日历 | 半系（API 重设计） |
| Boost.Timer | 人体工学 | 无 | ⭐ 小而常用 |

本章讲法沿用"先立概念、再背合同、最后看坑"：date_time 的概念三角形（时间点/时长/区间）一旦立住，后面所有 API 都是在这个三角形上做算术。

## 7.1 Boost.Timer：两代计时器

Boost.Timer 是观察 Boost 版本演化的最佳标本：它同时保存着一具化石（V1）和一个现役组件（V2），两者只隔一次库重构。

### 7.1.1 V1 化石层：`boost::timer` 与 `progress_timer`

V1 的 `boost::timer` 是一个不到 20 行的秒表，全部实现就是 `std::clock()`：构造时记下时钟读数，`elapsed()` 用当前读数减它再除以 `CLOCKS_PER_SEC`。它有两个先天缺陷，也正是它退场的原因：

1. **精度是平台彩票**。`elapsed_min()`（最小可测刻度）是 `1/CLOCKS_PER_SEC`——MSVC 下 `CLOCKS_PER_SEC` 是 1000（毫秒粒度），glibc 下通常是 1000000（微秒）。
2. **量程小**。`elapsed_max()` 受 `clock_t` 上限约束，Windows 上只有约 0.068 年（见下面实测）。

`progress_timer` 是它的派生类：**析构时自动报时**。"声明即计时、离开作用域自动打印"这个 RAII 用法如此好用，以至于它直接塑造了 V2 的 `auto_cpu_timer`。

在 1.72 之后，V1 被整个库弃用。1.92 里的现状是：不定义宏直接 `#include <boost/timer.hpp>` 是**编译期硬错误**（`This header is deprecated and will be removed`），必须先 `#define BOOST_TIMER_ENABLE_DEPRECATED` 才能启用——像博物馆里一件要按按钮才亮灯的展品。

```cpp
#define BOOST_TIMER_ENABLE_DEPRECATED
#include <boost/progress.hpp>
#include <boost/timer.hpp>

boost::timer t;                       // 构造即开始计时
t.elapsed_min();                      // 1/CLOCKS_PER_SEC —— 平台彩票
std::this_thread::sleep_for(std::chrono::milliseconds(10));
t.elapsed() >= 0.010;                 // true

std::ostringstream ss;
{
    boost::progress_timer pt(ss);     // 输出定向到字符串流
}                                     // 析构 → ss 里写入报时
```

（对应示例：`timer_v1.cpp`。）

运行输出（`timer_v1.cpp`）：

```text
V1 最小刻度 = 0.001 秒（本机 CLOCKS_PER_SEC = 1000）
V1 最大量程 = 0.0680963 年
V1 elapsed >= 10ms? true
progress_timer 输出形如 "x.xx s\n\n"? true
自检通过
```

这四行输出里有两个"与书对账"的发现。其一：第 5 版书（罗剑锋《Boost 程序库完全开发指南》，基于 Boost 1.72/GCC 7）记录 `elapsed_min()` 为 `1e-06` 秒——本机（MSVC）是 0.001 秒，差一千倍，印证"精度是平台彩票"。其二：`progress_timer` 的析构输出在 1.92/MSVC 实测是 `"x.xx s\n\n"`（8 字节、**两个**换行，实现用了 `endl`），比书里记录的 `"x.xx s\n"` 多一个空行——例程按字节校验而不是打印原始值，就是因为计时输出不可复现。

> 实测坑（1.92）：V1 与 V2 **不能出现在同一个编译单元**。V1 头把秒表类定义在名字 `boost::timer`，V2 头把全部新组件放进**同名命名空间** `boost::timer`——同屏即报 `C2869: "boost::timer": 已被定义为命名空间`。所以本章把两代拆成 `timer_v1.cpp` 与 `timer.cpp` 两个文件，想对比两代的读者也只能这么做。

### 7.1.2 V2 现役层：`cpu_timer` 与 `auto_cpu_timer`

V2 的核心洞察是：**一次测量应该同时给出三只表的读数**。

```cpp
struct cpu_times {                     // boost/timer/timer.hpp
    nanosecond_type wall;              // 挂钟时间：进程经历的真实时间
    nanosecond_type user;              // 用户态 CPU 时间：执行你的代码花的 CPU
    nanosecond_type system;            // 内核态 CPU 时间：替你做系统调用花的 CPU
};
```

wall 大而 user+system 小，说明时间花在了等待（睡眠、锁、I/O）上；user+system 接近 wall，说明是 CPU 密集。这一刀切开的信息，`std::chrono` 至今没有现成件能一行给全。

`cpu_timer` 的手动档是 `start()` / `stop()` / `resume()`：`stop()` 之后**连 wall 也不再累计**（不是只停 CPU 表），`resume()` 从冻结处继续。`auto_cpu_timer` 继承它，加上"析构自动打印"，就是 progress_timer 的转世。

格式化由 `format()` 承担：第一个参数是小数位数（默认 6，即微秒档），第二个参数是格式串，五个占位符 `%w/%u/%s/%t/%p` 分别对应 wall/user/system/合计(user+system)/百分比。演示格式语义时用**合成数据**——真实计时每次都不同，没法做断言：

```cpp
const boost::timer::nanosecond_type ms = 1000LL * 1000;
boost::timer::cpu_times demo{2000 * ms, 1000 * ms, 100 * ms};   // 2s / 1s / 0.1s
std::cout << boost::timer::format(demo, 7);
//  2.0000000s wall, 1.0000000s user + 0.1000000s system = 1.1000000s CPU (55.0%)
boost::timer::format(demo, 3, "墙钟%w秒 用户%u秒 内核%s秒 合计%t秒 百分比%p\n");
```

（对应示例：`timer.cpp`。）

运行输出（`timer.cpp`；第二行是 `auto_cpu_timer` 打的**真实耗时，每次都不同**）：

```text
段1（50ms）:
停止后 is_stopped? true
段2 stop 期间 wall 冻结? true  wall>=1ms? true
resume 后 wall 继续增长? true
format 默认:  2.0000000s wall, 1.0000000s user + 0.1000000s system = 1.1000000s CPU (55.0%)
format 3 位:  2.000s wall, 1.000s user + 0.100s system = 1.100s CPU (55.0%)
format 微值:  0.000s wall, 0.000s user + 0.000s system = 0.000s CPU (n/a%)
自定义: 墙钟2.000秒 用户1.000秒 内核0.100秒 合计1.100秒 百分比55.0
自检通过
```

三个读数点：段 1 里 50ms 睡眠打出 `0.000000s CPU (n/a%)`——**纯等待不消耗 CPU**，这正是三表同测的价值；`format 微值` 一行说明 CPU 合计低于度量精度时百分比显示 `n/a` 而不是误导性的 `0.0%`；`自定义` 一行证明占位符可以配中文标签重复摆放。

> 实测坑（阈值断言）：`段2 wall>=1ms?` 这条断言**不能卡在阈值附近**。原来例程是 200 万次 `volatile double` 累加，实测耗时正好压在 1ms 线上——同一条通道连跑 5 次里有 2 次打印 `false`，而它本该是"断言"。放大到 2000 万次（离阈值两个数量级）之后才 5/5 稳定。
>
> 实测坑（CPU 时间粒度）：Windows 上进程 CPU 时间的度量粒度约 15.6ms（系统节拍）。程序刚启动就查 `process_*_cpu_clock`，读数常常还是 0（见 7.5 的 chrono 例程：先烧一百万次浮点累加才读到非零）。
>
> 实测坑（跨平台）：`auto_cpu_timer` 那行是唯一"本来就不可能跨通道一致"的输出，所以 macOS 侧 `run-all.sh` 对它的豁免是**按行**给的（只删 `^ [0-9]+\.[0-9]+s wall, ` 这一行），其余行照常逐字节比——整例豁免会把上面那条掷硬币的输出一起放过。

**⭐ 2026 选型**：`auto_cpu_timer` 仍是"这个函数到底多慢"的一行答案；`cpu_times` 的 wall/user/system 三分比 std 里任何现成件都全。V1 只在维护老代码时才会遇到，且要记得那个宏。

## 7.2 Boost.Date_Time（2001）：日期系统 gregorian

C++ 标准直到 C++20 才有日历，而 Boost.Date_Time 在 2001 年就把日历算清了。它分两半：`gregorian` 管日期（年月日），`posix_time` 在日期上加了时分秒（7.3）。先立概念三角形：

- **时间点**（`date`）：数轴上的一个点，天粒度；
- **时长**（`days`/`weeks`/`months`/`years`）：有符号标量，两点之差；
- **区间**（`date_period`）：左闭右开 `[begin, end)`，`end()` 是"逾尾"，与标准容器的 `end()` 同义。

再配上**特殊值**——数学里"极限"概念的时间版，这是 date_time 独有的表达力：

```cpp
date d1;                          // 默认构造 = not_a_date_time（无效日期）
date pinf(pos_infin);             // +infinity
date ninf(neg_infin);             // -infinity
date dmin(min_date_time);         // 1400-01-01（表示范围下界）
date dmax(max_date_time);         // 9999-12-31（上界）
```

### 7.2.1 创建、访问与转换

创建 date 有五条路：数字构造（`date(2010,1,1)`）、英文月份枚举（`date(2000,Jan,1)`）、字符串工厂（`from_string("1999-12-31")` 认斜杠或连字符、`from_undelimited_string("20011118")` 认裸数字）、时钟（`day_clock::local_day()/universal_day()`——唯一"现在"来源）、特殊值枚举。

**非法输入抛异常而不是变成无效日期**，而且三种典型错误走两条异常路径：本机（1.92/MSVC）实测三种都走 `std::out_of_range`（包括平年 2 月 29 这种"日期不存在"）；`std::invalid_argument` 分支留给其他畸形输入。

访问接口比 `tm` 结构丰富一档：`year()/month()/day()`，一次取全的 `year_month_day()`，`day_of_week()`（星期几）、`day_of_year()`（年积日）、`end_of_month()`（直接给月末 date）、`week_number()`（ISO 周号 0~53）。输出有三个自由函数加流输出：`to_simple_string`（`2017-Jan-23`）、`to_iso_string`（`20170123`）、`to_iso_extended_string`（`2017-01-23`）。

与 C 的 `tm` 互转有明确的"字段合同"：`to_tm(date)` 把时分秒清零、`tm_isdst` 置 -1（未知）；`date_from_tm(tm)` 只看年月日三个字段。往返一致。

```cpp
// 对应示例 date_time.cpp 的第 1~3 段
date d(2017, 6, 1);
auto ymd = d.year_month_day();            // 一次取全
d.day_of_week();                          // Thu（day_of_week_type 可流输出）
d.day_of_year();                          // 152
d.end_of_month();                         // 2017-Jun-30
date(2015,1,10).week_number();            // 2 —— 三年三个答案（2/1/2），
date(2016,1,10).week_number();            // 1   周号取决于当年 1 月 1 日
date(2017,1,10).week_number();            // 2   是星期几，不是简单除以 7
```

运行输出（`date_time.cpp`）：

```text
无效日期 == not_a_date_time? true
字符串工厂: 1999-Dec-31 / 2001-Nov-18
day_clock 本地日在 [2026,2100] 且为合法日? true
特殊值: -infinity +infinity not-a-date-time 1400-Jan-01 9999-Dec-31
无穷判断: is_infinity=true is_pos=true is_neg=true is_not_a_date=true
越界(1399,12,1) 越界(10000,1,1) 越界(2017,2,29) 
访问: 2017-6-1 星期Thu 年积日152 月末2017-Jun-30
周数: 2015-1-10→2 2016-1-10→1 2017-1-10→2
输出: 2017-Jan-23 20170123 2017-01-23（流输出 = 2017-Jan-23）
to_tm: 年偏移117 月0基0 日23 时0 往返一致? true
自检通过
```

（"年偏移 117"是 `tm_year` 的 1900 基约定、"月 0 基 0"是 `tm_mon` 的 0 基约定——合同如此，别按 2017/6 去读。）

### 7.2.2 时长与"月末吸附"坑

`days` 是基本时长（`date_duration` 的 typedef），行为像一个可除整数：可正可负、支持四则中的加减乘除整数、全序比较。`weeks` 是它的近义词（构造单位 ×7）。`months`/`years` 则换了一种语义——**日历单位**而非固定秒数，支持 `number_of_months()/number_of_years()` 读数。

```cpp
days dd1(10), dd2(-100);
(dd1 + dd2).days();                     // -90
(dd1 + dd3).days() / 5;                 // 53（支持除以整数；不能除以另一个 days）
weeks w(3);  w.days();                  // 21
months m(5);  years y(2);
months ym = y + m;                      // 29 个月（years 自动折算进 months）
(y * 2).number_of_years();              // 4
```

日历单位带来 date_time 最著名的坑——**月末吸附**：

```cpp
date snap(2017, 3, 30);
snap -= months(1);   // 2017-Feb-28 —— 2 月没有 30 号，钳到月末
snap -= months(1);   // 2017-Jan-31 —— 上一步已是"月末"，这一步保持月末
snap += months(2);   // 2017-Mar-31 —— 回不去 3-30，"30 号"信息永久丢失
```

规则是"落到月末就保持月末"。第一天 3-30 减一个月得到 2-28 是生活常识；但 2-28 再减一个月得到 1-31（而不是 1-28）、加两个月得到 3-31（而不是 3-30）——一旦被钳制到月末，日期的"几号"维度就被重写了。要避免这种静默漂移，有两个办法：涉及月/年的运算后显式校验结果；或干脆只用 `days`（date_time 甚至提供了 `BOOST_DATE_TIME_OPTIONAL_GREGORIAN_TYPES` 宏——undef 掉它就不提供 weeks/months/years，逼所有人用 days）。

特殊值会沿运算传染：`date + days(pos_infin)` 得到正无穷日期，`date + days(not_a_date_time)` 得到无效日期——做区间端点计算时要想到这条规则。

运行输出（`date_time.cpp`）：

```text
days 运算: dd1+dd2==-90 (dd1+dd3)/5==53
weeks=3 → 21天; 2年+5月 = 29月; 2年*2 = 4年
月末吸附: 3-30 -1月 → 2017-Feb-28 -1月 → 2017-Jan-31 +2月 → 2017-Mar-31（回不到 3-30）
2000-1-1 到 2017-11-18 = 6531天  往返一致? true
特殊值传染: +∞→is_pos_infinity=true +NADT→is_not_a_date=true
自检通过
```

### 7.2.3 区间代数：date_period

`date_period` 的构造合同：`(左端点, 逾尾端点)` 或 `(左端点, days 长度)`。**左大右小或负长度不抛异常，产出"空区间"**（`is_null()` 为 true）——这与非法日期抛异常的路线刻意不同：区间为空是一种合法的中间状态（比如两个不相交区间的交集）。

区间比较按端点字典序（先比 end 再比 begin），只在区间不相交时才有意义。关系运算全家桶：

- `contains(date)` / `contains(period)`：包含；
- `intersects(period)`：相交；`is_adjacent(period)`：相邻（首尾相接但不重叠）；
- `intersection(period)`：交集，无交集返回**空区间**而不是异常；
- `merge(period)`：并集，仅当相交或相邻才有效，否则空区间；`span(period)`：广义并集——隔空也把中间吞进来。

变形运算两个：`shift(days)` 整体平移（长度不变）；`expand(days)` 两端各外扩 n 天（长度 +2n）。

```cpp
date_period p1(date(2010,1,1), days(20));   // 1-1 .. 1-20
date_period p2(date(2010,1,5), days(10));   // 1-5 .. 1-14（被 p1 包住）
date_period p3(date(2010,1,21), days(5));   // 1-21 .. 1-25（与 p1 相邻不交）
p1.contains(p2);                            // true
p1.intersects(p3);                          // false
p1.is_adjacent(p3);                         // true
p1.intersection(p3).is_null();              // true（空区间不是异常）
p1.merge(p4);                               // 部分重叠 → [2010-Jan-01/2010-Jan-24]
p1.span(p3);                                // 隔空 → [2010-Jan-01/2010-Jan-25]
```

运行输出（`date_time.cpp`）：

```text
区间: [2017-Jan-01,2017-Jan-20] end(逾尾)=2017-Jan-21 长度20天 空? false 非法构造→空? true
shift+3天: begin=2017-Jan-04 长度仍20
expand+3天: begin=2017-Jan-01 长度26
关系: p1 包含 1-10? true 包含 p2? true 相交 p2? true 与 p3 相邻? true 交集==p2? true 与 p3 交集为空? true
并集: merge(重叠)=[2010-Jan-01/2010-Jan-24] span(隔空含间隔)=[2010-Jan-01/2010-Jan-25]
自检通过
```

### 7.2.4 日期迭代器：能走日历，不是容器迭代器

四个迭代器 `day_iterator / week_iterator / month_iterator / year_iterator` 在构造时给起点和步长，之后 `++/--` 沿日历走，解引用得 date，还支持与 date 直接比较。它们**不是标准迭代器**：没有 `difference_type` 等内型定义，`iter += 5` 和 `std::advance(iter, 5)` 都编译不过——想跳步只能循环 `++` 或自己加 date。

`gregorian_calendar` 类提供最后的静态工具：`is_leap_year()`（闰年判断，百年不闰四百年再闰都对）和 `end_of_month_day(year, month)`。

运行输出（`date_time.cpp`）：

```text
迭代器: 起走一天 → 2007-Sep-29 再走十年 → 2017
闰年: 2017? false 2024? true 2000? true 1900? false（百年不闰、四百年再闰）
自检通过
```

### 7.2.5 综合运用：月历、生日与免息期

三个由浅入深的小应用，把上面的积木拼起来。

**月历**：当月第一天到月末拉一个 `day_iterator`，7 个一换行：

运行输出（`date_time.cpp`）：

```text
 1   2   3   4   5   6   7  
 8   9  10  11  12  13  14  
15  16  17  18  19  20  21  
22  23  24  25  26  27  28  
29  30  31  （2017 年 1 月共 31 天）
```

**生日推算**：2017-01-23 出生，18 岁生日是星期几、当年 1 月有几个星期日、当年多少天——`+years(18)`、迭代器数 Sunday、闰年判断三段接力：

运行输出（`date_time.cpp`）：

```text
2035-Jan-23 是星期Tue 当年 1 月有 4 个星期日 当年 365 天
```

**信用卡免息期**：这是 date_time 做"业务规则计算"的典型——消费日在记账日之前，免息期 = 到本月记账日的天数 + 20；消费日在记账日之后，记账日推到下月（**注意这里 `+= months(1)` 恰好是月末吸附安全的方向**，但若消费日是月末就值得警惕）：

```cpp
int calc_free_days(date consume_day) const {
    date bill_day(consume_day.year(), consume_day.month(),
                  static_cast<unsigned short>(bill_day_no));
    if (consume_day > bill_day)
        bill_day += months(1);                 // 过了记账日 → 下月记账
    return static_cast<int>((bill_day - consume_day).days()) + 20;
}
```

运行输出（`date_time.cpp`）：

```text
免息期: 5 号消费 A=40天 B=27天 | 15 号消费 A=30天 B=48天
```

（与第 5 版书的结论一致：月初用 A 行卡、月中用 B 行卡——用 date 代数算出来的选卡策略。）

## 7.3 Boost.Date_Time（2001）：时刻系统 posix_time

`posix_time` 在日期之下细分出时分秒：`time_duration` 是"钟表时长"（几点几分几秒加小数秒），`ptime` 是"日期 + 钟表时长"的时刻。默认精度微秒；在包含头文件前定义 `BOOST_DATE_TIME_POSIX_TIME_STD_CONFIG` 可升到纳秒（构造函数里第四个参数的解释随之从微秒变纳秒——要写分辨率无关代码，就用 `millisec()/microsec()` 这些具名单位而不是裸数字，并用 `time_duration::ticks_per_second()/num_fractional_digits()/unit()` 做运行时自省）。

### 7.3.1 time_duration

构造函数认"时分秒+小数秒"四元组，**超范围字段自动进/借位**（`1 时 60 分 60 秒 + 6.001 秒` 规范化成 `02:01:06.001000`）；也认具名子类 `hours/minutes/seconds/millisec/microsec`（可加合成任意时长）和字符串工厂 `duration_from_string("1:10:30:001")`。负值合法，`is_negative()` 判别、`invert_sign()` 取反。四则与比较全开，比 date_duration 的算力强一档（可乘可除）。

`total_seconds()/total_milliseconds()/total_microseconds()` 是"全部折算"读数，`fractional_seconds()` 只读小数秒部分——四个数各管一段，配对使用才不丢信息（见输出：01:10:30.001000 → 秒 4230、微秒 4230001000、小数秒 1000）。

```cpp
time_duration td(1, 10, 30, 1000);     // 1h10m30s + 1000 微秒
time_duration carry(1, 60, 60, 1000 * 1000 * 6 + 1000);
//        → 规范化 02:01:06.001000
time_duration sum = hours(1) + minutes(10) + seconds(30) + millisec(1);
time_duration from_str = duration_from_string("1:10:30:001");
sum == from_str;                       // true：具名单位与字符串殊途同归
time_duration::unit();                 // 00:00:00.000001 —— 最小刻度
time_duration::ticks_per_second();     // 1000000
time_duration::num_fractional_digits();// 6
```

运行输出（`posix_time.cpp`）：

```text
构造: 01:10:30.001000 ISO: 011030.001000
进位: 02:01:06.001000
子类求和 == 字符串解析? true
total: 秒4230 毫秒4230001 微秒4230001000 小数秒1000
负时长: is_negative=true invert→10h
特殊时长: not-a-date-time is_not_a_date_time=true
运算: x1<x2=true (x1+x2)=03:30:00 (x1-x2)负=true x1*5==x2*2=true
分辨率: tick/秒=1000000 小数位数=6 最小单位=00:00:00.000001
自检通过
```

### 7.3.2 ptime：日期 + 时刻

`ptime` 内部是一个 64 位整数（微秒档），轻量可拷贝。构造四条路：`ptime(date, time_duration)`（省略时长即零点）、字符串工厂 `time_from_string("2017-7-7 01:00:00")` 与 `from_iso_string("20170707T010000")`（ISO 用 T 分隔）、时钟 `second_clock/microsec_clock` 的 `local_time()/universal_time()`（秒级与微秒级、本地与 UTC 两两组合）、特殊值。

分解用 `date()` 与 `time_of_day()` 各取一半；加减时长得新时刻、两时刻相减得时长；`to_tm()/ptime_from_tm()` 与 `from_time_t()/to_time_t()` 双向对接 C 世界。

输出三件套带 T：`to_simple_string` → `2017-Feb-14 20:00:00`、`to_iso_string` → `20170214T200000`、`to_iso_extended_string` → `2017-02-14T20:00:00`。

```cpp
ptime p1(date(2017, 7, 7), hours(1));
ptime p2 = time_from_string("2017-7-7 01:00:00");
ptime p3 = from_iso_string("20170707T010000");
p1 == p2 && p2 == p3;                  // true：三种写法同一个时刻
ptime t0(date(2010, 3, 20), hours(12) + minutes(30));
ptime later = t0 + hours(3);
later - t0;                            // 03:00:00
later += months(1);                    // 月末吸附同样适用于 ptime
from_time_t(0);                        // 1970-Jan-01 00:00:00 —— Unix 纪元
```

运行输出（`posix_time.cpp`）：

```text
三种构造相等? true → 2017-Jul-07 01:00:00
时钟: microsec 读数 >= second 读数? true（同为 UTC）
分解: 日期2010-Mar-20 时刻12:30:00
运算: +3h 后差值==03:00:00 < 比较=true
运算: +1月后月份=Apr
输出: 2017-Feb-14 20:00:00 20170214T200000 2017-02-14T20:00:00
to_tm 年偏移117 时20 往返一致? true
from_time_t(0) = 1970-Jan-01 00:00:00 回转一致? true
自检通过
```

### 7.3.3 time_period、time_iterator 与两个综合件

`time_period` 与 `date_period` 是同一套区间代数在时刻粒度的翻版（`shift/expand/contains/intersects/is_adjacent`，交集空不抛异常）；`time_iterator` 以任意 `time_duration` 为步长——这是"每 10 分钟一档"这类调度的自然写法。

两个综合件值得背下来。**ptimer**：把"时钟"做成模板参数的高精度计时器——`elapsed()` 直接返回 duration（自带单位、能流输出），析构自动报时是 progress_timer 的思想在微秒世界的重现：

```cpp
template <typename Clock>
class basic_ptimer {
    // ... restart() 记起点；elapsed_dur() = Clock::local_time() - start_;
    // 析构时打印 elapsed_dur()
};
```

**work_time**：把一天切成若干 `time_period`，挂在 `std::map<time_period, string>` 上（time_period 支持比较，可作关联容器的键），查询"现在属于哪一段"就是线性找 `contains(now)` 的段——日程表、值班表的通用骨架。

运行输出（`posix_time.cpp`）：

```text
区间: tp1 逾尾=2017-Jan-01 20:00:00 与 tp2 相邻? true 相交? false
shift 后 tp1 从 13:00:00 起 在正午之后? true 现在与 tp2 相交? true
expand 后 tp2 同时包含正午与 tp1? true
步进: 10:00:00 → 11:00:00（含两端共 7 个十分钟档）
ptimer 秒钟版计 15ms 析构输出 → 00:00:00；微秒版 >= 15ms? true
8 点 → 太早了  12 点 → 上午  13 点 → 午餐  15 点 → 下午  20 点 → 还在加班?  
自检通过
```

## 7.4 Boost.Date_Time 尾声：local_time 时区

处理"地理时间"是 date_time 的第三层：`posix_time_zone` 描述时区、`local_date_time` 是带时区标签的时刻（**内部统一存 UTC**，展示时按区换算）、`tz_database` 是 CSV 时区库。C++20 `std::chrono` 的时区支持（`zoned_time` + IANA 数据库）在 2026 年才在三大编译器上补齐，这之前 Boost 的这套是唯一成熟选项。

### 7.4.1 先记一个符号坑

`posix_time_zone` 用一行 TZ 串描述时区，格式是 `"缩写 偏移 [夏令时缩写[偏移][,起始规则[/时刻],结束规则[/时刻]]]"`。**Boost 的偏移符号与 POSIX 标准相反**——官方文档（1.92）原话：`"PST-8"` 是 "eight hours west of GMT"（UTC−8）。而 POSIX 里 `TZ=CST-8` 表示 UTC+8（POSIX 约定西为正）。于是从系统 `TZ` 环境变量照抄串到 Boost 会得到镜像的时区：北京在 Boost 里必须写 `CST+8`，写 `CST-8` 会被解析成 UTC−8。实测（`base_utc_offset()` 直接给出 ±hh:mm:ss）：

运行输出（`local_time.cpp`）：

```text
时区: CST 偏移=08:00:00 有夏令时? false | PST 有夏令时? true（夏令时名=PDT）
自检通过
```

夏令时规则 `M3.2.0,M11.1.0` 读作"3 月第 2 个星期日起、11 月第 1 个星期日止"，缺省切换时刻 02:00。

### 7.4.2 local_date_time 与幽灵时刻

`local_date_time` 的两条构造路线语义不同：从 **UTC ptime** 构造最无歧义（`local_date_time(utc_ptime, tz)`）；从**本地墙钟三件套** `(date, time_duration, tz, is_dst)` 构造则要你对"是否夏令时"签字负责——落在夏令时跳跃区间里的时刻（如旧金山 2014-03-09 02:30，那天 02:00 直接跳 03:00）不存在，构造按错误策略抛异常或产出无效值。这种"幽灵时刻"的拒绝行为是时区库的正确姿势，值得专门验证：

```cpp
time_zone_ptr shz(new posix_time_zone("CST+8"));          // 北京（Boost 符号：东 +）
time_zone_ptr sfz(new posix_time_zone("PST-8PDT,M3.2.0,M11.1.0"));

ptime utc_start(date(2014, 3, 6), hours(8));              // UTC 08:00
local_date_time bj(utc_start, shz);                       // → 北京 16:00

local_date_time arrive = bj + hours(12);                  // 加法在 UTC 域里做
local_date_time sf = arrive.local_time_in(sfz);           // 再换算到旧金山
```

运行输出（`local_time.cpp`；飞行例与第 5 版书同题同答）：

```text
北京时刻: 2014-Mar-06 16:00:00 CST（utc_time() 回读一致? true）
飞行: 起飞 2014-Mar-06 16:00:00 CST → 落地(北京时间) 2014-Mar-07 04:00:00 CST → 落地(当地时间) 2014-Mar-06 12:00:00 PST
落地是否夏令时? false（3 月 6 日在 3 月第 2 个周日之后? false→否）
幽灵时刻 2014-03-09 02:30 被拒? true
跳跃前 01:30 合法? true 缩写=PST
自检通过
```

跨时区飞行 12 小时："落地(北京时间) 3 月 7 日 04:00、落地(当地时间) 3 月 6 日 12:00"——**跨过日界线日期往回走**，这只有"内部统一 UTC"的模型才能算对。

`local_time_period` 是带时区的区间，代数同 `time_period`。

### 7.4.3 tz_database 与格式化 facet

`tz_database` 从 CSV 文件装载全球时区（`tz_db.load_from_file("date_time_zonespec.csv"); tz_db.time_zone_from_region("Asia/Shanghai")`），文件随源码树发布在 `libs/date_time/data/` 下。自建一行式时区用 `posix_time_zone` 就够（本例程为了输出可复现没有依赖外部文件，走的就是这条路）。

输出格式化由三个 facet 分层负责：`date_facet` 管日期、`time_facet` 管时刻、`local_time_facet` 管本地时刻。用法是 strftime 风格格式串 → 装进 `std::locale` → `imbue` 到流：

```cpp
date_facet* df = new date_facet("%Y 年 %m 月 %d 日");
std::cout.imbue(std::locale(std::locale::classic(), df));
std::cout << date(2014, 11, 3);        // 2014 年 11 月 03 日

time_facet* tf = new time_facet("%Y 年 %m 月 %d 日 %H 点 %M 分 %S%F 秒");
// ...同上，%F 是小数秒
local_time_facet* lf = new local_time_facet("%Y-%m-%d %H:%M %Z");
// ...%Z 是时区缩写
```

运行输出（`local_time.cpp`）：

```text
区间: [2014-Mar-06 16:00:00 CST .. 2014-Mar-07 00:59:59.999999 CST] 长度 09:00:00
facet 日期: 2014 年 11 月 03 日
facet 时刻: 2014 年 11 月 03 日 21 点 50 分 00.100000 秒
facet 本地: 2014-03-06 16:00 CST
自检通过
```

**毕业档案**：C++20 `std::chrono` 终于有了日历（`year_month_day`、`weekday`、`month_day_last`...），但 **API 是重新设计的**（`sys_days + days{30}` vs `date + date_duration(30)`）——这是"半系毕业"：思想直系、接口换代。date_time 的残余场景：老代码、`date_period` 这类现成区间代数、以及时区数据库在 std 实现补齐前的过渡期。**2026 选型**：新代码日历优先 C++20 chrono；混用两套时间库时注意 `days` 在两个名字空间里都有（`boost::gregorian` 与 `std::chrono` 同开必二义），名字要全限定。

> 实测坑：`using namespace boost::gregorian` 和 `using namespace std::chrono` 同时开，`days` 直接二义（两边都有）——混用两套时间库时名字要全限定。

## 7.5 Boost.Chrono（2008）：物理层的现代范式

chrono 的世界观只有三个词：**duration**（数值 + 单位，单位是编译期分数）、**clock**（纪元 + 精度 + `now()`）、**time_point**（某时钟自纪元的 duration 读数）。它与 date_time 的分工：chrono 表达"计算机世界"的时间（单调、可测、精确），date_time 表达"人类世界"的时间（日历、时区）。

### 7.5.1 duration：单位错配在编译期被抓

`duration<Rep, Period>` 的单位是 `ratio`：`seconds` 是 `duration<int64, ratio<1>>`，`milliseconds` 是 `duration<int64, milli>`。隐式转换只允许**无损方向**（大单位 → 小单位，如 minutes → seconds）；有精度损失的方向（90 秒 → 1.5 分钟）直接编译错误，必须 `duration_cast` 显式声明"我接受截断"。想要小数结果就把 rep 换成 double：

```cpp
namespace bc = boost::chrono;
bc::seconds s(90);
bc::duration_cast<bc::minutes>(s);         // 1 minute（截断）
bc::minutes m(2);
bc::seconds s2 = m + s;                    // minutes 隐式折算 seconds：210 seconds
bc::duration<double> frac = m + s;         // double rep：无损
bc::duration_cast<bc::duration<double, boost::ratio<60>>>(frac);
                                           // 3.5 minutes
```

`duration_cast` 是纯截断；Boost 扩展了 `floor/ceil/round` 三件套补全取整语义（std::chrono 直到 C++17 才有 floor/ceil/round）：

```cpp
bc::seconds odd(3600 + 50);                // 1 小时 50 秒
bc::floor<bc::minutes>(odd);               // 60 minutes（向下）
bc::ceil<bc::minutes>(odd);                // 61 minutes（向上）
bc::round<bc::minutes>(odd);               // 61 minutes（四舍五入）
bc::round<bc::hours>(odd);                 // 1 hour
```

### 7.5.2 时钟族与 time_point

标准三时钟（`system_clock` 挂钟/`steady_clock` 单调/`high_resolution_clock` 通常是其一）加 Boost 独有的四个进程时钟（`process_real_cpu_clock` / `process_user_cpu_clock` / `process_system_cpu_clock` / `thread_clock`）——**std::chrono 至今没有进程/线程 CPU 时钟**，测 CPU 时间仍要靠它们或平台 API。`clock_string<Clock, char>::name()/since()` 能问时钟"你叫什么、从哪起算"（system 从 1970-01-01，steady 从开机）。

铁律只有一条：**测耗时只用 `steady_clock`**——`system_clock` 是挂钟，NTP 校时会回拨，可能测出"负耗时"。

`time_point` 的算术合同：点 + 时长 = 点、点 − 点 = 时长；`time_since_epoch()` 读自纪元读数。`system_clock` 独有 `to_time_t/from_time_t` 与 C 世界互通（steady 没有对应现实时刻的语义）。

```cpp
auto t0 = bc::steady_clock::now();
std::this_thread::sleep_for(std::chrono::milliseconds(50));
auto cost = bc::duration_cast<bc::milliseconds>(bc::steady_clock::now() - t0);
cost >= bc::milliseconds(50);              // true
```

（对应示例：`chrono.cpp`，含书的 steady_timer 综合——`elapsed()` 直回 duration。）

运行输出（`chrono.cpp`）：

```text
90 秒 = 1 minute(截断)
1500ms = 1 second(截断)
2 分钟 + 90 秒 = 210 seconds
double rep 下 = 3.5 minutes
count(): 210 秒 = 210000 毫秒
floor<minutes>=60 minutes ceil<minutes>=61 minutes round<minutes>=61 minutes round<hours>=1 hour
steady 读数非零? true  system 秒数 > 17 亿? true
clock_string: system=system_clock since  since Jan 1, 1970 | steady= since boot
进程实际时钟读数非零? true
耗时 >= 50ms? true
to_time_t 往返一致? true
格式化: 3661000 milliseconds 与 3661 seconds（同计数不同单位）
steady_timer >= 15ms? true
自检通过
```

（"耗时 63ms"每次都不同——它是真实测量；断言 `>= 50ms` 才是可复现的判据。）

> 实测坑（Windows 进程时钟粒度）：`进程实际时钟读数非零?` 这行前有一段一百万次浮点累加——不是演示需要，是**不烧 CPU 就读到 0**：Windows 进程 CPU 时间的度量粒度约 15.6ms（系统节拍），程序启动初期累积的 CPU 时间不到一个节拍。本机实测更进一步的怪象：同样粒度下 `process_user_cpu_clock` 累积比 `process_real_cpu_clock` 慢得多，短任务里前者几乎恒 0，想稳定读到非零请用 real 时钟。

**毕业档案**：`std::chrono`（C++11，直系），且 std 版在 C++17 补了 floor/ceil/round、C++20 长出了日历和时区。Boost 版的残余价值：进程/线程 CPU 时钟、`chrono_io` 的 duration 流输出（`3661000 milliseconds` 这种带单位的打印，std 要等 C++20 `std::format` 的 chrono 特化）。

## 7.6 Boost.Ratio（C++11 同船毕业的地基）

`std::chrono::milliseconds` 为什么能"零开销换算单位"？因为单位比是**编译期分数**——`ratio<N, D>` 就是那个分数：构造时自动约分（`ratio<6,12>` 即 `1/2`），四则（`ratio_add/subtract/multiply/divide`）与比较（`ratio_less` 等）全在编译期完成，运行时零开销。它几乎不单独出场——存在感全在 chrono 的单位定义和"编译期单位制运算"里（物理仿真中 kg·m/s² 的类型追踪）。

SI 前缀成品表从 `atto`（10⁻¹⁸）到 `exa`（10¹⁸）都是现成的 typedef；**存储业的 1024 进位（kibi/mebi/gibi）不在表里**，要自己定义——而 `kilo < kibi`（1000 < 1024）这种比较本身就是编译期断言的天然素材：

```cpp
using kibi = boost::ratio<1024>;
boost::ratio_less<boost::kilo, kibi>::value;        // true
boost::ratio_divide<mebi, boost::mega>::num;        // 16384/15625 约分前的分子？不——
                                                    // 是 (2^20)/(10^6) 约分后的读数
boost::ratio_string<boost::kilo, char>::symbol();   // "k"
boost::ratio_string<boost::kilo, char>::prefix();   // "kilo"
boost::ratio_string<boost::ratio<22,7>, char>::prefix();  // "[22/7]"（无特化给原样）
```

`ratio_string` 给单位配文字（`symbol()` 缩写、`prefix()` 全名，预定义单位有特化，自定义单位给 `[N/D]` 原样）。数字单位的语法糖是自定义字面值：

```cpp
// C++23 起 operator"" _kb（引号后带空格）已弃用，必须写 operator""_kb
constexpr std::intmax_t operator""_kb(unsigned long long n) {
    return static_cast<std::intmax_t>(n) * 1024;
}
constexpr std::intmax_t operator""_gb(unsigned long long n) { /* ... */ }
2_gb == 2048LL * 1024_kb;               // true
```

（对应示例：`ratio.cpp`；与 `std::ratio` 完全同型——`static_assert(std::is_same<boost::ratio<1,2>, std::ratio<1,2>>::value)` 直接通过。）

运行输出（`ratio.cpp`）：

```text
half = 1/2
ratio<6,12> 约分 = 1/2
1/2+1/3 = 5/6
1/2*1/3 = 1/6
1/2 < 1/3 ? false
fortnight = 1209600 秒的倍数
kilo = 1000  milli = 1/1000
kilo < kibi? true  mebi/mega = 16384
kilo: k / kilo  nano: n / nano  自定义: [22/7]
2_gb = 2147483648  10_kb = 10240  2gb == 2048*1024kb? true
自检通过
```

> 实测坑（C++26）：第 5 版书里的字面值写法 `operator"" _kb`（引号后带空格）在新标准下触发弃用告警 C5311——C++23 起必须写 `operator""_kb`。老书代码迁移时这是高频告警点。

**毕业档案**：`std::ratio`（C++11，直系）。单独使用场景只有编译期单位制运算；其余场合它都藏在 chrono 的单位里。

---

## 本章小结

四件套各就各位：**timer** 给"这个函数多慢"的一行答案（V2 三表同测，V1 进博物馆）；**date_time** 管人类时间（日历运算、时区、区间代数，C++20 才有 std 对应）；**chrono** 管机器时间（duration/clock/time_point，编译期单位安全）；**ratio** 是 chrono 的地基。选型口诀：测耗时 `cpu_timer`/`steady_clock`，算日子 `date_time`（或 C++20 chrono 日历），做单位安全运算 `chrono`，都别混开名字空间。

> 上一章：[06 · 正则与随机](06-regex-random.md) ｜ 下一章：[08 · 无序与哈希](08-unordered.md) ｜ 返回：[README](../README.md)
