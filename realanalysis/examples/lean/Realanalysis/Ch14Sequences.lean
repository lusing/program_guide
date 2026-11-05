import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Topology.Separation.Hausdorff
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic

/-!
# 第 14 章 序列与收敛

对应原书第 14 章：ε-N、例子、极限唯一、收敛蕴含值域有界、
朝极限点走的序列。极限的四则运算属于下一章。
-/

namespace Realanalysis.Ch14

open Set Filter Metric Bornology

/-! ## 14.3–14.4 ε-N 与例子 -/

/-- 取 ε = 1/10 时，N = 11 就够：n ≥ 11 则 1/n < 1/10。 -/
theorem harmonic_past_ten (n : ℕ) (hn : 11 ≤ n) : (1 : ℝ) / n < 1 / 10 := by
  have h10 : (0 : ℝ) < 10 := by norm_num
  have h10n : (10 : ℝ) < n := by
    exact_mod_cast (show 10 < n by omega)
  exact one_div_lt_one_div_of_lt h10 h10n

/-- 1/(n+1) → 0。书上对 1/n 取 N = ⌈1/ε⌉，这里分母写成 n+1，从 n = 0 起就有定义。 -/
theorem harmonic_to_zero :
    Tendsto (fun n : ℕ => 1 / ((n : ℝ) + 1)) atTop (nhds 0) :=
  tendsto_one_div_add_atTop_nhds_zero_nat

/-- 这条序列的每一项都在 (0, 1] 里，而且不是极限 0。这是定理 14.8 的一个具体情形。 -/
theorem harmonic_in_unit (n : ℕ) :
    1 / ((n : ℝ) + 1) ∈ Ioc (0 : ℝ) 1 := by
  refine ⟨?_, ?_⟩
  · positivity
  · rw [div_le_one (by positivity : (0 : ℝ) < (n : ℝ) + 1)]
    linarith

/-- 1 + (-1)^n/(n+1) → 1。它到 1 的距离正好是 1/(n+1)。 -/
theorem alternating_to_one :
    Tendsto (fun n : ℕ => (1 : ℝ) + (-1 : ℝ) ^ n / ((n : ℝ) + 1)) atTop (nhds 1) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  have hlim : Tendsto (fun n : ℕ => 1 / ((n : ℝ) + 1)) atTop (nhds 0) :=
    tendsto_one_div_add_atTop_nhds_zero_nat
  rw [Metric.tendsto_atTop] at hlim
  obtain ⟨N, hN⟩ := hlim ε hε
  refine ⟨N, fun n hn => ?_⟩
  have habs :
      |(-1 : ℝ) ^ n / ((n : ℝ) + 1)| = |(1 : ℝ) / ((n : ℝ) + 1)| := by
    rw [abs_div, abs_div, abs_neg_one_pow, abs_one]
  rw [Real.dist_eq, add_sub_cancel_left, habs]
  have hgoal := hN n hn
  rwa [Real.dist_eq, sub_zero] at hgoal

/-- 常数序列收敛到那个常数。 -/
theorem const_to_one : Tendsto (fun _ : ℕ => (1 : ℝ)) atTop (nhds 1) :=
  tendsto_const_nhds

/-- 常数序列的值域是单点。单点不是它自己的极限点：半径 1/2 的球里只有这一个点。 -/
theorem not_accPt_singleton (x : ℝ) : ¬ AccPt x (𝓟 ({x} : Set ℝ)) := by
  rw [accPt_iff_nhds]
  intro h
  obtain ⟨y, hy, hne⟩ := h (ball x (1 / 2)) (ball_mem_nhds x (by norm_num))
  rw [mem_inter_iff, mem_singleton_iff] at hy
  exact hne hy.2

/-! ## 14.6–14.7 唯一与有界 -/

/-- 定理 14.6：极限若存在则唯一。豪斯多夫空间里两个邻域滤子的极限相同。 -/
theorem limit_unique {s : ℕ → ℝ} {p q : ℝ}
    (hp : Tendsto s atTop (nhds p)) (hq : Tendsto s atTop (nhds q)) : p = q :=
  tendsto_nhds_unique hp hq

/-- 定理 14.7：收敛序列的值域有界。 -/
theorem convergent_range_bounded {s : ℕ → ℝ} {p : ℝ}
    (h : Tendsto s atTop (nhds p)) : IsBounded (range s) :=
  isBounded_range_of_tendsto s h

/-- n ↦ n² 不收敛：收敛序列的值域有界，而平方可以任意大。 -/
theorem squares_not_convergent :
    ¬ ∃ p : ℝ, Tendsto (fun n : ℕ => (n : ℝ) ^ 2) atTop (nhds p) := by
  intro h
  obtain ⟨p, hp⟩ := h
  have hb : IsBounded (range fun n : ℕ => (n : ℝ) ^ 2) :=
    isBounded_range_of_tendsto _ hp
  obtain ⟨r, hr⟩ := hb.subset_closedBall (0 : ℝ)
  have hr0 : 0 ≤ r := by
    have h0 : (fun n : ℕ => (n : ℝ) ^ 2) 0 ∈ closedBall (0 : ℝ) r :=
      hr (mem_range_self (0 : ℕ))
    simp [mem_closedBall, dist_self, pow_two] at h0
    exact h0
  obtain ⟨n, hn⟩ := exists_nat_gt (r + 1)
  have hn1 : (1 : ℝ) ≤ n := by
    have : (1 : ℝ) ≤ r + 1 := by linarith
    exact this.trans hn.le
  have hle : (n : ℝ) ≤ (n : ℝ) ^ 2 := by
    have hmul : (n : ℝ) * 1 ≤ (n : ℝ) * n :=
      mul_le_mul_of_nonneg_left hn1 (Nat.cast_nonneg n)
    simpa [pow_two, mul_one] using hmul
  have hmem : (n : ℝ) ^ 2 ∈ closedBall (0 : ℝ) r := hr (mem_range_self n)
  have habs : |(n : ℝ) ^ 2| ≤ r := by
    simpa [mem_closedBall, dist_zero_right, Real.norm_eq_abs] using hmem
  rw [abs_of_nonneg (by positivity : 0 ≤ (n : ℝ) ^ 2)] at habs
  have : (n : ℝ) ^ 2 < (n : ℝ) ^ 2 :=
    calc
      (n : ℝ) ^ 2 ≤ r := habs
      _ < r + 1 := by linarith
      _ < n := hn
      _ ≤ (n : ℝ) ^ 2 := hle
  exact lt_irrefl _ this

end Realanalysis.Ch14
