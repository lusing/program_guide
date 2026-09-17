# 18 · 并发 III：锁、原子与 context

> 对应示例：`examples/18_sync/`（build.ps1 用 `go test -race` 验证）

channel 管"通信"，这一章管"共享状态的防守"与"全局取消"。

## 18.1 sync.Mutex：最基础的锁

```go
type Counter struct {
	mu sync.Mutex        // 惯例：锁字段紧跟它保护的数据，名字 mu
	n  int
}

func (c *Counter) Inc() {
	c.mu.Lock()
	defer c.mu.Unlock()     // defer 解锁：panic 也不忘
	c.n++
}

func (c *Counter) Value() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.n
}
```

三规矩：**锁与数据同住一个结构体**（锁保护谁一目了然）；**defer 解锁**；**临界区越小越好**（锁里别调未知代码——IO、回调、可能再锁的函数都是死锁预约）。

## 18.2 sync.RWMutex：读多写少

```go
func (c *SafeCache) Get(key string) (string, bool) {
	c.mu.RLock()             // 读锁：可多路并发
	defer c.mu.RUnlock()
	v, ok := c.data[key]
	return v, ok
}

func (c *SafeCache) Set(key, val string) {
	c.mu.Lock()              // 写锁：独占
	defer c.mu.Unlock()
	c.data[key] = val
}
```

读锁是共享的、写锁排他。**读远多于写才有赚**（缓存、配置快照）；读写各半时 RWMutex 比 Mutex 更慢。

## 18.3 sync/atomic：单变量的无锁操作

```go
var n atomic.Int64
n.Add(1)              // 原子自增
n.Load()              // 原子读
n.CompareAndSwap(1, 2)

var p atomic.Pointer[Config]     // 泛型指针（1.19+）
p.Store(newCfg)
cfg := p.Load()                  // 无锁读配置快照
```

计数器、标志位、单槽快照——一个变量的并发访问，atomic 比 Mutex 快且免忘锁。超过一个变量需要**一致性地**变，就得锁。

## 18.4 sync.Map 一瞥

并发 map 的官方答案之一：读多写少、键集合稳定（如只增的缓存）时用 `sync.Map`；其余场景 `map + RWMutex` 更直白（07 章说过：**裸 map 并发读写直接 fatal**，连 recover 都救不了）。

## 18.5 context：取消、超时、请求级数据

```go
// 超时：50ms 后自动取消
ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
defer cancel()                       // 惯例：拿到 cancel 立刻 defer，防泄漏

// 干活函数：select 同时听"干完了"和"上头叫停了"
func Fetch(ctx context.Context, name string, work time.Duration) (string, error) {
	select {
	case <-time.After(work):
		return name + " 的数据", nil
	case <-ctx.Done():             // 取消信号
		return "", ctx.Err()       // context.DeadlineExceeded 或 Canceled
	}
}
```

ctx 是**自顶向下的树**：请求进来建根 ctx，每层函数第一个参数透传 `ctx context.Context`，任何一层超时/取消，整棵子树收到信号。规矩：

- `ctx` 永远是**第一个参数**，名字就叫 ctx；
- `WithTimeout/WithCancel/WithDeadline` 返回的 cancel **必须被调用**（defer）；
- 主动叫停：`WithCancel` 的 cancel 想啥时候叫啥时候调（示例 18 的另一路 goroutine 调它）；
- `WithValue` 只放请求级元数据（reqID、登录身份），**别当全局变量使**。

标准库全线认 ctx：`http.NewRequestWithContext`、`db.QueryContext`、`t.Context()`（1.24+，测试结束自动取消）。

## 18.6 选型速查

| 场景 | 工具 |
|---|---|
| 等一组任务收工 | `WaitGroup`（16 章） |
| 就初始化一次 | `sync.Once` / `OnceValue` |
| 保护一段临界区 | `Mutex` |
| 读多写少的缓存 | `RWMutex` |
| 单变量计数/标志/单槽 | `atomic` |
| goroutine 间传数据 | channel（17 章） |
| 全局取消/超时 | `context` |
| errgroup 风格"一错全停" | `golang.org/x/sync/errgroup`（标准库外，值得知道） |

## 18.7 坑位清单

1. **锁拷贝**：`func (c Counter)` 值接收者把 Mutex 一起拷了——锁形同虚设；vet 的 copylocks 检查器专抓（含结构体里藏 Mutex 的传值）。
2. **map 并发读写是 fatal 不是 panic**：recover 救不回，进程直接退——要么锁要么 sync.Map。
3. **RWMutex 重入死锁**：读锁里再拿读锁（同 goroutine）会自锁——Go 的锁都不可重入，需要重入是设计问题。
4. **cancel 不调 → 泄漏**：WithTimeout 的计时器挂在树上直到 cancel——defer cancel() 是肌肉记忆。
5. **ctx 塞业务参数**：WithValue 传"这次请求要查哪个用户"——看到这种设计就重构，参数走参数。
6. **原子拼凑一致性**：两个变量各自 atomic 但要一起变——观察者会看到"一半新一半旧"，该上锁了。

---
