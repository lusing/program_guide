import Mathlib.Tactic

/-!
# 第 35 章：估计方程线性化与 sandwich 的代数锚
-/

namespace Ch35

/-- 标量 sandwich：若 `A=E[ell'']`、`J=Var(score)`，则 `V=J/A²`。 -/
def scalarSandwich (a j : ℚ) : ℚ := j / a ^ 2

/-- 正确设定正则模型中 `A=-I,J=I`，sandwich 化简为 `I⁻¹`。 -/
theorem sandwich_information_equality (i : ℚ) (hi : i ≠ 0) :
    scalarSandwich (-i) i = 1 / i := by
  simp only [scalarSandwich]
  field_simp

/-- 估计方程 `0=s+h*d+r` 给出局部误差表示 `d=-(s+r)/h`。 -/
theorem linearized_estimation_error (s h d r : ℚ) (hh : h ≠ 0)
    (hroot : s + h * d + r = 0) : d = -(s + r) / h := by
  field_simp
  linarith

/-- 误设工作模型 `N(mu,1)` 而真实方差为 4 时，稳健方差为 4。 -/
example : scalarSandwich (-1) 4 = 4 := by norm_num [scalarSandwich]

end Ch35
