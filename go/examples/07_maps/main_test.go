package main

import (
	"reflect"
	"testing"
)

func TestWordCount(t *testing.T) {
	got := WordCount("a b a c b a")
	want := map[string]int{"a": 3, "b": 2, "c": 1}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("WordCount = %v, want %v", got, want)
	}
	if len(WordCount("")) != 0 {
		t.Error("空串应得到空 map")
	}
}

func TestSortedKeys(t *testing.T) {
	got := SortedKeys(map[string]int{"b": 1, "a": 2, "c": 3})
	if want := []string{"a", "b", "c"}; !reflect.DeepEqual(got, want) {
		t.Errorf("SortedKeys = %v, want %v", got, want)
	}
	if got := SortedKeys(nil); len(got) != 0 {
		t.Errorf("SortedKeys(nil) 应为空，得 %v", got)
	}
}

func TestSet(t *testing.T) {
	s := Set{}
	s.Add("go")
	if !s.Has("go") || s.Has("zig") {
		t.Error("Set 的 Add/Has 行为不对")
	}
	if len(s) != 1 {
		t.Errorf("len(Set) = %d, want 1", len(s))
	}
}
