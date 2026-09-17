# Go 编程指南（1.27）

面向**会编程（C/C++ 背景最佳）、初学 Go** 的读者：从零教到现代 Go——`wg.Go`、`range` 整数、迭代器（`iter.Seq`）从对应章节就是默认姿势，老写法（`err == io.EOF`、`interface{}`、`for i := 0; i < b.N; i++`）只在坑位清单里教"认得"。**Go 特色全部独立成章细讲**：接口（09）、泛型（11）、迭代器（13）、测试（15）、并发三连（16–18）、HTTP（22）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例四层验证通过（gofmt + vet + test + 运行 exit 0；并发三章加 `-race`）。

> ⚠️ 网上教程版本混杂（1.20 前的写法与现在差异不小）。本教程所有代码在 **go1.27.1 windows/amd64** 实测，每章坑位清单收录版本差异（含 1.27 的 `synctest.Test` 新签名、`json/v2` 默认可用等）。

## 目录结构

```text
go/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；14/24 为自带 go.mod 的多包工程）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
└── CHEATSheet.md   语法速查 + 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 设计哲学、版本演进（1.21–1.27）、工具链一览 | — |
| [02 第一个程序](docs/02-hello.md) | go run/test、fmt 动词、字节与 rune | `02_hello` |
| [03 类型与变量](docs/03-types.md) | 零值、声明三件套、iota、显式转换 | `03_types` |
| [04 控制流](docs/04-control.md) | for 四形态、range int、switch、标签 | `04_control` |
| [05 函数](docs/05-functions.md) | 多返回值、defer、闭包、高阶函数 | `05_functions` |
| [06 数组切片字符串](docs/06-slices.md) | 三元组、append 扩容、共享底层数组 | `06_slices` |
| [07 map](docs/07-maps.md) | 逗号 ok、nil 陷阱、set 惯用法 | `07_maps` |
| [08 结构体与方法](docs/08-structs.md) | 值/指针接收者、嵌入组合、Stringer | `08_structs` |
| [09 ⭐接口](docs/09-interfaces.md) | 隐式实现、两元组、typed-nil 大坑 | `09_interfaces` |
| [10 错误处理](docs/10-errors.md) | Is/As、%w 包装链、Join、panic 边界 | `10_errors` |
| [11 ⭐泛型](docs/11-generics.md) | 类型参数、约束、cmp.Ordered、何时不用 | `11_generics` |
| [12 slices/maps 标准库](docs/12-collections.md) | SortFunc、Compact、迭代器联动 | `12_collections` |
| [13 ⭐迭代器](docs/13-iterators.md) | iter.Seq/Seq2、range over func、Pull | `13_iterators` |
| [14 包与模块](docs/14-modules.md) | go.mod、internal、init、go.work | `14_module`（工程） |
| [15 ⭐测试](docs/15-testing.md) | 表驱动、基准、模糊、synctest、Example | `15_testing` |
| [16 ⭐并发 I：goroutine](docs/16-goroutines.md) | wg.Go、Once、race 检测器 | `16_goroutines` |
| [17 ⭐并发 II：channel](docs/17-channels.md) | select、关闭协议、worker pool、流水线 | `17_channels` |
| [18 并发 III：同步](docs/18-sync.md) | Mutex/atomic、context 取消超时 | `18_sync` |
| [19 时间](docs/19-time.md) | 参考时间格式化、时区、Timer/Ticker | `19_time` |
| [20 文件与 IO](docs/20-files.md) | io.Reader/Writer、bufio、os.Root、embed | `20_files` |
| [21 JSON](docs/21-json.md) | v1 全套 + json/v2（1.27 默认可用） | `21_json` |
| [22 HTTP 服务](docs/22-http.md) | 方法路由、中间件、httptest、优雅关停 | `22_http` |
| [23 工具链与调试](docs/23-tooling.md) | 交叉编译、pprof/trace、delve、构建信息 | `23_tooling` |
| [24 ⭐实战：迷你 grep](docs/24-minigrep.md) | flag + 正则 + 并发遍历 + 高亮 + 测试 | `24_minigrep`（工程） |

## 构建工具链

- Go **1.27.1**：`G:\scoop\apps\go\current\bin\go.exe`（scoop 安装；版本不符先看 01 章的版本时间线）。
- `-race` 竞态检测依赖 cgo——本机有 gcc（15.2.0），build.ps1 对 16/17/18 三个并发示例自动启用。
- 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8）。

## 验证命令

```powershell
cd G:\code\guide\go
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全部 23 个示例：gofmt+vet+test+运行
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_collections   # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理 build 目录
```

单跑某个示例（每章标准学法）——改代码后重跑：

```powershell
cd go/examples/12_collections
G:/scoop/apps/go/current/bin/go.exe run .      # 改完立刻看效果
G:/scoop/apps/go/current/bin/go.exe test .     # 跑本章测试
```

## 相关教程

系统语言对照：[cpp20（C++20/23）](../cpp20/README.md)、[zig（0.16）](../zig/README.md)、[rust](../rust/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
