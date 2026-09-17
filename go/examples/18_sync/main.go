// 18_sync：Mutex/RWMutex、atomic、context 取消与超时。
// 本示例由 build.ps1 用 go test -race 验证。
package main

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

// Counter 互斥锁版：state 藏在锁后面。
type Counter struct {
	mu sync.Mutex
	n  int
}

func (c *Counter) Inc()       { c.mu.Lock(); defer c.mu.Unlock(); c.n++ }
func (c *Counter) Value() int { c.mu.Lock(); defer c.mu.Unlock(); return c.n }

// SafeCache 读写锁版：读多写少时 RLock 可多路并发。
type SafeCache struct {
	mu   sync.RWMutex
	data map[string]string
}

func NewSafeCache() *SafeCache { return &SafeCache{data: map[string]string{}} }

func (c *SafeCache) Get(key string) (string, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	v, ok := c.data[key]
	return v, ok
}

func (c *SafeCache) Set(key, val string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.data[key] = val
}

// Fetch 演示 context 传播：上层取消或超时，干活函数立刻收摊。
// select 同时等"活干完了"和"上头叫停了"，谁先到听谁的。
func Fetch(ctx context.Context, name string, work time.Duration) (string, error) {
	select {
	case <-time.After(work): // 模拟 IO 耗时
		return name + " 的数据", nil
	case <-ctx.Done(): // 取消或超时信号
		return "", ctx.Err()
	}
}

func main() {
	fmt.Println("== Mutex：一千次并发自增，一个不少 ==")
	var wg sync.WaitGroup
	counter := &Counter{}
	for range 1000 {
		wg.Go(func() { counter.Inc() })
	}
	wg.Wait()
	fmt.Println(counter.Value())

	fmt.Println("== RWMutex：读缓存 ==")
	cache := NewSafeCache()
	cache.Set("lang", "go")
	if v, ok := cache.Get("lang"); ok {
		fmt.Println("缓存命中:", v)
	}

	fmt.Println("== atomic：简单计数不用上锁 ==")
	var n atomic.Int64
	for range 1000 {
		wg.Go(func() { n.Add(1) })
	}
	wg.Wait()
	fmt.Println(n.Load())

	fmt.Println("== context.WithTimeout：按期放弃 ==")
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel() // 惯例：拿到 cancel 立刻 defer，防泄漏
	if _, err := Fetch(ctx, "慢接口", time.Second); err != nil {
		fmt.Println("放弃:", err) // context deadline exceeded
	}

	fmt.Println("== context.WithCancel：主动叫停 ==")
	ctx2, cancel2 := context.WithCancel(context.Background())
	go func() {
		time.Sleep(10 * time.Millisecond)
		cancel2() // 另一路决定取消
	}()
	if _, err := Fetch(ctx2, "慢活", time.Second); err != nil {
		fmt.Println("叫停:", err) // context canceled
	}

	fmt.Println("== context.WithValue：只放请求级元数据 ==")
	ctx3 := context.WithValue(context.Background(), "reqID", "R-42")
	fmt.Println("本次请求:", ctx3.Value("reqID"))
}
