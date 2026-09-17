# 14 · 包与模块

> 对应示例：`examples/14_module/`（自带 go.mod 的多包工程）

## 14.1 两个概念：包与模块

- **包（package）**：同目录的 .go 文件集合，编译单位。目录名 ≈ 包名；
- **模块（module）**：一个 go.mod 管辖的包集合，版本化与依赖管理的单位。

```powershell
go mod init layout      # 生成 go.mod：module layout + go 版本
```

本教程大部分示例住在根模块 `guidego` 里（`examples/NN_xxx` 各自是一个 main 包）；14/24 两个示例有自己的 go.mod——**嵌套模块是独立王国**，外层 `go build ./...` 不会踏进去。

## 14.2 导入路径与可见性

```go
import (
	"layout/internal/store"   // 模块路径 + 目录路径
	"layout/pkg/units"
)

fmt.Sprintf(...)   // 大写 = 导出；fmt 是包名
```

可见性只有一条规则：**标识符首字母大写 = 包外可见**。没有 public/private 关键字、没有 friend——简单粗暴，写两天就习惯。

## 14.3 internal：编译器撑腰的私有

```text
layout/
├── go.mod
├── cmd/app/main.go          # 入口：main 包尽量薄
├── internal/store/          # 只有 layout 模块内能 import！
└── pkg/units/               # 公共库：外部模块可 import
```

`internal/` 目录是 Go 的硬封装：**外部模块 import 它直接编译错**。比 pkg/ 的"君子协定"强一级——库的内部实现一律塞 internal，对外只露 API 面。`cmd/` 放可执行入口也是生态惯例（一个仓库多个工具就多个 cmd/ 子目录）。

## 14.4 依赖管理

```powershell
go get github.com/xxx/yyy@v1.2.3    # 加依赖（写进 go.mod）
go mod tidy                          # 按实际 import 增删依赖、补 go.sum
go mod why github.com/xxx/yyy        # 谁把它引进来的
go mod graph                         # 依赖图
```

- `go.mod`：模块名、go 版本、require 清单（你直接依赖什么）；
- `go.sum`：依赖内容哈希锁——**提交进仓库**，防供应链偷换；
- 国内网络拉不动：`go env -w GOPROXY=https://goproxy.cn,direct`；
- 本地多模块联调：根目录 `go work init ./a ./b` 生成 go.work，改代码即时生效不用发版。

本教程只用标准库——零依赖是刻意为之，先把语言吃透，依赖管理等真需要时再看官方文档。

## 14.5 包的初始化顺序

```go
var table = buildTable()      // ① 包级变量初始化（按依赖序）
func init() { validate() }    // ② init 函数自动执行（每包可多个，少见）
func main() { ... }           // ③ main 包的 main 最后
```

导入驱动的顺序：被依赖的包先初始化，main 永远最后。init 能不用就不用——它是"看不见的执行"，排错时全是惊喜；包级变量初始化 + `sync.Once`（16 章）能覆盖九成需求。

## 14.6 工程布局惯例

```text
项目/
├── cmd/app/          # 可执行入口
├── internal/         # 私有实现（按领域再分 store/、service/…）
├── pkg/              # 允许外部用的库（没有可导出库就别建）
├── go.mod / go.sum
└── README.md
```

没有官方强制，但 `cmd/internal/pkg` 三件套是事实标准（示例 14_module 就是迷你版）。**别建 utils/helper 包**——按领域命名（store、units），不按"杂物"命名。

## 14.7 工具依赖：go.mod 的 tool 指令（1.24+）

```powershell
go get -tool golang.org/x/tools/cmd/stringer   # 写进 go.mod 的 [tool]
go tool stringer -type=Color                   # 团队成员零配置复用
```

把开发工具钉在 go.mod 里，替代 Makefile 里的安装步骤——多了一块官方拼图。

## 14.8 坑位清单

1. **import 路径 = 模块路径 + 目录**：`module layout` 的 internal/store 就是 `layout/internal/store`——路径拼错报"no required module provides package"。
2. **循环导入是编译错**：A 包 import B、B 又 import A——Go 不允许，重构为第三个包或定义接口倒置依赖（09 章接口在这救场）。
3. **main 包测试难**：逻辑塞 main 包只能整体黑盒——从第一个文件起就分包（示例 24 的 internal/grep 就是这么拆的）。
4. **go.sum 被人删了提交**：CI 校验和失败——go.sum 和 go.mod 一起提交。
5. **包名和目录名不一致**：能编但读代码的人会迷路——目录名 = 包名是铁律（main 包除外，目录叫 cmd/app）。
6. **vendor 目录**：`go mod vendor` 冻结依赖副本——CI 离线环境才需要，日常别用。

---
