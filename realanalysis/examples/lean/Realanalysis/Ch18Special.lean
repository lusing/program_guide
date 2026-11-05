import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Order.Filter.AtTopBot.Archimedean
import Mathlib.Topology.Order.Basic
import Mathlib.Tactic

/-!
# 第 18 章 特殊序列

对应原书第 18 章：夹逼定理，以及 1/n^p、p^{1/n}、n^{1/n}、
n^α/(1+p)^n、|x|<1 时的 x^n。
-/

namespace Realanalysis.Ch18

open Filter

/-- 夹在 0 和 1/(n+1) 之间的平方也趋于 0。 -/
theorem squeezed_square :
    Tendsto (fun n : ℕ => ((1 : ℝ) / ((n : ℝ) + 1)) ^ 2) atTop (nhds 0) :=
  tendsto_of_tendsto_of_tendsto_of_le_of_le
    (tendsto_const_nhds : Tendsto (fun _ : ℕ => (0 : ℝ)) atTop (nhds 0))
    tendsto_one_div_add_atTop_nhds_zero_nat
    (fun n => by positivity)
    (fun n => by
      have hx : 0 ≤ (1 : ℝ) / ((n : ℝ) + 1) := by positivity
      have h1 : (1 : ℝ) / ((n : ℝ) + 1) ≤ 1 := by
        rw [div_le_one (by positivity : (0 : ℝ) < (n : ℝ) + 1)]
        linarith
      simpa [pow_two] using mul_le_of_le_one_right hx h1)

/-- |1/121| 已经小于 1/10，用来核对 1/n^2 的尾部。 -/
theorem eleven_square : |(1 : ℝ) / 121| < 1 / 10 := by
  norm_num

/-- |x|<1 时 x^n → 0。这里取 x = 1/2。 -/
theorem half_pow : Tendsto (fun n : ℕ => ((1 : ℝ) / 2) ^ n) atTop (nhds 0) :=
  tendsto_pow_atTop_nhds_zero_of_abs_lt_one (by norm_num)

theorem half_ten : ((1 : ℝ) / 2) ^ 10 < 1 / 100 := by
  norm_num

/-- 二项式展开丢掉正项之后仍留下 1 + n x。n=2、x=1/2 时，(3/2)^2 > 2。 -/
theorem binomial_step : (1 : ℝ) + 2 * (1 / 2) < (3 / 2) ^ 2 := by
  norm_num

/-- n^{1/n} = n^(1/n) → 1。 -/
theorem root_n :
    Tendsto (fun n : ℕ => (n : ℝ) ^ ((1 : ℝ) / (n : ℝ))) atTop (nhds 1) :=
  tendsto_rpow_div.comp (tendsto_natCast_atTop_atTop (R := ℝ))

/-- 多项式增长输给指数：n / 2^n → 0。这是 n^α/(1+p)^n 在 α=1、p=1 的情形。 -/
theorem linear_over_double :
    Tendsto (fun n : ℕ => (n : ℝ) / (2 : ℝ) ^ n) atTop (nhds 0) := by
  simpa [pow_one] using
    tendsto_pow_const_div_const_pow_of_one_lt 1 (by norm_num : (1 : ℝ) < 2)

end Realanalysis.Ch18
