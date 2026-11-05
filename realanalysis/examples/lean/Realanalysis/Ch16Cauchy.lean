import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.UniformSpace.Cauchy
import Mathlib.Topology.Order.MonotoneConvergence
import Mathlib.Topology.Algebra.Group.Defs
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic

/-!
# 第 16 章 柯西序列与单调序列

对应原书第 16 章：柯西与收敛的关系、直径的数值例子、
实数的完备性、闭子集保持完备、有界单调序列收敛到上确界。
-/

namespace Realanalysis.Ch16

open Filter Set

/-! ## 16.1–16.3 柯西序列 -/

/-- 从第 11 项起，1/n 与 1/m 的距离已经小于 1/10。书上的估计是不超过 1/N。 -/
theorem harmonic_gap : |(1 : ℝ) / 11 - 1 / 12| < 1 / 10 := by
  norm_num

/-- √2 的两位与三位小数截断都是有理数，距离小于 10^{-2}。 -/
theorem sqrt_two_truncations : |(141 : ℝ) / 100 - 1414 / 1000| < 1 / 100 := by
  norm_num

/-- 定理 16.3：收敛序列是柯西序列。两边各让出 ε/2，再用三角不等式。 -/
theorem convergent_is_cauchy {s : ℕ → ℝ} {p : ℝ} (h : Tendsto s atTop (nhds p)) :
    CauchySeq s :=
  h.cauchySeq

/-- 定理 16.10 的一维情形：ℝ 完备，柯西序列必收敛。 -/
theorem cauchy_converges {s : ℕ → ℝ} (h : CauchySeq s) : ∃ p, Tendsto s atTop (nhds p) :=
  cauchySeq_tendsto_of_complete h

/-- 定理 16.13：完备空间的闭子集仍完备。极限落在闭集里。 -/
theorem closed_subset_complete {E : Set ℝ} (hE : IsClosed E) {s : ℕ → ℝ}
    (hs : ∀ n, s n ∈ E) (hc : CauchySeq s) : ∃ p ∈ E, Tendsto s atTop (nhds p) :=
  cauchySeq_tendsto_of_isComplete hE.isComplete hs hc

/-! ## 16.4 直径的两个端点 -/

/-- 例 16.5：{1,2,3} 里最远的两点相距 2，[-3,3] 的两端相距 6。 -/
theorem three_point_span : dist (1 : ℝ) 3 = 2 := by
  rw [Real.dist_eq]
  norm_num

theorem interval_span : dist (-3 : ℝ) 3 = 6 := by
  rw [Real.dist_eq]
  norm_num

/-! ## 16.14–16.16 单调序列 -/

/-- 1/(n+1) 递减。分母变大，倒数变小。 -/
theorem harmonic_antitone : Antitone (fun n : ℕ => (1 : ℝ) / ((n : ℝ) + 1)) := by
  intro a b hab
  have ha : (0 : ℝ) < (a : ℝ) + 1 := by positivity
  have habN : a + 1 ≤ b + 1 := Nat.add_le_add_right hab 1
  have hle : (a : ℝ) + 1 ≤ (b : ℝ) + 1 := by exact_mod_cast habN
  exact one_div_le_one_div_of_le ha hle

/-- 1 - 1/(n+1) 递增，而且每一项都不超过 1。 -/
theorem approach_one_mono : Monotone (fun n : ℕ => (1 : ℝ) - 1 / ((n : ℝ) + 1)) := by
  intro a b hab
  have h := harmonic_antitone hab
  linarith

theorem approach_one_bounded :
    BddAbove (range fun n : ℕ => (1 : ℝ) - 1 / ((n : ℝ) + 1)) := by
  refine ⟨1, ?_⟩
  rintro y ⟨n, rfl⟩
  have : (0 : ℝ) ≤ 1 / ((n : ℝ) + 1) := by positivity
  linarith

/-- 定理 16.16：有界递增序列收敛到值域的上确界。 -/
theorem approach_one_to_sup :
    Tendsto (fun n : ℕ => (1 : ℝ) - 1 / ((n : ℝ) + 1)) atTop
      (nhds (⨆ n : ℕ, (1 : ℝ) - 1 / ((n : ℝ) + 1))) :=
  tendsto_atTop_ciSup approach_one_mono approach_one_bounded

/-- 同一条序列也收敛到 1。极限唯一，所以上确界就是 1。 -/
theorem approach_one_to_one :
    Tendsto (fun n : ℕ => (1 : ℝ) - 1 / ((n : ℝ) + 1)) atTop (nhds 1) := by
  simpa using
    (tendsto_const_nhds : Tendsto (fun _ : ℕ => (1 : ℝ)) atTop (nhds 1)).sub
      tendsto_one_div_add_atTop_nhds_zero_nat

theorem approach_one_sup_eq : (⨆ n : ℕ, (1 : ℝ) - 1 / ((n : ℝ) + 1)) = 1 :=
  tendsto_nhds_unique approach_one_to_sup approach_one_to_one

end Realanalysis.Ch16
