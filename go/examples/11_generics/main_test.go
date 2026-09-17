package main

import (
	"reflect"
	"testing"
)

func TestMax(t *testing.T) {
	if Max(3, 9) != 9 || Max(-1, -5) != -1 || Max(2.5, 2.5) != 2.5 {
		t.Error("Max 数值分支不对")
	}
	if Max("ab", "aa") != "ab" {
		t.Error("Max 字符串分支不对")
	}
}

func TestStack(t *testing.T) {
	s := &Stack[int]{}
	if _, ok := s.Pop(); ok {
		t.Error("空栈 Pop 应失败")
	}
	s.Push(1)
	s.Push(2)
	if v, ok := s.Pop(); !ok || v != 2 {
		t.Errorf("Pop = (%v,%v), want (2,true)", v, ok)
	}
	if s.Len() != 1 {
		t.Errorf("Len = %d, want 1", s.Len())
	}
}

func TestFilterMap(t *testing.T) {
	got := Filter([]int{1, 2, 3, 4}, func(n int) bool { return n%2 == 0 })
	if want := []int{2, 4}; !reflect.DeepEqual(got, want) {
		t.Errorf("Filter = %v, want %v", got, want)
	}
	got = Map([]string{"go", "c"}, func(w string) int { return len(w) })
	if !reflect.DeepEqual(got, []int{2, 1}) {
		t.Errorf("Map = %v", got)
	}
}

func TestSum(t *testing.T) {
	type Meters int
	if got := Sum([]Meters{100, 200}); got != 300 {
		t.Errorf("Sum(Meters) = %v", got)
	}
}
