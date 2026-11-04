import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Topology.Basic
import Mathlib.Order.Filter.Basic

/-!
# 第 20 章 Lyapunov 稳定性（Lean）

- x(t) = e^{-t}·x₀ 是 x' = -x 的解，且 t → ∞ 时趋于 0
  （渐近稳定的最小完整样本）。
-/

open Real Topology Filter

namespace Ch20

/-- 解的导数账：d/dt (e^{-t}·x₀) = -(e^{-t}·x₀)。 -/
example (x0 : ℝ) (t : ℝ) :
    HasDerivAt (fun t => exp (-t) * x0) (-(exp (-t) * x0)) t := by
  have hm : HasDerivAt (fun t : ℝ => -t) (-1 : ℝ) t := by
    simpa using (hasDerivAt_id t).const_mul (-1 : ℝ)
  have hc : HasDerivAt (fun t => exp (-t)) (exp (-t) * (-1 : ℝ)) t := by
    have h := HasDerivAt.comp t (hasDerivAt_exp (-t)) hm
    simpa only [Function.comp_def] using h
  have hexp : HasDerivAt (fun t => exp (-t)) (-(exp (-t))) t :=
    hc.congr_deriv (by ring)
  have hm2 : HasDerivAt (fun t => x0 * exp (-t)) (x0 * (exp (-t) * (-1 : ℝ))) t :=
    HasDerivAt.const_mul x0 hc
  have hfun : (fun t : ℝ => exp (-t) * x0) = (fun t : ℝ => x0 * exp (-t)) := by
    funext (z : ℝ); ring
  rw [hfun]
  exact hm2.congr_deriv (by ring)

/-- 渐近稳定：e^{-t}·x₀ → 0（t → ∞）。 -/
example (x0 : ℝ) : Tendsto (fun t => exp (-t) * x0) atTop (nhds 0) := by
  have hc : Tendsto (fun _ : ℝ => x0) atTop (nhds x0) := tendsto_const_nhds
  have h := Real.tendsto_exp_neg_atTop_nhds_zero.mul hc
  simpa [zero_mul] using h

end Ch20
