package main

import "testing"

func TestTotalArea(t *testing.T) {
	shapes := []Shape{Rect{W: 3, H: 4}, Circle{R: 1}}
	got := TotalArea(shapes)
	want := 12.0 + 3.141592653589793
	if got != want {
		t.Errorf("TotalArea = %g, want %g", got, want)
	}
}

func TestDescribe(t *testing.T) {
	if got := Describe(Rect{W: 2, H: 5}); got != "Shape，面积 10" {
		t.Errorf("Describe(Rect) = %q", got)
	}
	if got := Describe(42); got != "整数 42" {
		t.Errorf("Describe(42) = %q", got)
	}
	if got := Describe(3.14); got != "类型 float64" {
		t.Errorf("Describe(3.14) = %q", got)
	}
}

func TestTypedNil(t *testing.T) {
	if BadRelease() == nil {
		t.Error("typed-nil 接口应 != nil（这正是坑）")
	}
	if GoodRelease() != nil {
		t.Error("GoodRelease 应返回 nil")
	}
}
