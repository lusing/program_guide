# 27 · 标准库拾遗：时间、随机数与命令行

> 示例：[`examples/ch27_stdlib.adb`](../examples/ch27_stdlib.adb)
> 运行：`./run-all.sh 27`

刘炳文《程序设计语言 Ada》§7.9 列出了 1993 年一台 PC 上"全部"
的预定义程序包——**七个**：`CALENDAR`、`SEQUENTIAL_IO`、
`DIRECT_IO`、`IO_EXCEPTIONS`、`TEXT_IO`、`SYSTEM`、`STANDARD`
（外加两个类属子程序）。今天的 GNAT 附带**数百个**预定义库单元。
本教程已沿途覆盖了大多数常客（Text_IO 三件套见 [18](18-file-io.md)/
[19](19-file-io-full.md)，Containers 见 [23](23-containers.md)，
契约见 [24](24-contracts.md)）；本章把剩下的三类"老书绕不开、
新教程常忘了讲"的一次补齐：**时间**（Calendar/Real_Time）、
**随机数**（Ada.Numerics）、**命令行**（Command_Line）——最后
把老书附录 2 的 `STANDARD` 包（看不见的地基）讲清楚。

---

## 27.1 Ada.Calendar：墙上时钟

老书 §16.5 为了让响铃任务每分钟一响，第一次用到 `CALENDAR`——
今天它是 `Ada.Calendar`，日历运算的全家桶。核心类型只有一个
私有的 `Time`，围绕它的是"一拆一组一算"：

```ada
with Ada.Calendar;
...
Now  : constant Ada.Calendar.Time := Ada.Calendar.Clock;   -- 此刻
Y    : Ada.Calendar.Year_Number;                           -- 1901..2099
M    : Ada.Calendar.Month_Number;                          -- 1..12
D    : Ada.Calendar.Day_Number;                            -- 1..31
Secs : Ada.Calendar.Day_Duration;                          -- 0..86400.0
Ada.Calendar.Split (Now, Y, M, D, Secs);      -- 拆：Time → 日历字段
Dawn : constant Ada.Calendar.Time :=
  Ada.Calendar.Time_Of (2026, 10, 13);         -- 组：日历字段 → Time
```

**时间算术**是 `Time` 的灵魂：`Time ± Duration` 得 `Time`，
`Time − Time` 得 `Duration`（定长秒数），六个比较运算符照常工作：

```ada
Dusk : constant Ada.Calendar.Time :=
  Ada.Calendar.Time_Of (2026, 10, 13, 12 * Hours);  -- 正午
Gap  : constant Duration := Dusk - Dawn;
-- Gap = 43200.0（12 小时 = 43200 秒）
```

`Duration` 是预定义的**定长定点类型**（第 22 章的近亲），
`delay` 语句吃的正是它。可读性习惯（老书 §16.5 原话推荐）：

```ada
Seconds : constant := 1.0;
Minutes : constant := 60.0;
Hours   : constant := 3600.0;
-- delay 3 * Hours + 25 * Minutes + 8 * Seconds;   -- 3h25m08s
```

普通实数表达式自动并入 `Duration`，一眼可读。

**日历合法性**由 `TIME_Error` 把关——`Time_Of (2026, 2, 30)`
（2 月没有 30 日）、月份 13、`Time + Duration` 溢出 2099 年上限，
都会引发它。示例实测捕获：

```text
  Time_Of (2026, 2, 30) → TIME_Error（日历不合法）
```

### Ada.Calendar.Formatting：现成的格式化

`Ada.Calendar.Formatting`（Ada 2005）是日历的"瑞士军刀"：

| 设施 | 用法 |
|------|------|
| `Image (T)` | `"2026-10-13 12:53:12"` 一行搞定（替代手拼 Split 字段） |
| `Day_Of_Week (T)` | 返回 `Day_Name` 枚举（Monday…Sunday），星期几不用自己算 |
| `Split`/`Time_Of` | 带亚秒（`Leap_Seconds` 版本还有闰秒参数）的加强版 |
| `Year`/`Month`/`Day`/`Seconds` | 单字段快捷函数 |

实测：2026-10-13 是 `TUESDAY`；`Image` 直接给出可读时间戳
（[18 章](18-file-io.md)的日志追加用的就是它）。

**实测坑（时区）**：GNAT 的 `Ada.Calendar.Split`/`Time_Of` 按
**本地时区**解释，而 `Formatting.Image` 缺省 `Time_Zone => 0`
按 **UTC** 显示——本地构造的正午 `Time_Of (…, 12*Hours)` 用
缺省 `Image` 打出来是 `04:00:00`（北京时间 −8h）。要本地时刻
就显式给偏移：

```ada
Ada.Calendar.Formatting.Image
  (Now, Time_Zone => Ada.Calendar.Time_Zones.UTC_Time_Offset (Now))
```

写进日志、发往别机的时刻戳请想清楚时区——这是日历库唯一
容易踩的深坑。

## 27.2 Ada.Real_Time：单调钟

墙上钟有两个致命伤：**会被对时拨动**（NTP 一校时，`Clock` 可能
倒退），**精度有限**。测耗时、做节拍请改用 `Ada.Real_Time`——
**单调钟**：只增不减、不受校时影响、精度实现定义（通常优于
微秒）：

```ada
with Ada.Real_Time;
...
declare
   use Ada.Real_Time;
   Start : Time;                       -- 注意：这是 Real_Time.Time，
begin                                  -- 与 Calendar.Time 是两个类型！
   Start := Clock;
   delay 0.02;                         -- 干一小段活
   Put_Line (Boolean'Image (Clock - Start >= Milliseconds (20)));
   -- TRUE：Time 差是 Time_Span，Milliseconds(20) 造同样的量纲
end;
```

`Real_Time` 自带一套量纲家族，避免拿裸秒数做单位换算：
`Milliseconds/Microseconds/Nanoseconds (N)` 造 `Time_Span`，
`To_Duration (Time_Span)` 折回秒。实测 `Microseconds (1000)`
= `0.001000000` 秒。

选型口诀：**日历问题（几月几日、几点）用 Calendar，物理时间
（多久、间隔）用 Real_Time**；[17 章](17-select-family.md)的
周期任务无漂移延迟在两者之间选了前者（`Duration` 可直接喂
`delay`），嵌入式实时系统更常用后者 + `delay until`。

## 27.3 随机数：Ada.Numerics

老书 §6.5 的例 6-5 让读者**自己写**线性同余发生器——
`X := X * 29 + 37; X := X mod 1000`，§7.2 再包装成 `RANDOM`
程序包（`RAND_VAL := 999` 作种子，`(259 * RAND_VAL) mod 4096`）。
原因很简单：**Ada 83 标准没有随机数库**。今天这是两行实例化
的事：

### 浮点均匀分布：Float_Random

`Ada.Numerics.Float_Random` 是**普通包**（不是泛型！），产出
`[0, 1)` 区间的均匀 `Float`：

```ada
package FR renames Ada.Numerics.Float_Random;
G : FR.Generator;
begin
   FR.Reset (G, 42);           -- 带种子：此后序列完全确定
   X := FR.Random (G);         -- 每次调用吐一个 [0,1) 的数
```

### 离散分布：Discrete_Random（泛型）

掷骰子、抽枚举值用 `Ada.Numerics.Discrete_Random`——它是泛型
包，实参是**具名离散子类型**（匿名子界不能直接当泛型实参，
本章示例实测的第一坑）：

```ada
subtype Die_Face is Integer range 1 .. 6;
package Dice is new Ada.Numerics.Discrete_Random (Die_Face);
G : Dice.Generator;

type Color is (Red, Green, Blue);
package CR is new Ada.Numerics.Discrete_Random (Color);   -- 枚举也行
```

```text
  Float_Random (种子 42) 前 5 个:  6.87270E-01  8.98271E-01  4.87679E-01 ...
  掷骰子 (种子 42) 10 次:  1 6 5 5 1 6 5 3 5 6
  随机颜色 (种子 7) 5 次: RED GREEN GREEN BLUE GREEN
```

### Reset 的两种用法：真随机与可复现

`Reset (G)` 不带参数用系统熵（真随机，每次运行不同）；
**`Reset (G, 种子)` 生成完全确定的序列**——同一编译器上跨运行
逐位一致。这不是缺陷是特性：**自动化测试的确定性输出**全靠它
（本教程的示例能在 CI 里逐字节比对，就是给随机数钉了种子）。
蒙特卡洛一例（20000 点估 π，种子 2026）：

```text
  蒙特卡洛 π ≈  3.15020E+00（20000 点，种子 2026，跨运行可复现）
```

顺带一提：正态分布、指数分布去 `Ada.Numerics.Normal_Random` 等
GNAT 扩展或自己用均匀数变换（Box–Muller）；教学范围够用就好。

## 27.4 Ada.Command_Line：main 的参数

老书时代的 Ada 主程序连"命令行参数"概念都无从谈起（Meridian
在 DOS 上跑）。标准库的补课单元：

```ada
with Ada.Command_Line;
...
Ada.Command_Line.Argument_Count      -- 参数个数（程序名不算）
Ada.Command_Line.Argument (I)        -- 第 I 个参数（1 起）
Ada.Command_Line.Command_Name        -- 程序名（调用时的写法）
Ada.Command_Line.Set_Exit_Status (N) -- 用退出码 N 结束（0 = 成功）
```

示例在无参调用下实测 `Argument_Count = 0`。写工具类程序时
把参数解析放主过程开头、配 `Set_Exit_Status` 报成败——shell
脚本就能接住你的程序（`run-all.sh` 判定退出码正是这个约定）。
配套的 `Ada.Environment_Variables`（查/设环境变量）同属"进程
环境"一族，按需 `with`。

## 27.5 看不见的地基：Standard

老书附录 2 全文照抄的 `package STANDARD`，是唯一**不用 with**
的库单元——`Boolean`、`Integer`、`Float`、`String`、`Duration`
以及 `Constraint_Error` 等异常全在这里，编译器假定每个编译
单元都隐含 `with Standard; use Standard;`。三个值得知道的点：

1. **预定义操作符都是函数**。附录 2 里 `"+" (LEFT, RIGHT : in
   INTEGER) return INTEGER` 一行行写得明白——这正是 [05 章]
   (05-subprograms.md)能重载 `"+"`、[10 章](10-packages.md)能
   给分数类型定义 `"+"` 的语言根基：操作符只是名字特殊的函数。
2. **具体定义"实现说了算"**。`Integer` 的范围、`Float` 的精度
   都是 `implementation_defined`——所以第 03 章反复强调用
   `'First`/`'Last`/`digits` 查询，别把 2147483647 写死在代码里。
3. **异常全家福**：`Constraint_Error`、`Program_Error`、
   `Storage_Error`、`Tasking_Error`（[17 章](17-select-family.md)
   刚用过它）住在 `Standard`；`NUMERIC_ERROR` 已沦为 J.6 的
   弃用别名（等同 `Constraint_Error`），老书里它还是独立异常。

`System`（`Address`、`Min_Int` 等实现常量，[21 章](21-low-level.md)
的常客）是它的难兄难弟——同样"预定义、依赖实现"。

## 27.6 本章示例的完整输出

```text
=== 标准库拾遗：时间 / 随机数 / 命令行 ===

--- 1. Ada.Calendar ---
  Split 拆解: 2026-10-13（墙上钟，可被系统对时拨动）
  Image 本地时刻: 2026-10-13 12:53:12
  2026-10-13 正午 - 零点 =  43200.000000000 秒
  2026-10-13 是星期TUESDAY
  Duration 习惯写法: 3*Hours+25*Minutes+8*Seconds =  12308.000000000
  Time_Of (2026, 2, 30) → TIME_Error（日历不合法）

--- 2. Ada.Real_Time ---
  测得耗时 >= 20ms : TRUE
  Time_Span 单位族: Microseconds(1000) =  0.001000000 秒

--- 3. 随机数 ---
  Float_Random (种子 42) 前 5 个:  6.87270E-01  8.98271E-01  4.87679E-01  5.91717E-01  8.65997E-01
  掷骰子 (种子 42) 10 次:  1 6 5 5 1 6 5 3 5 6
  随机颜色 (种子 7) 5 次: RED GREEN GREEN BLUE GREEN
  蒙特卡洛 π ≈  3.15020E+00（20000 点，种子 2026，跨运行可复现）

--- 4. Ada.Command_Line ---
  Argument_Count =  0（run-all 不带参数；命令名走 Command_Name）

标准库拾遗演示完成。
```

（第 1 节的两行墙上钟内容随运行时刻变化；随机数各行因种子
钉死而跨运行逐位一致。）

## 27.7 小结

| 单元 | 要点 |
|------|------|
| `Ada.Calendar` | `Time` 私有类型；Split/Time_Of/Clock；`Time±Duration`、`Time−Time=Duration` |
| `TIME_Error` | 日历不合法（2 月 30 日、月份越界）即引发 |
| `Formatting` | `Image` 一行时间戳、`Day_Of_Week` 星期几；**缺省 UTC**，本地要传 `Time_Zone` |
| `Ada.Real_Time` | 单调钟（不受校时影响）；`Time_Span` + `Milliseconds` 族 |
| 选型 | 日历问题 Calendar / 物理时长 Real_Time |
| `Float_Random` | 普通包非泛型；[0,1) 均匀浮点 |
| `Discrete_Random` | 泛型；实参须**具名**子类型；整数子界与枚举通吃 |
| `Reset (G, 种子)` | 确定性序列 = 可测试输出；无参 Reset = 真随机 |
| `Command_Line` | Argument_Count/Argument/Set_Exit_Status；接 shell 的退出码约定 |
| `Standard` | 隐式 with 的地基；操作符即函数；`Integer` 实现定义 |

老书的七个预定义包到今天膨胀成了数百个库单元，但"预定义包
=语言送给你的第一批现成积木"这个世界观没变。下一章的附录里
有一张按家族整理的**常用属性速查表**——那是读老书附录 3 的
正确姿势。

---
上一章：[26 独立编译与可见性](26-separate-compilation.md) ｜ 下一章：[28 附录](28-appendix.md) ｜ 返回：[README](../README.md)
