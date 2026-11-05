import Mathlib.Topology.Compactness.Compact
import Mathlib.Topology.Constructions
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Topology.Order.DenselyOrdered
import Mathlib.Tactic

/-!
# 第 11 章 紧集

对应原书第 11 章：开覆盖与有限子覆盖、有限集是紧集、开区间不是紧集、
紧性不依赖所在的空间、紧集是闭集、闭子集仍紧、紧集有界、嵌套交非空、
无限子集必有极限点。闭区间的紧性是下一章的海涅–博雷尔定理。
-/

namespace Realanalysis.Ch11

open Set Bornology Filter

/-! ## 11.1 开覆盖与定义 -/

/-- 定义 11.3：每个开覆盖都有有限子覆盖。 -/
example {K : Set ℝ} {ι : Type} {U : ι → Set ℝ} (hK : IsCompact K)
    (hU : ∀ i, IsOpen (U i)) (hcov : K ⊆ ⋃ i, U i) :
    ∃ t : Finset ι, K ⊆ ⋃ i ∈ t, U i :=
  hK.elim_finite_subcover U hU hcov

/-- 例 11.2：三个开区间盖住 [-3, 3]。这只是一个覆盖，还不是紧性。 -/
example : Icc (-3 : ℝ) 3 ⊆ Ioo (-4) 0 ∪ Ioo (-1) 3 ∪ Ioo 2 6 := by
  intro x hx
  rcases lt_or_ge x 0 with h0 | h0
  · refine Or.inl (Or.inl ?_)
    constructor <;> linarith [hx.1, h0]
  · rcases lt_or_ge x 3 with h3 | h3
    · refine Or.inl (Or.inr ?_)
      constructor <;> linarith [h0, h3]
    · refine Or.inr ?_
      have hx3 : x = 3 := le_antisymm hx.2 h3
      constructor <;> linarith [hx3]

/-! ## 11.2 有限集紧，开区间不紧 -/

example : IsCompact (∅ : Set ℝ) := isCompact_empty

example (p : ℝ) : IsCompact ({p} : Set ℝ) := isCompact_singleton

/-- 有限集是紧集：每个点从覆盖里挑一个开集，最多挑有限次。 -/
example : IsCompact ({0, 1} : Set ℝ) := by
  have : ({0, 1} : Set ℝ).Finite := by simp
  exact this.isCompact

/-- 定理 11.5 的短证明：开区间不闭，而紧集一定闭（定理 11.7）。 -/
example : ¬ IsCompact (Ioo (0 : ℝ) 1) := by
  intro h
  have hc : IsClosed (Ioo (0 : ℝ) 1) := h.isClosed
  have h1 : (1 : ℝ) ∈ closure (Ioo 0 1) := by
    rw [closure_Ioo (by norm_num : (0 : ℝ) ≠ 1)]
    simp
  rw [hc.closure_eq] at h1
  simp at h1

/-! ## 11.3 相对紧致、闭子集、有界 -/

/-- 定理 11.6：含入是诱导映射，子空间里的紧与全空间里的像的紧是一回事。 -/
example {Y : Set ℝ} {K : Set Y} : IsCompact K ↔ IsCompact (Subtype.val '' K) :=
  Topology.IsEmbedding.subtypeVal.isCompact_iff

/-- 定理 11.7。 -/
example {K : Set ℝ} (h : IsCompact K) : IsClosed K := h.isClosed

/-- 定理 11.8：紧集的闭子集仍紧。 -/
example {K F : Set ℝ} (hK : IsCompact K) (hF : IsClosed F) (hsub : F ⊆ K) : IsCompact F :=
  hK.of_isClosed_subset hF hsub

/-- 推论 11.9。 -/
example {K F : Set ℝ} (hK : IsCompact K) (hF : IsClosed F) : IsCompact (F ∩ K) :=
  hK.inter_left hF

/-- 那段话的漏洞：[-5, 5] 不是 (-3, 3) 的子集，推论用不上。 -/
example : ¬ (Icc (-5 : ℝ) 5 ⊆ Ioo (-3) 3) := by
  intro h
  have h4 : (4 : ℝ) ∈ Icc (-5) 5 := by
    rw [mem_Icc]
    constructor <;> norm_num
  have hmem : (4 : ℝ) ∈ Ioo (-3) 3 := h h4
  simp [mem_Ioo] at hmem
  linarith

/-- 定理 11.10。 -/
example {K : Set ℝ} (h : IsCompact K) : IsBounded K := h.isBounded

/-! ## 11.4 嵌套交与极限点 -/

/-- 推论 11.12：非空紧集逐个缩小，交仍非空。 -/
example {t : ℕ → Set ℝ} (htd : ∀ i, t (i + 1) ⊆ t i) (htn : ∀ i, (t i).Nonempty)
    (ht0 : IsCompact (t 0)) (htcl : ∀ i, IsClosed (t i)) : (⋂ i, t i).Nonempty :=
  IsCompact.nonempty_iInter_of_sequence_nonempty_isCompact_isClosed t htd htn ht0 htcl

/-- 定理 11.13：紧集的无限子集在紧集里有极限点。 -/
example {K E : Set ℝ} (hK : IsCompact K) (hE : E.Infinite) (hsub : E ⊆ K) :
    ∃ x ∈ K, AccPt x (𝓟 E) :=
  hE.exists_accPt_of_subset_isCompact hK hsub

end Realanalysis.Ch11
