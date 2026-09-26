# 01 · Lean 4 简介与环境搭建

## 1.1 什么是 Lean 4

Lean 是由 Leonardo de Moura 发起的交互式定理证明器与函数式编程语言，基于**依赖类型理论**（Dependent Type Theory）。Lean 4 是完全重写的版本：内核更小更快，整个系统（包括编译器、构建系统 Lake）都用 Lean 自身实现。

Lean 4 的核心特性：

- **依赖类型系统**：类型可以依赖于值，实现"命题即类型，证明即程序"的柯里-霍华德对应
- **纯函数式编程**：高阶函数、模式匹配、归纳类型、类型类一应俱全；同时支持可变数组等带引用语义的高效数据结构
- **交互式定理证明**：战术（tactic）系统 + 强大的自动化（`simp`、`omega`、`aesop`、`polyrith` 等）
- **高效代码生成**：经 `lean` 编译器生成 C 代码再编译为原生可执行文件
- **元编程**：宏（macro）、语法扩展（syntax/elab）都在 Lean 内实现，Mathlib 的大量战术本身就是 Lean 程序
- **Mathlib4**：单一巨型数学库（超过 17 万个定理、20 万+ 定义），所有数学分支共用一套代数/分析/范畴基础设施

Lean 4 与 Mathlib 的版本是**强绑定**的：每个 Mathlib 提交都锁定一个确切的 Lean 工具链版本（见仓库根目录的 `lean-toolchain` 文件）。升级 Mathlib 通常意味着同时升级工具链。

## 1.2 安装 elan 和 Lean 4

elan 是 Lean 的工具链管理器（类似 Rust 的 rustup）。它会安装 `lean`、`lake`、`leanc` 等命令的**转发器（shim）**：进入项目目录时自动读取 `lean-toolchain` 文件并切换到对应版本，无需手动管理。

**Windows 安装**：
1. 从 [elan releases](https://github.com/leanprover/elan/releases) 下载 `elan-x86_64-pc-windows-msvc.zip` 或安装脚本
2. 解压/运行后将 `bin` 目录加入 PATH

**Linux/macOS 安装**：
```bash
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
```

**常用 elan 命令**：
```bash
elan show                              # 查看已安装工具链与当前默认版本
elan toolchain install leanprover/lean4:v4.34.0   # 安装指定版本
elan default leanprover/lean4:v4.34.0             # 设置全局默认
elan toolchain list                    # 列出所有已安装版本
```

在项目目录中，`lean-toolchain` 文件内容形如：

```text
leanprover/lean4:v4.34.0
```

elan shim 会据此自动选择工具链，因此**同一台机器可以并行使用多个 Lean 版本**。

## 1.3 第一个 Lean 项目

Lake 是 Lean 4 的构建系统（类似 Cargo），随工具链一起安装：

```bash
lake init hello_lean          # 生成可执行项目模板
lake init hello_lean lib      # 生成库项目模板
cd hello_lean
lake build
```

生成的项目结构：
```
hello_lean/
├── .lake/              # Lake 构建目录（含依赖包缓存）
├── HelloLean/          # 源代码目录
│   └── Basic.lean      # 根模块
├── HelloLean.lean      # 库入口（导入所有子模块）
├── lakefile.lean       # 项目配置（也支持 lakefile.toml）
├── lake-manifest.json  # 依赖版本锁定文件（应提交到 git）
└── lean-toolchain      # 指定工具链版本
```

编辑 `HelloLean/Basic.lean`：

```lean
def hello : String := "Hello, Lean 4!"

-- 三个常用"命令行"：
#eval hello     -- 执行并打印结果："Hello, Lean 4!"
#check hello    -- 打印类型：hello : String
#reduce hello   -- 打印完全归约后的值（不做 IO，纯计算）
```

`#eval`、`#check`、`#reduce` 是 Lean 的**信息命令**，只影响编辑器/编译器输出，不产生代码。它们与 `example`、`#print`（打印定义源码）、`#exit` 等一样，是学习期最常用的工具。

运行方式：
```bash
lake build                            # 构建整个项目
lake env lean HelloLean/Basic.lean    # 在项目环境中直接编译单个文件
lake env run hello                    # 运行项目定义的 exe
```

`lake env <cmd>` 会设置好 `LEAN_PATH` 等环境变量后运行命令，单文件验证示例代码时非常方便——本教程的全部示例就是这样逐一编译验证的。

## 1.4 开发工具

推荐 **VS Code + lean4 扩展**：

1. 安装 VS Code，扩展市场搜索 "lean4"（作者 leanprover）
2. 用 VS Code **打开项目根目录**（不是单个 .lean 文件），扩展会自动检测 `lean-toolchain`
3. 核心交互：
   - 光标停在 `#check`/`#eval` 行 → Infoview 面板显示结果
   - 光标停在 `by` 之后的战术块内 → Infoview 显示**当前目标与上下文**（这是证明时的主要工作界面）
   - `Ctrl+Shift+P` → "Lean 4: Restart Server" 用于异常时重启语言服务器

其他选择：
- **Neovim**：`nvim-lspconfig` + leanprover 的 Lean Language Server（同一套 `lean --server` 协议）
- **Emacs**：`lean4-mode`
- **浏览器**：[live.lean-lang.org](https://live.lean-lang.org/)（lean4web，内置 Mathlib，无需本地安装，适合快速试验）

## 1.5 获取 Mathlib

使用 Mathlib 的标准流程：

```bash
# 1. 创建项目并把 mathlib 加入依赖（git 方式）
lake init my_math && cd my_math
lake update                   # 修改 lakefile 添加 require mathlib 后执行
lake exe cache get            # 下载预编译的 olean 缓存（关键！否则要本地编译数小时）
```

`lakefile.lean` 中添加依赖：

```lean
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "main"
```

本教程项目使用的是**本地路径依赖**（`G:/github/lang/mathlib4` 是预构建好的 mathlib4 检出）：

```lean
require mathlib from "G:/github/lang/mathlib4"
```

路径依赖适合阅读/修改 mathlib 源码的场景；日常使用推荐 git 依赖 + `lake exe cache get`。

---

> 下一章：[02 · 基础类型与函数](02-basics.md) ｜ 返回：[README](../README.md)
