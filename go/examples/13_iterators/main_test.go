package main

import (
	"iter"
	"slices"
	"testing"
)

func TestIntRange(t *testing.T) {
	if got := slices.Collect(IntRange(1, 4)); !slices.Equal(got, []int{1, 2, 3}) {
		t.Errorf("IntRange(1,4) = %v", got)
	}
	if got := slices.Collect(IntRange(5, 5)); len(got) != 0 {
		t.Errorf("空序列 = %v", got)
	}
}

func TestFilterSeq(t *testing.T) {
	seq := Filter(IntRange(0, 8), func(v int) bool { return v%3 == 0 })
	if got := slices.Collect(seq); !slices.Equal(got, []int{0, 3, 6}) {
		t.Errorf("Filter = %v", got)
	}
}

func TestListAll(t *testing.T) {
	l := &List{}
	for _, v := range []int{7, 8, 9} {
		l.Push(v)
	}
	var got []int
	for v := range l.All() {
		got = append(got, v)
	}
	if !slices.Equal(got, []int{7, 8, 9}) {
		t.Errorf("List.All = %v", got)
	}
}

func TestPairs(t *testing.T) {
	var keys []string
	var vals []int
	for k, v := range Pairs([]string{"x", "y"}, []int{10, 20}) {
		keys = append(keys, k)
		vals = append(vals, v)
	}
	if !slices.Equal(keys, []string{"x", "y"}) || !slices.Equal(vals, []int{10, 20}) {
		t.Errorf("Pairs = %v %v", keys, vals)
	}
}

func TestPull(t *testing.T) {
	next, stop := iter.Pull(IntRange(5, 7))
	defer stop()
	v, ok := next()
	if !ok || v != 5 {
		t.Errorf("第一次 next = (%v,%v)", v, ok)
	}
	v, ok = next()
	if !ok || v != 6 {
		t.Errorf("第二次 next = (%v,%v)", v, ok)
	}
	if _, ok := next(); ok {
		t.Error("第三次应耗尽")
	}
}
