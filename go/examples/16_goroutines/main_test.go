package main

import (
	"sync"
	"testing"
)

func TestSumParallel(t *testing.T) {
	nums := make([]int, 1000)
	for i := range nums {
		nums[i] = i + 1
	}
	if got := SumParallel(nums, 8); got != 500500 {
		t.Errorf("SumParallel = %d, want 500500", got)
	}
	if got := SumParallel([]int{1, 2, 3}, 0); got != 6 {
		t.Errorf("SumParallel(parts=0) = %d, want 6", got)
	}
	if got := SumParallel(nil, 4); got != 0 {
		t.Errorf("SumParallel(nil) = %d, want 0", got)
	}
}

func TestLazyConfig(t *testing.T) {
	lc := &LazyConfig{}
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			if lc.Get().Name != "默认配置" {
				t.Error("配置读错")
			}
		})
	}
	wg.Wait()
	if lc.Get().Name != "默认配置" {
		t.Error("Once 之后应有值")
	}
}
