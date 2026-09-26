/-
文件: Lean4Tutorial.lean
描述: Lean 4 & Mathlib4 教程 - 根模块
编译: lake build Lean4Tutorial
-/

/-!
# Lean 4 & Mathlib4 教程示例

本项目包含完整的 Lean 4 和 Mathlib4 教程示例代码，
按类别分模块组织，与教程文档逐章对应（单文件版 `lean4-mathlib4-tutorial.md`，
按章拆分版见 `docs/01-intro-setup.md` … `docs/30-appendix.md`），
所有示例均在 Lean 4.34.0 + Mathlib4（master@2026-09）上编译验证通过。

## 使用方式

```bash
# 构建全部示例
lake build

# 构建单个模块
lake build Lean4Tutorial.Examples.Basics.Basics

# 运行单个文件的 #eval / #check
lake env lean Lean4Tutorial/Examples/Basics/Basics.lean
```

## 模块结构

### 第一部分：Lean 4 基础（教程第 2-10 章）

- `Lean4Tutorial.Examples.Basics` - 基础类型与函数（第 2 章）
- `Lean4Tutorial.Examples.InductiveTypes` - 宇宙与归纳类型（第 3-4 章）
- `Lean4Tutorial.Examples.PatternMatching` - 模式匹配与递归（第 5 章）
- `Lean4Tutorial.Examples.Typeclasses` - 类型类（第 6 章）
- `Lean4Tutorial.Examples.Propositions` - 命题与证明（第 7 章）
- `Lean4Tutorial.Examples.Tactics` - 战术基础（第 8 章）
- `Lean4Tutorial.Examples.Structures` - 结构与记录（第 9 章）
- `Lean4Tutorial.Examples.ModulesProjects` - 模块与项目管理（第 10 章）

### 第二部分：Mathlib4（教程第 11-20 章）

- `Lean4Tutorial.Examples.MathlibAlgebra` - 代数结构（第 12 章）
- `Lean4Tutorial.Examples.MathlibNumberTheory` - 数论（第 13 章）
- `Lean4Tutorial.Examples.MathlibAnalysis` - 实分析（第 14 章）
- `Lean4Tutorial.Examples.MathlibTopology` - 拓扑学（第 15 章）
- `Lean4Tutorial.Examples.MathlibLinearAlgebra` - 线性代数（第 16 章）
- `Lean4Tutorial.Examples.MathlibCombinatorics` - 组合数学（第 17 章）
- `Lean4Tutorial.Examples.MathlibMeasureProbability` - 测度论与概率论（第 18 章）
- `Lean4Tutorial.Examples.AdvancedTactics` - 常用高级战术（第 19 章）
- `Lean4Tutorial.Examples.Workflow` - 定理检索与工作流（第 20 章）
-/

namespace Lean4Tutorial
end Lean4Tutorial
