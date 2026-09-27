# 33 · 命令行与日志：flag / log / slog / expvar

> 对应示例：`examples/33_flaglog/`。24 章用过 flag 的基础；这里补子命令、自定义类型，把日志两代（log/slog）和运行时指标（expvar）一起讲完。

## 33.1 flag：定义与解析

```go
var (
	verbose = flag.Bool("v", false, "输出详细日志")      // 返回指针
	port    = flag.Int("port", 8080, "监听端口")
	name    = flag.String("name", "world", "问候对象")
)
flag.Parse()                       // 解析到第一个非 flag 参数为止
flag.NArg(), flag.Arg(0)           // 剩下的位置参数
flag.Args()                        // 全部位置参数（[]string）
flag.Visit(func(f *flag.Flag))     // 只遍历"被设置过"的 flag
```

用法自动生成：`-h`/`--help` 打印所有定义，格式就是第三参的说明文字。**bool flag 特殊**：`-v` 后面不跟值（设 true），要显式 false 得写 `-v=false`。等价写法 `-port=9000` / `--port 9000` 都认。

## 33.2 子命令与自定义类型

```go
// 子命令：git 风格——每个子命令一个 FlagSet
fs := flag.NewFlagSet("add", flag.ContinueOnError)   // 出错返回 err 而不是 os.Exit
fs.Int("n", 1, "重复次数")
fs.Parse(args)                                        // args 是去掉子命令名后的参数

// 自定义类型：实现 flag.Value 两方法
type IntList []int
func (l *IntList) String() string { ... }
func (l *IntList) Set(s string) error { /* "1,2,3" → []int{1,2,3} */ }

fs.Var(&repeats, "ids", "逗号分隔的 ID 列表")
```

**测试里别碰全局 flag.Parse**——测试框架自己占着 `-test.*` 参数，解析必炸；永远在 FlagSet 上做（这也是库代码统一用 FlagSet 的原因）。

## 33.3 log：老牌日志（还是 stdlib 默认）

```go
log.Printf("启动 %s", ver)                 // 默认写 stderr：日期时间 + 内容
log.SetFlags(log.LstdFlags | log.Lshortfile) // 加文件:行号
log.SetPrefix("[api] ")
log.Fatal("起不来", err)                    // 打完日志 os.Exit(1)——defer 不执行！
log.SetOutput(os.Stdout)                  // 换目的地（测试里换 io.Discard 静音）

l := log.New(w, "[worker] ", log.LstdFlags|log.Lmsgprefix) // 独立 logger
```

`log.Fatal*` 直接退出——**defer 跳过**，有清理逻辑的路径用 error 往上抛（10 章）。22 章 HTTP 中间件打的就是这个包（默认 stderr，本教程 build 脚本里登记过的"已知豁免"就是它）。

## 33.4 slog：结构化日志（1.21+）

```go
// 键值对而非格式串——日志变成可查询的数据
slog.Info("user login", "user", "ada", "attempts", 3)
slog.Error("db down", "err", err, "host", host)

// 三 handler：文本（人读）、JSON（机器收）、默认（Info 走 log）
h := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,            // 默认 Info——Debug 默认被丢掉
    AddSource: true,                   // 带文件:行号
})
logger := slog.New(h)
logger.Warn("慢查询", "sql", q, "took", time.Millisecond*120)

// 预置字段（中间的 With 链）+ 分组
auth := logger.With("module", "auth").WithGroup("request") // 后续键都进 request 组
auth.Info("hit", "path", "/login")

slog.SetDefault(logger)               // 换掉全局默认（slog.Info 走它）
```

配 `log/slog` 的纪律：**消息是给人看的摘要，字段是给机器查的载荷**——别把动态值拼进消息串。速记构造器 `slog.String/Int/Any` 在热路径少一层反射开销。

## 33.5 expvar：/debug/vars

```go
hits := expvar.NewInt("hits")
hits.Add(1)                                   // 原子

var buildInfo expvar.String                   // String 没有 NewString 构造器
func init() { buildInfo.Set("v1.27"); expvar.Publish("build", &buildInfo) }
expvar.Publish("uptime", expvar.Func(func() any { return time.Since(start).Seconds() }))

// http.Handle("/debug/vars", expvar.Handler()) —— 已注册到 DefaultServeMux（22 章）
```

`/debug/vars` 输出 JSON（附带 runtime 的 memstats 等公共变量），Prometheus 抓它只需格式转换。**同名 Publish 两次直接 panic**——初始化集中在 init/启动期，别在热路径注册。

## 33.6 速查

| 需求 | 用 |
|---|---|
| 简单 CLI | 全局 `flag.Xxx` + `Parse` |
| 子命令 / 库代码 / 测试 | `flag.NewFlagSet` |
| 逗号列表这类参数 | 实现 `flag.Value` + `fs.Var` |
| 快速排错日志 | `log.Printf` |
| 可采集的生产日志 | `slog` + JSONHandler |
| 运行时指标 | `expvar` + `/debug/vars` |

## 33.7 坑位清单

1. **测试里 flag.Parse**：跟 `-test.v` 撞车直接挂——FlagSet 隔离。
2. **`-v false`**：bool flag 不吃后随值——要 `-v=false`。
3. **flag.Parse 后再定义 flag**：不生效——定义全放包级/init，解析放 main。
4. **log.Fatal 吞 defer**：os.Exit(1) 不跑延迟清理——资源要关就用 error 上抛。
5. **slog.Debug 不输出**：默认 LevelInfo——`HandlerOptions{Level: LevelDebug}` 才放行。
6. **slog 消息拼动态值**：`slog.Info("用户" + name + "登录")`——字段化 `slog.Info("用户登录", "user", name)`。
7. **expvar 重复注册同名**：panic——注册只在启动期做一次。
8. **log 与 slog 混着配目的地**：`slog.SetDefault` 后老 `log` 输出也会走新 handler（两者打通），别在两处各配各的。

---
