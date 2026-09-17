// 17_channels：无缓冲/缓冲、select、关闭语义、worker pool、流水线。
// 本示例由 build.ps1 用 go test -race 验证。
package main

import (
	"fmt"
	"time"
)

// PoolSum worker pool 模式：一个 jobs channel + N 个 worker + 结果回收。
func PoolSum(nums []int, workers int) int {
	jobs := make(chan int)
	done := make(chan int)

	// 投递者单独开 goroutine：jobs 无缓冲，谁在收谁在发要错开，否则死锁
	go func() {
		for _, n := range nums {
			jobs <- n
		}
		close(jobs) // 关闭 = 广播"没活儿了"，worker 的 range 随之退出
	}()

	for range workers {
		go func() {
			part := 0
			for n := range jobs { // 消费到 close 为止
				part += n
			}
			done <- part
		}()
	}
	total := 0
	for range workers {
		total += <-done
	}
	return total
}

// Pipeline 流水线：generator → square → 消费端。每级一个 goroutine + 一个 channel。
func Pipeline(nums ...int) []int {
	gen := make(chan int)
	go func() {
		for _, n := range nums {
			gen <- n
		}
		close(gen)
	}()

	sq := make(chan int)
	go func() {
		for n := range gen {
			sq <- n * n
		}
		close(sq)
	}()

	out := make([]int, 0, len(nums))
	for v := range sq {
		out = append(out, v)
	}
	return out
}

func main() {
	fmt.Println("== 无缓冲 channel：发送阻塞到有人接收 ==")
	ch := make(chan string)
	go func() {
		ch <- "同步交接" // 发送方卡在这里，直到 main 接收
	}()
	fmt.Println(<-ch)

	fmt.Println("== 缓冲 channel：装满之前发送不堵 ==")
	buf := make(chan int, 2)
	buf <- 1
	buf <- 2
	fmt.Println("len =", len(buf), "收到:", <-buf, <-buf)

	fmt.Println("== close + range 流水线 ==")
	for _, v := range Pipeline(1, 2, 3) {
		fmt.Print(v, " ")
	}
	fmt.Println()

	fmt.Println("== comma-ok 探测关闭 ==")
	closed := make(chan int)
	close(closed)
	if v, ok := <-closed; !ok {
		fmt.Println("通道已关，收到零值", v)
	}

	fmt.Println("== select：多路就绪，谁先来收谁 ==")
	a := make(chan string)
	go func() {
		time.Sleep(10 * time.Millisecond)
		a <- "A 到货"
	}()
	select {
	case msg := <-a:
		fmt.Println(msg)
	case <-time.After(50 * time.Millisecond): // After：到点自动关闭的通道
		fmt.Println("超时放弃")
	}

	fmt.Println("== worker pool ==")
	nums := []int{1, 2, 3, 4, 5, 6, 7, 8}
	fmt.Println("8 个数 3 个工人求和:", PoolSum(nums, 3))
}
