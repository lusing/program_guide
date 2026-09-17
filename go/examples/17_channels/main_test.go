package main

import (
	"slices"
	"testing"
)

func TestPoolSum(t *testing.T) {
	if got := PoolSum([]int{1, 2, 3, 4, 5, 6, 7, 8}, 3); got != 36 {
		t.Errorf("PoolSum = %d, want 36", got)
	}
	if got := PoolSum(nil, 4); got != 0 {
		t.Errorf("PoolSum(nil) = %d, want 0", got)
	}
	if got := PoolSum([]int{5}, 100); got != 5 { // worker 比任务多也不慌
		t.Errorf("PoolSum(多工人) = %d, want 5", got)
	}
}

func TestPipeline(t *testing.T) {
	if got := Pipeline(1, 2, 3, 4); !slices.Equal(got, []int{1, 4, 9, 16}) {
		t.Errorf("Pipeline = %v", got)
	}
	if got := Pipeline(); len(got) != 0 {
		t.Errorf("Pipeline() = %v", got)
	}
}

func TestClosedChannelReceive(t *testing.T) {
	ch := make(chan int, 1)
	ch <- 7
	close(ch) // 关闭后缓冲里的存量仍可读（先读完再得到 ok=false）
	if v, ok := <-ch; !ok || v != 7 {
		t.Errorf("缓冲存量读取 = (%d,%v)", v, ok)
	}
	if v, ok := <-ch; ok || v != 0 {
		t.Errorf("耗尽后应得 (0,false)，得 (%d,%v)", v, ok)
	}
}
