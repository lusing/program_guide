import Mathlib.MeasureTheory.Measure.MeasureSpace
import Mathlib.MeasureTheory.Measure.Dirac
import Mathlib.MeasureTheory.Measure.ProbabilityMeasure

/-!
# 第 02 章 概率公理与基本定律（Lean）

Miller ch2 的机器侧：mathlib 的 `MeasureTheory.Measure` 就是
Kolmogorov 三公理的化身——本章登记三条"免费午餐"引理的
机器版（补律/单调性/不交并可加），并在两点均匀空间上
实例化容斥二项版。

本科向说明：你不需要先学 Lean——把每个 `example` 读作
"计算机替我们把正文 02.4 的推导重演了一遍，且不会算错"。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名：三公理的免费午餐 -/

#check @measure_mono        -- 02.D 单调性：A ⊆ B ⟹ μ A ≤ μ B
#check @measure_compl       -- 02.B 补律：μ Aᶜ = μ Ω − μ A
#check @measure_union       -- 02.E 容斥的基件：不交并的可加
#check @measure_empty       -- 02.C 空事件：μ ∅ = 0

/-! ## 两点均匀空间：公理定律的实弹 -/

/-- 两点均匀测度：μ{true} = μ{false} = 1/2（dirac 折叠 +
标量乘——正文 02.5 的玩具空间）。 -/
noncomputable def coin2 : Measure Bool :=
  (2 : ℝ≥0∞)⁻¹ • (Measure.dirac true + Measure.dirac false)

instance : IsProbabilityMeasure coin2 := by
  constructor
  simp [coin2, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem,
    ENNReal.inv_two_add_inv_two]

/-- 容斥二项版的实例：A = {true}，B = {false}（不交情形，
减项为零）——μ(A ∪ B) = μ A + μ B。 -/
example : coin2 ({true, false} : Set Bool) = 1 := by
  simp [coin2, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem,
    ENNReal.inv_two_add_inv_two]

/-- 单调性的实例：{true} ⊆ {true, false} ⟹ 1/2 ≤ 1。 -/
example : coin2 ({true} : Set Bool) ≤ coin2 ({true, false} : Set Bool) :=
  measure_mono (by intro x hx; simp)

/-- 补律的实例：μ({true}ᶜ) = μ(Ω) − μ({true}) = 1 − 1/2 = 1/2
（measure_compl 的直译——正文 02.B 的机器版）。 -/
example : coin2 ({true} : Set Bool)ᶜ = (2 : ℝ≥0∞)⁻¹ := by
  have h : ({true} : Set Bool)ᶜ = {false} := by ext x; cases x <;> simp
  rw [h]
  simp [coin2, Measure.smul_apply, Measure.add_apply, Set.indicator_of_mem]

/-- Boole 上界的实例（两事件版）：μ(A ∪ B) ≤ μ A + μ B——
在两点空间上取等（不交）。 -/
example (A B : Set Bool) (h : Disjoint A B) :
    coin2 (A ∪ B) = coin2 A + coin2 B :=
  measure_union h (by measurability)
