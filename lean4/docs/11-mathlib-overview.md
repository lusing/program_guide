# 11 · Mathlib4 概述

## 11.1 什么是 Mathlib4

Mathlib4 是 Lean 4 的官方社区数学库：单一巨型仓库（`Mathlib/` 目录下约 7000 个模块，2026 年规模），覆盖代数、分析、拓扑、数论、组合、测度论、概率论、范畴论、代数几何等领域。

设计原则：

- **统一的抽象**：用类型类串联所有代数结构（`Monoid → Group → Ring → Field` 一条链），一次证明处处可用
- **构造性与经典性并存**：默认允许经典逻辑，但可判定的内容尽量保留 `Decidable` 实例
- **命名约定即文档**：定理名编码命题结构（见 11.4）
- **严格的代码评审**：所有合并经 CI + 人工评审；废弃声明定期清理（教程代码须跟随更新）

## 11.2 仓库组织（2026-09 版）

| 目录 | 主要内容 |
|------|----------|
| `Mathlib/Algebra/` | 代数结构类型类、群环域的运算与序 |
| `Mathlib/AlgebraicGeometry/` | 代数几何（概形等） |
| `Mathlib/AlgebraicTopology/` | 代数拓扑 |
| `Mathlib/Analysis/` | 微积分、范数空间、特殊函数、傅里叶 |
| `Mathlib/Basic/` | **2026 年重构新增**：基础数系与结构（Real、Complex、NNReal、Countable 等） |
| `Mathlib/CategoryTheory/` | 范畴论 |
| `Mathlib/Combinatorics/` | 图论、鸽笼、加法组合 |
| `Mathlib/Data/` | 具体数据结构：Nat/Int/Rat/Real 性质、List/Finset/Set |
| `Mathlib/FieldTheory/` | 域扩张、伽罗瓦理论 |
| `Mathlib/Geometry/` | 欧氏几何、流形 |
| `Mathlib/GroupTheory/` | 群论专题（Sylow、自由群等） |
| `Mathlib/LinearAlgebra/` | 线性代数（维数、矩阵、双线性型） |
| `Mathlib/Logic/` | 逻辑工具 |
| `Mathlib/MeasureTheory/` | 测度与积分 |
| `Mathlib/NumberTheory/` | 数论 |
| `Mathlib/Order/` | 序理论与格 |
| `Mathlib/Probability/` | 概率论（独立性、条件期望、极限定理） |
| `Mathlib/RingTheory/` | 环论专题（理想、局部化、幂级数） |
| `Mathlib/Tactic/` | 全部战术实现 |
| `Mathlib/Topology/` | 拓扑与一致空间 |
| `Mathlib/Util/` | 元编程工具 |

**重要变化**：`Mathlib.Data.Real.Basic` 已于 2026-08 废弃，新位置是 `Mathlib.Basic.Real.Basic`（旧模块保留 `deprecated_module` 重导出，编译时会有警告）。本教程全部使用新路径。

## 11.3 在项目里用 Mathlib4

```lean
-- lakefile.lean
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "main"
```

```bash
lake update            # 解析依赖
lake exe cache get     # 拉取预编译 olean（必做，否则本地编译数小时）
```

导入时**只取所需模块**——`import Mathlib` 全量导入可行但编译慢：

```lean
-- 精确导入（推荐）
import Mathlib.Algebra.Group.Basic      -- 群
import Mathlib.Data.Nat.Prime.Basic     -- 素数

-- 全量导入（快速试验时）
import Mathlib
```

## 11.4 定理命名约定（最重要的生存技能）

Mathlib 定理名是**按结构编码**的，读懂命名规律就能猜出定理名：

| 模式 | 例子 | 含义 |
|------|------|------|
| `操作_操作` | `mul_comm`、`add_assoc` | 该操作的代数性质 |
| `操作_常量` | `mul_one`、`add_zero` | 与单位元的交互 |
| `主语_性质` | `Nat.Prime.dvd_mul` | 主语满足某性质 |
| `A_of_B` | `dvd_of_mod_eq_zero` | 从 B 推出 A |
| `A_iff_B` | `Nat.prime_def_lt` | 等价刻画 |
| `X.map_op` | `MonoidHom.map_mul` | 态射保持运算 |
| `Continuous.op` | `Continuous.add` | 性质在运算下封闭 |
| 点号记法 | `h.dvd_mul`、`hf.comp` | 放在假设后直接调用 |

**点号记法证明**是 Mathlib 的地道风格：假设 `h : p ∣ a * b`（`hp : p.Prime`），直接写 `hp.dvd_mul.mp h`，而不是搜一长串 `exact` 链。

## 11.5 查找定理的四种武器

```lean
-- 1. #check 猜名字（配合 11.4 命名规律）
#check mul_comm

-- 2. exact? / apply?：让 Lean 在库里搜索能关闭目标的定理（见第20章）
example (a b : Nat) : a + b = b + a := by exact?

-- 3. Loogle / Moogle：在线语义搜索（附录）
--    https://loogle.lean-lang.org/

-- 4. 官方 API 文档全文检索
--    https://leanprover-community.github.io/mathlib4_docs/
```

## 11.6 与版本共舞

- Mathlib 与 Lean 工具链**强绑定**：看 `lean-toolchain` 文件确认版本
- 废弃声明会保留数月（`@[deprecated]` 别名 + 编译警告），然后批量删除
- 跟随升级的标准流程：升 `lean-toolchain` → 同步 manifest 中依赖 rev → 编译 → 按警告改名

---

> 上一章：[10 · 项目管理与模块系统](10-modules-projects.md) ｜ 下一章：[12 · 代数结构](12-algebra.md) ｜ 返回：[README](../README.md)
