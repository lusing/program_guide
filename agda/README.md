# Agda 教程（Agda 2.9.0 / 标准库 3.0）

面向**会编程（任意语言背景）、初学 Agda** 的读者：从依赖类型语言的心智模型讲到
类型系统、数据与模式匹配、命题等价与归纳证明，再到 Vec/Fin 依赖编程实战、
判定性与代数结构、Monad/IO/余归纳/反射等工程专题，最后以**类型良好表达式
解释器**与**可验证插入排序**两个综合项目收束。
**章号 = 示例编号**——01–27 章每章对应 `examples/` 里一个经 agda 2.9.0 +
stdlib 3.0 类型检查验证的完整 .agda 文件，29–34 章为 stdlib 深潜示例
（28 章为 60+ 条实测坑位总清单、35 章为 macOS 校验清单，均无示例）。

> 核心理念：**类型即命题，程序即证明，且程序必须终止。**
> Agda 把依赖类型做成了一等公民——编译（类型检查）通过，定理就成立；
> 详见 [01 章](docs/01-intro.md) 与 [28 章](docs/28-pitfalls.md)。

## 目录结构

```text
agda/
├── README.md              本文件
├── build.sh               类型检查 / 编译运行脚本（bash）
├── AgdaTutorial.agda-lib  项目库定义（examples 目录 + 标准库路径）
├── docs/                  35 章教程（01 → 35 顺序阅读）
├── examples/              33 个 .agda 示例（章号 = 示例编号）
└── _build/                类型检查产物（已 gitignore）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识 Agda](docs/01-intro.md) | Agda 是什么、Curry–Howard、与 Coq/Lean/Idris 对比 | `Ex01_intro.agda` |
| [02 工具链与交互方式](docs/02-toolchain.md) | agda 命令行、.agda-lib、Emacs 交互与孔洞 | `Ex02_toolchain.agda` |
| [03 第一个文件](docs/03-basics.md) | 定义、求值、类型标注与第一个证明 | `Ex03_basics.agda` |
| [04 记号与运算符](docs/04-syntax.md) | fixity、syntax 声明、Unicode 与命名 | `Ex04-syntax.agda` |
| [05 类型系统与宇宙](docs/05-universes.md) | Set / Setω、Level 多态、Π 与依赖函数 | `Ex05_universes.agda` |
| [06 数据类型与模式匹配](docs/06-patterns.md) | data、通配符、荒谬模式、点模式 | `Ex06_patterns.agda` |
| [07 递归与终止检查](docs/07-recursion.md) | 结构递归、递归论据、终止性实测边界 | `Ex07_recursion.agda` |
| [08 列表专题](docs/08-lists.md) | List 操作、隐式参数、append 家族 | `Ex08_lists.agda` |
| [09 记录与 Σ 类型](docs/09-records.md) | record、依赖对、函数即记录 | `Ex09_records.agda` |
| [10 依赖类型入门：Fin](docs/10-dependent.md) | 索引类型、依赖消除、荒谬模式实战 | `Ex10_dependent.agda` |
| [11 命题等式](docs/11-equality.md) | ≡ 的构造、subst / transport、Leibniz 等式 | `Ex11_equality.agda` |
| [12 逻辑连接词](docs/12-logic.md) | ⊤ ⊥ ¬ × ⊎ ⇔ 与 Curry–Howard 实战 | `Ex12_logic.agda` |
| [13 归纳证明](docs/13-induction.md) | 归纳剧本、依赖消除版归纳、generalize | `Ex13_induction.agda` |
| [14 推理框架](docs/14-reasoning.md) | ≡-Reasoning、≤ 推理、calc 风格 | `Ex14_reasoning.agda` |
| [15 可判定性质](docs/15-decidable.md) | Dec、_?=_、布林判定与命题证明的分野 | `Ex15_decidable.agda` |
| [16 Vec：长度索引的列表](docs/16-vectors.md) | 依赖编程招牌：向量与越界不可表达 | `Ex16_vectors.agda` |
| [17 函数世界：同构与外延](docs/17-functions.md) | _↔_、Function.Related、外延公理 | `Ex17_functions.agda` |
| [18 关系代数与抽象代数](docs/18-algebra.md) | Relation.Binary、Semigroup/Monoid 接口 | `Ex18_algebra.agda` |
| [19 Functor/Applicative/Monad](docs/19-monads.md) | Effect 模块族与 do 记号 | `Ex19_monads.agda` |
| [20 IO 与真实程序](docs/20-io.md) | IO 单子、--compile 编译流水线 | `Ex20_io.agda` |
| [21 文本处理](docs/21-strings.md) | String / Char / Nat 互转与解析 | `Ex21_strings.agda` |
| [22 余归纳与无限流](docs/22-codata.md) | guardedness、Musical.Stream | `Ex22-codata.agda` |
| [23 反射与元编程](docs/23-reflection.md) | TCDecls、quote goal、宏基础 | `Ex23_reflection.agda` |
| [24 立方类型论初步](docs/24-cubical.md) | --cubical、Path、Univalence 体验 | `Ex24_cubical.agda` |
| [25 实战：类型良好表达式解释器](docs/25-typedast.md) | 依赖 AST：良 scoped + 良 typed 构造即正确 | `Ex25_typedast.agda` |
| [26 实战：可验证插入排序](docs/26-sorting.md) | sorted 谓词 + 重排证明的插入排序 | `Ex26_sorting.agda` |
| [27 标准库阅读指南](docs/27-stdlib-guide.md) | 模块组织、Base/API 约定、命名地图 | `Ex27_stdlib.agda` |
| [28 坑清单与最佳实践](docs/28-pitfalls.md) | 60+ 条实测坑位与最佳实践总清单 | — |
| [29 stdlib 代数结构](docs/29-stdlib-algebra.md) | Algebra 三层（Definitions/Structures/Bundles）+ Solver 家族 | `Ex29_stdlib-algebra.agda` |
| [30 stdlib 判定性体系](docs/30-stdlib-decidable.md) | Dec 内部构造、Recomputable、判定式组合子、`_≟_`→`_≡?_` | `Ex30_stdlib-decidable.agda` |
| [31 stdlib 关系产业](docs/31-stdlib-relations.md) | 关系三层 + Construct 变形、Reasoning 挂接 | `Ex31_stdlib-relations.agda` |
| [32 stdlib 函数论与类型运算](docs/32-stdlib-functions.md) | Function.Base/Bundles/Related、外延公理位置 | `Ex32_stdlib-functions.agda` |
| [33 stdlib 数据结构系统](docs/33-stdlib-data.md) | List 关系树、Fin 构造、`Data.AVL`→`Data.Tree.AVL` | `Ex33_stdlib-data.agda` |
| [34 stdlib 自动证明](docs/34-stdlib-automation.md) | Reasoning 基础设施 + Tactic 求解器（Cong/Monoid/Ring） | `Ex34_stdlib-automation.agda` |
| [35 macOS 校验与 3.0 迁移](docs/35-macos-checklist.md) | macOS 源码编译装机 + 2.3→3.0 导入迁移清单 | — |

学习路线：01–04 上手与记号 → 05–10 数据建模与依赖类型（宇宙/匹配/递归/
列表/记录/Fin）→ 11–18 证明主线（等式/逻辑/归纳/推理/判定/Vec/同构/代数）→
19–24 工程专题（Monad/IO/文本/余归纳/反射/立方）→ 25–26 综合实战 →
27–28 手册化收尾（先查 28 再动手）→ 29–34 stdlib 深潜（代数/判定/关系/
类型运算/数据结构/自动化，可穿插此前各章复习）→ 35 macOS 装机校验清单。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| Agda（Debian/WSL） | `/usr/bin/agda`（2.8.0，apt 安装） |
| Agda（macOS） | 源码编译：`/Volumes/mac004/lang/agda`（master，Agda 2.9.0）经 stack + GHC 9.14.1 构建，详见 [35 章](docs/35-macos-checklist.md) |
| 标准库 | Debian：`/usr/share/agda-stdlib`（2.3）；macOS：git 源 `/Volumes/mac004/lang/agda-stdlib/src`（3.0），经 `AgdaTutorial.agda-lib` 引入 |
| Emacs 交互 | Debian：`elpa-agda2-mode`（C-u C-x ` 跳孔洞，C-c C-l 加载） |

## 验证命令

```bash
cd agda
./build.sh                # 全部示例类型检查
./build.sh Ex13_induction # 单文件检查
./build.sh run Ex20_io    # 编译为可执行文件并运行
./build.sh clean          # 清理 _build/
```

**判定标准**：全部示例 `agda` 类型检查退出码 0；`Ex20_io` 额外
`--compile` 后运行输出 `hello agda 42`。

## 平台差异说明

- .agda 文件为 UTF-8 无 BOM；中文注释直接可用（Agda 的 Unicode 标识符
  与中文注释天然共存）。
- `AgdaTutorial.agda-lib` 的 `include` 写死标准库源码路径（当前为 macOS
  git 源 `/Volumes/mac004/lang/agda-stdlib/src`，stdlib 3.0）；换机器改
  这一行即可。
- 本教程现以 Agda 2.9.0 + stdlib 3.0 为基线（macOS 源码编译装机与全量
  校验结果见 35 章）。stdlib 各版本间模块路径有挪动（如 `Data.AVL` →
  `Data.Tree.AVL`、单子群顶层名 `+-isMonoid` → `+-0-isMonoid`），
  2.3→3.0 的实测迁移清单见 [35 章](docs/35-macos-checklist.md)。
- `build.sh` 自动定位 agda：先探 `PATH`，再逐个试常见安装位（stack/
  cabal/ghcup/Homebrew），找不到才报错——非交互 shell 里 PATH 缺
  `/opt/local/bin` 也能跑；darwin 下脚本会 `export LC_ALL=en_US.UTF-8`，
  保证 `≟`/`ℕ`/`≤` 等 Unicode 正常输出。

## 示例怎么读

- **章号 = 示例编号**：`docs/13-induction.md` ↔ `examples/Ex13_induction.agda`，
  每章开头一行"对应示例"标注。
- 示例文件名带 `Ex` 前缀：Agda 模块名不能以数字开头，
  `module 13_induction` 直接是语法错误——这个坑 01 章就会撞上。
  04/22 两章用**连字符**（`Ex04-syntax`、`Ex22-codata`）：`syntax`/`codata`
  是关键字，被下划线分隔成独立词法片段后连 parse 都过不去。
- 28 章无示例，是全教程坑位的汇总清单——写代码前先查它。

## 相关教程

同为证明助手的 [coq](../coq/README.md)（tactic 证明主线）与
[lean4](../lean4/README.md)（数学定理主线）；三者共享 Curry–Howard 心智
模型，Agda 的特殊处是**项构造为主 + 终止性检查**；函数式对照
[haskell](../haskell/README.md)（Agda 语法与模块系统与其同源）。
