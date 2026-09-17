# 17 · 并发 II：channel ⭐

> 对应示例：`examples/17_channels/`（build.ps1 用 `go test -race` 验证）

Go 的口号：**不要通过共享内存来通信，而要通过通信来共享内存**。channel 就是那条通信管道。

## 17.1 两款 channel

```go
ch := make(chan string)        // 无缓冲：发送阻塞到有人接收（同步交接点）
buf := make(chan int, 2)       // 缓冲 2：装满之前发送不堵

ch <- "数据"                   // 发送
v := <-ch                      // 接收
v, ok := <-ch                  // comma-ok：ok=false 表示通道已关闭且已读空
```

无缓冲 channel 是**会合点**：发送方和接收方握手才都继续——天然的同步语义。缓冲 channel 只是排队：满了照样堵。**默认用无缓冲**，说得出容量理由才加缓冲。

## 17.2 close 的协议

```go
// 生产者关闭——唯一正确的一方；消费者永远不该 close
close(jobs)

// 消费者两种姿势
for n := range jobs { }        // range：自动收到 close 停止
v, ok := <-ch                  // 手动探测：关闭后 ok=false、v 是零值
```

- `close` 后**还能把缓冲里的存量读完**（示例 17 的测试专门验证）；
- 关闭后再**收**：零值 + ok=false，不 panic；
- 关闭后再**发** / 重复 close：**panic**；
- close 是广播：N 个接收方同时醒来——`done := make(chan struct{}); close(done)` 是"全体收工"信号的标准写法。

## 17.3 select：多路复用

```go
select {
case msg := <-a:                 // 哪个 case 就绪执行哪个
	fmt.Println(msg)
case <-time.After(50 * time.Millisecond):   // 超时兜底
	fmt.Println("超时放弃")
}

select {                        // 全不就绪时 default 立即走：非阻塞探测
case v := <-ch:
	use(v)
default:                        // ch 空着：不等
}
```

多个 case 同时就绪时**随机挑一个**（不给饥饿留机会）。惯用组合：

- 超时：`case <-time.After(d)`；
- 取消：`case <-ctx.Done()`（18 章）；
- 心跳/退出信号：`case <-quit:`。

`time.After` 每次新建 Timer——高频循环里用 `time.NewTimer` 复用（19 章）。

## 17.4 方向：签名里声明意图

```go
func produce(out chan<- int) { }     // 只发
func consume(in <-chan int) { }      // 只收
```

通道方向写进函数签名，**编译器替调用方把越权操作拦下**——好 API 的标配（示例 17 的投递 goroutine 可以这么改）。

## 17.5 worker pool：三件套组合拳

```go
jobs := make(chan int)
done := make(chan int)

go func() {                 // ① 投递者：喂完关火
	for _, n := range nums {
		jobs <- n
	}
	close(jobs)
}()

for range workers {          // ② 工人池：range 到 close 为止
	go func() {
		part := 0
		for n := range jobs {
			part += n
		}
		done <- part         // 交卷
	}()
}

total := 0
for range workers {          // ③ 收卷：收 workers 份
	total += <-done
}
```

**投递者必须单独开 goroutine**：jobs 无缓冲时主流程自己投递又自己收 → 死锁。这个"投递/加工/收卷"三角是并发动机学（示例 17 的 PoolSum 原样实现，24 章实战再用一次）。

## 17.6 流水线：channel 串 channel

```go
gen := make(chan int)                // 第一级：生成
go func() { for _, n := range nums { gen <- n }; close(gen) }()

sq := make(chan int)                 // 第二级：加工
go func() { for n := range gen { sq <- n * n }; close(sq) }()

for v := range sq { ... }            // 消费端驱动全局
```

每级一进一出、close 逐级传递，**消费速度反向压回源头**（背压天然存在）。range 循环退出 = 整条流水线排空。

## 17.7 nil channel 的妙用与陷阱

`var ch chan int`（未 make）是 nil：**收发永远阻塞**，select 的 case 里放 nil channel = 禁用该分支——动态开关分支的小技巧（进阶，知道即可）。误用（忘了 make）则是死锁事故。

## 17.8 坑位清单

1. **死锁三连**：无缓冲自发自收、主 goroutine 投递无人收、循环里 select 没有 default 也超时——`go test -race` 不抓死锁，靠 `go run -race` 的 "all goroutines are asleep" 报错定位。
2. **消费者 close**：唯一法则是生产者关——消费者关完生产者一发就 panic。
3. **close 后读缓冲**：存量合法可读，别把 ok=false 误当"从没发过数据"。
4. **goroutine 里 t.Fatal**：只终结自己那个 goroutine——用通道把失败传回主测试 goroutine。
5. **忘了 drain**：生产者堵在发送（没人收）导致泄漏——退出路径要把所有通道读空或让生产者可被取消（context）。
6. **select 随机性**：同时就绪随机选——测试里别赌"肯定先走第一个 case"。

---
