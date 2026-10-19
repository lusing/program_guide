import Mathlib.MeasureTheory.Measure.MeasureSpace

/-!
# 第 00 章 导言（Lean 冒烟）

本文件验证工程骨架：mathlib 钉版加载成功 + 测度基本 API 可用。
真正的形式化内容从 B1（01 章）开始逐批加入。
-/

open MeasureTheory

/-- 测度的非负性与空集为零：冒烟用真断言。 -/
example (μ : Measure ℕ) : μ ∅ = 0 := measure_empty

/-- 测度的单调性（测度论第一课：大集合测度不小）。 -/
example (μ : Measure ℕ) (s t : Set ℕ) (h : s ⊆ t) : μ s ≤ μ t := measure_mono h

/-- 可数可加性在两个不交可测集上的特例（有限可加）。 -/
example (μ : Measure ℕ) (s t : Set ℕ) (hs : MeasurableSet s)
    (h : Disjoint s t) : μ (s ∪ t) = μ s + μ t := measure_union h hs
