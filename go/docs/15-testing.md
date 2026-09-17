# 15 · 测试 ⭐

> 对应示例：`examples/15_testing/`（被测对象：wordwrap.go 的 WordWrap）

测试在 Go 里是**语言内建**：`_test.go` 后缀 + `go test`，零框架零配置。示例 15 是完整示范——单元、基准、模糊、示例输出、假时钟并发测试一应俱全。

## 15.1 表驱动测试：Go 的招牌形态

```go
func TestWordWrap(t *testing.T) {
	cases := []struct {
		name  string
		in    string
		width int
		want  []string
	}{
		{"正好一行放下", "go is fun", 10, []string{"go is fun"}},
		{"折成两行", "go is fun", 5, []string{"go is", "fun"}},
		{"空串", "", 10, nil},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {     // 子测试：失败时带用例名
			if !slices.Equal(WordWrap(tc.in, tc.width), tc.want) {
				t.Errorf("WordWrap(%q,%d) 得 %q", tc.in, tc.width, WordWrap(tc.in, tc.width))
			}
		})
	}
}
```

对比一用例一函数的写法：新增用例只加一行结构体字面量。断言没有 assert 库——`if` + `t.Errorf` 就是官方姿势（要第三方就 testify，但 std 能打）。

## 15.2 三个报错方法

| 方法 | 行为 |
|---|---|
| `t.Error/T.Errorf` | 记失败，**继续跑**（能一次看全所有失败） |
| `t.Fatal/T.Fatalf` | 记失败，**立即终止本测试**（后续代码依赖前置时用） |
| `t.Skip/Skipf` | 跳过（环境不满足、未实现） |

**辅助函数开头 `t.Helper()`**——让报错行号定位到调用处而不是辅助函数内部。

## 15.3 Example 函数：文档即测试

```go
func ExampleWordWrap() {
	for _, l := range WordWrap("go is simple go is fast", 9) {
		fmt.Println(l)
	}
	// Output:
	// go is
	// simple go
	// is fast
}
```

`go test` 逐行核对 `// Output:` 注释与真实输出——**示例文档永远不会过期**（本仓库示例 15 的 Example 抓到过我手算的折行错误）。格式化输出的空白敏感，`// Unordered output:` 是乱序版。

## 15.4 基准测试：b.Loop（1.24+）

```go
func BenchmarkWordWrap(b *testing.B) {
	text := strings.Repeat("the quick brown fox ", 100)
	for b.Loop() {              // 新姿势：自动排除准备代码 + 防优化掉循环体
		_ = WordWrap(text, 40)
	}
}
```

```powershell
go test -bench . -benchmem
# BenchmarkWordWrap-16   20000   58 ns/op   256 B/op   1 allocs/op
```

`b.Loop()` 取代老的 `for i := 0; i < b.N; i++` + `b.ResetTimer()` 组合。看三个数：ns/op（单次耗时）、B/op（单次分配字节）、allocs/op（分配次数）——**减分配往往比减计算更见效**。

## 15.5 模糊测试：让机器造输入

```go
func FuzzWordWrap(f *testing.F) {
	f.Add("go is fun", 5)          // 种子语料
	f.Fuzz(func(t *testing.T, s string, width int) {
		for _, line := range WordWrap(s, width) {
			if len(line) > width && strings.Contains(line, " ") {
				t.Fatalf("行 %q 超宽且含空格", line)   // 断言不变量，不是精确值
			}
		}
	})
}
```

```powershell
go test -fuzz=FuzzWordWrap -fuzztime=10s   # 随机探索 10 秒
```

平时 `go test` 只回放种子（零成本回归）；开 `-fuzz` 才随机变异。模糊测试断言的是**不变量**（任何输入下都成立的性质），不是精确输出。崩溃语料自动存进 `testdata/fuzz/`，提交后永久回归。

## 15.6 synctest：并发代码的假时钟（1.25+）

```go
func TestConcurrentSleepSynctest(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {     // 1.27 实测签名（老教程是 Run(func())）
		start := time.Now()
		var wg sync.WaitGroup
		for i := range 5 {
			wg.Go(func() { time.Sleep(time.Duration(i) * time.Minute) })
		}
		wg.Wait()                              // 全部阻塞 → 气泡时间直接快进
		if time.Since(start) < 4*time.Minute { t.Error("时间没走够") }
	})
}
```

气泡（bubble）内的 time 是**假时钟**：所有 goroutine 阻塞时时间瞬移到下一个唤醒点——"等 4 分钟"的测试 0.001 秒跑完。规则：气泡里别碰真 IO（网络、文件）——那些不Durably 阻塞，时间不前进。

## 15.7 测试环境的挂件

```go
t.Parallel()                // 与其他测试并发（默认串行）
dir := t.TempDir()          // 独立临时目录，测试结束自动删
t.Cleanup(func() { ... })   // 注册清理，LIFO 执行
ctx := t.Context()          // 测试专用 context，结束自动取消（1.24+）
sub := t.Run("名", fn)       // 子测试（可与并行组合）
```

`t.TempDir` 的清理也是 t.Cleanup 挂的——**后注册先执行**，想"事后检查"就得先挂自己的清理再要目录（示例 15 有这个顺序演示）。

## 15.8 覆盖率与命令速查

```powershell
go test -cover                          # 覆盖率百分比
go test -coverprofile=c.out && go tool cover -html=c.out   # 热力图
go test -v -run TestName                # 只跑某个（支持正则）
go test -race                           # 竞态检测（16 章主角）
go test -count=1 ./...                  # 禁缓存全量重跑
go test -shuffle=on                     # 随机顺序（揪出测试间依赖）
```

## 15.8 坑位清单

1. **Example 的 Output 必须逐字符匹配**：末尾多一个空格都挂——打印前想清楚，或用 `%q` 把空白显形。
2. **Fatal 在 goroutine 里不生效**：t.Fatal 只终止调用它的 goroutine——子 goroutine 里用 Error + 通道回传，或 t.Errorf。
3. **测试缓存错觉**："没跑"可能是缓存命中——`-count=1` 强制重跑。
4. **synctest 里做真 IO**：网络/文件读不推进假时钟，气泡永远不 idle → 死锁 panic——气泡里只用内存与通道。
5. **b.N 手动计时老姿势**：新代码 `b.Loop()`；教程里 `for i := 0; i < b.N; i++` 还会存在很多年，认识即可。
6. **断言第三方库的坑**：testify 的 assert（不中断）vs require（中断）混用导致失败后继续跑出僵尸错误——团队统一选一个。

---
