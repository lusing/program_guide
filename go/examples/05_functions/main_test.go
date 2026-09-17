package main

import "testing"

func TestDiv(t *testing.T) {
	if q, err := Div(7, 2); err != nil || q != 3 {
		t.Errorf("Div(7,2) = (%d,%v), want (3,nil)", q, err)
	}
	if _, err := Div(1, 0); err == nil {
		t.Error("Div(1,0) 应返回错误")
	}
}

func TestSum(t *testing.T) {
	if got := Sum(); got != 0 {
		t.Errorf("Sum() = %d, want 0", got)
	}
	if got := Sum(1, 2, 3, 4); got != 10 {
		t.Errorf("Sum(1,2,3,4) = %d, want 10", got)
	}
	if got := Sum([]int{5, 6}...); got != 11 {
		t.Errorf("Sum(切片展开) = %d, want 11", got)
	}
}

func TestCounter(t *testing.T) {
	c1, c2 := Counter(), Counter()
	if c1() != 1 || c1() != 2 || c2() != 1 {
		t.Error("两个闭包应各自独立计数")
	}
}

func TestApply(t *testing.T) {
	got := Apply([]int{1, 2, 3}, func(n int) int { return n * n })
	want := []int{1, 4, 9}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("Apply 结果[%d] = %d, want %d", i, got[i], want[i])
		}
	}
}

func TestTitle(t *testing.T) {
	if f, l := Title("Rob Pike"); f != "Rob" || l != "Pike" {
		t.Errorf("Title = (%q,%q), want (Rob,Pike)", f, l)
	}
	if f, l := Title("单名"); f != "单名" || l != "" {
		t.Errorf("Title(单名) = (%q,%q)", f, l)
	}
}
