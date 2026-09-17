# 24 · 实战：迷你 grep ⭐

> 对应示例：`examples/24_minigrep/`（自带 go.mod 的多包工程）

把前 23 章组装成一个真工具：**flag 解析（03/05）+ 正则（12）+ 并发遍历（16/17）+ 文件 IO（20）+ 工程组织（14）**。

## 24.1 需求与用法

```text
minigrep [-i] [-r] [-n] [-c auto|always|never] 模式 [文件或目录...]
```

对齐 grep 惯例：`-i` 忽略大小写、`-r` 递归、`-n` 行号、`-c` 着色；退出码 0 = 有命中、1 = 无命中、2 = 用法错误。目录默认跳过隐藏项（.git 不搜）。

## 24.2 工程结构：逻辑进 internal、入口进 main

```text
examples/24_minigrep/
├── go.mod                     # module minigrep（嵌套模块）
├── main.go                    # 薄入口：flag + 输出格式 + 退出码
└── internal/grep/
    ├── grep.go                # Matcher / SearchFile / SearchTree
    └── grep_test.go           # 单元测试（不依赖命令行）
```

main 包只有 `run()` 一个函数——**能在 internal 里测的逻辑绝不停留在 main**（14 章的规矩落地）。

## 24.3 flag：标准库的命令行解析

```go
opts := grep.Options{}
flag.BoolVar(&opts.IgnoreCase, "i", false, "忽略大小写")
flag.BoolVar(&opts.Recursive, "r", false, "递归搜索目录")
flag.StringVar(&opts.ColorMode, "c", "auto", "颜色 auto|always|never")
flag.Usage = func() { ... }            // 定制 -h 输出
flag.Parse()

pattern := flag.Arg(0)                 // 位置参数：模式
targets := flag.Args()[1:]             // 其余：目标列表
```

比手撕 `os.Args` 强在：类型化（直接灌进结构体）、自动 `-h`、错误用法自动报。多子命令（git 风格）就每子命令一个 `flag.NewFlagSet`。

## 24.4 正则：编译一次，处处复用

```go
func NewMatcher(pattern string, ignoreCase bool) (*Matcher, error) {
	if ignoreCase {
		pattern = "(?i)" + pattern         // 前缀开关：忽略大小写
	}
	re, err := regexp.Compile(pattern)
	if err != nil {
		return nil, fmt.Errorf("正则不合法 %q: %w", pattern, err)   // 10 章包装
	}
	return &Matcher{re: re}, nil
}
```

`regexp` 是 RE2 引擎：**线性时间保证**（没有灾难性回溯），代价是不支持反向引用。`(?i)`/`(?m)` 这类内联开关塞在模式前面。高亮用 `ReplaceAllStringFunc` 把每处命中包 ANSI 色：

```go
m.re.ReplaceAllStringFunc(line, func(s string) string {
	return "\x1b[31m" + s + "\x1b[0m"    // 红色前景 + 重置
})
```

## 24.5 并发搜索：WalkDir + worker pool

```go
// ① 串行收集文件（WalkDir + SkipDir 跳隐藏目录）
filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error { ... })

// ② worker pool（17 章三角的实战版）
jobs := make(chan string)
results := make(chan []Match)
var wg sync.WaitGroup
for range min(runtime.NumCPU(), 8) {
	wg.Go(func() {                        // 16 章 wg.Go
		for path := range jobs {
			hits, _ := SearchFile(path, m, opts)   // 20 章流式扫描
			if len(hits) > 0 {
				results <- hits
			}
		}
	})
}
go func() {
	for _, f := range files { jobs <- f }
	close(jobs)
	wg.Wait()
	close(results)                        // fan-in 收尾
}()
for hits := range results { all = append(all, hits...) }

// ③ 排序：并发结果按 (路径, 行号) 定序——输出确定、测试可断言
slices.SortFunc(all, ...)
```

**为什么排序不是可有可无**：worker 并发完成顺序随机，不排序输出每次不同——11 章测试没法写、用户 diff 也没法看。确定性是工具的基本礼仪。

## 24.6 输出：管道自动关色

```go
color := opts.ColorMode == "always" ||
	(opts.ColorMode == "auto" && isTerminal(os.Stdout))

func isTerminal(f *os.File) bool {
	info, _ := f.Stat()
	return info.Mode()&os.ModeCharDevice != 0    // 字符设备 = 终端
}
```

`auto` 模式下管道/重定向自动关色（ANSI 码混进重定向文件是所有 grep 类工具的经典脏点）；`-c always` 强制开（`less -R` 场景）。本仓库 build.ps1 管道运行验证的正是无色路径。

## 24.7 验证与测试

```powershell
cd go/examples/24_minigrep
go run . -n "func \w+" main.go          # 立刻玩
go run . -rn "TODO" .                   # 递归搜目录
go test ./internal/grep -v              # 单元：匹配/高亮/遍历/隐藏目录
```

测试覆盖（grep_test.go）：匹配语义（大小写两种）、非法正则报错、高亮转义码精确断言、SearchTree 的文件收集（含 .git 跳过）、零命中路径。build.ps1 对本工程跑四层验证后还执行 `minigrep func main.go`——**工具自己搜自己的源码**，命中退出 0。

## 24.8 扩展练习

1. `-v` 反选（不匹配的行）——一行搞定，试试；
2. `-c` 计数模式（只报每文件命中数）；
3. 用 `errgroup`（18 章坑位提过）替换 WaitGroup：worker 出错提前收摊；
4. 输出改 `iter.Seq[Match]` 惰性流（13 章）：边搜边打，不等全部完成。

## 24.9 坑位清单

1. **regexp 每行重新 Compile**：编译是重活（微秒级 × 百万行 = 秒级）——Matcher 模式编译一次是底线。
2. **SearchFile 里 defer f.Close() 挪进循环**：单文件一次 Open/Close，循环在函数外——defer 挂错层积压句柄。
3. **Worker 里吞错**：`hits, _ := SearchFile(...)` 把读失败当空——生产版要把错误传出去（channel 或 errgroup）。
4. **隐藏目录判断漏了根**：`path != root` 条件不写，`minigrep -r .` 会因 "." 以点开头直接跳过一切（测试里防的就是这个）。
5. **Windows 终端 ANSI**：Windows Terminal / VS Code 默认支持；老 conhost 要色码支持得开 VT——`-c never` 永远是安全兜底。

---
