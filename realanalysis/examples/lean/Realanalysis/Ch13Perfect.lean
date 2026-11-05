import Mathlib.Topology.Instances.CantorSet
import Mathlib.Topology.Connected.Basic
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Order.DenselyOrdered
import Mathlib.Analysis.Real.Cardinality
import Mathlib.Tactic

/-!
# 第 13 章 完备集与连通集

对应原书第 13 章：闭区间的每个点都是极限点且区间不可数、康托尔集、
分离、直线上的连通集就是含有全部中间点的集合。
-/

namespace Realanalysis.Ch13

open Set Metric Filter

/-! ## 13.1 闭区间不可数，端点是极限点 -/

/-- (0,1) 不可数，它又含在 [0,1] 里，所以闭区间不可数。 -/
example : ¬ (Icc (0 : ℝ) 1).Countable := by
  intro h
  have hsub : Ioo (0 : ℝ) 1 ⊆ Icc 0 1 := Ioo_subset_Icc_self
  exact (by simp : ¬ (Ioo (0 : ℝ) 1).Countable) (h.mono hsub)

/-- 0 是 [0,1] 的极限点：每个邻域里都还有区间中的另一个点。 -/
example : AccPt (0 : ℝ) (𝓟 (Icc (0 : ℝ) 1)) := by
  rw [accPt_iff_nhds]
  intro U hU
  obtain ⟨ε, hε, hsub⟩ := Metric.mem_nhds_iff.mp hU
  set y : ℝ := min (ε / 2) (1 / 2)
  have hypos : 0 < y := by
    exact lt_min (by linarith) (by norm_num)
  refine ⟨y, ⟨?_, ?_⟩, ne_of_gt hypos⟩
  · apply hsub
    rw [mem_ball, Real.dist_eq, sub_zero, abs_of_pos hypos]
    have : y ≤ ε / 2 := min_le_left _ _
    linarith
  · rw [mem_Icc]
    exact ⟨hypos.le, (min_le_right _ _).trans (by norm_num)⟩

/-! ## 13.2–13.5 康托尔集 -/

example : (0 : ℝ) ∈ cantorSet := zero_mem_cantorSet

example : (1 / 4 : ℝ) ∈ cantorSet := quarter_mem_cantorSet

example : cantorSet ⊆ Icc (0 : ℝ) 1 := cantorSet_subset_unitInterval

example : IsClosed cantorSet := isClosed_cantorSet

example : IsCompact cantorSet := isCompact_cantorSet

/-- 第一步删掉的开区间 (1/3, 2/3) 与康托尔集不相交。 -/
example : (1 / 2 : ℝ) ∉ cantorSet := by
  intro h
  have h1 : (1 / 2 : ℝ) ∈ preCantorSet 1 := mem_iInter.mp h 1
  rw [preCantorSet_succ, preCantorSet_zero, mem_union] at h1
  rcases h1 with ⟨x, hx, hxeq⟩ | ⟨x, hx, hxeq⟩
  · rw [mem_Icc] at hx
    have hle : x / 3 ≤ (1 : ℝ) / 3 := by
      rw [div_le_div_iff_of_pos_right (by norm_num : (0 : ℝ) < 3)]
      linarith [hx.2]
    have hx' : x / 3 = 1 / 2 := hxeq
    rw [hx'] at hle
    norm_num at hle
  · rw [mem_Icc] at hx
    have hge : (2 : ℝ) / 3 ≤ (2 + x) / 3 := by
      rw [div_le_div_iff_of_pos_right (by norm_num : (0 : ℝ) < 3)]
      linarith [hx.1]
    have hx' : (2 + x) / 3 = 1 / 2 := hxeq
    rw [hx'] at hge
    norm_num at hge

/-- 自相似：康托尔集是左三分之一与右三分之一各一份自己。 -/
example :
    cantorSet = (· / 3) '' cantorSet ∪ (fun x : ℝ => (2 + x) / 3) '' cantorSet :=
  cantorSet_eq_union_halves

/-! ## 13.6–13.8 分离 -/

/-- [-3, 0) 与 (0, 3] 分离：谁都不碰到对方的闭包。 -/
example :
    (Ico (-3 : ℝ) 0 ∩ closure (Ioc (0 : ℝ) 3) = ∅) ∧
      (closure (Ico (-3 : ℝ) 0) ∩ Ioc (0 : ℝ) 3 = ∅) := by
  constructor
  · rw [closure_Ioc (by norm_num : (0 : ℝ) ≠ 3), eq_empty_iff_forall_notMem]
    intro x hx
    simp [mem_Ico, mem_Icc] at hx
    linarith
  · rw [closure_Ico (by norm_num : (-3 : ℝ) ≠ 0), eq_empty_iff_forall_notMem]
    intro x hx
    simp [mem_Icc, mem_Ioc] at hx
    linarith

/-- [-3, 0] 与 (0, 3] 不相交，但 0 在右段的闭包里，所以不分离。 -/
example : Icc (-3 : ℝ) 0 ∩ Ioc 0 3 = ∅ := by
  rw [eq_empty_iff_forall_notMem]
  intro x hx
  simp [mem_Icc, mem_Ioc] at hx
  linarith

example : (0 : ℝ) ∈ Icc (-3) 0 ∩ closure (Ioc 0 3) := by
  rw [closure_Ioc (by norm_num : (0 : ℝ) ≠ 3)]
  refine ⟨?_, ?_⟩ <;> simp [mem_Icc]

/-- 定理 13.8：分离集的子集仍然分离。 -/
example {A B A1 B1 : Set ℝ} (hAB : A ∩ closure B = ∅) (hBA : closure A ∩ B = ∅)
    (hA : A1 ⊆ A) (hB : B1 ⊆ B) : A1 ∩ closure B1 = ∅ ∧ closure A1 ∩ B1 = ∅ := by
  constructor
  · rw [eq_empty_iff_forall_notMem]
    intro x hx
    have hxA : x ∈ A := hA hx.1
    have hxB : x ∈ closure B := closure_mono hB hx.2
    have : x ∈ (∅ : Set ℝ) := by
      rw [← hAB]
      exact ⟨hxA, hxB⟩
    exact this
  · rw [eq_empty_iff_forall_notMem]
    intro x hx
    have hxA : x ∈ closure A := closure_mono hA hx.1
    have hxB : x ∈ B := hB hx.2
    have : x ∈ (∅ : Set ℝ) := by
      rw [← hBA]
      exact ⟨hxA, hxB⟩
    exact this

/-! ## 13.9–13.13 连通 -/

example : IsPreconnected (∅ : Set ℝ) := isPreconnected_empty

example : IsConnected (Icc (0 : ℝ) 1) := isConnected_Icc (by norm_num)

example : IsConnected (Ioo (0 : ℝ) 1) := isConnected_Ioo (by norm_num)

/-- 定理 13.12：直线上，连通就是含有任意两点之间的全部点。 -/
example (E : Set ℝ) : IsPreconnected E ↔ OrdConnected E := isPreconnected_iff_ordConnected

/-- [-3, 0) ∪ (0, 3] 漏掉 0，所以不连通。 -/
example : ¬ IsPreconnected (Ico (-3 : ℝ) 0 ∪ Ioc 0 3) := by
  rw [isPreconnected_iff_ordConnected]
  intro h
  have hm : (-1 : ℝ) ∈ Ico (-3) 0 ∪ Ioc 0 3 := Or.inl ⟨by norm_num, by norm_num⟩
  have hp : (1 : ℝ) ∈ Ico (-3) 0 ∪ Ioc 0 3 := Or.inr ⟨by norm_num, by norm_num⟩
  have hz : (0 : ℝ) ∈ Icc (-1) 1 := ⟨by norm_num, by norm_num⟩
  have h0 := h.out hm hp hz
  simp [mem_Ico, mem_Ioc] at h0

end Realanalysis.Ch13
