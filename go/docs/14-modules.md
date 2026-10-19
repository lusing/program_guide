# 14 · 包与模块

> 对应示例：`examples/14_module/`（自带 go.mod 的多包工程，零外部依赖、可离线验证）。
> 本章凡是"需要联网"的命令，都用真实模块 `rsc.io/quote` 在 **go1.27.2 + `GOPROXY=https://goproxy.cn,direct`** 下实测过，输出原样贴进正文；离线可复现的部分（`go mod edit`、`go.work`、`replace` 到本地目录）则不依赖网络。读完这一章，你不需要再翻任何外部文档——模块系统的全部日常用法都在这里讲清楚。

模块（module）是 Go 的**依赖管理 + 可复现构建**系统，`go.mod` 是它的账本。这一章把官方《Go Modules Reference》的内容提炼成一条能照着做的线：先讲清"包 / 模块 / 模块路径"三个层次，再逐条精讲 `go.mod` 的每个指令，然后讲版本号怎么读、MVS 怎么选版本、`go.sum` 怎么防偷换、命令全家桶怎么用、多模块联调的 `go.work`、代理与私有模块，最后是发布流程与工程布局。

## 14.1 从 GOPATH 到模块：为什么要有 go.mod

2019 年以前，Go 只有 **GOPATH 模式**：所有第三方代码都 `go get` 到一个全局目录 `$GOPATH/src` 下，一个包全机器只能有一份，**没有版本概念**。后果是经典的"依赖地狱"——A 库要 `foo v1`、B 库要 `foo v2`，全机器只能装一个，装错了就编译失败；换台机器、换个时间 `go get`，拉到的代码可能已经变了，构建不可复现。

**模块模式**（module mode）就是来解决这三件事的：

1. **版本化**：每个依赖钉在具体版本（`foo v1.2.3`），不同库可以各自要不同版本，由 MVS（14.5）算出一个大家都能用的版本；
2. **可复现**：`go.mod` 记下"要哪些版本"，`go.sum` 记下"这些版本的内容哈希"，换机器、换时间拉到的字节完全一致；
3. **去中心化 + 防偷换**：依赖通过模块代理（14.9）拉取，并由全局校验和数据库（14.6）背书，别人塞给你的代码动过一个字节都会被发现。

`GO111MODULE` 这个开关从 **Go 1.16 起默认 `on`**，GOPATH 模式已成历史。现在写 Go 一律是模块模式：只要目录里有 `go.mod`，`go build`/`go test`/`go run` 就以它为根。看见老教程教 `go get` 把代码装进 `GOPATH/src`，直接换教程。

## 14.2 三个层次：包、模块、模块路径

这三个词天天混用，先把边界划清：

- **包（package）**：同一个目录下所有 `.go` 文件的集合，是**编译单位**。包名 ≈ 目录名（`main` 包除外）。导入一个包，导入的是它的**导入路径**。
- **模块（module）**：一个 `go.mod` 管辖的一组包，是**版本化与依赖管理的单位**。一个模块可以有任意多个包（子目录），它们共享同一个版本号和同一份 `go.mod`。
- **模块路径（module path）**：`go.mod` 第一行 `module` 后面那个字符串，它是**模块内所有包导入路径的公共前缀**。比如模块路径是 `example.com/hello`，它下面 `greet` 子目录的包，导入路径就是 `example.com/hello/greet`。

一句话记法：**导入路径 = 模块路径 + 包在模块内的相对目录**。

本教程的结构正好演示了"模块可以嵌套"：根目录有一个 `go.mod`（模块 `guidego`），绝大多数示例 `examples/NN_xxx` 都是它里面的一个 `main` 包；但 `14_module` 和 `24_minigrep` 两个示例**自带独立的 `go.mod`**——

```text
go/go.mod                      module guidego
go/examples/14_module/go.mod   module layout      ← 嵌套模块
```

**嵌套模块是独立王国**：外层在 `go/` 里跑 `go build ./...` 不会踏进 `examples/14_module`，因为它有自己的 `go.mod`，归它自己管。这也是 `run-all.sh` 要单独 `cd` 进这两个目录编译的原因。

`examples/14_module/go.mod` 全部内容就两行：

```text
module layout

go 1.27.1
```

`module layout` 是模块路径（这里不起域名，因为它是纯本地、不发布的模块，路径随便取）；`go 1.27.1` 声明它需要的最低 Go 版本。在这个模块里查它的身份，输出是真实的：

```bash
cd examples/14_module
go list -m            # 打印主模块路径
```
```text
layout
```

`go list -m` 不带参数就是"我现在在哪个模块里"。加 `all` 会列出整个构建列表（14.5），这个零依赖模块的构建列表只有它自己：

```bash
go list -m all
```
```text
layout
```

## 14.3 go.mod 逐指令精讲

`go.mod` 是一个纯文本文件，由若干**指令（directive）**组成。指令可以单行写，也可以用括号写成块。下面把每个指令的**语法、语义、什么时候用**讲透，并给出真实生成的文件内容。

先看一个把所有指令都塞进去的"全家福"（用 `go mod edit` 一条条加出来的，命令见 14.7，文件内容是真实的）：

```text
module example.com/editdemo

go 1.27.2

toolchain go1.27.2

require (
	example.com/dep v1.2.3
	example.com/dep/v2 v2.0.0
)

exclude example.com/dep v1.2.0

replace example.com/bad v1.0.0 => example.com/good v1.0.0

retract (
	[v1.0.0, v1.0.5]
	v0.9.0
)

tool golang.org/x/tools/cmd/stringer

godebug default=http2debug=0
```

逐个拆。

### module —— 模块路径

```text
module example.com/hello
```

模块路径是这个模块所有包的导入前缀，也是别人 `go get` 你时用的名字。命名规则：

- 由斜杠分隔的若干段组成，每段只能用 ASCII 字母、数字和 `- . _ ~`，不能以点开头或结尾，不能有空段；
- **要发布的模块**，第一段必须是你拥有的域名（`github.com/you/proj`、`example.com/foo`）——代理和 `go get` 靠它去对应的代码仓库取货；
- **纯本地、不发布的模块**（比如本教程的 `guidego`、`layout`），路径可以随便取，不需要域名；
- **主版本号 ≥ 2 的模块，路径必须以 `/vN` 结尾**（`example.com/dep/v2`）——这叫语义导入版本化（SIV），见 14.4。上面全家福里 `example.com/dep v1.2.3` 和 `example.com/dep/v2 v2.0.0` 是**两个不同的模块路径**，可以在同一个构建里共存，互不打架。

初始化一个新模块：

```bash
go mod init example.com/hello    # 在当前目录生成 go.mod
```

`go mod init` 会写两行：`module <你给的路径>` 和 `go <当前工具链版本>`。如果你在一个已经 `import` 了第三方包的目录里 init，它还会顺手把缺的依赖 `require` 进来。

### go —— 最低版本 + 语言版本

```text
go 1.27.2
```

`go` 指令做两件事：

1. **声明这个模块要求的最低 Go 版本**。如果你的工具链比它旧，`go` 命令会（在 `GOTOOLCHAIN=auto` 下）**自动下载并切换**到满足要求的工具链再编译——这就是 Go 1.21 起的工具链管理（见下条 `toolchain`）。
2. **锁定语言语义版本**。Go 保证向后兼容，但偶尔会引入"新写法"（比如 1.22 的 `range` 整数、1.23 的迭代器）。`go 1.27.2` 意味着这个模块按 1.27 的语言规则编译；一个 `go 1.20` 的模块即使被 1.27 工具链编译，也按 1.20 的语义走，避免"升级工具链就悄悄改了行为"。

从 Go 1.21 起，`go` 行允许（且 `go mod init` 默认）写到**补丁号**（`1.27.2` 而不只是 `1.27`）。

### toolchain —— 建议用哪个工具链

```text
toolchain go1.27.2
```

`toolchain` 声明"建议用 go1.27.2 这个工具链来构建"。它和 `go` 的区别：`go` 是**底线**（低于它就编不了），`toolchain` 是**建议**（比本地新才切换）。规则：`toolchain` 的版本**不能低于** `go` 指令的版本。`GOTOOLCHAIN=auto`（默认）时，`go` 命令会在 `go`/`toolchain` 声明的版本比本地新时自动拉取；`GOTOOLCHAIN=local` 则永远用本地装的、绝不下载。多数项目不写 `toolchain`，只写 `go` 就够了。

### require —— 依赖清单（直接 vs 间接）

```text
require example.com/dep v1.2.3

require (
	example.com/other v1.0.0
	example.com/transitive v0.3.1 // indirect
)
```

`require` 声明"本模块构建需要哪个模块的哪个版本"。行尾的 `// indirect` 注释是 `go` 命令自动维护的标记，含义是：**这个依赖没有被本模块的任何包直接 `import`**，它是"依赖的依赖"（传递依赖），或者是为了模块图剪枝（14.5）而显式记下来的。

直接依赖和间接依赖在文件里通常分成两个 `require` 块（`go mod tidy` 会帮你整理）。看一个真实的例子——一个 `main.go` 只 `import "rsc.io/quote"` 的模块，`go get` 之后再 `go mod tidy`，`go.mod` 长这样：

```text
module example.com/netdemo

go 1.27.2

require rsc.io/quote v1.5.2

require (
	golang.org/x/text v0.0.0-20170915032832-14c0d48ead0c // indirect
	rsc.io/sampler v1.3.0 // indirect
)
```

读这份文件：`rsc.io/quote v1.5.2` 没有 `// indirect`，因为 `main.go` 直接导入了它，是**直接依赖**；`rsc.io/sampler` 和 `golang.org/x/text` 带 `// indirect`，因为代码里没直接导入它们——`quote` 依赖 `sampler`、`sampler` 依赖 `x/text`，是**传递依赖**。你只需要关心直接依赖那一行，间接的那块交给 `go mod tidy` 自动维护。

> 小坑：刚 `go get rsc.io/quote@v1.5.2` 完、还没 `tidy` 时，`go.mod` 里**三个依赖全被标成 `// indirect`**（连你直接导入的 `quote` 也是）。`go get` 只负责把版本写进 `require`，不扫描你的 `import`；是 `go mod tidy` 才会把"你真正 import 的"提升为直接依赖、去掉它的 `// indirect`。所以 **`go get` 之后记得 `go mod tidy`**。

### exclude —— 拉黑某个版本

```text
exclude example.com/dep v1.2.0
```

`exclude` 告诉 `go` 命令："算版本的时候，把 `example.com/dep v1.2.0` 当不存在。" 如果别的依赖正好要了这个版本，MVS 会跳过它、选下一个更高的版本。这是给"某个版本坏了、但你改不了上游"时用的应急开关，**日常几乎用不到**——正常做法是升级依赖或让上游 `retract`（见下）。

### replace —— 偷梁换柱

```text
replace example.com/bad v1.0.0 => example.com/good v1.0.0
replace example.com/greet v1.0.0 => ../greet
```

`replace` 把"某个模块（的某个版本）"替换成"另一个模块版本"或"本地目录"。两种右侧：

- **换成另一个模块版本**：`=> example.com/good v1.0.0`，常用于临时用 fork 替换上游；
- **换成本地目录**：`=> ../greet`，常用于**本地多模块联调**——改了 `../greet` 的代码立刻生效，不用发版。

左侧不带版本号（`replace example.com/greet => ../greet`）表示**替换它的所有版本**。

两条铁律：

1. **只有主模块（你正在构建的那个模块）的 `replace` 生效**；依赖自己 `go.mod` 里写的 `replace` 会被**忽略**。否则一个依赖就能偷偷改写你整个构建，太危险。
2. **被替换成本地目录的模块不进 `go.sum`、不联网拉取**——本地代码就在磁盘上，没有"内容哈希防偷换"的必要。

下面是一个真实、离线可复现的 `replace` 演示。先有一个库模块 `greet`：

```go
// greet/greet.go
package greet

func Hello(name string) string { return "hello, " + name }
```

再有一个 `main` 模块 `hello`，它 `import "example.com/greet"`，但用 `replace` 把 `greet v1.0.0` 指到本地的 `../greet` 目录（这样**完全不联网**也能编）：

```go
// hello/main.go
package main

import (
	"fmt"

	"example.com/greet"
)

func main() { fmt.Println(greet.Hello("modules")) }
```

`hello/go.mod` 用 `go mod edit` 加上 `require` 和 `replace` 后是这样：

```text
module example.com/hello

go 1.27.2

require example.com/greet v1.0.0

replace example.com/greet v1.0.0 => ../greet
```

构建、运行、查依赖，全程离线：

```bash
cd hello
go build -o hello.bin . && ./hello.bin
```
```text
hello, modules
```
```bash
go list -m all
```
```text
example.com/hello
example.com/greet v1.0.0 => ../greet
```

`go list -m all` 里那行 `example.com/greet v1.0.0 => ../greet` 就是 `replace` 生效的证据：它没有去网上找 `greet v1.0.0`，而是用了本地目录。而且这个模块目录下**没有 `go.sum` 文件**——被 `replace` 到本地的依赖不需要校验和。

### retract —— 撤回坏版本（发布方用）

```text
retract (
	[v1.0.0, v1.0.5]
	v0.9.0
)
```

`retract` 是**模块发布方**用的：声明"我自己的某些版本是坏的，别用"。可以撤单个版本（`retract v0.9.0`），也可以撤一个**闭区间**（`retract [v1.0.0, v1.0.5]`，方括号表示含端点）。效果：

- 别人 `go get -u` / `go mod tidy` 升级时，**不会**升到被撤回的版本；
- `go list -m -u` 也**不会**把被撤回的版本列为"可升级目标"；
- 已经用了坏版本的人，构建时 `go` 命令会给出提示。

为什么需要它：Git 标签一旦推出去、被代理和校验和数据库收录，就**不能删**（删了会破坏别人已锁定的构建）。发现 `v1.0.3` 有严重 bug，正确做法不是删标签，而是发一个 `v1.0.4`，在它的 `go.mod` 里 `retract v1.0.3`。注意：**撤回指令要写在模块的某个已发布版本的 `go.mod` 里**（通常是最新版），`go` 命令读到那个版本才知道哪些版本被撤了。

### tool —— 把开发工具钉进模块（1.24+）

```text
tool golang.org/x/tools/cmd/stringer
```

`tool` 指令（Go 1.24 新增）把一个**开发工具**登记为模块的依赖。配合命令：

```bash
go get -tool golang.org/x/tools/cmd/stringer   # 写进 go.mod 的 tool 行
go tool stringer -type=Color                    # 团队成员零配置直接跑
```

意义：以前团队约定"先 `go install` 一堆工具再开发"，靠 README 口头传达、版本还各不相同。现在工具及其版本钉在 `go.mod` 里，`go tool <名字>` 会用模块锁定的那个版本跑，**新人 clone 下来零配置复用**。它替代了 Makefile 里那堆安装步骤。

### godebug —— 模块级运行时开关（1.23+）

```text
godebug default=http2debug=0
```

`godebug` 指令为**主模块**设置 `GODEBUG` 运行时调试/兼容开关的默认值（`GODEBUG` 是 Go 运行时读取的一组 `key=value`，用来微调某些行为、或在升级时临时保留旧语义）。只有主模块的 `godebug` 生效，依赖里写的会被忽略（和 `replace` 同理）。日常很少手写，多用于"升级到新 Go 后某个行为变了，先用 godebug 兜一下再逐步迁移"。

## 14.4 版本号与版本查询

### 语义化版本与模块兼容性（SIV）

Go 模块版本遵循**语义化版本**（SemVer）：`v主.次.补丁`，例如 `v1.2.3`。约定：

- **`v0.y.z`**：不稳定，API 随时可变，不承诺兼容；
- **`v1.y.z`**：稳定，向后兼容；次版本 `y` 加功能、补丁 `z` 修 bug，都不破坏兼容；
- **`v2` 及以上（破坏性变更）**：这里有个 Go 独有的硬规矩——**语义导入版本化（Semantic Import Versioning, SIV）**：主版本 ≥ 2 的模块，**模块路径必须以 `/vN` 结尾**。

SIV 的道理：`import` 路径就是模块的"身份证"。如果 `v2` 和 `v1` 用同一个路径，那么同一个构建里就没法同时依赖两个版本（导入路径撞车）。给 `v2` 换个路径 `example.com/dep/v2`，它就成了**另一个模块**，能和 `example.com/dep`（v1）在一个程序里共存——你可以渐进迁移，一半代码用 v1、一半用 v2。所以发布 `v2.0.0` 时，你必须把 `go.mod` 的 `module` 行改成 `.../v2`，代码里的导入路径也跟着加 `/v2`。

还有一个历史包袱 **`+incompatible`**：模块系统出现之前，有些仓库已经打了 `v2.0.0` 这种标签，但既没有 `/v2` 路径、也没有 `go.mod`。为了让这些老仓库还能被引用，Go 允许用 `vX.Y.Z+incompatible` 的形式导入它们——`+incompatible` 表示"这是个不遵守 SIV 的老式主版本 ≥2 版本"。新项目不会遇到，看见认得即可。

### 版本查询：@ 后面能写什么

很多命令（`go get`、`go list -m`）接受 `模块@查询` 的形式，`@` 后面不一定是写死的版本号：

| 查询 | 含义 |
|---|---|
| `@v1.2.3` | 精确版本 |
| `@latest` | 最新的**发布版**（优先正式版，没有才考虑预发布） |
| `@upgrade` | 比当前版本**新**的最新版（只升不降） |
| `@patch` | 当前 `主.次` 下**最新的补丁版**（`v1.2.3` → `v1.2.9`，不跨次版本） |
| `@分支名` / `@commit` | 解析成一个**伪版本**（见下） |
| `@>=v1.2.0` | 比较查询：满足 `≥v1.2.0` 的**最低**版本（实测 `rsc.io/quote@>=v1.2.0` → `v1.2.0`） |
| `@<v1.5.0` | 比较查询：`<v1.5.0` 的**最高**版本（实测 `rsc.io/quote@<v1.5.0` → `v1.4.0`） |

> 比较查询**一次只能写一个**：`@>=v1.2.0` 或 `@<v1.5.0` 都行，但把它们用空格拼成 `@'>=v1.2.0 <v1.5.0'` 会报 `invalid semantic version`——Go 不支持这种区间 AND。

预发布版本（`v1.5.3-pre1`、`v2.0.0-rc.1`）排在对应正式版**之前**，`@latest` 默认不会选到它们。真实看一眼某个模块有哪些版本：

```bash
go list -m -versions rsc.io/quote
```
```text
rsc.io/quote v0.9.9-pre1 v1.0.0 v1.1.0 v1.2.0 v1.2.1 v1.3.0 v1.4.0 v1.5.0 v1.5.1 v1.5.2 v1.5.3-pre1
```

（版本列表会随上游发新版而增长，这里是你跑命令当时的快照。注意首尾两个 `-pre1` 是预发布版，`@latest` 会选 `v1.5.2` 而不是 `v1.5.3-pre1`。）

### 伪版本（pseudo-version）

如果你 `go get` 一个**没打 SemVer 标签**的 commit（或某个分支的最新 commit），Go 会造一个**伪版本**给它。它由三段用 `-` 连起来：**基版本 - 提交时间 - commit 前 12 位**。基版本长什么样，取决于该 commit 之前最近的那个 SemVer 标签：

```text
vX.0.0-yyyymmddhhmmss-abcdefabcdef            ← 之前没有该主版本的标签（最常见，如 v0.0.0-…）
vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef      ← 上一个标签是 vX.Y.Z
vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef      ← 上一个标签是预发布 vX.Y.Z-pre
```

- `yyyymmddhhmmss`：那个 commit 的 UTC 提交时间（14 位）；
- `abcdefabcdef`：commit 哈希的**前 12 位十六进制**。

上面 netdemo 里的 `golang.org/x/text v0.0.0-20170915032832-14c0d48ead0c` 就是第一种（之前没标签），拆开看：

```text
v0.0.0 - 20170915032832 - 14c0d48ead0c
基版本    提交时间(UTC)      commit 前 12 位
```

伪版本保证"同一个 commit 永远解析成同一个版本字符串"，所以照样可复现、照样进 `go.sum`。

## 14.5 最小版本选择（MVS）

**MVS（Minimal Version Selection）** 是 Go 决定"每个依赖到底用哪个版本"的算法。它的核心思想一句话：

> 对每个模块路径，在整张依赖图里收集所有对它的版本要求，**选其中最高的那个**——而不是选网上能找到的最新版。

"最小"指的是：选出的是**能满足所有约束的最小版本**，不是最新版。这带来两个好处：**可复现**（结果只由 `go.mod` 里写的要求决定，跟"今天上游发了什么新版"无关）和**不会偷偷升级**（你不动 `go.mod`，构建用的版本就不变）。

举个菱形依赖的例子（这是概念演示，用来说清算法）：

```text
        你的模块 (main)
         /            \
   要 A v1.1        要 B v1.2
        |             |
     A v1.1         B v1.2
     要 C v1.0      要 C v1.3
         \            /
          C 到底用哪个版本？
```

A 要 `C v1.0`，B 要 `C v1.3`。MVS 收集对 C 的所有要求 `{v1.0, v1.3}`，**取最高 = `v1.3`**。于是构建列表里 C 是 `v1.3`。注意它不会去查"C 最新是不是 v2.0"——没人要求 v2.0，就不用。这就是"最小"：够用即可，绝不多要。

真实看一眼 netdemo 的构建列表和模块图。`go list -m all` 打印的就是 MVS 算出的**构建列表**（每个模块路径一行、一个选定版本）：

```bash
go list -m all
```
```text
example.com/netdemo
golang.org/x/text v0.0.0-20170915032832-14c0d48ead0c
rsc.io/quote v1.5.2
rsc.io/sampler v1.3.0
```

`go mod graph` 打印**模块图的边**（`A B` 表示 A 依赖 B），MVS 就是在这张图上跑的：

```bash
go mod graph
```
```text
example.com/netdemo go@1.27.2
example.com/netdemo golang.org/x/text@v0.0.0-20170915032832-14c0d48ead0c
example.com/netdemo rsc.io/quote@v1.5.2
example.com/netdemo rsc.io/sampler@v1.3.0
go@1.27.2 toolchain@go1.27.2
rsc.io/quote@v1.5.2 rsc.io/sampler@v1.3.0
rsc.io/sampler@v1.3.0 golang.org/x/text@v0.0.0-20170915032832-14c0d48ead0c
```

读这张图：`netdemo → quote → sampler → x/text` 是真实的依赖链（你只 import 了 quote，但 quote 要 sampler、sampler 要 x/text，所以它们都进了构建列表）。另外两行 `go@1.27.2` 和 `toolchain@go1.27.2` 是 Go 1.21 起把**工具链本身也建模成模块**的结果——`go` 指令声明的语言版本、`toolchain` 声明的工具链，在图里以 `go@版本` / `toolchain@版本` 两个特殊节点出现。看见它们别慌，不是你的依赖。

### 模块图剪枝（go 1.17+）

早期 MVS 要把**整张传递依赖图**都加载一遍才能算构建列表，依赖一多就很慢。Go 1.17 引入**图剪枝**：当模块的 `go` 指令 ≥ 1.17 时，`go mod tidy` 会把所有间接依赖**显式记进 `go.mod`**（就是那些 `// indirect` 行）。这样 `go` 命令不必再深入每个依赖的依赖去加载它们的 `go.mod`，光看主模块的 `go.mod` 就能确定构建列表，**大幅减少要下载/解析的 `go.mod` 数量**。这就是为什么现代 `go.mod` 里会有一大块 `// indirect`——不是冗余，是剪枝需要的"已展开"记录。

## 14.6 go.sum 与校验和数据库

`go.sum` 是**依赖内容哈希锁**，和 `go.mod` 一起**提交进仓库**。它记录每个依赖模块的内容哈希，下次谁（包括 CI、包括换台机器）拉这个依赖，`go` 命令都会重新算哈希跟 `go.sum` 比对——**对不上就报错、拒绝构建**。这是防供应链攻击（有人偷换了某个版本的代码）的关键一环。

`go.sum` 每行格式是 `模块 版本 哈希`，而且**每个模块通常有两行**——一行是模块内容（zip）的哈希，一行是它 `go.mod` 文件的哈希。看 netdemo 真实的 `go.sum`（节选 quote 的两行）：

```text
rsc.io/quote v1.5.2 h1:w5fcysjrx7yqtD/aO+QwRjYZOKnaM9Uh2b40tElTs3Y=
rsc.io/quote v1.5.2/go.mod h1:LzX7hefJvL54yjefDEDHNONDjII0t9xZLPXsUe+TKr0=
```

- 第一行 `rsc.io/quote v1.5.2 h1:...`：模块**内容**（整个 zip）的哈希；
- 第二行 `rsc.io/quote v1.5.2/go.mod h1:...`：该版本 **`go.mod` 文件**的哈希（注意版本后面多了 `/go.mod`）。

`h1:` 是哈希算法标识（基于 SHA-256 的目录哈希，base64 编码）。为什么连 `go.mod` 也要单独哈希？因为 MVS 只下载依赖的 `go.mod`（不下载整个 zip）就能算版本选择，`go.mod` 的哈希保证这一步也不被篡改。

这两个哈希从哪来、跟谁比对？`go mod download -json` 会把它们和缓存位置一起打出来（路径里的 `$GOMODCACHE` 在你机器上是 `go env GOMODCACHE`，默认 `~/go/pkg/mod`）：

```bash
go mod download -json rsc.io/quote
```
```text
{
	"Path": "rsc.io/quote",
	"Version": "v1.5.2",
	"Info": "$GOMODCACHE/cache/download/rsc.io/quote/@v/v1.5.2.info",
	"GoMod": "$GOMODCACHE/cache/download/rsc.io/quote/@v/v1.5.2.mod",
	"Zip": "$GOMODCACHE/cache/download/rsc.io/quote/@v/v1.5.2.zip",
	"Dir": "$GOMODCACHE/rsc.io/quote@v1.5.2",
	"Sum": "h1:w5fcysjrx7yqtD/aO+QwRjYZOKnaM9Uh2b40tElTs3Y=",
	"GoModSum": "h1:LzX7hefJvL54yjefDEDHNONDjII0t9xZLPXsUe+TKr0="
}
```

`Sum` 和 `GoModSum` 正好就是 `go.sum` 里那两行的哈希——一个对内容、一个对 `go.mod`。

### 校验和数据库（checksum database）

光有本地 `go.sum` 还不够：第一次拉某个依赖、`go.sum` 里还没有它时，拿什么判断"我下到的这份是不是干净的"？答案是**全局校验和数据库** `sum.golang.org`——一个**只增不改、公开可审计**的 Merkle 树日志，收录了全世界公开模块每个版本的哈希。`go` 命令第一次见到某模块版本时，会去校验和数据库取它的官方哈希、写进你的 `go.sum`；以后任何人拉到的若与数据库记录不符，立刻暴露。这样即使代理被黑、返回了篡改的代码，也对不上数据库里的哈希。

相关环境变量（14.9 详述）：`GOSUMDB` 指定用哪个校验和数据库（默认 `sum.golang.org`，设 `off` 关闭）；私有模块不该出现在公开数据库里，用 `GOPRIVATE`/`GONOSUMDB` 跳过校验。

### go mod verify 与几条注意

```bash
go mod verify
```
```text
all modules verified
```

`go mod verify` 检查**本地模块缓存**里的依赖跟 `go.sum` 记录是否一致（"我磁盘上这份没被动过手脚"）。几条注意：

- **`go.sum` 必须提交**。有人嫌它长就 `.gitignore` 掉——CI 上每次构建都重新解析、还可能拉到不同内容，可复现性和安全性全没了。合并冲突时别手动改，删掉冲突段重跑 `go mod tidy` 让它重建。
- **被 `replace` 到本地目录的依赖不进 `go.sum`**（14.3 的 hello 模块就没有 `go.sum`）——本地代码没有"下载内容"可校验。
- `go mod tidy` 会同步维护 `go.sum`：加依赖补哈希、删依赖清哈希。

## 14.7 依赖管理命令全家桶

下面把日常会碰到的模块命令一次讲清，每条都给语法、关键 flag 和"什么时候用"。能在本机离线复现的，输出都贴真实的。

### go mod init —— 建模块

```bash
go mod init example.com/hello
```

在当前目录生成 `go.mod`（`module` + `go` 两行起步）。新项目的第一个模块命令。

### go get —— 加/升/降依赖

```bash
go get example.com/dep@v1.2.3   # 钉到精确版本
go get example.com/dep@latest   # 升到最新发布版
go get -u example.com/dep       # 升级（含其传递依赖）
go get -u ./...                 # 升级当前模块所有依赖
go get -t ./...                 # 连测试专用依赖一起处理
go get -tool golang.org/x/tools/cmd/stringer   # 登记为工具依赖（14.3 tool）
```

`go get` 会改 `go.mod`（写 `require`）和 `go.sum`（补哈希），并把需要的模块下载进缓存。关键 flag：

- `-u`：升级到更新的版本（`-u=patch` 只升补丁）；不带 `@版本` 又想让 `go get` 有意义，基本都要 `-u`；
- `-t`：把"只有测试才用到"的依赖也纳入；
- `-tool`：加的是 `tool` 指令（开发工具），不是普通依赖；
- `-d`：历史 flag——**Go 1.16 起 `go get` 默认就只改 `go.mod`、不再构建安装**，所以 `-d`（"只下载不构建"）现在近乎空操作，看见认得即可。

真实跑一次（联网，goproxy.cn）：

```bash
go get rsc.io/quote@v1.5.2
```
```text
go: added golang.org/x/text v0.0.0-20170915032832-14c0d48ead0c
go: added rsc.io/quote v1.5.2
go: added rsc.io/sampler v1.3.0
```

一句 `go get` 把 `quote` 和它的两个传递依赖一起 `added` 进了 `go.mod`。再强调一次：**`go get` 之后跑 `go mod tidy`**，让它把直接/间接标记理顺、把没用到的清掉。

### go mod tidy —— 对齐 import 与 go.mod

```bash
go mod tidy
go mod tidy -e            # 即使有错误也尽量完成（比如某个依赖拉不到）
go mod tidy -go=1.27      # 顺便把 go 指令改成指定版本
go mod tidy -compat=1.27  # 保证与某版本向后兼容
```

`go mod tidy` 扫描**所有包的实际 `import`**，做两件事：把缺的依赖加进 `go.mod`/`go.sum`，把没人用的依赖删掉，并整理直接/间接分块。它是你最常敲的模块命令——**加完代码、删完代码、`go get` 完，都 tidy 一下**。`-e` 用于"明知有拉不到的依赖也想先 tidy 其余的"。

### go mod download —— 预下载

```bash
go mod download                 # 下载构建当前模块所需的全部依赖到缓存
go mod download -json           # 每个模块输出一段 JSON（路径/版本/哈希/缓存位置）
go mod download -x              # 打印执行的细节
```

CI 里常在构建前先 `go mod download` 把依赖灌进缓存，好把"下载"和"编译"两步分开缓存。`-json` 的输出见 14.6。

### go mod vendor —— 冻结依赖副本

```bash
go mod vendor               # 把所有依赖的源码复制进 ./vendor 目录
go mod vendor -o myvendor   # 换个输出目录
go mod vendor -e            # 有错误也尽量完成
```

`vendor/` 是依赖源码的本地副本，之后构建默认（Go 1.14+，且 `vendor/modules.txt` 与 `go.mod` 一致时）会**用 vendor 里的代码、不联网**。只在**离线/内网 CI**、或要求"构建绝对不依赖外部网络"时才用；日常开发别 vendor（占空间、易过期）。

真实看 vendor 产物（接 14.3 的 hello 模块，用 `GOWORK=off` 退出工作区后跑）：

```bash
GOWORK=off go mod vendor
cat vendor/modules.txt
```
```text
# example.com/greet v1.0.0 => ../greet
## explicit; go 1.27.2
example.com/greet
```

`vendor/modules.txt` 是 vendor 目录的清单：`#` 行记模块和版本（`=> ../greet` 说明它来自 replace），`## explicit` 表示这是 `go.mod` 里显式要求的，后面跟着被 vendor 的包。构建时用 `-mod=vendor` 强制走 vendor：

```bash
GOWORK=off go build -mod=vendor -o hello.bin . && ./hello.bin
```
```text
hello, modules
```

> **工作区里不能直接 `go mod vendor`**：如果当前处于 `go.work` 工作区模式（14.8），`go mod vendor` 会**报错拒绝**——
> ```text
> go: 'go mod vendor' cannot be run in workspace mode. Run 'go work vendor' to vendor the workspace or set 'GOWORK=off' to exit workspace mode.
> ```
> 要么用 `go work vendor` 给整个工作区做 vendor，要么 `GOWORK=off` 退出工作区再 `go mod vendor`。这是真实的报错，认得它就不慌。

### go mod verify —— 校验缓存

```bash
go mod verify
```

检查模块缓存里的依赖与 `go.sum` 是否一致，输出 `all modules verified`（见 14.6）。怀疑缓存被污染时跑它，或直接 `go clean -modcache` 清空重下。

### go mod why —— 这玩意谁引进来的

```bash
go mod why example.com/dep        # 为什么需要这个【包】
go mod why -m rsc.io/sampler      # 为什么需要这个【模块】（-m）
go mod why -vendor example.com/dep  # 只考虑 vendor 里的依赖
```

排查"我根本没 import 它，怎么在依赖里"时用。`-m` 按**模块**追问，输出从主模块到目标的依赖链。真实的：

```bash
go mod why -m rsc.io/sampler
```
```text
# rsc.io/sampler
example.com/netdemo
rsc.io/quote
rsc.io/sampler
```

读法：`netdemo` 依赖 `quote`、`quote` 依赖 `sampler`——所以 `sampler` 进了构建列表。再追一个更深的：

```bash
go mod why -m golang.org/x/text
```
```text
# golang.org/x/text
example.com/netdemo
rsc.io/quote
rsc.io/sampler
golang.org/x/text/language
```

最后一行 `golang.org/x/text/language` 是**具体哪个包**把 `x/text` 拽进来的——`sampler` 用了 `x/text/language`。

### go mod graph —— 打印模块图

```bash
go mod graph
```

打印 MVS 用的整张依赖图的边（`A B` = A 依赖 B），输出见 14.5。想可视化可以管道给 `graphviz`，或用 `go mod graph | go run golang.org/x/exp/cmd/apidiff` 之类工具二次加工（按需）。

### go mod edit —— 脚本化改 go.mod

```bash
go mod edit -require=example.com/dep@v1.2.3   # 加/改 require
go mod edit -droprequire=example.com/dep      # 删 require
go mod edit -exclude=example.com/dep@v1.2.0   # 加 exclude
go mod edit -dropexclude=example.com/dep@v1.2.0
go mod edit -replace=old@v1=new@v1            # 加 replace
go mod edit -dropreplace=old@v1
go mod edit -retract='[v1.0.0,v1.0.5]'        # 加 retract
go mod edit -dropretract=v0.9.0
go mod edit -tool=golang.org/x/tools/cmd/stringer   # 加 tool（1.24+）
go mod edit -droptool=golang.org/x/tools/cmd/stringer
go mod edit -godebug=default=http2debug=0     # 加 godebug（1.23+）
go mod edit -dropgodebug=default
go mod edit -go=1.27.2 -toolchain=go1.27.2    # 改 go / toolchain 行
go mod edit -compat=1.27
go mod edit -module=new/path                  # 改模块路径
go mod edit -fmt                              # 格式化 go.mod
go mod edit -print                            # 打印改后的内容、不写文件
go mod edit -json                             # 以 JSON 打印整个 go.mod
```

`go mod edit` 是**给脚本用的**：不解析代码、不联网、不下载，纯文本级增删 `go.mod` 指令。批量改依赖、CI 里注入版本号，都靠它。`-print` 预演不落盘，`-json` 给机器读。上面 14.3 那份"全家福" go.mod 就是用这一串 `-require/-exclude/-replace/-retract/-tool/-godebug` 加出来的；对它跑 `go mod edit -json`，把整个文件结构化成 JSON（下面是真实完整输出，注意 `Retract` 把单版本 `v0.9.0` 表示成 `Low==High==v0.9.0`，把区间 `[v1.0.0, v1.0.5]` 表示成 `Low=v1.0.0, High=v1.0.5`）：

```bash
go mod edit -json
```
```text
{
	"Module": {
		"Path": "example.com/editdemo"
	},
	"Go": "1.27.2",
	"Toolchain": "go1.27.2",
	"GoDebug": [
		{
			"Key": "default",
			"Value": "http2debug=0"
		}
	],
	"Require": [
		{
			"Path": "example.com/dep",
			"Version": "v1.2.3"
		},
		{
			"Path": "example.com/dep/v2",
			"Version": "v2.0.0"
		}
	],
	"Exclude": [
		{
			"Path": "example.com/dep",
			"Version": "v1.2.0"
		}
	],
	"Replace": [
		{
			"Old": {
				"Path": "example.com/bad",
				"Version": "v1.0.0"
			},
			"New": {
				"Path": "example.com/good",
				"Version": "v1.0.0"
			}
		}
	],
	"Retract": [
		{
			"Low": "v1.0.0",
			"High": "v1.0.5"
		},
		{
			"Low": "v0.9.0",
			"High": "v0.9.0"
		}
	],
	"Tool": [
		{
			"Path": "golang.org/x/tools/cmd/stringer"
		}
	]
}
```

### go list -m —— 查模块信息

```bash
go list -m                    # 当前主模块路径
go list -m all                # 整个构建列表（14.5）
go list -m -u all             # 构建列表 + 每个依赖【可升级到什么】
go list -m -versions rsc.io/quote   # 某模块所有可用版本（14.4）
go list -m -f '{{.Path}}@{{.Version}}' all   # 自定义模板输出
```

`-u` 会在每个有新版可升的依赖后面用方括号标出目标版本，真实的：

```bash
go list -m -u all
```
```text
example.com/netdemo
golang.org/x/text v0.0.0-20170915032832-14c0d48ead0c [v0.43.0]
rsc.io/quote v1.5.2
rsc.io/sampler v1.3.0 [v1.99.99]
```

`x/text` 后面 `[v0.43.0]` 表示"可升级到 v0.43.0"，`sampler` 后面 `[v1.99.99]` 同理（方括号里的具体版本会随时间变，这里是你跑命令当时的快照）；`quote` 后面没有方括号，说明它已经是最新。`-f` 接 Go 模板，能挑字段输出，比如只看路径和版本：

```bash
go list -m -f '{{.Path}}@{{.Version}}' all
```
```text
example.com/netdemo@
golang.org/x/text@v0.0.0-20170915032832-14c0d48ead0c
rsc.io/quote@v1.5.2
rsc.io/sampler@v1.3.0
```

（主模块 `netdemo` 的 `@` 后面是空的——主模块没有版本号，它就是"你正在改的这份"。）

### go clean -modcache 与 go env -w

```bash
go clean -modcache       # 删掉整个模块缓存（~/go/pkg/mod），下次重新下载
go env -w GOPROXY=https://goproxy.cn,direct   # 永久写某个 go 环境变量
go env GOPROXY           # 读某个 go 环境变量
go env                   # 读全部
```

`go clean -modcache` 是"依赖缓存出怪问题"时的核选项（清空重下，会慢一次）。`go env -w KEY=VALUE` 把配置**持久化**到 Go 的环境文件（不污染 shell 的 `export`，跨终端生效），`go env KEY` 读单个、`go env` 读全部。本教程联网演示前就是用 `go env -w GOPROXY=https://goproxy.cn,direct` 把代理钉到国内镜像的。

## 14.8 工作区：go.work 多模块联调

当你**同时开发多个相互依赖的本地模块**（比如一个 monorepo 里 `service` 依赖 `lib`，两个各有 `go.mod`），用 `replace => ../lib` 一个个指太繁琐、还容易把临时的 replace 误提交。**工作区（workspace）** 就是为这个场景设计的：一个 `go.work` 文件把磁盘上多个模块**一起当作主模块**，它们之间的相互引用自动用本地代码，改一处立刻生效，不用发版、不用 replace。

### go.work 的指令

`go.work` 也是纯文本，指令是 `go.mod` 的一个子集：

```text
go 1.27.2

toolchain go1.27.2

use (
	./greet
	./hello
)

exclude example.com/dep v1.2.0

replace example.com/bad v1.0.0 => example.com/good v1.0.0

godebug default=http2debug=0
```

- **`go` / `toolchain`**：同 `go.mod`，声明工作区的语言版本/建议工具链；
- **`use`**：核心指令。`use ./dir` 把 `dir` 里的模块加进工作区当主模块。可以单行，也可以括号成块。**注意 `use` 不会自动包含子目录里的模块**——每个要参与的模块都得单独 `use`（或用 `go work use -r` 递归）；
- **`exclude` / `replace` / `godebug`**：工作区级的覆盖。工作区里的 `replace` 会**盖过**各模块 `go.mod` 里的 `replace`，用来统一联调时的替换。

### 建工作区与工作区命令

```bash
go work init ./hello ./greet     # 用这些模块建一个 go.work
go work use ./another            # 往现有工作区再加一个模块
go work use -r ./...             # 递归把子目录里的模块都加进来
go work edit -json               # 像 go mod edit 一样，脚本化改 go.work
go work sync                      # 把工作区用 MVS 算出的构建列表同步回各成员模块的 go.mod
go work vendor                   # 给整个工作区做 vendor（对应 go mod vendor）
```

真实建一个工作区（接 14.3 的 greet/hello 两个本地模块）：

```bash
go work init ./hello ./greet
cat go.work
```
```text
go 1.27.2

use (
	./greet
	./hello
)
```

`go work init` 把两个模块写进 `use` 块（按字典序排了）。`go work edit -json` 看它的结构（真实完整输出）：

```bash
go work edit -json
```
```text
{
	"Go": "1.27.2",
	"Use": [
		{
			"DiskPath": "./greet"
		},
		{
			"DiskPath": "./hello"
		}
	]
}
```

进了工作区后，从工作区根目录查构建列表，**两个模块都是主模块**（都没有版本号）：

```bash
go list -m all
```
```text
example.com/greet
example.com/hello
```

### GOWORK：工作区开关

`go` 命令靠 `GOWORK` 环境变量决定用不用工作区：

- `GOWORK=auto`（默认）或空：从当前目录**逐级向上找** `go.work`，找到就进工作区模式；
- `GOWORK=off`：**禁用**工作区，回到单模块模式（各模块只认自己的 `go.mod`）；
- `GOWORK=/path/to/x.work`：强制用指定的工作区文件。

查当前用的是哪个：

```bash
go env GOWORK
```
```text
/tmp/modemo/go.work
```

（输出是找到的 `go.work` 的绝对路径；不在工作区里则为空。）临时退出工作区跑一条命令，前面加 `GOWORK=off` 即可——14.7 里 `GOWORK=off go mod vendor` 就是这么用的。

### 工作区的几个真实坑

这些都是本机实测会撞到的，认得就少踩：

1. **工作区根目录不是包目录**。在 `go.work` 所在的根目录直接 `go build ./...` 会报错，因为根目录本身不含任何模块的包：
   ```text
   pattern ./...: directory prefix . does not contain modules listed in go.work or their selected dependencies
   ```
   想在工作区根一次性构建所有成员模块，用特殊模式 `all`：`go build all`（实测通过）；或者 `cd` 进某个模块目录再 `go build ./...`。**别直接 `go build ./hello`**——它会报 `build output "hello" already exists and is a directory`，因为要生成的可执行文件名 `hello` 和 `hello/` 目录撞了；指名构建时给个 `-o`：`go build -o bin/hello ./hello`。

2. **在 go.work 底下、但没被 `use` 的模块会被拒绝构建**。如果某个模块目录位于 `go.work` 的管辖范围内，却没出现在 `use` 列表里，在它里面跑 `go build` 会得到：
   ```text
   current directory is contained in a module that is not one of the workspace modules listed in go.work. You can add the module to the workspace using:
   	go work use .
   ```
   照提示 `go work use .` 把它加进来，或 `GOWORK=off` 退出工作区。

3. **`go.work` 一般不提交**。它是**本地联调**的便利设施，每台机器的工作区组成可能不同；提交它会把你的本地目录结构强加给所有人。要提交的是各模块的 `go.mod`/`go.sum`。（`go.work.sum` 同理，是工作区的校验和缓存，通常也不提交。）

## 14.9 模块代理、校验和数据库与私有模块

### 模块代理协议与 GOPROXY

`go` 命令默认不直接从 GitHub 之类的源站拉代码，而是走**模块代理（module proxy）**——一个按固定 HTTP 协议提供模块文件的缓存服务。协议很简单，给定模块路径和版本，代理要能提供这几个端点（`$base` 是代理根 URL）：

```text
$base/$module/@v/list           该模块所有已知版本
$base/$module/@v/$version.info  版本元数据（JSON，含时间）
$base/$module/@v/$version.mod   该版本的 go.mod（MVS 只下这个就能算版本）
$base/$module/@v/$version.zip   模块内容的 zip（真正要编译时才下）
$base/$module/@latest           最新版本的 .info
```

走代理的好处：**快**（全球 CDN 缓存）、**稳**（源站删库/改标签也不影响已发布版本，代理留了不可变副本）、**安全**（配合校验和数据库）。

`GOPROXY` 控制用哪些代理，可以是用逗号或竖线分隔的**多个 URL**，外加两个特殊值：

- `direct`：不走代理，**直接连源站的版本控制系统**（git 等）；
- `off`：**禁止任何下载**（只能用缓存里已有的，纯离线构建时用）。

默认值是 `https://proxy.golang.org,direct`（Go 官方代理，拉不到再回源）。逗号 vs 竖线的区别很关键：

- **逗号 `,`**：当前代理返回 **404 或 410（Gone）**（"这个版本我这没有"）时，才回退到下一个；其他错误（如网络超时）直接失败；
- **竖线 `|`**：**任何错误**都回退到下一个（包括连不上、5xx）。

国内网络拉 `proxy.golang.org` 常常很慢或失败，换国内镜像：

```bash
go env -w GOPROXY=https://goproxy.cn,direct
```

含义：先试 `goproxy.cn`（七牛云的国内 Go 模块代理），它返回 404/410（比如某个没被它收录的私有路径）时再 `direct` 回源。本章所有联网演示都是在 `goproxy.cn` 下实测的。

### 校验和数据库与 GOSUMDB

14.6 讲过 `sum.golang.org` 这个全局只增日志。`GOSUMDB` 指定用哪个校验和数据库（默认 `sum.golang.org`；设 `off` 完全关闭校验）。关闭校验有风险（拉到的代码无人背书），一般只在完全隔离的内网、且用可信私有代理时才关。

### 私有模块：GOPRIVATE / GONOPROXY / GONOSUMDB

公司内网的模块（`git.corp.example.com/team/lib`）**不该**走公共代理（代理上没有、还可能把你的内网地址和凭证泄露给公共代理），也**不该**进公共校验和数据库（私有代码的哈希不该公开）。三个环境变量管这事，值都是**逗号分隔的 glob 模式**（`path.Match` 语法）匹配模块路径前缀：

- **`GOPRIVATE`**：声明"哪些是私有模块"。它是 `GONOPROXY` 和 `GONOSUMDB` 的**默认值来源**——设了 `GOPRIVATE`，匹配的模块自动既不走代理、也不查校验和数据库。推荐只设它，语义最清晰：
  ```bash
  go env -w GOPRIVATE=git.corp.example.com,github.com/myorg/*
  ```
- **`GONOPROXY`**：匹配的模块**绕过代理、直连源站**（相当于对这些模块强制 `direct`）。默认取 `GOPRIVATE` 的值。
- **`GONOSUMDB`**：匹配的模块**不跟校验和数据库比对**。默认取 `GOPRIVATE` 的值。

`GONOPROXY` 和 `GONOSUMDB` 是**两个独立开关**，分别管"下载走不走代理"和"校验查不查数据库"。只设 `GOPRIVATE` 通常就够（它给两者兜底）；要精细控制才分别设。还有两个相关的：

- **`GOINSECURE`**：匹配的模块允许**不安全（HTTP/跳过 TLS 校验）**地拉取——只用于你完全信任的内网源。注意它**不**关闭校验和数据库校验，关校验得用 `GONOSUMDB`/`GOPRIVATE`。
- **`GOVCS`**：限制对哪些主机可以用哪些版本控制命令（安全护栏，比如禁止对公共主机用 `git`）。

私有模块的 **git 认证要单独配**（SSH key 或 `.netrc`/credential helper），Go 只是调用系统 `git`——`git` 能连，Go 就能连；`git` 报 401，Go 一定也失败。

### 其余相关环境变量速查

| 变量 | 作用 | 本机默认（实测） |
|---|---|---|
| `GO111MODULE` | `on`/`off`/`auto`，是否启用模块模式 | 空（= 默认 `on`） |
| `GOPROXY` | 模块代理列表 | `https://proxy.golang.org,direct` |
| `GOSUMDB` | 校验和数据库 | `sum.golang.org` |
| `GOPRIVATE` / `GONOPROXY` / `GONOSUMDB` | 私有模块模式 | 空 |
| `GOMODCACHE` | 模块缓存目录 | `~/go/pkg/mod`（即 `GOPATH/pkg/mod`） |
| `GOTOOLCHAIN` | 工具链选择：`auto`/`local`/`path`/`go1.x.y` | `auto` |
| `GOWORK` | 工作区文件：`auto`/`off`/路径 | 空（不在工作区） |
| `GOFLAGS` | 给 go 命令附加的默认 flag（空格分隔，如 `-mod=vendor`） | 空 |

`GOTOOLCHAIN` 值得多说一句：`auto`（默认）表示"`go.mod` 的 `go`/`toolchain` 行要求的版本比本地新时，自动下载并切过去"；`local` 表示"永远用本地装的、绝不下载切换"；也可以直接写死 `GOTOOLCHAIN=go1.27.2` 强制用某版本。CI 里想要"版本不对就失败、别偷偷下载"，用 `local`。

## 14.10 发布一个模块

让别人能 `go get` 你的模块，流程其实很短：

1. **模块路径 = 仓库地址**。`go.mod` 的 `module` 行要写成别人能克隆到的路径，比如仓库在 `github.com/you/proj`，模块路径就写 `github.com/you/proj`（子目录包自动是 `github.com/you/proj/sub`）。
2. **打 SemVer 标签并推送**。发布 `v1.0.0` 就是 `git tag v1.0.0 && git push origin v1.0.0`。标签必须是合法的 `vX.Y.Z`。
3. **主版本 ≥ 2 要改路径**。发 `v2.0.0` 前，把 `module` 行改成 `github.com/you/proj/v2`，代码里所有自引用导入路径也加 `/v2`（SIV，见 14.4），再打 `v2.0.0` 标签。
4. **首次被请求时进代理**。你不用主动"上传"——当有人第一次 `go get github.com/you/proj@v1.0.0`，公共代理 `proxy.golang.org` 会去你的仓库抓这个版本、缓存下来，并把它的哈希登记进校验和数据库。之后全世界拉到的都是这份不可变副本。
5. **坏版本用 retract 撤，别删标签**。发现 `v1.0.3` 有严重问题，发 `v1.0.4`，在其 `go.mod` 里 `retract v1.0.3`（14.3）。删标签会破坏已经锁定该版本的构建。

发布前自查：`go mod tidy` 干净、`go test ./...` 通过、`go vet ./...` 无警告、`go.mod` 的 `go` 行是你想支持的最低版本。

## 14.11 工程布局：cmd / internal / pkg

模块内部怎么摆包，没有官方强制，但 `cmd/internal/pkg` 三件套是事实标准。`examples/14_module` 就是个迷你版：

```text
examples/14_module/
├── go.mod                       module layout
├── cmd/app/main.go              可执行入口：main 包尽量薄
├── internal/store/              私有实现：只有 layout 模块内能 import
│   ├── store.go
│   └── store_test.go
└── pkg/units/                   公共库：允许外部模块 import
    ├── units.go
    └── units_test.go
```

### 导入路径与可见性

`cmd/app/main.go` 的导入块，正是"导入路径 = 模块路径 + 目录"的活例子：

```go
package main

import (
	"fmt"

	"layout/internal/store"   // 模块路径 layout + 目录 internal/store
	"layout/pkg/units"        // 模块路径 layout + 目录 pkg/units
)
```

可见性只有**一条规则**：标识符**首字母大写 = 包外可见（导出）**，小写 = 包内私有。没有 `public`/`private`/`friend` 关键字。`store.go` 里就是这么体现的——导出的类型配非导出的字段，数据结构公开、表示细节私有：

```go
// ErrNotFound 缺键哨兵错误：导出给调用方做 errors.Is 判断。
var ErrNotFound = errors.New("key not found")

// Store 内存 KV。导出类型 + 非导出字段（data 小写）。
type Store struct {
	data map[string]string
}

// Get 取值；缺键时返回包裹了 ErrNotFound 的错误。
func (s *Store) Get(key string) (string, error) {
	v, ok := s.data[key] // nil map 读是安全的
	if !ok {
		return "", fmt.Errorf("get %q: %w", key, ErrNotFound)
	}
	return v, nil
}
```

`Store`、`ErrNotFound`、`Get` 大写导出，`data` 小写私有。`pkg/units` 的 `FormatBytes` 同理是导出的公共 API：

```go
// Package units 做单位换算。放在 pkg/ 下：约定俗成的"公共库"位置。
package units

// FormatBytes 把字节数格式化成人类可读形式（512 B、4.0 KiB、4.8 MiB）。
func FormatBytes(n int64) string { /* ... */ }
```

### internal：编译器撑腰的私有

`internal/` 目录是 Go 的**硬封装**：**外部模块 `import` 它直接编译错**。规则是——`.../a/internal/b` 这个包，只能被 `.../a/` 这棵子树下的代码导入。放在模块根的 `internal/`（如 `layout/internal/store`），就只有 `layout` 模块自己能 import，别的模块就算把导入路径写对也过不了编译。

这比 `pkg/` 的"君子协定"强一级：`pkg/` 只是**约定**"这里的东西欢迎外部用"，编译器不拦；`internal/` 是**编译器强制**"这里的东西外部休想碰"。所以库的内部实现一律塞 `internal/`，对外只露你想公开的 API 面（放 `pkg/` 或模块根的导出包）。`cmd/` 放可执行入口也是生态惯例——一个仓库要出多个工具，就多个 `cmd/xxx` 子目录，每个一个 `main` 包。

**别建 `utils`/`helper`/`common` 包**——按领域命名（`store`、`units`、`auth`），不按"杂物"命名。杂物包会变成谁都能塞、谁都不敢删的垃圾场。

## 14.12 包的初始化顺序

一个包被加载时，初始化按固定顺序发生：

```go
var table = buildTable()      // ① 包级变量初始化（按依赖顺序，被依赖的先）
func init() { validate() }    // ② init 函数自动执行（每个包可有多个，少见）
func main() { ... }           // ③ 只有 main 包有 main，最后执行
```

顺序由**导入关系驱动**：被依赖的包先初始化完，才轮到依赖它的包；`main` 包的 `main` 函数永远最后。同一个包内，包级变量按"被引用的先初始化"排序，`init()` 函数在变量初始化之后、`main` 之前跑。

`init()` 能不用就不用——它是"看不见的执行"，排错时全是惊喜（谁调的？什么时候调的？多个 `init` 谁先？）。包级变量初始化表达式 + `sync.Once`（16 章）能覆盖九成"惰性/一次性初始化"的需求，且看得见、可控。

## 14.13 坑位清单

1. **导入路径 = 模块路径 + 目录**：`module layout` 下的 `internal/store` 就是 `layout/internal/store`。路径拼错报 `no required module provides package ...`——先核对 `go.mod` 的 `module` 行和目录结构。
2. **`go get` 完不 `tidy`，直接/间接标记是乱的**：`go get` 只写 `require`、不扫 `import`，刚 get 完连你直接导入的包都标 `// indirect`。`go mod tidy` 才理顺，并删掉没用到的依赖。
3. **`replace` 只在主模块生效**：依赖自己 `go.mod` 里的 `replace` 会被忽略。想全局替换，只能在**你的**主模块（或 `go.work`）里写 `replace`。
4. **主版本 ≥ 2 忘了加 `/vN` 路径**：发 `v2.0.0` 但 `module` 行还是老路径，别人 `go get .../v2` 找不到、或和 v1 撞车。SIV 是硬规矩（14.4）。
5. **`go.sum` 被 `.gitignore` 或手改**：CI 校验失败、可复现性丢失。`go.sum` 必须提交；合并冲突别手改，删冲突段重跑 `go mod tidy` 重建。
6. **工作区里跑 `go mod vendor` 报错**：`go.work` 生效时要用 `go work vendor`，或 `GOWORK=off` 退出工作区（14.7/14.8 有真实报错）。
7. **模块在 `go.work` 底下却没被 `use`**：在它里面构建会被拒（`not one of the workspace modules`）——`go work use .` 加进来，或 `GOWORK=off`。
8. **`go.work` 误提交**：它是本地联调设施，提交会把你的目录结构强加给别人。提交 `go.mod`/`go.sum`，`go.work`/`go.work.sum` 一般进 `.gitignore`。
9. **私有模块没配 `GOPRIVATE`**：内网模块被当公开模块发往公共代理，结果 403/404，还可能泄露内网地址/凭证。`go env -w GOPRIVATE=你的内网域名`（14.9）。
10. **`GOPROXY` 用逗号还是竖线搞反**：逗号只在 404/410 回退、竖线任何错误都回退。`goproxy.cn,direct` 用逗号是常态（镜像没有的才回源）；想让"镜像连不上也自动回源"用竖线 `goproxy.cn|direct`。
11. **没打标签就 `go get` 某 commit**：得到一长串伪版本 `v0.0.0-2017...-14c0d48ead0c`（14.4）。想固定就 `go get 模块@commit`，想要干净版本号就让上游打 SemVer 标签。
12. **循环导入是编译错**：A 包 import B、B 又 import A——Go 不允许。重构为第三个包，或用接口倒置依赖（09 章接口在这救场）。
13. **逻辑全塞 `main` 包，没法测**：`main` 包只能整体黑盒。从第一个文件起就把逻辑放进 `internal/xxx` 库包，`main` 只做组装（示例 24 的 `internal/grep` 就是这么拆的）。
14. **包名和目录名不一致**：能编但读代码的人迷路。目录名 = 包名是铁律（`main` 包除外，目录可以叫 `cmd/app`）。
15. **`go` 行版本 ≠ 本机工具链**：`go.mod` 写 `go 1.27.2` 而本机是更旧的工具链时，`GOTOOLCHAIN=auto` 会**自动下载**新工具链（CI 无网会卡住，用 `GOTOOLCHAIN=local` 让它直接失败而不是偷偷下载）。
16. **删标签代替 retract**：发布的版本进了代理和校验和数据库就**删不掉**（删了破坏别人的锁定构建）。坏版本用 `retract` 撤回（14.3），发新版本引导大家升上去。

---

上一章：[13 ⭐迭代器](13-iterators.md) · 下一章：[15 ⭐测试](15-testing.md)
