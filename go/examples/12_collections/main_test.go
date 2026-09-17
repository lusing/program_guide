package main

import (
	"cmp"
	"maps"
	"reflect"
	"slices"
	"strings"
	"testing"
)

func TestSortCloneDoesNotMutate(t *testing.T) {
	nums := []int{3, 1, 2}
	got := slices.Clone(nums)
	slices.Sort(got)
	if !reflect.DeepEqual(got, []int{1, 2, 3}) {
		t.Errorf("Sort = %v", got)
	}
	if !reflect.DeepEqual(nums, []int{3, 1, 2}) {
		t.Errorf("原切片不该被动: %v", nums)
	}
}

func TestIndexContains(t *testing.T) {
	nums := []int{42, 7, 19}
	if slices.Index(nums, 19) != 2 || slices.Index(nums, 99) != -1 {
		t.Error("Index 不对")
	}
	if !slices.Contains(nums, 7) || slices.Contains(nums, 8) {
		t.Error("Contains 不对")
	}
}

func TestSortFunc(t *testing.T) {
	users := []User{{"b", 30}, {"a", 25}, {"c", 25}}
	slices.SortFunc(users, func(x, y User) int {
		if c := cmp.Compare(x.Age, y.Age); c != 0 {
			return c
		}
		return strings.Compare(x.Name, y.Name) // 次级排序键
	})
	if users[0].Name != "a" || users[1].Name != "c" || users[2].Name != "b" {
		t.Errorf("SortFunc 结果不对: %v", users)
	}
}

func TestMapsCloneKeys(t *testing.T) {
	m := map[string]int{"b": 2, "a": 1}
	c := maps.Clone(m)
	c["a"] = 99
	if m["a"] != 1 {
		t.Error("Clone 应得到独立的新 map")
	}
	keys := slices.Sorted(maps.Keys(m))
	if !reflect.DeepEqual(keys, []string{"a", "b"}) {
		t.Errorf("Sorted(Keys) = %v", keys)
	}
}

func TestCompact(t *testing.T) {
	got := slices.Compact([]int{1, 1, 2, 2, 2, 3})
	if !reflect.DeepEqual(got, []int{1, 2, 3}) {
		t.Errorf("Compact = %v", got)
	}
}
