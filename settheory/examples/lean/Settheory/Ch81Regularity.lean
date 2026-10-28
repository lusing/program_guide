import Mathlib

/-!
# 第 81 章 · 实数子集的正则性

登记 mathlib 中真正的贝尔纲定理、非空开集非稀疏、勒贝格区间测度，
以及零测集的两种可测性接口。有限例子只承担离散计算，
不参与这些无限定理的证明。
-/

namespace Settheory.Ch81

open Set MeasureTheory

/-- 实数是贝尔空间：可数个稠密开集的交仍稠密。 -/
theorem real_baire {ι : Type*} [Countable ι] {U : ι → Set ℝ}
    (hopen : ∀ i, IsOpen (U i)) (hdense : ∀ i, Dense (U i)) :
    Dense (⋂ i, U i) :=
  dense_iInter_of_isOpen hopen hdense

/-- 非空开集不能是可数个无处稠密集合的并（第二纲）。 -/
theorem open_not_meagre {s : Set ℝ} (hs : IsOpen s) (hne : s.Nonempty) :
    ¬ IsMeagre s :=
  not_isMeagre_of_isOpen hs hne

/-- 闭区间的勒贝格测度就是区间长度。 -/
example (a b : ℝ) : volume (Icc a b) = ENNReal.ofReal (b - a) :=
  Real.volume_Icc

/-- 零测集总有可测零覆盖：这是「零测集可测」的完备化前形式。 -/
theorem null_has_measurable_cover (s : Set ℝ) (hs : volume s = 0) :
    ∃ t, s ⊆ t ∧ MeasurableSet t ∧ volume t = 0 :=
  exists_measurable_superset_of_null hs

/-- 完备测度上零测集直接可测；这是书中事实 (5) 的 mathlib 对应物。 -/
example (μ : Measure ℝ) [μ.IsComplete] {s : Set ℝ} (hs : μ s = 0) :
    MeasurableSet s :=
  measurableSet_of_null hs

/-- 每个测度的完备化都完备，故完备化上零测集皆可测。 -/
example (μ : Measure ℝ) : μ.completion.IsComplete :=
  inferInstance

end Settheory.Ch81
