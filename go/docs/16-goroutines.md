# 16 · 并发 I：goroutine ⭐

> 对应示例：`examples/16_goroutines/`（build.ps1 用 `go test -race` 验证）

## 16.1 go：六千字的并发史压缩成一个关键字

```go
go worker(1)                 // 前面加 go：这个调用在新的 goroutine 里并发执行
go func() { ... }()          // 匿名函数同样成立（注意别丢了末尾的调用括号）
```

goroutine 是**运行时调度的轻量线程**（初始栈 2KB，OS 线程 1MB 起步），GMP 模型下 M:N 复用少量 OS 线程。开十万个 goroutine 是日常，不是炫技。

**main 不等它**：main 函数返回，所有 goroutine 立即陪葬——这是新手第一个"为什么没输出"。

```go
done := make(chan struct{})
go func() {
	work()
	close(done)          // 干完了：关通道广播（17 章主角）
}()
<-done                   // main 在这里等
```

## 16.2 等待与汇总：sync.WaitGroup

```go
var wg sync.WaitGroup
for i := range 4 {
	wg.Go(func() {           // 新版三合一（1.25+）：Add(1) + go + Done
		defer 语义内置        // wg.Go 保证 panic 也会 Done（老 Add/Go 手写容易漏）
		partSum(nums[i])
	})
}
wg.Wait()                   // 全部收工才放行
```

老三样 `Add(1)` / `go f()` / `defer wg.Done()` 依然铺满现有代码——**Add 必须在 go 之前**（go 之后再 Add 是竞态：Wait 可能提前放行）。`wg.Go` 把整套拍死，新代码无脑用它。

**1.22 前后对比**（面试常客，现状）：

```go
for i := 0; i < 3; i++ {
	go func() { print(i) }()    // 1.21：可能三个 3；1.22+：0 1 2——每轮新副本
}
```

老代码的 `go func(i int) {...}(i)` 参数传副本是历史遗迹。

## 16.3 数据竞争：绕不过去的课

```go
var count int
for range 1000 {
	wg.Go(func() { count++ })    // ❌ count++ 不是原子：读-改-写三步会被插队
}
wg.Wait()
// count 多半 < 1000，而且每次不一样
```

三个修法（示例 16 用的是第一个，18 章补齐后两个）：

```go
// ① 互斥锁：一段代码一次一个
mu.Lock(); count++; mu.Unlock()

// ② 原子操作：单个数值计数
var count atomic.Int64
count.Add(1)

// ③ 不共享：各算各的，最后汇总（channel 或锁保护的一行）
part := compute(); mu.Lock(); sum += part; mu.Unlock()
```

**race 检测器**是 Go 送的神器：

```powershell
go test -race ./...
go run -race main.go
```

基于 happens-before 的动态检测，撞见竞争当场报栈（两个 goroutine 各自的访问现场）。本仓库两个入口（build.ps1 / run-all.sh）对 16/17/18 三个示例都用 `-race` 跑测试——**并发代码不跑 race 检测等于没测**。代价是 2-10 倍慢和需要 cgo：Windows 上要有 gcc，macOS 用自带的 clang（`xcode-select --install` 装命令行工具即可）。`go env CGO_ENABLED` 为 `0` 时两个入口会自动降级成不带 `-race` 跑并提示。

## 16.4 sync.Once：并发安全的"就一次"

```go
var once sync.Once
var config *Config

func GetConfig() *Config {
	once.Do(func() {           // 并发调用：只有一个执行，其余等它完成
		config = loadConfig()  //   ——天然的双重检查锁
	})
	return config
}
```

惰性初始化的标准答案。`sync.OnceValue(f)` 更现代：把"函数 + 缓存"打成一个可复用的值（`getCfg := sync.OnceValue(load)`）。

## 16.5 goroutine 的生死礼仪

| 规矩 | 为什么 |
|---|---|
| 谁启动谁负责收尾 | main 退出全部陪葬；泄漏的 goroutine 拖着资源不放 |
| 必须有退出条件 | `for { poll() }` 没有取消口子的 goroutine 是泄漏 |
| panic 在 goroutine 里没人 recover → 崩进程 | worker 顶层 defer recover（10 章） |
| 优雅退出走 context | 18 章 |

## 16.6 坑位清单

1. **main 先退，输出消失**：起手式永远是"启动 + 等待"（channel 或 WaitGroup）。
2. **count++ 是三个动作**：无锁并发自增必丢数——锁 / atomic / 不共享三选一。
3. **Add 写在 go 后面**：`go f(); wg.Add(1)` 是竞态，Wait 可能提前返回——`wg.Go` 免疫。
4. **闭包捕获循环变量**（1.22 前）：老代码 `go func(){print(i)}()` 共享 i——现在每轮新副本，但读老代码要认识这个坑。
5. **WaitGroup 复用不 Reset**：Wait 返回后可以再来一轮，但 Add 与 Wait 并发混用没有定义——一轮结束再开下一轮。
6. **race 检测不报 ≠ 没竞争**：它只抓"跑到过的路径"——测试覆盖率越高它越有用，但静态保证还得靠纪律。

---
