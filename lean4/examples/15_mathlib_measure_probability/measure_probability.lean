/-
文件: 15_mathlib_measure_probability/measure_probability.lean
描述: 第18章 测度论与概率论（与教程同步，Mathlib4 master@2026-09 验证）
编译: lake build Lean4Tutorial.Examples.MathlibMeasureProbability.MeasureProbability
-/

import Mathlib.MeasureTheory.MeasurableSpace.Basic
import Mathlib.MeasureTheory.Measure.MeasureSpaceDef
import Mathlib.MeasureTheory.Function.StronglyMeasurable.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Real          -- μ.real（= (μ s).toReal）
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Probability.BorelCantelli
import Mathlib.Topology.Instances.Real.Lemmas

open MeasureTheory

namespace Lean4Tutorial.Examples.MathlibMeasureProbability.Ch18

/-! # 18.1 可测空间 -/

example [MeasurableSpace α] : MeasurableSet (∅ : Set α) := MeasurableSet.empty
example [MeasurableSpace α] : MeasurableSet (Set.univ : Set α) := MeasurableSet.univ
example [MeasurableSpace α] {s : Set α} (hs : MeasurableSet s) :
    MeasurableSet sᶜ := hs.compl
example [MeasurableSpace α] {s : ℕ → Set α} (hs : ∀ i, MeasurableSet (s i)) :
    MeasurableSet (⋃ i, s i) := MeasurableSet.iUnion hs

#check BorelSpace
example : MeasurableSpace ℝ := inferInstance

/-! # 18.2 测度与 volume -/

-- ℝ 上 volume = 勒贝格测度；μ.real s = (μ s).toReal
example : volume (Set.Icc (0 : ℝ) 1) = 1 := by simp

example [MeasurableSpace α] (μ : Measure α) : μ ∅ = 0 := μ.empty
example [MeasurableSpace α] (μ : Measure α) {s t : Set α} (h : s ⊆ t) :
    μ s ≤ μ t := μ.mono h

-- 概率测度是谓词类：IsProbabilityMeasure μ ⟺ μ univ = 1
example [MeasurableSpace α] (μ : Measure α) [IsProbabilityMeasure μ] :
    μ Set.univ = 1 := IsProbabilityMeasure.measure_univ

/-! # 18.3 可测函数 -/

example {f : ℝ → ℝ} (hf : Measurable f) (s : Set ℝ) (hs : MeasurableSet s) :
    MeasurableSet (f ⁻¹' s) := hf hs

example {f : ℝ → ℝ} (hf : Continuous f) : Measurable f := hf.measurable

example : Measurable (fun x : ℝ => x^2 + x) := by fun_prop

/-! # 18.4 博赫纳积分 -/

-- 常值积分（Bochner/Basic.lean:987）：μ.real univ = (μ univ).toReal
-- 注意：测度论 API 的 MeasurableSpace 是隐式数据参数 {m : MeasurableSpace α}，
-- 不是实例隐式——需要从实例手动喂入
example [MeasurableSpace α] (μ : Measure α) (c : ℝ) :
    ∫ _ : α, c ∂μ = μ.real Set.univ • c := integral_const (m := ‹MeasurableSpace α›) c

-- 线性性（同样需要显式喂 m）
example [MeasurableSpace α] {f g : α → ℝ} {μ : Measure α}
    (hf : Integrable f μ) (hg : Integrable g μ) :
    ∫ x, f x + g x ∂μ = ∫ x, f x ∂μ + ∫ x, g x ∂μ :=
  integral_add (m := ‹MeasurableSpace α›) hf hg

-- 区间积分实战（SpecialFunctions/Integrals/Basic.lean:201，根命名空间）
example : ∫ x in (0 : ℝ)..1, x = 1 / 2 := by
  rw [integral_id]
  norm_num

/-! # 18.5 概率论专题 -/

-- 中心极限定理（ProbabilityTheory 命名空间，CentralLimitTheorem.lean:79）：
-- iid、均值 0、方差 1 ⟹ 标准化和依分布收敛到标准高斯
#check @ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum

-- Borel-Cantelli 第二引理
#check @ProbabilityTheory.measure_limsup_eq_one

end Lean4Tutorial.Examples.MathlibMeasureProbability.Ch18
