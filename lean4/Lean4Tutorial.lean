/-
文件: Lean4Tutorial.lean
描述: Lean 4 & Mathlib4 教程 - 根模块
编译: lake build Lean4Tutorial
-/

/-!
# Lean 4 & Mathlib4 教程示例

本项目包含完整的 Lean 4 和 Mathlib4 教程示例代码，
按类别分模块组织，所有示例均可在 Lean 4.33.1 + Mathlib4 4.33.1 上编译通过。

## 使用方式

```bash
# 构建全部示例
lake build

# 构建单个模块
lake build Lean4Tutorial.Examples.Basics.BasicTypes

# 运行单个文件的 #eval / #check
lake env lean Lean4Tutorial/Examples/Basics/BasicTypes.lean
```

## 模块结构

### 第一部分：Lean 4 基础

- `Lean4Tutorial.Examples.Basics` - 基础类型与函数
- `Lean4Tutorial.Examples.InductiveTypes` - 归纳类型
- `Lean4Tutorial.Examples.PatternMatching` - 模式匹配与递归
- `Lean4Tutorial.Examples.Typeclasses` - 类型类
- `Lean4Tutorial.Examples.Propositions` - 命题与证明
- `Lean4Tutorial.Examples.Tactics` - 战术基础
- `Lean4Tutorial.Examples.Structures` - 结构与记录
- `Lean4Tutorial.Examples.ModulesProjects` - 模块与项目管理

### 第二部分：Mathlib4

- `Lean4Tutorial.Examples.MathlibAlgebra` - 代数结构
- `Lean4Tutorial.Examples.MathlibNumberTheory` - 数论
- `Lean4Tutorial.Examples.MathlibAnalysis` - 实分析
- `Lean4Tutorial.Examples.MathlibTopology` - 拓扑学
- `Lean4Tutorial.Examples.MathlibLinearAlgebra` - 线性代数
- `Lean4Tutorial.Examples.MathlibCombinatorics` - 组合数学
- `Lean4Tutorial.Examples.MathlibMeasureProbability` - 测度论与概率论
- `Lean4Tutorial.Examples.AdvancedTactics` - 常用高级战术
-/

namespace Lean4Tutorial
end Lean4Tutorial
