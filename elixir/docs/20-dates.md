# 20 · 日期与时间

> 对应示例：`examples/20_dates/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

日期时间是每门语言都绕不开的深水区，Elixir 的解法是用**四种不同的结构**
表达四个不同的概念：

| 结构 | 字面量 | 表示 | 时区 |
|---|---|---|---|
| `Date` | `~D[2026-09-21]` | 日历上的一天 | 无 |
| `Time` | `~T[12:34:56.789]` | 一天内的钟点 | 无 |
| `NaiveDateTime` | `~N[2026-09-21 08:00:00]` | 日 + 时刻 | 无 |
| `DateTime` | `~U[2026-09-21 08:00:00Z]` | 带时区的时刻 | 有（零依赖时只有 UTC） |

选型先回答两个问题：**需不需要具体钟点？需不需要时区？** 生日、合同到期日
用 `Date`；每天的定时时刻用 `Time`；「本地墙钟记录」用 `NaiveDateTime`；
跨系统传输、需要绝对时间点用 `DateTime`。混用类型正是本章后半的主要坑源。

## 20.1 四个字面量与字段拆解

sigil（符咒）是 Elixir 对「自带格式的字面量」的写法：`~D`、`~T`、`~N`、`~U`
中括号里写 ISO 8601 格式，编译期解析，格式非法直接编译报错。字段都是普通的
结构体字段，可以显式读取：

```elixir
def date_info(%Date{} = d) do
  %{
    year: d.year,
    month: d.month,
    day: d.day,
    wday: Date.day_of_week(d),      # ISO：1=周一 .. 7=周日（不是美式的周日=0）
    quarter: Date.quarter_of_year(d)
  }
end

def time_info(%Time{} = t) do
  %{hour: t.hour, minute: t.minute, second: t.second,
    microsecond: elem(t.microsecond, 0)}
end
```

注意 `microsecond` 字段不是整数而是 **`{值, 精度}` 元组**：
`~T[12:34:56.789]` 里是 `{789000, 3}`，`~T[12:34:56]` 里是 `{0, 0}`。
值与打印精度分开存储——这一点在 20.6 会反过来咬一口。

```text
-- 1. ~D/~T/~N/~U 是不同类型；字段显式可读 --
  date_info => %{month: 9, day: 21, year: 2026, quarter: 3, wday: 1}
  time_info => %{microsecond: 789000, second: 56, minute: 34, hour: 12}
  无时区时刻 => ~N[2026-09-21 08:00:00]
```

（再次提醒：1.20 里原子键 map 的 inspect 顺序不按字母序，但等值与顺序无关。）

## 20.2 日期算术：月末按日历推进，不溢出

`Date.add/2` 按**日历日**平移，`Date.diff/2` 给两个日期相差的天数：

```elixir
def shift_days(%Date{} = d, days), do: Date.add(d, days)
def days_between(%Date{} = later, %Date{} = earlier), do: Date.diff(later, earlier)
```

关键性质：**月末算术不会制造出非法日期**。1 月 31 日加一天是 2 月 1 日，
绝不会出现「2 月 31 日」；闰年规则也内建：

```text
-- 2. add/diff 按日历走，月末不溢出 --
  加 10 天 => 2026-10-01
  相差 => 10
  1-31 +1 => 2026-02-01
```

`Date.add` 的参数是「天」。想加一个月、一年没有对应函数——「一个月」长度
不固定，正确做法是用 `Date.new!/3` 重组字段并自己处理年末进位，或者用
下一章会提到的 `Date.shift/2`（带 `:months` 选项的日历平移）。

## 20.3 Date.range：闭区间，可枚举

`Date.range/2` 构造一个**两端都包含**的日期区间，而且它本身就是 `Enumerable`，
第 7 章的 Enum 全套直接可用。但它**不是列表**——`length/1` 会抛
`ArgumentError`，计数用 `Enum.count/1`：

```elixir
def workdays(%Date{} = from, %Date{} = to) do
  # 1.20 起 Date.range/2 不允许隐式逆序（运行告警），逆序必须显式传 -1。
  step = if Date.compare(from, to) == :gt, do: -1, else: 1

  Date.range(from, to, step)
  |> Enum.count(fn day -> Date.day_of_week(day) in 1..5 end)
end
```

1.20 的新规矩：起点晚于终点时，`Date.range/2` 会发告警要求你改用
`Date.range/3` 显式传步长 `-1`——防止「悄悄得到逆序区间」的笔误。

```text
-- 3. Date.range 两端包含；枚举计数 --
  9 月工作日 => 22
```

2026 年 9 月有 30 天、22 个工作日。区间是惰性枚举，跨一整年也不会先造
365 个日期的列表。

## 20.4 时刻算术：秒级 add/diff，钟点滚动

有了具体钟点，算术单位就换成**秒**。`NaiveDateTime.add/2`、
`NaiveDateTime.diff/3` 处理无时区时刻，`diff` 的第三参数可选单位：

```elixir
def add_seconds(%NaiveDateTime{} = n, seconds), do: NaiveDateTime.add(n, seconds)

def seconds_between(%NaiveDateTime{} = later, %NaiveDateTime{} = earlier, unit \\ :second) do
  NaiveDateTime.diff(later, earlier, unit)   # :second/:millisecond/:microsecond/:nanosecond
end
```

`Time` 只有钟点、没有日期，加秒的语义是**按 24 小时自动取模**——跨午夜
绕一圈，不保留「跨了几天」的信息：

```elixir
def roll_hours(%Time{} = t, seconds), do: Time.add(t, seconds)
```

```text
-- 4. NaiveDateTime 秒级 add/diff；Time 跨午夜取模 --
  +3661 秒 => 2026-09-21 09:01:01
  相差秒 => 7200
  23 点 +2 小时 => 01:00:00
```

23:00 加 7200 秒得到次日 01:00，但 `Time` 里只剩 `01:00:00`，「第二天」
这个事实被丢掉了。需要保留跨天信息就别用 `Time`，用 `NaiveDateTime`。

## 20.5 与 Unix 整数互转；零依赖下的固定偏移

`DateTime` 与 Unix 时间戳可以无损互转，这是**跨系统存储与传输最稳的形态**：

```elixir
def unix_epoch(ms), do: DateTime.from_unix!(ms, :millisecond)
def to_unix(%DateTime{} = dt), do: DateTime.to_unix(dt)
```

零依赖工程里更常见的需求是：我有一个「北京墙钟」和一个固定的 UTC 偏移，
怎么换成绝对时间点？答案是**先减偏移、再解释为 UTC**：

```elixir
def wall_to_unix(%NaiveDateTime{} = wall, offset_seconds) do
  utc_naive = NaiveDateTime.add(wall, -offset_seconds)
  {:ok, dt} = DateTime.from_naive(utc_naive, "Etc/UTC")
  DateTime.to_unix(dt)
end
```

偏移东向为正：北京 `+28800`，纽约 `−18000`。北京 9 月 21 日 08:00 减去
8 小时正好是 UTC 同日 00:00：

```text
-- 5. 与 Unix 整数互转；固定偏移=先减偏移再转 UTC --
  epoch 0 => 1970-01-01 00:00:00.000Z
  UTC->unix => 1789948800
  北京 08:00(+8) 的 unix => 1789948800
```

注意「固定偏移」四个字——它只对没有夏令时、偏移永不变的场景成立。
DST 切换的地区，同一个北京对应纽约的偏移一年里会变两次，那需要真正的
时区数据库（下一节）。

## 20.6 命名时区坑：零依赖只有 UTC

这是本章的核心坑。`DateTime.shift_zone/2` 想把 UTC 时刻换到命名时区，
`DateTime.new/3` 想直接构造命名时区的时刻——在没有加载时区数据库的
零依赖工程里，**所有非 UTC 时区串一律返回同一个 error tag**：

```elixir
def shift_error(time_zone) when is_binary(time_zone) do
  DateTime.shift_zone(~U[2026-09-21 00:00:00Z], time_zone)
end

def new_local(%Date{} = d, %Time{} = t, time_zone) do
  DateTime.new(d, t, time_zone)
end
```

```text
-- 6. 未装时区数据库：命名时区（含 Etc/GMT±n）全返回 error tag --
  Asia/Shanghai => {:error, :utc_only_time_zone_database}
  new 命名时区 => {:error, :utc_only_time_zone_database}
  new Etc/UTC => {:ok, ~U[2026-09-21 08:00:00Z]}
```

实测几个反直觉的点：

- 唯一可用的时区串是 **`"Etc/UTC"`**。连裸 `"UTC"` 都不行。
- **`"Etc/GMT-8"` 也不行**——它不是固定偏移语法，而是需要数据库的命名区。
  零依赖下没有任何「写个串就能表达 +8」的捷径，只能走 20.5 的显式偏移。
- 需要命名时区（DST 规则、历史变更）时，依赖里加 `tzdata`，并在
  `config/config.exs` 配置 `config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase`。

另外留意最后一行输出没有 `.000`：从 `~T[08:00:00]` 构造时，微秒精度元组
是 `{0, 0}`，精度 0 被结构体重现了；你写 `~U[...08:00:00.000Z]` 字面量
则是精度 3。**两个值相等，inspect 外观却不同**，doctest 里尤其容易踩。

## 20.7 比较：同类三态，跨类不可比

四种结构各自有 `compare/2`，返回排序三原子 `:lt` / `:eq` / `:gt`。
但比较函数**只接受同类型**——`Date` 比 `Time`、甚至 `NaiveDateTime`
比 `DateTime` 都会直接抛 `FunctionClauseError`。写一个兜底函数把跨类型
情况变成显式 tag，比让进程崩在比较上稳妥：

```elixir
def safe_compare(%DateTime{} = a, %DateTime{} = b), do: DateTime.compare(a, b)
def safe_compare(%NaiveDateTime{} = a, %NaiveDateTime{} = b), do: NaiveDateTime.compare(a, b)
def safe_compare(%Date{} = a, %Date{} = b), do: Date.compare(a, b)
def safe_compare(%Time{} = a, %Time{} = b), do: Time.compare(a, b)
def safe_compare(_a, _b), do: {:error, :incomparable}
```

```text
-- 7. 同类型比较三态；跨类型不可比（tag 隔离，不让它崩） --
  日期比较 => gt
  跨类型 => {:error, :incomparable}
```

实践中「一个字段在不同记录里类型不一致」往往是上游建模问题：同一含义的
时间在系统里只能选一种结构，跨类型比较的需求本身就是信号。

## 20.8 要点小结

```text
  Date/Time/NaiveDateTime/DateTime 按「有无钟点、有无时区」四选一，别混用
  日期算术按天（Date.add），时刻算术按秒（NaiveDateTime.add）；月末不溢出
  Date.range 闭区间、可枚举、不是列表；逆序在 1.20 必须显式 Date.range/3
  存储传输用 Unix 整数或 ~U；固定偏移=墙钟减偏移再解释为 Etc/UTC
  零依赖只有 "Etc/UTC"：命名时区（含 Etc/GMT-8）全是 utc_only_time_zone_database
  比较只认同类型；微秒 {值,精度} 元组会影响 inspect 外观
  确定性程序绝不打印「今天/现在」——本章全部用固定日期
```

## 20.9 坑位清单

1. **四种类型不是一种类型的四种写法**。`~D` 没有钟点、`~N` 没有时区，
   函数不接受混用；建模时一个含义只选一种，别在字段里今天存 Date 明天存 DateTime。
2. **`Date.day_of_week` 是 ISO 编号 1=周一..7=周日**，不是其他语言常见的
   周日=0。按周末过滤写 `wday in 1..5`，别写 `wday < 6`。
3. **`Date.range` 是结构体不是列表**。`length(range)` 抛 ArgumentError；
   用 `Enum.count`、`Enum.member?`。区间两端都包含，差一天的区间也是两个元素。
4. **1.20 隐式逆序区间会告警**。起点晚于终点必须 `Date.range(from, to, -1)`；
   公共函数里根据比较结果选步长，才能双向都干净。
5. **加「一个月」没有现成函数**。月份长度不固定、年末要进位；用
   `Date.new!/3` 重组或日历 shift 选项，并自己决定「3-31 加一个月」该是几号。
6. **`Time.add` 跨午夜只剩钟点**。23:00 +2h = 01:00，「次日」信息丢失；
   需要跨天事实的场景用 NaiveDateTime，别用 Time 硬扛。
7. **零依赖唯一时区串是 `"Etc/UTC"`**。`"UTC"`、`"Etc/GMT-8"`、
   `"Asia/Shanghai"` 全部返回 `{:error, :utc_only_time_zone_database}`；
   固定偏移只能显式存偏移整数（20.5 的算法），命名时区要加 tzdata 依赖。
8. **微秒是 `{值, 精度}`，精度影响打印**。`~T[08:00:00]` 构造出的
   DateTime 打印没有 `.000`，与写死 `~U[...08:00:00.000Z]` 的 doctest
   外观不同（值相等）；doctest 期望值要照实测写。
9. **跨类型比较直接崩**。Date/Time、Naive/DateTime 互比是 FunctionClauseError；
   边界数据用 tag 兜底（`:incomparable`），并回头检查上游类型一致性。
10. **别在输出里调用「今天/现在」**。`Date.utc_today/0`、`DateTime.utc_now/0`
    的结果随运行时刻变化，直接破坏第 5 层逐字节比对；教程和测试一律固定日期，
    需要当前时间的生产代码把时钟作为参数传入。

---

下一章反过来审视我们一路在写的测试本身：[21 · 测试 ExUnit](21-testing.md)
——`describe`/`setup`/context 组织、doctest 的边界、`capture_io`/`capture_log`
捕获副作用、`assert_receive` 断言消息，以及 Elixir 社区「不 mock」的测试哲学。
