import Lake
open Lake DSL

package «lean4-tutorial» where
  -- Lean 4 & Mathlib4 教程示例项目
  version := "4.33.1"

-- 依赖本地 Mathlib4
-- 如需从网络获取，请改为：
-- require mathlib from git
--   "https://github.com/leanprover-community/mathlib4.git"
--   @ "v4.33.1"
require mathlib from "H:/Lang/lean4/mathlib4-4.33.1"

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

-- 示例可执行程序（用于运行测试）
lean_exe «tutorial-runner» where
  root := `Main
  supportInterpreter := true
