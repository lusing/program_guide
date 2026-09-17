// 16_goroutines：go 关键字、WaitGroup（含新 Go 方法）、sync.Once、竞态检测器。
// 本示例由 build.ps1 用 go test -race 验证——数据竞争在普通运行里可能潜伏很久。
package main

import (
	"fmt"
	"sync"
)

// SumParallel 把切片分 parts 份并发求和，互斥锁汇总。
// 闭包捕获的 lo/hi 是本轮迭代专属副本——1.22 之前这里是并发第一大坑。
func SumParallel(nums []int, parts int) int64 {
	if parts <= 0 {
		parts = 1
	}
	chunk := (len(nums) + parts - 1) / parts
	var (
		wg  sync.WaitGroup
		mu  sync.Mutex
		sum int64
	)
	for p := range parts { // range 整数（1.22+）
		lo := p * chunk
		hi := min(lo+chunk, len(nums))
		if lo >= hi {
			break
		}
		wg.Go(func() { // 新版便捷方法：Add(1)+go+Done 三合一
			part := int64(0)
			for _, n := range nums[lo:hi] {
				part += int64(n)
			}
			mu.Lock()
			sum += part
			mu.Unlock()
		})
	}
	wg.Wait()
	return sum
}

// LazyConfig 用 sync.Once 做并发安全的惰性初始化。
type Config struct{ Name string }

type LazyConfig struct {
	once sync.Once
	val  Config
}

func (l *LazyConfig) Get() Config {
	l.once.Do(func() {
		fmt.Println("  （初始化只发生一次）")
		l.val = Config{Name: "默认配置"}
	})
	return l.val
}

func main() {
	fmt.Println("== 最小 goroutine ==")
	done := make(chan struct{})
	go func() {
		fmt.Println("  我在另一个 goroutine 里跑")
		close(done)
	}()
	<-done // main 不等的话进程可能先退（坑位清单第 1 条）

	fmt.Println("== 并发分片求和 ==")
	nums := make([]int, 1000)
	for i := range nums {
		nums[i] = i + 1
	}
	fmt.Println("1..1000 =", SumParallel(nums, 4))

	fmt.Println("== sync.Once 惰性初始化 ==")
	lc := &LazyConfig{}
	var wg sync.WaitGroup
	for range 5 {
		wg.Go(func() {
			fmt.Println("  读到:", lc.Get().Name)
		})
	}
	wg.Wait()
}
