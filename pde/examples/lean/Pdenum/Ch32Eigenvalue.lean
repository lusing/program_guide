import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# 第 32 章（Lean 通道）：离散谱从上方逼近的代数核

差分最小特征值 λ₁,h = 2(1−cos πh)/h²。其**从上方逼近** π² 的方向
由 Taylor 上界 cos x ≤ 1 − x²/2 + x⁴/24 给出。本教程的分工纪律：
Lean 证**代数核**（给定 cos 的 Taylor 上界，推出谱不等式），
具体数值点的 cos 界核对交给 Julia/Python 通道。

核心代数：cos x ≤ 1 − x²/2 + x⁴/24 ⟹
2(1 − cos x) ≥ x²·(1 − x²/12) ⟹ λ₁,h ≥ π²·(1 − π²h²/12)。
-/

open Real

namespace Pdenum.Ch32

/-- **代数核**：给定 cos 的 Taylor 上界（0 ≤ x ≤ 2），
`x²(1 − x²/12) ≤ 2(1 − cos x)`——纯 nlinarith。 -/
theorem one_minus_cos_lower (x : ℝ)
    (hcos : cos x ≤ 1 - x ^ 2 / 2 + x ^ 4 / 24) :
    x ^ 2 * (1 - x ^ 2 / 12) ≤ 2 * (1 - cos x) := by
  nlinarith

/-- **λ₁,h 的下界**：`x = πh`、`0 < x` 时 `2(1−cos x)/x² ≥ 1 − x²/12`
——离散最小特征值从上方逼近的定量形式（h → 0 时右端 → 1）。 -/
theorem discrete_eig_lower_bound (x : ℝ) (hx : 0 < x)
    (hcos : cos x ≤ 1 - x ^ 2 / 2 + x ^ 4 / 24) :
    1 - x ^ 2 / 12 ≤ 2 * (1 - cos x) / x ^ 2 := by
  have h := one_minus_cos_lower x hcos
  field_simp
  linarith

end Pdenum.Ch32
