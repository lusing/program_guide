import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Topology.Order.Compact
import Mathlib.Topology.Order.DenselyOrdered
import Mathlib.Topology.Compactness.Compact
import Mathlib.Tactic

/-!
# 第 12 章 海涅–博雷尔定理

对应原书第 12 章：闭区间套（用最小上界，不用紧性）、k 维格子紧、
有界集落进格子、海涅–博雷尔、魏尔斯特拉斯。
-/

namespace Realanalysis.Ch12

open Set Bornology Filter Metric

/-! ## 12.1 闭区间套 -/

/-- 定理 12.1：左端点递增、右端点递减、每段都非空，则交集非空。
    x 取左端点集的上确界。 -/
theorem nestedIcc (a b : ℕ → ℝ) (hab : ∀ n, a n ≤ b n) (ha : Monotone a) (hb : Antitone b) :
    (⋂ n, Icc (a n) (b n)).Nonempty := by
  have hne : (range a).Nonempty := range_nonempty a
  have hbu : BddAbove (range a) := by
    refine ⟨b 0, mem_upperBounds.2 ?_⟩
    rintro y ⟨n, rfl⟩
    exact (hab n).trans (hb (Nat.zero_le n))
  refine ⟨sSup (range a), mem_iInter.2 fun n => ?_⟩
  refine mem_Icc.2 ⟨le_csSup hbu (mem_range_self n), ?_⟩
  apply csSup_le hne
  rintro y ⟨m, rfl⟩
  rcases le_total m n with hmn | hnm
  · exact (ha hmn).trans (hab n)
  · exact (hab m).trans (hb hnm)

/-! ## 12.4–12.6 格子、有界、海涅–博雷尔 -/

/-- 定理 12.4 的一维情形：闭区间是紧的。 -/
example (a b : ℝ) : IsCompact (Icc a b) := isCompact_Icc

/-- 定理 12.4：二维格子 [0,1]×[0,1] 是紧的。 -/
example : IsCompact (Icc (0 : Fin 2 → ℝ) 1) := isCompact_Icc

/-- 定理 12.5：有界集落在某个闭区间里。圆内接于正方形，这里是一维。 -/
example (E : Set ℝ) (hE : IsBounded E) (c : ℝ) : ∃ r, E ⊆ Icc (c - r) (c + r) := by
  obtain ⟨r, hr⟩ := hE.subset_closedBall c
  exact ⟨r, by simpa [Real.closedBall_eq_Icc] using hr⟩

/-- 定理 12.6：ℝ 上紧当且仅当既闭又有界。 -/
example (E : Set ℝ) : IsCompact E ↔ IsClosed E ∧ IsBounded E :=
  isCompact_iff_isClosed_bounded

/-- (0,1) 有界，但不闭，所以不是紧集。有理数上的反例见教程正文。 -/
example : IsBounded (Ioo (0 : ℝ) 1) ∧ ¬ IsCompact (Ioo (0 : ℝ) 1) := by
  refine ⟨isBounded_Ioo 0 1, ?_⟩
  intro h
  have hmem : (0 : ℝ) ∈ closure (Ioo (0 : ℝ) 1) := by
    rw [closure_Ioo (by norm_num : (0 : ℝ) ≠ 1), mem_Icc]
    exact ⟨by norm_num, by norm_num⟩
  rw [h.isClosed.closure_eq] at hmem
  simp [mem_Ioo] at hmem

/-! ## 12.7–12.8 极限点与魏尔斯特拉斯 -/

/-- 定理 12.7 的一个方向：紧集的无限子集在紧集里有极限点。
    闭区间现在已知是紧的，所以可以直接用。 -/
example {E : Set ℝ} (hE : E.Infinite) (hsub : E ⊆ Icc 0 1) :
    ∃ x ∈ Icc (0 : ℝ) 1, AccPt x (𝓟 E) :=
  hE.exists_accPt_of_subset_isCompact isCompact_Icc hsub

/-- 定理 12.8：有界无限集在 ℝ 里有极限点。极限点可以落在集合外面。 -/
example (E : Set ℝ) (hE : E.Infinite) (hb : IsBounded E) : ∃ x, AccPt x (𝓟 E) := by
  obtain ⟨x, -, hx⟩ :=
    hE.exists_accPt_of_subset_isCompact hb.isCompact_closure (subset_closure (s := E))
  exact ⟨x, hx⟩

end Realanalysis.Ch12
