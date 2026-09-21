# 17 · 时间与随机

> 对应示例：`examples/17_time_random/`

## 17.1 vbcompat.bi：日期函数的家

`Now`、`Format`、`DateSerial`、`DateAdd`、`DateDiff`、`Year/Month/Day/Hour/Minute/Second` 全部住在 **`vbcompat.bi`** 里——不 `#Include Once "vbcompat.bi"` 就全是"Variable not declared"。

## 17.2 Timer：间隔测量

```freebasic
Var t0 = Timer
Sleep 60
Var dt = Timer - t0          ' ≈ 0.06 秒
```

**Windows 实测：`Timer` 返回开机以来的秒数**（不是很多文档说的"自午夜"——本机值 28 万秒 vs 自午夜 7 万秒，对不上）。**Linux 实测（1.10.2）：返回 Unix epoch 秒**（自 1970-01-01，形如 1790007793.75）。两边绝对语义不同，但做**间隔**测量都正合适；要墙钟时间用 `Now`。

## 17.3 Now 与 Format

```freebasic
Dim d As Double = Now                    ' OLE 序数日期（Double，自 1899-12-30 的天数）
Print Format(Now, "yyyy-mm-dd hh:nn:ss") ' 2026-09-19 19:19:40
Print Year(Now); Month(Now); Day(Now)
Print Hour(Now); Minute(Now); Second(Now)
```

- `Format(Now)` 不带模式打出的是裸 Double——没意义，永远带模式。
- **分钟占位符是 `n`/`nn`，不是 `m`**（`m` 是月份）——VB 家族传统，写错差 30 天。

## 17.4 DateSerial / DateAdd / DateDiff

```freebasic
Var d0 = DateSerial(2004, 9, 1)                 ' 构造日期
Var d1 = DateAdd("m", 3, d0)                    ' 加 3 个月：2004-12-01
Var days = DateDiff("d", d0, Now)               ' 相差天数
```

`DateAdd/DateDiff` 的单位串：`"yyyy"` 年、`"m"` 月、`"d"` 日、`"h"` 时、`"n"` 分、`"s"` 秒（又是 `n` 当分钟）。

## 17.5 随机数

```freebasic
Randomize 42          ' 确定性种子：同种子 → 同序列（实测逐位复现）
Dim r As Double = Rnd ' [0, 1)：含 0 不含 1
Dim dice As Integer = Int(Rnd * 6) + 1     ' 1..6 的骰子
Randomize             ' 不带参：用系统时间做种子（每次运行不同）
```

- `Randomize 42` 的确定性是**可测性工具**：游戏回放、蒙特卡洛复现、单元测试全靠它（24 章贪吃蛇的"确定性演示模式"就是种子固定）。
- `Rnd` 上界开区间：一万次抽样最大值恒 < 1（实测）。
- `Int(Rnd * n) + 1` 是整数区间标准式；`Int` 向下取整（03 章）。

## 17.6 高精度计时

`Timer` 是 Double 秒（本机分辨率约微秒级，够用）。要纳秒级：Windows 用 Win32 `QueryPerformanceCounter`，Linux 用 `clock_gettime(CLOCK_MONOTONIC)`（20 章互操作示例里有双平台现成写法）。

## 17.7 坑位清单（1.10.1 实测）

1. 日期/Format 函数都要 **`#Include Once "vbcompat.bi"`**。
2. `Timer` 绝对语义随平台：**Windows = 开机至今秒数，Linux = Unix epoch 秒**——都不是自午夜；只拿它做间隔，别拿它当日历。
3. `Format` 分钟是 `n`，`m` 是月份。
4. `Randomize n`（带种子）确定性；`Randomize`（无参）按时间——测试里永远用前者。
5. `Rnd ∈ [0,1)`：`Int(Rnd * n)` 产 0..n-1，加 1 才是 1..n。
