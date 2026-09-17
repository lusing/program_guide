# 01 · 全景：Go 是什么、凭什么、用什么

## 1.1 设计哲学：少即是多

Go 是 Google 在 2009 年放出的编译型语言，三位作者（Rob Pike、Ken Thompson、Robert Griesemer）的出发点很简单：**C++ 太重、动态语言太散、多核时代缺一门省心的系统语言**。它为此砍掉的东西和留下来的东西一样重要：

| 砍掉了 | 换成了 |
|---|---|
| 类继承 | 结构体嵌入（组合）+ 接口（08/09 章） |
| 异常 | 错误即返回值（10 章） |
| 三种循环 | 只有 `for`（04 章） |
| 头文件 / 声明与实现分离 | 包 + 大写导出（14 章） |
| 手写构建脚本 | `go build` 一个命令（23 章） |
| 线程库 + 锁的海洋 | goroutine + channel（16–18 章） |

一句话：**编译快、部署快（单文件可执行）、并发是一等公民、标准库管饱**。它不适合的场面（模板元编程、极致抽象）恰好是它故意不做的。

## 1.2 版本演进：近五年值得记住的节点

Go 承诺**向后兼容**——1.0 时代的代码今天还能编。但新版本持续把"老姿势"换成更顺手的写法，网上教程鱼龙混杂，先对齐时间线（本教程全部在 **1.27.1** 实测）：

| 版本 | 年份 | 你会用到的 |
|---|---|---|
| 1.21 | 2023 | `min`/`max`/`clear` 内建；`slices`/`maps`/`log/slog` 进标准库 |
| 1.22 | 2024 | **for 循环变量每轮新副本**（并发头号坑就此填平）；`for i := range n`；HTTP 方法路由 |
| 1.23 | 2024 | 迭代器 `iter.Seq` + range over func（13 章） |
| 1.24 | 2025 | `os.Root` 防路径逃逸；`go.mod` 的 `tool` 指令；swiss table map |
| 1.25 | 2025 | `testing/synctest` 假时钟并发测试（15 章）；`WaitGroup.Go`；容器感知 GOMAXPROCS |
| 1.26/1.27 | 2026 | `encoding/json/v2` 默认可用（21 章）；`synctest.Test(t, f)` 新签名 |

> ⚠️ 老教程常见三化石：`err == io.EOF` 直接比较（应 `errors.Is`）、循环变量捕获坑当"必考题"（1.22 已修）、`interface{}` 满天飞（现在是 `any`）。

## 1.3 工具链一览：go 一个命令就是全家桶

```powershell
go version                    # 版本
go run .                      # 编译 + 立即运行（开发期主力）
go build -o out.exe .         # 产可执行文件
go test [-v] [-race] [-bench .]  # 测试 / 竞态检测 / 基准
go vet .                      # 静态检查（可疑代码模式）
go fmt                        # gofmt 的薄封装；格式化就是 gofmt 的输出
go mod init / tidy / graph    # 模块管理（14 章）
go doc fmt.Println            # 命令行看文档
go tool pprof / trace         # 性能画像（23 章）
```

对比 C++（编译器 + CMake + vcpkg + clang-format + clang-tidy 五件套）和 Zig（zig 一个但生态小）：Go 的工具链是**官方一体**的，装好 Go 就什么都有了。

本机安装：Windows 用 scoop 的 `G:\scoop\apps\go\current\bin\go.exe`；macOS 用 MacPorts 的
`/opt/local/bin/go`（官方包则是 `/usr/local/go/bin/go`）。两个验证入口都会自己找 `go`，
PATH 里有就直接 `go` 也行；找不到时用 `GOBIN`（PowerShell 入口）或 `GO=...`（shell 入口）指定。

## 1.4 一个程序长什么样

```go
package main        // 包声明：main 包 + main 函数 = 可执行程序

import "fmt"        // 导入标准库

func main() {       // 入口，无参数无返回值（参数在 flag/os.Args 里拿）
	fmt.Println("你好，Go 1.27！")
}
```

编译成单个 exe，拷到任何 Windows/Linux 机器直接跑——没有运行时依赖、没有 DLL 地狱。这份"部署即复制"是 Go 占领云原生的重要原因。

## 1.5 本教程的走法

24 章三层结构（与 cpp20/zig 教程同一标准）：

- **读讲解**——每章一个主题，代码全部在 1.27.1 上验证过；
- **跑示例**——`examples/NN_xxx/` 与章号对应，`go run .` 立刻看效果；
- **改代码再跑**——每章末尾的"坑位清单"收录了老教程与新版本的全部差异点。

Go 特色全部独立成章细讲：接口（09）、泛型（11）、迭代器（13）、测试（15）、并发三连（16–18）。第 24 章把 flag、正则、并发、文件 IO 组装成一个迷你 grep。

## 1.6 坑位清单

1. **老 GOPATH 教程**：2019 年前的教程教 `go get` 装到 GOPATH——现在是 module 时代（14 章），看见 `GOPATH/src` 直接换教程。
2. **国内拉不下模块**：`go env -w GOPROXY=https://goproxy.cn,direct`。本教程只用标准库，不配置也不影响。
3. **Windows 时区数据库**：`time.LoadLocation` 在 Windows 上需要 `import _ "time/tzdata"`（19 章实测）。
4. **版本漂移**：教程写 1.20 时代的 `interface{}`、`ioutil.*`（已废弃，用 `os.ReadFile`）都能编，但别学。
5. **gofmt 不是可选项**：公司/开源项目一律 `gofmt` 格式，缩进用 tab、行尾无分号——手写风格不一致会被 CI 拦下。

---
