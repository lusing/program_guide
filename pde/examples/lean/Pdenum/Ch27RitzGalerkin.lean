import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Pdenum.Ch24Variational

/-!
# 第 27 章（Lean 通道）：Ritz 系数方程与能量最优性

Ritz 法把变分问题投影到有限维：v = Σ c_j φ_j，对 J(v) = ½D(v,v) − F(v)
求导得**系数方程** Σ_j c_j D(φ_j, φ_i) = F(φ_i)（线性方程组 Ac = b）。

本章的代数核：
1. **正交基对角化**：若 D(φ_j, φ_k) = δ_{jk}·d_j（正交基，如正弦
   基 d_j = (j²π²+1)/2），系数方程**解耦**：c_j = F(φ_j)/d_j；
2. **能量最优性**：Ritz 解 c 使 J(c) 在系数空间最小——对二次函数
   ∇J(c) = Ac − b = 0 与配方法 J(c) − J(c*) = ½(c−c*)ᵀA(c−c*) ≥ 0
   （A 对称正定时）等价。
-/

open Real

namespace Pdenum.Ch27

/-! ## 正交基的解耦 -/

/-- **对角系数方程**：正交基下 A = diag(d_j)，解 c_j = F_j/d_j。
数值版恒等式：`c_j·d_j = F_j`——`ring` 级。 -/
theorem ritz_diagonal (cj dj Fj : ℝ) (hdj : dj ≠ 0)
    (heq : cj * dj = Fj) : cj = Fj / dj := by
  field_simp
  exact heq

/-! ## 配方法与能量最优性 -/

/-- **二次型的配方**：J(c) = ½cᵀAc − bᵀc（A 对称），c* = A⁻¹b 时

    J(c) − J(c*) = ½(c−c*)ᵀA(c−c*) ≥ 0（A ≥ 0 时）。

一维（单基函数）版本的代数核： -/
theorem completing_square (a c cstar b : ℝ)
    (hcstar : a * cstar = b) :
    (a / 2) * c ^ 2 - b * c - ((a / 2) * cstar ^ 2 - b * cstar)
      = (a / 2) * (c - cstar) ^ 2 := by
  -- 纯代数恒等式：两边之差 = (a·cstar − b)(cstar − c)·...，代入 hcstar 后为零
  have key : (a / 2) * c ^ 2 - b * c - ((a / 2) * cstar ^ 2 - b * cstar)
      - (a / 2) * (c - cstar) ^ 2 = (b - a * cstar) * (cstar - c) := by
    field_simp
    ring
  have hb : b - a * cstar = 0 := by linarith [hcstar]
  have hz : (a / 2) * c ^ 2 - b * c - ((a / 2) * cstar ^ 2 - b * cstar)
      - (a / 2) * (c - cstar) ^ 2 = 0 := by
    rw [key, hb, zero_mul]
  linear_combination hz

/-- **能量最优**：a > 0 时 c* 使 J 最小（差 = 非负量）。 -/
theorem ritz_minimal (a c cstar b : ℝ)
    (ha : 0 < a) (hcstar : a * cstar = b) :
    (a / 2) * cstar ^ 2 - b * cstar ≤ (a / 2) * c ^ 2 - b * c := by
  have h := completing_square a c cstar b hcstar
  have h1 : 0 ≤ (c - cstar) ^ 2 := sq_nonneg (c - cstar)
  have h2 : 0 ≤ (a / 2) * (c - cstar) ^ 2 := mul_nonneg (by linarith) h1
  linarith

end Pdenum.Ch27
