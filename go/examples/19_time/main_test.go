package main

import (
	"testing"
	"time"
)

func TestNextMonday(t *testing.T) {
	wed := time.Date(2026, 9, 16, 0, 0, 0, 0, time.UTC) // 周三
	got := NextMonday(wed)
	if got.Weekday() != time.Monday || got.Sub(wed) != 5*24*time.Hour {
		t.Errorf("NextMonday(周三) = %v", got)
	}
	mon := time.Date(2026, 9, 14, 0, 0, 0, 0, time.UTC) // 周一当天 → 下周一
	if NextMonday(mon).Sub(mon) != 7*24*time.Hour {
		t.Error("周一当天应返回下周一")
	}
}

func TestAddDateNormalizes(t *testing.T) {
	jan31 := time.Date(2026, 1, 31, 0, 0, 0, 0, time.UTC)
	got := jan31.AddDate(0, 1, 0)
	if got.Month() != time.March || got.Day() != 3 {
		t.Errorf("1/31 加一个月 = %v，应归一化到 3/3（2 月没有 31 号）", got)
	}
}

func TestFormatParseRoundtrip(t *testing.T) {
	want := time.Date(2026, 9, 17, 10, 30, 0, 0, time.UTC)
	s := want.Format(layoutCN)
	got, err := time.Parse(layoutCN, s)
	if err != nil || !got.Equal(want) {
		t.Errorf("往返 = (%v, %v)", got, err)
	}
}

func TestFixedZone(t *testing.T) {
	utc := time.Date(2026, 9, 17, 0, 0, 0, 0, time.UTC)
	cst := time.FixedZone("CST", 8*3600)
	if got := utc.In(cst).Format("15"); got != "08" {
		t.Errorf("UTC 0 点 = 东八区 %s 点, want 08", got)
	}
}
