import Lake
open Lake DSL

package «lean4-tutorial» where
  -- Lean 4 & Mathlib4 教程示例项目

-- 使用本地 Mathlib4（已预构建仓库）
require mathlib from "G:/github/lang/mathlib4"

/-!
# 示例库配置

所有示例代码位于 examples/ 目录下，按类别分子目录组织。
模块名前缀为 `Lean4Tutorial.Examples`。

分类目录与模块名映射：
- 01_basics               → Basics
- 02_inductive_types      → InductiveTypes
- 03_pattern_matching     → PatternMatching
- 04_typeclasses          → Typeclasses
- 05_propositions         → Propositions
- 06_tactics              → Tactics
- 07_structures           → Structures
- 08_modules_projects     → ModulesProjects
- 09_mathlib_algebra      → MathlibAlgebra
- 10_mathlib_number_theory → MathlibNumberTheory
- 11_mathlib_analysis     → MathlibAnalysis
- 12_mathlib_topology     → MathlibTopology
- 13_mathlib_linear_algebra → MathlibLinearAlgebra
- 14_mathlib_combinatorics → MathlibCombinatorics
- 15_mathlib_measure_probability → MathlibMeasureProbability
- 16_advanced_tactics     → AdvancedTactics
-/

@[default_target]
lean_lib «Lean4Tutorial» where
  -- 所有示例代码的根模块
  roots := #[`Lean4Tutorial]
