defmodule Ex20DatesTest do
  use ExUnit.Case, async: true

  doctest Ex20Dates

  describe "字段拆解" do
    test "周日 wday=7；闰年 2-29 合法" do
      # 2026-09-20 是周日
      assert Ex20Dates.date_info(~D[2026-09-20]).wday == 7

      assert Ex20Dates.date_info(~D[2028-02-29]) == %{
               year: 2028,
               month: 2,
               day: 29,
               wday: 2,
               quarter: 1
             }
    end

    test "microsecond 保留精度元组信息" do
      info = Ex20Dates.time_info(~T[08:00:00.12])
      assert info.microsecond == 120_000
      assert ~T[08:00:00.12].microsecond == {120_000, 2}
    end
  end

  describe "日期算术" do
    test "负天数往前平移；跨年" do
      assert Ex20Dates.shift_days(~D[2026-01-01], -1) == ~D[2025-12-31]
    end

    test "2 月底在闰年有 29 天" do
      assert Ex20Dates.shift_days(~D[2028-02-28], 1) == ~D[2028-02-29]
      assert Ex20Dates.shift_days(~D[2026-02-28], 1) == ~D[2026-03-01]
    end

    test "diff 反向为负" do
      assert Ex20Dates.days_between(~D[2026-09-21], ~D[2026-09-30]) == -9
    end
  end

  describe "Date.range" do
    test "区间可往回走；两端包含" do
      # 周一 21、周日 20、周六 19：只有周一是工作日
      assert Ex20Dates.workdays(~D[2026-09-21], ~D[2026-09-19]) == 1
      # 周五-周六-周日：只有周五一个工作日
      assert Ex20Dates.workdays(~D[2026-09-18], ~D[2026-09-20]) == 1
    end

    test "Date.range 是 %Date.Range{}，不是 list" do
      range = Date.range(~D[2026-09-01], ~D[2026-09-30])
      assert is_struct(range, Date.Range)
      assert Enum.count(range) == 30
    end
  end

  describe "时刻算术" do
    test "加秒跨天" do
      assert Ex20Dates.add_seconds(~N[2026-09-21 23:59:59], 2) ==
               ~N[2026-09-22 00:00:01]
    end

    test "diff 支持微秒/纳秒单位" do
      a = ~N[2026-09-21 08:00:00.000001]
      b = ~N[2026-09-21 08:00:00.000000]
      assert Ex20Dates.seconds_between(a, b, :microsecond) == 1
      assert Ex20Dates.seconds_between(a, b, :nanosecond) == 1000
    end

    test "Time 加整整一天回到原点" do
      assert Ex20Dates.roll_hours(~T[12:00:00], 86_400) == ~T[12:00:00]
      assert Ex20Dates.roll_hours(~T[00:00:00], -1) == ~T[23:59:59]
    end
  end

  describe "Unix 互转与固定偏移" do
    test "from_unix 毫秒精度" do
      assert Ex20Dates.unix_epoch(1500) == ~U[1970-01-01 00:00:01.500Z]
    end

    test "to_unix 与 wall_to_unix 一致：UTC 00:00 == 北京 08:00" do
      utc = ~U[2026-09-21 00:00:00Z]

      assert Ex20Dates.wall_to_unix(~N[2026-09-21 08:00:00], 28800) ==
               Ex20Dates.to_unix(utc)
    end

    test "西五区偏移为负：纽约墙钟 19:00 == UTC 次日 00:00" do
      assert Ex20Dates.wall_to_unix(~N[2026-09-20 19:00:00], -18000) ==
               1_789_948_800
    end
  end

  describe "命名时区" do
    test "UTC 与 Etc/GMT 偏移串同样不可用" do
      assert Ex20Dates.shift_error("UTC") == {:error, :utc_only_time_zone_database}
      assert Ex20Dates.shift_error("Etc/GMT-8") == {:error, :utc_only_time_zone_database}
    end

    test "Etc/UTC 构造成功且偏移为 0" do
      {:ok, dt} = Ex20Dates.new_local(~D[2026-09-21], ~T[08:00:00], "Etc/UTC")
      assert dt.utc_offset == 0
      assert dt.zone_abbr == "UTC"
    end
  end

  describe "比较" do
    test "四种同类比较三态" do
      assert Ex20Dates.safe_compare(~T[10:00:00], ~T[09:00:00]) == :gt
      assert Ex20Dates.safe_compare(~N[2026-09-21 08:00:00], ~N[2026-09-21 09:00:00]) == :lt
      assert Ex20Dates.safe_compare(~U[2026-09-21 00:00:00Z], ~U[2026-09-21 00:00:00Z]) == :eq
    end

    test "NaiveDateTime 与 DateTime 也不可直接互比" do
      assert Ex20Dates.safe_compare(~N[2026-09-21 08:00:00], ~U[2026-09-21 08:00:00Z]) ==
               {:error, :incomparable}
    end
  end
end
