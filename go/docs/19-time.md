# 19 · 时间

> 对应示例：`examples/19_time/`

## 19.1 两个概念：Time（时刻）与 Duration（时长）

```go
var d time.Duration = 2*time.Hour + 15*time.Minute   // 强类型时长，不带单位歧义
d.Milliseconds()          // 8100000
d.Seconds()               // 8100.0

t := time.Now()           // 时刻：含时区 + 单调时钟两套读数
t.Add(90 * time.Minute)   // 时刻 + 时长 = 时刻
t.Sub(u)                  // 时刻 - 时刻 = 时长
```

`time.Duration` 是 int64 纳秒——`3 * time.Second` 写错成 `3`（裸数字）编译器不拦（它就是 3 纳秒），**永远带 time.XXX 单位**。

## 19.2 格式化：参考时间代替 yyyy-MM-dd

```go
t.Format("2006-01-02 15:04:05")    // → 2026-09-17 10:30:00
t.Format("2006/1/2 3:04 PM")       // → 2026/9/17 10:30 AM
t.Format(time.RFC3339)             // 2026-09-17T10:30:00Z（常量现成）
```

布局串不是占位符，是**参考时间的真实长相**（美式顺序：1月2日 3点4分5秒 2006 年——`1 2 3 4 5 6`）。背不下就记 `2006-01-02 15:04:05`，其他布局照着"参考时间该怎么显示"写。

解析是同一个串：

```go
t, err := time.Parse("2006-01-02 15:04:05", "2026-10-01 09:00:00")
```

Parse 失败给的错误信息**精确到哪个字符不对**——比 C 的 strptime 亲切得多。

## 19.3 时区

```go
// Windows 必坑：LoadLocation 需要时区数据库——标准做法是嵌入 tzdata
import _ "time/tzdata"                       // +450KB，换来到处能跑

tokyo, err := time.LoadLocation("Asia/Tokyo")
utc := time.Date(2026, 9, 17, 0, 0, 0, 0, time.UTC)
utc.In(tokyo)                                // 时刻不变，换显示时区

cst := time.FixedZone("CST", 8*3600)         // 固定偏移：不查表、永不失败
```

`time.Time` 内部记着时区，`In(loc)` 只是换个镜头看同一时刻。**比较用 `t.Equal(u)`**：`==` 会连时区一起比，UTC 的 10 点和东京的 19 点（同一瞬间）用 `==` 不相等。

## 19.4 单调时钟：测耗时不受改表影响

```go
start := time.Now()
heavyWork()
fmt.Println(time.Since(start))     // 基于单调时钟读数
```

`time.Now()` 同时带墙钟（被人改系统时间会跳）和单调钟（只前进）——`Since/Until/Sub` 走单调钟。**测量用 Since，对账用墙钟**，Go 替你选好了。

## 19.5 AddDate：月末归一化

```go
jan31 := time.Date(2026, 1, 31, 0, 0, 0, 0, time.UTC)
jan31.AddDate(0, 1, 0)      // 2026-03-03！2 月没有 31 号，进位到 3 月
```

月/日运算按日历翻页，翻到不存在的日期就**顺延**（示例 19 的测试断言了这个行为）。计费类代码按月加减的 bug 高发于此——先想清楚"1 月 31 日 + 1 月"业务上要什么。

## 19.6 Timer / Ticker / After

```go
timer := time.NewTimer(10 * time.Millisecond)
<-timer.C                        // 到点收到一个值；可用 timer.Stop() 提前取消

ticker := time.NewTicker(5 * time.Millisecond)
for range ticker.C {             // 每隔 5ms 收一个
	if done() {
		ticker.Stop()             // 用完显式 Stop（1.23 起不 Stop 不再泄漏，但仍是好习惯）
		break
	}
}

select {
case <-time.After(d):            // 一次性等待（17 章 select 的超时搭档）
}
```

高频循环里 `time.After` 每轮造新 Timer——复用场景用 `NewTimer` + `Reset`。Ticker 在接收方跟不上时会**丢拍**（不排队）——定时任务的重采样语义，要"每秒恰好一次"得自己校正。

## 19.7 时间比较速查

| 需求 | 写法 |
|---|---|
| 相同一瞬间 | `t.Equal(u)` |
| 先后 | `t.Before(u)` / `t.After(u)` |
| 截止时刻 | `deadline := start.Add(d)` + `time.Now().After(deadline)` |
| Unix 秒/毫秒 | `t.Unix()` / `t.UnixMilli()` |
| 从 Unix 构造 | `time.Unix(sec, 0)` |

## 19.8 坑位清单

1. **Windows 上 LoadLocation 报错**：没有系统 tzdata——`import _ "time/tzdata"` 一行解决（示例 19 就带着）。
2. **布局串抄 yyyy-MM-dd**：Java/时刻格式的惯性——Go 只认参考时间 `2006-01-02`，抄错位直接 Parse 失败（错误信息会告诉你差在哪）。
3. **`==` 比时刻**：时区不同的同一瞬间判不等——用 `Equal`。
4. **裸数字当 Duration**：`Sleep(3)` 是 3 纳秒不是 3 秒——单位必须写 `3 * time.Second`。
5. **AddDate 月末进位**：1/31 + 1 月 = 3/3，计费代码的头号暗雷（测试里断言它）。
6. **time.Now() 每次不同**：示例/测试里要确定输出就 `time.Date(...)` 构造固定时刻（本教程所有示例都这么做）。

---
