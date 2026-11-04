import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Pdenum.Ch03Schemes

/-!
# 第 06 章（Lean 通道）：能量法的凸性内核与矩阵法的特征值

能量不等式方法（书 §4.3）对变系数迎风格式的证明，代数核心是
**凸性不等式**：加权平均的平方不超过平方的加权平均——
`((1−λ)a + λb)² ≤ (1−λ)a² + λb²`，λ ∈ [0,1]。差恰是
`λ(1−λ)(a−b)²`（恒等式，`ring` 可证），非负性即得不等式。

矩阵法（书 §4.2）的特征值闭式依赖第 03 章的模板恒等式：三对角
二阶差算子作用在 `sin(jθ)` 上是乘 `2cosθ − 2`。本章把它组装成
FTCS 热传导格式的**逐模式放大**结论：一步更新恰好把模式乘以
`1 + r(2cosθ − 2)`。
-/

open Real

namespace Pdenum.Ch06

/-! ## 能量法的凸性内核 -/

/-- 恒等式：`RHS − LHS = λ(1−λ)(a−b)²`，无需任何假设。
（注意：`λ` 是 Lean 保留字，参数名用 `lam`。） -/
theorem convex_identity (a b lam : ℝ) :
    (1 - lam) * a ^ 2 + lam * b ^ 2 - ((1 - lam) * a + lam * b) ^ 2
      = lam * (1 - lam) * (a - b) ^ 2 := by
  ring

/-- **凸性不等式**（能量法每一步的核心）：λ ∈ [0,1] 时
`((1−λ)a + λb)² ≤ (1−λ)a² + λb²`。逐格应用于
`u_j^{n+1} = (1−λ)u_j + λu_{j−1}` 并对 j 求和，得 ℓ² 能量的
单调性——书 (4.18)→(4.19) 的推导在常系数情形的全部代数内容。 -/
theorem convex_sq (a b lam : ℝ) (hlam1 : 0 ≤ lam) (hlam2 : lam ≤ 1) :
    ((1 - lam) * a + lam * b) ^ 2 ≤ (1 - lam) * a ^ 2 + lam * b ^ 2 := by
  have h1 : 0 ≤ 1 - lam := by linarith
  have hprod : 0 ≤ lam * (1 - lam) := mul_nonneg hlam1 h1
  have hs := sq_nonneg (a - b)
  have hid := convex_identity a b lam
  have h2 : 0 ≤ lam * (1 - lam) * (a - b) ^ 2 := mul_nonneg hprod hs
  linarith

/-! ## 矩阵法：模板恒等式 → 逐模式放大 -/

/-- FTCS 热传导格式作用在模式 `v_j = sin(jθ)` 上，一步把模式乘以
`1 + r(2cosθ − 2) = 1 − 4r·sin²(θ/2)`——矩阵法求 (J−1) 阶矩阵特征值
与 Fourier 方法求增长因子**得到同一个数**的代数原因。 -/
theorem ftcs_mode_amplification (r θ j : ℝ) :
    sin (j * θ) + r * (sin ((j + 1) * θ) - 2 * sin (j * θ) + sin ((j - 1) * θ))
      = (1 + r * (2 * cos θ - 2)) * sin (j * θ) := by
  have h := Pdenum.Ch03.stencil_eigen_identity j θ
  have hbr : sin ((j - 1) * θ) + sin ((j + 1) * θ) - 2 * sin (j * θ)
      = (2 * cos θ - 2) * sin (j * θ) := h
  have hbr2 : sin ((j + 1) * θ) - 2 * sin (j * θ) + sin ((j - 1) * θ)
      = (2 * cos θ - 2) * sin (j * θ) := by linarith
  rw [hbr2]
  ring

end Pdenum.Ch06
