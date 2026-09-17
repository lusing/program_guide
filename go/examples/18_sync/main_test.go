package main

import (
	"context"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func TestCounterUnderContention(t *testing.T) {
	c := &Counter{}
	var wg sync.WaitGroup
	for range 1000 {
		wg.Go(func() { c.Inc() })
	}
	wg.Wait()
	if c.Value() != 1000 {
		t.Errorf("并发自增丢了数: %d", c.Value())
	}
}

func TestSafeCacheConcurrent(t *testing.T) {
	c := NewSafeCache()
	var wg sync.WaitGroup
	for range 50 {
		wg.Go(func() {
			c.Set("key", "值")
			c.Get("key")
		})
	}
	wg.Wait()
	if v, ok := c.Get("key"); !ok || v != "值" {
		t.Errorf("Get = (%q,%v)", v, ok)
	}
}

func TestAtomicCounter(t *testing.T) {
	var n atomic.Int64
	var wg sync.WaitGroup
	for range 1000 {
		wg.Go(func() { n.Add(1) })
	}
	wg.Wait()
	if n.Load() != 1000 {
		t.Errorf("atomic 计数 = %d", n.Load())
	}
}

func TestFetchContext(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel() // 先取消再调用
	if _, err := Fetch(ctx, "x", time.Minute); err != context.Canceled {
		t.Errorf("已取消的 ctx 应得 context.Canceled，得 %v", err)
	}
	// t.Context()（1.24+）：测试专用 ctx，测试结束自动取消
	if data, err := Fetch(t.Context(), "y", 0); err != nil {
		t.Errorf("未取消不应报错: %v", err)
	} else if data != "y 的数据" {
		t.Errorf("data = %q", data)
	}
}
