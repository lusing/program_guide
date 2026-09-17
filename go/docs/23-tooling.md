# 23 · 工具链与调试

> 对应示例：`examples/23_tooling/`（含 pprof/trace 落盘、构建信息读取）

## 23.1 交叉编译：一行命令，全平台

```powershell
# Windows / PowerShell：环境变量是 $env: 前缀，且要单独语句设
$env:GOOS="linux";   $env:GOARCH="amd64"; go build -o app-linux .
$env:GOOS="darwin";  $env:GOARCH="arm64"; go build -o app-mac .
$env:GOOS=""; $env:GOARCH=""                      # 用完清掉
```

```bash
# macOS / Linux：环境变量写在命令前面就行，只作用于这一条命令，不留残留
GOOS=linux  GOARCH=amd64 go build -o app-linux .
GOOS=darwin GOARCH=arm64 go build -o app-mac .
```

Go 编译器**原生跨平台**（对比 Zig 的 `-target` 同款能力）：本机编 Linux 二进制不用工具链、不用容器。纯 Go 代码零障碍；牵扯 cgo（race 检测、某些数据库驱动）才需要目标平台的 C 编译器。

本仓库 `run-all.sh` 末尾会按 `windows/amd64`、`linux/amd64`、`darwin/arm64` 各编一遍全仓库，交叉编译不过就报失败——这能抓出"只在某一平台编译得过"的问题（误用 syscall 常量、构建标签写错等）。

常用组合：`linux/amd64`（服务器）、`linux/arm64`（ARM 云/树莓派）、`darwin/arm64`（Apple Silicon）、`windows/amd64`。`go tool dist list` 看全表。

## 23.2 构建标签与注入

```go
//go:build windows          // 文件顶部：整个文件只在 Windows 编译

var buildNote = "开发版"     // 构建期注入：-X 包.变量=值
```

```powershell
go build -ldflags "-s -w -X main.buildNote=v1.2.0" -o app.exe .
# -s -w 去符号表：体积减 30%（代价：panic 栈只剩地址）
# -X 往 string 变量里塞版本号——CI 打 tag 的标准动作
```

示例 23 有 `version_windows.go` / `version_other.go` 一对文件演示构建标签的"平台分支"；`buildNote` 演示 -X 注入。（下文命令里的 `app.exe` 是 Windows 写法，macOS/Linux 上去掉 `.exe`。示例 23 打印的 pprof 命令会按 `runtime.GOOS` 现算后缀，两个平台都对。）

## 23.3 构建信息：从二进制里读出身

```go
if bi, ok := debug.ReadBuildInfo(); ok {
	fmt.Println(bi.GoVersion)          // 编译用的 Go 版本
	for _, s := range bi.Settings {    // vcs.revision / vcs.time / -ldflags…
		_ = s
	}
}
```

`go build` 在 git 仓库里自动嵌版本信息——**运行中的服务能自报编译出身**（诊断神器）。命令行版：`go version -m app.exe` 看同一份数据（含依赖清单）。

## 23.4 pprof：性能画像

```go
import "runtime/pprof"

f, _ := os.CreateTemp("", "cpu-*.prof")
pprof.StartCPUProfile(f)
heavyWork()
pprof.StopCPUProfile()

// 堆画像（随时快照）
pprof.WriteHeapProfile(f)
```

```powershell
go tool pprof app.exe cpu-xxxx.prof    # 交互式：top / web / list 函数名
```

长跑服务的姿势是 `import _ "net/http/pprof"`——`/debug/pprof/` 网页全套画像（线上性能问题的金标准）。看什么：CPU 的 `top10` 找热点函数，`allocs` 找分配狂魔（15 章基准的 B/op 对上）。示例 23 的 ProfileCPU 落盘了一个真实画像。

## 23.5 trace：调度器视角

```go
import "runtime/trace"

trace.Start(f)
concurrentWork()
trace.Stop()
```

```powershell
go tool trace trace-xxxx.out    # 浏览器打开：goroutine 调度 / GC / 阻塞时间线
```

pprof 答"哪段代码慢"，trace 答"**为什么慢**"——goroutine 在等锁、等 channel 还是 GC 暂停，时间线一眼见。并发问题（18 章）卡壳时先跑 trace。

## 23.6 调试器与运行时

```powershell
go install github.com/go-delve/delve/cmd/dlv@latest   # Go 官方推荐的调试器
dlv debug ./examples/24_minigrep -- -n func main.go    # 断点调试
dlv test ./internal/grep                              # 调测试
```

IDE（VS Code 的 Go 扩展 / GoLand）底层就是 dlv。运行时自省：`runtime.NumCPU()`、`GOMAXPROCS(0)`、`runtime.GC()`；1.25 起 GOMAXPROCS 在容器里**自动对齐 CPU 配额**（cgroup 限 2 核就不再默认开满 16 核）。

## 23.7 常用体检命令

```powershell
go vet ./...          # 静态检查（copylocks、printf 动词错配、锁拷贝…）
gofmt -l .            # 格式检查（本仓库 build.ps1 在用）
go test -race ./...   # 竞态（16 章）
go test -cover        # 覆盖率（15 章）
go build ./...        # 全包编译检查
go doc net/http.Handler   # 命令行文档
```

CI 最小集就这五条：fmt + vet + test（带 race）+ build + cover。

## 23.8 坑位清单

1. **GOOS 设置后忘清**：终端里 `$env:GOOS="linux"` 残留，下一个 build 编出 Linux exe 在 Windows 上跑不了——用完清空（或每次开新会话）。
2. **-s -w 去符号后难排障**：panic 栈没函数名——追求体积前先确认不需要栈。
3. **vcs 信息嵌入失败**：构建目录不在 git 仓库（或 .git 损坏）时静默缺失——`go build -buildvcs=false` 明示关掉，别让它意外参与构建缓存。
4. **pprof 采样太短**：几毫秒的画像没有统计意义——CPU profile 至少几秒（示例 23 采了 200ms 只为演示流程）。
5. **net/http/pprof 暴露公网**：/debug/pprof 是信息泄露面——只在内部端口监听或加鉴权。
6. **dlv 版本对不上**：delve 滞后于新 Go 版本会报 internal error——`go install ...@latest` 更新。

---
