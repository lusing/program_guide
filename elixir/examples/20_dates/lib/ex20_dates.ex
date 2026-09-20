defmodule Ex20Dates do
  @moduledoc """
  第 20 章示例：日期与时间。

  四类结构按「带不带时区、带不带具体时刻」区分：Date（日历日）、Time（钟点）、
  NaiveDateTime（无时区的日+时刻）、DateTime（UTC 时刻）。本章演示字面量、
  字段拆解、日历算术与日期区间、秒级时刻算术、与 Unix 整数互转、
  零依赖下唯一可行的「固定偏移」换算，以及命名时区的经典坑。
  """

  # ------------------------------------------------------------
  # 1. 四个字面量与字段
  # ------------------------------------------------------------

  @doc """
  拆解 Date 字段：ISO 星期 1=周一..7=周日；季度 1..4。

      iex> Ex20Dates.date_info(~D[2026-09-21])
      %{year: 2026, month: 9, day: 21, wday: 1, quarter: 3}

  """
  @spec date_info(Date.t()) :: %{
          year: pos_integer(),
          month: 1..12,
          day: 1..31,
          wday: 1..7,
          quarter: 1..4
        }
  def date_info(%Date{} = d) do
    %{
      year: d.year,
      month: d.month,
      day: d.day,
      wday: Date.day_of_week(d),
      quarter: Date.quarter_of_year(d)
    }
  end

  @doc """
  拆解 Time 字段；微秒取整数部分（精度单独存在 microsecond 元组第二位）。

      iex> Ex20Dates.time_info(~T[12:34:56.789])
      %{hour: 12, minute: 34, second: 56, microsecond: 789000}

  """
  @spec time_info(Time.t()) :: %{
          hour: 0..23,
          minute: 0..59,
          second: 0..59,
          microsecond: non_neg_integer()
        }
  def time_info(%Time{} = t) do
    %{hour: t.hour, minute: t.minute, second: t.second, microsecond: elem(t.microsecond, 0)}
  end

  # ------------------------------------------------------------
  # 2. 日期算术：add / diff，月末不溢出
  # ------------------------------------------------------------

  @doc """
  按天平移（负数往前）；跨月按日历走，1-31 +1 = 2-1，不会出现 2-31。

      iex> Ex20Dates.shift_days(~D[2026-09-21], 10)
      ~D[2026-10-01]

      iex> Ex20Dates.shift_days(~D[2026-01-31], 1)
      ~D[2026-02-01]

  """
  @spec shift_days(Date.t(), integer()) :: Date.t()
  def shift_days(%Date{} = d, days), do: Date.add(d, days)

  @doc """
  两天相差天数（后 - 前）。

      iex> Ex20Dates.days_between(~D[2026-10-01], ~D[2026-09-21])
      10

  """
  @spec days_between(Date.t(), Date.t()) :: integer()
  def days_between(%Date{} = later, %Date{} = earlier), do: Date.diff(later, earlier)

  # ------------------------------------------------------------
  # 3. Date.range：闭区间，可枚举
  # ------------------------------------------------------------

  @doc """
  统计日期闭区间内的工作日（周一到周五）个数。区间两端都包含。

      iex> Ex20Dates.workdays(~D[2026-09-01], ~D[2026-09-30])
      22

      iex> Ex20Dates.workdays(~D[2026-09-18], ~D[2026-09-20])
      1

  """
  @spec workdays(Date.t(), Date.t()) :: non_neg_integer()
  def workdays(%Date{} = from, %Date{} = to) do
    # 1.20 起 Date.range/2 不允许隐式逆序（运行告警），逆序必须显式传 -1。
    step = if Date.compare(from, to) == :gt, do: -1, else: 1

    Date.range(from, to, step)
    |> Enum.count(fn day -> Date.day_of_week(day) in 1..5 end)
  end

  # ------------------------------------------------------------
  # 4. 时刻算术：秒级 add/diff，钟点滚动
  # ------------------------------------------------------------

  @doc """
  NaiveDateTime 加秒；跨天按 24 小时滚。

      iex> Ex20Dates.add_seconds(~N[2026-09-21 08:00:00], 3661)
      ~N[2026-09-21 09:01:01]

  """
  @spec add_seconds(NaiveDateTime.t(), integer()) :: NaiveDateTime.t()
  def add_seconds(%NaiveDateTime{} = n, seconds), do: NaiveDateTime.add(n, seconds)

  @doc """
  两个无时区时刻之差，支持单位参数（:second / :millisecond / :microsecond / :nanosecond）。

      iex> Ex20Dates.seconds_between(
      iex>   ~N[2026-09-21 10:00:00],
      iex>   ~N[2026-09-21 08:00:00]
      iex> )
      7200

      iex> Ex20Dates.seconds_between(
      iex>   ~N[2026-09-21 08:00:01.000],
      iex>   ~N[2026-09-21 08:00:00.000],
      iex>   :millisecond
      iex> )
      1000

  """
  @spec seconds_between(NaiveDateTime.t(), NaiveDateTime.t(), System.time_unit()) :: integer()
  def seconds_between(%NaiveDateTime{} = later, %NaiveDateTime{} = earlier, unit \\ :second) do
    NaiveDateTime.diff(later, earlier, unit)
  end

  @doc """
  Time 加秒自动按 24 小时取模（跨午夜）。

      iex> Ex20Dates.roll_hours(~T[23:00:00], 7200)
      ~T[01:00:00]

  """
  @spec roll_hours(Time.t(), integer()) :: Time.t()
  def roll_hours(%Time{} = t, seconds), do: Time.add(t, seconds)

  # ------------------------------------------------------------
  # 5. 与 Unix 互转；零依赖固定偏移
  # ------------------------------------------------------------

  @doc """
  Unix 毫秒 0 => UTC 纪元；DateTime 默认微秒精度。

      iex> Ex20Dates.unix_epoch(0)
      ~U[1970-01-01 00:00:00.000Z]

  """
  @spec unix_epoch(integer()) :: DateTime.t()
  def unix_epoch(ms), do: DateTime.from_unix!(ms, :millisecond)

  @doc """
  UTC DateTime -> Unix 秒。

      iex> Ex20Dates.to_unix(~U[2026-09-21 00:00:00Z])
      1789948800

  """
  @spec to_unix(DateTime.t()) :: integer()
  def to_unix(%DateTime{} = dt), do: DateTime.to_unix(dt)

  @doc """
  零依赖下处理固定偏移的正确姿势：本地墙钟减去偏移得到 UTC naive，
  再解释为 UTC。偏移在东为正（北京 +28800）。

      iex> Ex20Dates.wall_to_unix(~N[2026-09-21 08:00:00], 28800)
      1789948800

  """
  @spec wall_to_unix(NaiveDateTime.t(), integer()) :: integer()
  def wall_to_unix(%NaiveDateTime{} = wall, offset_seconds) do
    utc_naive = NaiveDateTime.add(wall, -offset_seconds)
    {:ok, dt} = DateTime.from_naive(utc_naive, "Etc/UTC")
    DateTime.to_unix(dt)
  end

  # ------------------------------------------------------------
  # 6. 命名时区坑：零依赖没有时区数据库
  # ------------------------------------------------------------

  @doc """
  尝试把 UTC 时刻换到命名时区。没有加载时区数据库时，一切非 UTC 时区
  （连 Etc/GMT-8）都返回 `{:error, :utc_only_time_zone_database}`。

      iex> Ex20Dates.shift_error("Asia/Shanghai")
      {:error, :utc_only_time_zone_database}

      iex> Ex20Dates.shift_error("America/New_York")
      {:error, :utc_only_time_zone_database}

  """
  @spec shift_error(String.t()) :: {:error, :utc_only_time_zone_database}
  def shift_error(time_zone) when is_binary(time_zone) do
    DateTime.shift_zone(~U[2026-09-21 00:00:00Z], time_zone)
  end

  @doc """
  构造带时区的 DateTime 同理：只接受 Etc/UTC。

      iex> Ex20Dates.new_local(~D[2026-09-21], ~T[08:00:00], "Asia/Shanghai")
      {:error, :utc_only_time_zone_database}

      iex> Ex20Dates.new_local(~D[2026-09-21], ~T[08:00:00], "Etc/UTC")
      {:ok, ~U[2026-09-21 08:00:00Z]}

  """
  @spec new_local(Date.t(), Time.t(), String.t()) ::
          {:ok, DateTime.t()} | {:error, :utc_only_time_zone_database}
  def new_local(%Date{} = d, %Time{} = t, time_zone) do
    DateTime.new(d, t, time_zone)
  end

  # ------------------------------------------------------------
  # 7. 比较：同类三态，跨类不可比
  # ------------------------------------------------------------

  @doc """
  同类型比较返回 :lt / :eq / :gt；跨类型（如 Date 比 Time）返回
  `{:error, :incomparable}`——直接调 Date/DateTime.compare 会 FunctionClauseError。

      iex> Ex20Dates.safe_compare(~D[2026-09-21], ~D[2026-09-20])
      :gt

      iex> Ex20Dates.safe_compare(~D[2026-09-21], ~T[12:00:00])
      {:error, :incomparable}

      iex> Ex20Dates.safe_compare(~U[2026-09-21 00:00:00Z], ~U[2026-09-21 00:00:00Z])
      :eq

  """
  @spec safe_compare(term(), term()) :: :lt | :eq | :gt | {:error, :incomparable}
  def safe_compare(%DateTime{} = a, %DateTime{} = b), do: DateTime.compare(a, b)
  def safe_compare(%NaiveDateTime{} = a, %NaiveDateTime{} = b), do: NaiveDateTime.compare(a, b)
  def safe_compare(%Date{} = a, %Date{} = b), do: Date.compare(a, b)
  def safe_compare(%Time{} = a, %Time{} = b), do: Time.compare(a, b)
  def safe_compare(_a, _b), do: {:error, :incomparable}
end
