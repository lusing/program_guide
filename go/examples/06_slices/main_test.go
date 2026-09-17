package main

import (
	"reflect"
	"testing"
)

func TestEvens(t *testing.T) {
	got := Evens([]int{1, 2, 3, 4, 5, 6})
	if want := []int{2, 4, 6}; !reflect.DeepEqual(got, want) {
		t.Errorf("Evens = %v, want %v", got, want)
	}
	if got := Evens(nil); len(got) != 0 {
		t.Errorf("Evens(nil) 应为空，得 %v", got)
	}
}

func TestEvensDoesNotMutate(t *testing.T) {
	in := []int{1, 2, 3}
	_ = Evens(in)
	if !reflect.DeepEqual(in, []int{1, 2, 3}) {
		t.Errorf("Evens 不该改入参，现在 in = %v", in)
	}
}

func TestTailShares(t *testing.T) {
	a := []int{1, 2, 3}
	tl := Tail(a)
	if !reflect.DeepEqual(tl, []int{2, 3}) {
		t.Fatalf("Tail = %v", tl)
	}
	tl[0] = 99 // Tail 是视图：改它就是改 a[1]
	if a[1] != 99 {
		t.Error("Tail 返回的是共享视图，应能影响原切片")
	}
	if Tail(nil) != nil {
		t.Error("Tail(nil) 应返回 nil")
	}
}
