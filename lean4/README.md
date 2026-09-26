# Lean 4 / Mathlib4 教程（4.34 + 2026-09 master）

面向**零基础入门 Lean 4 定理证明与函数式编程**的读者：第一部分从依赖类型讲到战术证明，
第二部分进入 **Mathlib4 的真实用法**（代数、数论、分析、拓扑、线代、组合、测度概率），
第三部分对标四份官方文档覆盖单子编程、IO、依赖类型实战、公理体系、宏、迭代器与程序验证。

> 本教程所有代码均在 Windows + Lean 4.34.0 + 本地 Mathlib4（master 分支）下编译验证通过，
> 并已于 2026-09 在 **macOS（Apple Silicon）** 上全量复验：
> 第一、三部分在 **Lean 4.34.1**（纯 Lean 工具链）下逐文件验证通过；
> 第二部分（Mathlib）在 **Lean 4.35.0-rc3 + Mathlib4 master** 下 lake 构建 20/20 通过。
> macOS 用户**无需修改任何教程代码**；仅 `build.ps1`（PowerShell 脚本）不适用，
> 改用 `lake build` 即可（见 [10 · 项目管理与模块系统](docs/10-modules-projects.md)）。
> 验证中发现的 API 差异已在各章"版本陷阱"中标注。

## 目录结构

```text
lean4/
├── README.md       本文件
├── docs/           29 章 + 附录（01 → 30 顺序阅读）
├── examples/       章节示例（00_verified 快速冒烟 + 01_basics … 17_workflow）
├── build.ps1       构建验证脚本
├── lakefile.lean
├── lean-toolchain  leanprover/lean4:v4.34.0
├── Lean4Tutorial.lean             # 库根模块
└── Lean4Tutorial/Examples/        # Lake 模块镜像（与 examples/ 章节文件同步生成）
```

说明：
- `docs/` 每章一个文件，章内代码块与 `examples/` 章节文件一一对应，全部编译验证通过。
- `build.ps1 -All` 校验 `00_verified` + 教程章节文件的纯 Lean 部分；`-WithMathlib` 追加含 Mathlib 的章节（第 12-20 章对应文件）。
- `Lean4Tutorial/Examples/` 是章节文件的 Lake 模块镜像（模块名见各文件头注释），`lake build` 递归构建全部模块。
- `examples/` 中其他历史文件（basic_types.lean 等旧命名）保留为扩展素材，不在默认验证集内（可用 `-All -LegacyAll` 全量尝试，旧 API 可能失效）。

## 章节索引

### 第一部分：Lean 4 基础（01–10）

| 章 | 主题 | 示例 |
|---|---|---|
| [01 简介与环境搭建](docs/01-intro-setup.md) | 依赖类型核心思想、elan 安装、Lake 项目、hello world | — |
| [02 基础类型与函数](docs/02-basics.md) | Nat/String/List、函数定义、命名参数与默认参数 | `01_basics` |
| [03 依赖类型与宇宙](docs/03-universes.md) | 宇宙层级、依赖函数类型、多态定义 | `02_inductive_types` |
| [04 归纳类型](docs/04-inductive-types.md) | inductive 定义、构造子、递归函数、deriving | `02_inductive_types` |
| [05 模式匹配与递归](docs/05-pattern-matching.md) | match、模式展开、尾递归与良基递归 | `03_pattern_matching` |
| [06 类型类](docs/06-typeclasses.md) | class/instance、实例派生、类型类继承 | `04_typeclasses` |
| [07 命题与证明](docs/07-propositions.md) | Prop、∀/∃ 引入消去、term 证明与战术证明 | `05_propositions` |
| [08 战术基础](docs/08-tactics.md) | intro/apply/exact/rw/simp/omega | `06_tactics` |
| [09 结构与记录](docs/09-structures.md) | structure、字段访问、嵌套记录、继承 | `07_structures` |
| [10 项目管理与模块系统](docs/10-modules-projects.md) | lakefile、模块导入、目录组织、构建脚本 | `08_modules_projects` |

### 第二部分：Mathlib4 教程（11–20）

| 章 | 主题 | 示例 |
|---|---|---|
| [11 Mathlib4 概述](docs/11-mathlib-overview.md) | 库全景、模块命名规律、import 策略 | — |
| [12 代数结构](docs/12-algebra.md) | 群/环/域层级、子群、同态 | `09_mathlib_algebra` |
| [13 数论](docs/13-number-theory.md) | 整除与素数、Euclid 算法、√2 无理性 | `10_mathlib_number_theory` |
| [14 实分析](docs/14-analysis.md) | 极限/连续/导数、介值定理 | `11_mathlib_analysis` |
| [15 拓扑学](docs/15-topology.md) | 度量与拓扑空间、连续映射、紧致性 | `12_mathlib_topology` |
| [16 线性代数](docs/16-linear-algebra.md) | 矩阵与行列式、Cayley-Hamilton | `13_mathlib_linear_algebra` |
| [17 组合数学](docs/17-combinatorics.md) | 计数、组合恒等式、图论 | `14_mathlib_combinatorics` |
| [18 测度论与概率论](docs/18-measure-probability.md) | 测度空间、积分、概率分布 | `15_mathlib_measure_probability` |
| [19 常用高级战术](docs/19-advanced-tactics.md) | aesop/polyrith、calc、induction 定制 | `16_advanced_tactics` |
| [20 定理检索与 Mathlib 工作流](docs/20-mathlib-workflow.md) | exact?/apply?、Loogle/Moogle、Zulip | `17_workflow` |

### 第三部分：进阶专题（21–29）

| 章 | 主题 | 示例 |
|---|---|---|
| [21 函子、应用算子与单子](docs/21-functors-monads.md) | Functor/Applicative/Monad 实例、List 为何不是 Monad | — |
| [22 do-记法深入](docs/22-do-notation.md) | do 块脱糖、StateM、return 提前退出 | — |
| [23 IO 与程序入口](docs/23-io.md) | 文件/目录/进程/环境变量、main 与退出码 | — |
| [24 单子变换器](docs/24-monad-transformers.md) | OptionT/ExceptT/StateT、lift 与提升顺序 | — |
| [25 依赖类型编程实战](docs/25-dependent-types.md) | Vect、Subtype、Fin、消除依赖类型约束 | — |
| [26 公理与计算](docs/26-axioms-computation.md) | 三大公理、#print axioms、decide 与内核计算 | — |
| [27 强制转换、记法与宏](docs/27-coe-notation-macros.md) | Coe/CoeFun、notation、macro | — |
| [28 迭代器](docs/28-iterators.md) | Std.Iter 组合子、惰性求值 | — |
| [29 性能、编译与程序验证](docs/29-performance-verification.md) | implemented_by/extern、profiler、vcgen | — |
| [30 附录：学习资源](docs/30-appendix.md) | 官方文档、书籍、定理搜索工具、社区 | — |

## 如何使用本教程

- **第一部分**面向零基础的读者，从语言特性讲到证明战术；有函数式编程经验者可快速浏览。
- **第二部分**假设你已完成第一部分，重点在于 *Mathlib 的真实用法*：
  每个概念都给出**源码文件路径**（相对于 mathlib4 仓库根目录）、**定理命名规律**与**惯用证明写法**。
- **第三部分**对标四份官方文档——*Functional Programming in Lean*、*Theorem Proving in Lean 4*、
  *Mathematics in Lean* 与 *Lean Language Reference*——覆盖单子编程、IO、依赖类型、公理体系、
  宏、迭代器与程序验证等进阶主题；全部示例在 Lean 4.34.1 下验证通过（vcgen 一节需 4.35+）。
- 代码块中的 `#check` / `#eval` 输出以注释形式给出；`example` 与 `theorem` 均可直接编译。
- Mathlib 的定理名遵循严格的命名约定（见 11.4 节），掌握命名规律比死记硬背重要得多。

## 工具链

- Lean/Lake：`g:\lean\bin\lake.exe`（elan shim，或已在 PATH 中的 `lake`）
- Toolchain：`leanprover/lean4:v4.34.0`（见 `lean-toolchain`）
- Mathlib4（本地源码，path 依赖）：`G:\github\lang\mathlib4`（master@2026-09）
- 依赖锁定：`lake-manifest.json` 中 8 个 git 依赖的 rev 与 mathlib4 仓库的锁定一致

## 编译验证

```powershell
cd G:\code\guide\lean4
.\build.ps1 -All                # 00_verified + 章节文件（纯 Lean 部分）
.\build.ps1 -All -WithMathlib   # 含 Mathlib 章节一并校验
lake build                      # 递归构建 Lean4Tutorial 镜像库（全部模块）
```

macOS / Linux 侧直接用 `lake`（`build.ps1` 依赖 Windows 路径与 PowerShell）：

```bash
cd lean4
lake build        # 全部模块；Mathlib 章节文件需在配好 Mathlib 依赖的环境下 lean <file> 逐个校验
```

单文件校验：

```powershell
.\build.ps1 -File 09_mathlib_algebra\algebra.lean
```

清理：

```powershell
.\build.ps1 -Clean
```

历史示例全量扫描（可能较慢、并可能因旧 API 失败）：

```powershell
.\build.ps1 -All -LegacyAll
```

## 升级到 v4.34.0 的注意事项

- mathlib4 于 2026-08 将 `Mathlib.Data.Real.Basic` 等迁移到 `Mathlib.Basic.Real.Basic`（旧模块保留 deprecated 重导出）；2026-09-15 批量删除了 2021~2026-02 的废弃声明（如 `add_left_neg` → `neg_add_cancel`）。
- 大算子绑定符由 `∑ i in s` 改为 `∑ i ∈ s`。
- `simp_arith` 已废弃（改用 `simp +arith` 或 `omega`）；`refine'` 由 `refine` 取代。
- 教程代码已全部按新 API 校准；镜像库通过 `globs := #[.submodules `Lean4Tutorial]` 递归构建。

## 相关教程

证明助手方向：[agda](../agda/README.md)、[coq](../coq/README.md)、[isabelle](../isabelle/README.md)、[hol4](../hol4/README.md)；形式化验证实战见 [sel4（seL4 形式化验证）](../sel4/README.md)。
