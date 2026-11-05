import Mathlib.Analysis.Normed.Group.InfiniteSum
import Mathlib.Analysis.PSeries
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Tactic

/-!
# 第 19 章 级数

对应原书第 19 章：部分和、几何级数、比较判别、p 级数。
比值判别和根值判别只在章末被点名，这里不展开。
-/

namespace Realanalysis.Ch19

open Filter

/-- 从 n = 0 加到 x^2：1 + 1/2 + 1/4 = 7/4。 -/
theorem half_partial : (1 : ℝ) + 1 / 2 + 1 / 4 = 7 / 4 := by
  norm_num

/-- 闭式 (1 - x^3)/(1 - x) 在 x = 1/2 时也是 7/4。 -/
theorem half_closed : (1 - ((1 : ℝ) / 2) ^ 3) / (1 - 1 / 2) = 7 / 4 := by
  norm_num

/-- |x| < 1 时几何级数从 n = 0 加起来等于 1/(1 - x)。x = 1/2 时和是 2。 -/
theorem half_series : ∑' n : ℕ, ((1 : ℝ) / 2) ^ n = 2 := by
  rw [tsum_geometric_of_abs_lt_one (by norm_num : |(1 / 2 : ℝ)| < 1)]
  norm_num

/-- 从 n = 1 起的 (2/3)^n 等于全和减去首项 1，结果是 2。 -/
theorem two_thirds : ∑' n : ℕ, ((2 : ℝ) / 3) ^ n - 1 = 2 := by
  rw [tsum_geometric_of_abs_lt_one (by norm_num : |(2 / 3 : ℝ)| < 1)]
  norm_num

/-- 常数 1 的几何级数发散：|1| 并不小于 1。 -/
theorem const_one_diverges : ¬Summable (fun n : ℕ => (1 : ℝ) ^ n) := by
  rw [summable_geometric_iff_norm_lt_one]
  norm_num

/-- 比较判别：|(-1/2)^n| = (1/2)^n，右边可和，左边也可和。 -/
theorem alt_half_summable : Summable (fun n : ℕ => (-(1 : ℝ) / 2) ^ n) := by
  apply Summable.of_norm
  simpa [norm_pow, abs_div, abs_neg, abs_one] using
    summable_geometric_of_abs_lt_one (by norm_num : |(1 / 2 : ℝ)| < 1)

/-- p 级数 ∑ 1/n^p 收敛当且仅当 p > 1。n = 0 那一项在除法里是 0，不影响敛散。 -/
theorem p_series {p : ℝ} : Summable (fun n : ℕ => 1 / (n : ℝ) ^ p) ↔ 1 < p :=
  Real.summable_one_div_nat_rpow

theorem squares_converge : Summable (fun n : ℕ => 1 / (n : ℝ) ^ (2 : ℝ)) :=
  p_series.mpr (by norm_num)

theorem harmonic_diverges : ¬Summable (fun n : ℕ => 1 / (n : ℝ)) :=
  Real.not_summable_one_div_natCast

/-- 调和前四项已经大于 2。把 1/3 换成更小的 1/4，四项刚好是 2。 -/
theorem harmonic_four : (1 : ℝ) + 1 / 2 + 1 / 3 + 1 / 4 > 2 := by
  norm_num

theorem harmonic_group : (1 : ℝ) + 1 / 2 + 1 / 4 + 1 / 4 = 2 := by
  norm_num

end Realanalysis.Ch19
