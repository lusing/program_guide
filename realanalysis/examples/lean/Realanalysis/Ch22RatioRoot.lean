import Mathlib.Analysis.Normed.Group.InfiniteSum
import Mathlib.Topology.Algebra.InfiniteSum.NatInt
import Mathlib.Topology.Algebra.Monoid
import Mathlib.Analysis.PSeries
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Tactic

/-!
# 第 22 章 比值判别法与根值判别法（补充章）

原书第 19 章只点了两条判别法的名字。这一章把它们讲透：
两条判别法本质上都是同一件事——把级数和一条几何级数比较。
-/

namespace Realanalysis.Ch22

open Filter
open scoped Topology
open scoped Nat

/-- 根值判别（几何界形式）：最终有 ‖f n‖ ≤ r^n，其中 0 ≤ r < 1，则 f 可和。
证明只有一步：用可和的几何级数 r^n 做比较判别。 -/
theorem summable_of_root_eventually_le {f : ℕ → ℝ} {r : ℝ}
    (hr0 : 0 ≤ r) (hr1 : r < 1)
    (h : ∀ᶠ n in atTop, ‖f n‖ ≤ r ^ n) : Summable f :=
  Summable.of_norm_bounded_eventually_nat (summable_geometric_of_lt_one hr0 hr1) h

/-- 比值判别（极限形式，mathlib 库定理）：相邻项范数之比趋于 l < 1，
且项最终非零，则 f 可和。 -/
theorem ratio_test_lt_one {f : ℕ → ℝ} {l : ℝ} (hl : l < 1)
    (hnz : ∀ᶠ n in atTop, f n ≠ 0)
    (h : Tendsto (fun n => ‖f (n + 1)‖ / ‖f n‖) atTop (𝓝 l)) : Summable f :=
  summable_of_ratio_test_tendsto_lt_one hl hnz h

/-- 例：f n = 2^n / n!。相邻项之比恰为 2/(n+1)，趋于 0 < 1，所以可和。
它的和是 e^2，第 23 章会把这个和算出来。 -/
theorem factorial_series_summable :
    Summable (fun n : ℕ => (2 : ℝ) ^ n / n !) := by
  apply summable_of_ratio_test_tendsto_lt_one (by norm_num : (0 : ℝ) < 1)
  · exact .of_forall fun n => ne_of_gt <|
      div_pos (pow_pos (by norm_num) n) (Nat.cast_pos.mpr (Nat.factorial_pos n))
  · have hlim : Tendsto (fun n : ℕ => 2 * (1 / ((n : ℝ) + 1))) atTop (𝓝 0) := by
      simpa using (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).const_mul 2
    apply hlim.congr'
    filter_upwards with n
    have hpos : ∀ k : ℕ, (0 : ℝ) < (2 : ℝ) ^ k / k ! := fun k =>
      div_pos (pow_pos (by norm_num) k) (Nat.cast_pos.mpr (Nat.factorial_pos k))
    rw [Real.norm_eq_abs, abs_of_pos (hpos (n + 1)),
      Real.norm_eq_abs, abs_of_pos (hpos n)]
    simp only [Nat.factorial_succ, Nat.cast_mul, Nat.cast_add, Nat.cast_one, pow_succ]
    field_simp

/-- 前几项的比值可以直接算：n = 2 时比值是 2/3。 -/
theorem factorial_ratio_at_two :
    ((2 : ℝ)^3 / 3! / ((2 : ℝ)^2 / 2!)) = 2 / 3 := by norm_num

/-- 反例：f n = 2^n，相邻项之比恒为 2 > 1，级数不可和。 -/
theorem geometric_two_diverges :
    ¬Summable (fun n : ℕ => (2 : ℝ) ^ n) := by
  refine not_summable_of_ratio_test_tendsto_gt_one (by norm_num : (1 : ℝ) < 2) ?_
  refine tendsto_const_nhds.congr' ?_
  filter_upwards with n
  have hpos : ∀ k : ℕ, (0 : ℝ) < (2 : ℝ) ^ k := fun k => pow_pos (by norm_num) k
  rw [Real.norm_eq_abs, abs_of_pos (hpos (n + 1)),
    Real.norm_eq_abs, abs_of_pos (hpos n)]
  field_simp [pow_succ]
  ring

/-- 根值判别例：g n = (n/(2n+1))^n。底数对所有 n 都不超过 3/5，
所以 ‖g n‖ ≤ (3/5)^n，落入几何界。 -/
theorem root_series_summable :
    Summable (fun n : ℕ => ((n : ℝ) / (2 * n + 1)) ^ n) := by
  refine summable_of_root_eventually_le (r := 3 / 5) (by norm_num) (by norm_num) ?_
  filter_upwards with n
  have hb0 : (0 : ℝ) ≤ (n : ℝ) / (2 * n + 1) := by positivity
  have hdiff : 3 / 5 - (n : ℝ) / (2 * n + 1) =
      ((n : ℝ) + 3) / (5 * (2 * n + 1)) := by
    field_simp
    ring
  have hnonneg : 0 ≤ 3 / 5 - (n : ℝ) / (2 * n + 1) := by
    rw [hdiff]
    positivity
  have hle : (n : ℝ) / (2 * n + 1) ≤ 3 / 5 := by
    calc (n : ℝ) / (2 * n + 1)
        = 3 / 5 - (3 / 5 - (n : ℝ) / (2 * n + 1)) := by ring
      _ ≤ 3 / 5 := sub_le_self _ hnonneg
  have hpow : ((n : ℝ) / (2 * n + 1)) ^ n ≤ (3 / 5 : ℝ) ^ n := by gcongr
  have hg0 : (0 : ℝ) ≤ ((n : ℝ) / (2 * n + 1)) ^ n := by positivity
  rwa [Real.norm_eq_abs, abs_of_nonneg hg0]

/-- 同一几何界在 n = 2 处的具体样子：(2/5)^2 ≤ (3/5)^2。 -/
theorem root_bound_at_two :
    ((2 : ℝ) / 5) ^ 2 ≤ (3 / 5 : ℝ) ^ 2 := by norm_num

/-- 发散侧的机制：最终 ‖f n‖ ≥ 1 时通项不可能趋于 0，而可和级数的通项必须趋于 0。 -/
theorem not_summable_of_eventually_one_le_norm {f : ℕ → ℝ}
    (h : ∀ᶠ n in atTop, (1 : ℝ) ≤ ‖f n‖) : ¬Summable f := by
  intro hs
  have h0 : Tendsto f atTop (𝓝 0) := hs.tendsto_atTop_zero
  rw [Metric.tendsto_atTop] at h0
  obtain ⟨N, hN⟩ := h0 (1 / 2) (by norm_num)
  obtain ⟨n, hn, hnN⟩ := (h.and (eventually_ge_atTop N)).exists
  have hlt : dist (f n) 0 < 1 / 2 := hN n hnN
  rw [dist_zero_right] at hlt
  linarith

/-- 失效情形之一：平移下标的调和级数，相邻项之比 (n+1)/(n+2) 趋于 1。 -/
theorem harmonic_ratio_tendsto_one :
    Tendsto (fun n : ℕ => (n + 1 : ℝ) / (n + 2)) atTop (𝓝 1) := by
  have h0 := (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).comp
      (tendsto_add_atTop_nat 1)
  have h2 := h0.const_sub 1
  have heq2 : (fun n : ℕ => 1 - 1 / ((n : ℝ) + 2)) =
      fun x : ℕ => 1 - ((fun n : ℕ => 1 / ((n : ℝ) + 1)) ∘ fun a : ℕ => a + 1) x := by
    funext x
    simp only [Function.comp_def]
    have hcast : (↑(x + 1) : ℝ) = (x : ℝ) + 1 := by simp
    rw [hcast]
    ring
  have h1 : Tendsto (fun n : ℕ => 1 - 1 / ((n : ℝ) + 2)) atTop (𝓝 1) := by
    rw [heq2]
    simpa using h2
  have heq : (fun n : ℕ => (n + 1 : ℝ) / (n + 2)) =
      fun (n : ℕ) => 1 - 1 / ((n : ℝ) + 2) := by
    funext n
    field_simp
    ring
  rw [heq]
  exact h1

/-- 平移下标避免 1/0：1/(n+1) 与 1/n 只差有限项，可和性相同；调和级数仍然发散。 -/
theorem shifted_harmonic_diverges :
    ¬Summable (fun n : ℕ => 1 / (↑(n + 1) : ℝ)) :=
  (summable_nat_add_iff (G := ℝ) 1).not.mpr Real.not_summable_one_div_natCast

/-- 失效情形之二：平方倒数的相邻项之比同样趋于 1。 -/
theorem squares_ratio_tendsto_one :
    Tendsto (fun n : ℕ => ((n + 1 : ℝ) / (n + 2)) ^ 2) atTop (𝓝 1) := by
  have h := (continuous_pow 2).continuousAt.tendsto.comp harmonic_ratio_tendsto_one
  convert h using 1
  funext n
  rfl
  simp

/-- 但平方倒数级数收敛（第 19 章的 p 级数，p = 2 > 1）。比值极限都是 1，命运不同。 -/
theorem shifted_squares_summable :
    Summable (fun n : ℕ => 1 / (↑(n + 1) : ℝ) ^ (2 : ℝ)) :=
  (summable_nat_add_iff (G := ℝ) 1).mpr <|
    Real.summable_one_div_nat_rpow.mpr (by norm_num : (1 : ℝ) < 2)

end Realanalysis.Ch22
