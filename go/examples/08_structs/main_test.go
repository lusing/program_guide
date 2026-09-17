package main

import "testing"

func TestNewRectNormalizes(t *testing.T) {
	r := NewRect(3, 4, 0, 0) // 角点传反
	if r.Min.X != 0 || r.Min.Y != 0 || r.Max.X != 3 || r.Max.Y != 4 {
		t.Errorf("NewRect 未规范化: Min=%v Max=%v", r.Min, r.Max)
	}
	if r.Area() != 12 {
		t.Errorf("Area = %g, want 12", r.Area())
	}
}

func TestScale(t *testing.T) {
	r := NewRect(0, 0, 2, 3)
	r.Scale(2)
	if r.Area() != 24 { // 面积按 k² 缩放
		t.Errorf("Scale 后 Area = %g, want 24", r.Area())
	}
}

func TestPersonPromotion(t *testing.T) {
	emp := Employee{Person: Person{Name: "阿G", Age: 30}, Company: "BigCorp"}
	if emp.Name != "阿G" {
		t.Errorf("提升字段 Name = %q", emp.Name)
	}
	if got, want := emp.Greet(), "我是 阿G"; got != want {
		t.Errorf("提升方法 Greet = %q, want %q", got, want)
	}
}
