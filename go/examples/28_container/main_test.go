package main

import (
	"container/heap"
	"container/list"
	"container/ring"
	"reflect"
	"testing"
)

func TestHeapSort(t *testing.T) {
	got := HeapSort([]int{5, 2, 8, 1, 9, 3})
	want := []int{1, 2, 3, 5, 8, 9}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("HeapSort = %v", got)
	}
	if got := HeapSort(nil); len(got) != 0 {
		t.Errorf("空输入 = %v", got)
	}
}

func TestPriorityQueueOrder(t *testing.T) {
	q := &TaskQueue{}
	for _, task := range []Task{{"备份", 1}, {"告警", 9}, {"a清理", 1}, {"发布", 5}} {
		heap.Push(q, task)
	}
	got := PopAll(q)
	want := []string{"告警", "发布", "a清理", "备份"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("PopAll = %v, want %v（优先级降序，平局按名）", got, want)
	}
}

func TestHeapFix(t *testing.T) {
	h := &IntHeap{1, 3, 5}
	heap.Init(h)
	(*h)[0] = 10 // 堆顶被改大，堆性质破坏
	heap.Fix(h, 0)
	if got := heap.Pop(h).(int); got != 3 {
		t.Errorf("Fix 后堆顶应回到 3，got %d", got)
	}
}

func TestLowerBound(t *testing.T) {
	a := []int{1, 3, 5, 7, 9}
	cases := []struct {
		target, want int
	}{
		{6, 3},  // 第一个 >= 6 是 7（下标 3）
		{7, 3},  // 等于自身
		{0, 0},  // 全都比它大
		{99, 5}, // 都比它小 → len
	}
	for _, c := range cases {
		if got := LowerBound(a, c.target); got != c.want {
			t.Errorf("LowerBound(%d) = %d, want %d", c.target, got, c.want)
		}
	}
}

func TestIntSqrt(t *testing.T) {
	if got := IntSqrt(10); got != 4 {
		t.Errorf("IntSqrt(10) = %d, want 4", got)
	}
	if got := IntSqrt(16); got != 4 {
		t.Errorf("IntSqrt(16) = %d, want 4", got)
	}
	if got := IntSqrt(1); got != 1 {
		t.Errorf("IntSqrt(1) = %d, want 1", got)
	}
}

func TestListAndRing(t *testing.T) {
	l := list.New()
	e1 := l.PushBack(1)
	e2 := l.PushBack(2)
	l.MoveToFront(e2)
	l.Remove(e1)
	if l.Len() != 1 || l.Front().Value.(int) != 2 {
		t.Errorf("list 状态不对：len=%d front=%v", l.Len(), l.Front().Value)
	}
	r := ring.New(3)
	for i := range 3 {
		r.Value = i
		r = r.Next()
	}
	var seen []int
	r.Do(func(v any) { seen = append(seen, v.(int)) })
	if !reflect.DeepEqual(seen, []int{0, 1, 2}) {
		t.Errorf("ring 遍历 = %v", seen)
	}
}
