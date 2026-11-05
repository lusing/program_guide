import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Pdenum.Ch03Schemes

/-!
# 第 10 章（Lean 通道）：波动格式特征根的判别式条件

波动方程显式格式 `uⁿ⁺¹ = 2uⁿ − uⁿ⁻¹ + λ²(u_{j+1} − 2u_j + u_{j−1})`
代入模式 `sin(jθ)`（用第 03 章模板恒等式）得特征方程

    μ² − (2 + λ²(2cosθ − 2))μ + 1 = 0，

两根之积为 1。根落在单位圆上 ⟺ |2 − 4λ²sin²(θ/2)| ≤ 2 ⟺
λ²sin²(θ/2) ≤ 1。本章证明双向：

- `λ ≤ 1` 时对一切 s² ∈ [0,1] 有 |2 − 4λ²s²| ≤ 2（von Neumann 条件）；
- `λ > 1` 时取 s² = 1（θ = π）得 2 − 4λ² < −2（出界，与第 10 章
  Julia 通道 (−1)ʲ 模式的线性增长实验互证）。
-/

open Real

namespace Pdenum.Ch10

/-- 波动格式的逐模式放大：`v_j + λ²δ²v_j = (1 + λ²(2cosθ−2))·v_j`
（三层特征方程 `μ² − (2 + λ²(2cosθ−2))μ + 1 = 0` 的装配件）。 -/
theorem wave_characteristic (lam θ j : ℝ) :
    sin (j * θ) + lam ^ 2 * (sin ((j + 1) * θ) - 2 * sin (j * θ) + sin ((j - 1) * θ))
      = (1 + lam ^ 2 * (2 * cos θ - 2)) * sin (j * θ) := by
  have h := Pdenum.Ch03.stencil_eigen_identity j θ
  have hbr : sin ((j - 1) * θ) + sin ((j + 1) * θ) - 2 * sin (j * θ)
      = (2 * cos θ - 2) * sin (j * θ) := h
  have hbr2 : sin ((j + 1) * θ) - 2 * sin (j * θ) + sin ((j - 1) * θ)
      = (2 * cos θ - 2) * sin (j * θ) := by linarith
  rw [hbr2]
  ring

/-- **稳定方向**：`λ ≤ 1`、`s² ∈ [0,1]` 时特征方程系数
`c = 2 − 4λ²s²` 满足 `|c| ≤ 2`（两根共轭、模为 1——von Neumann 条件）。 -/
theorem wave_vn_stable (lam s2 : ℝ) (hlam : 0 ≤ lam) (hlam2 : lam ≤ 1)
    (hs1 : 0 ≤ s2) (hs2 : s2 ≤ 1) :
    |2 - 4 * lam ^ 2 * s2| ≤ 2 := by
  have hlo : 2 - 4 * lam ^ 2 * s2 ≤ 2 := by nlinarith
  have hhilaut : -2 ≤ 2 - 4 * lam ^ 2 * s2 := by nlinarith
  rw [abs_le]
  constructor <;> linarith

/-- **不稳定方向**：`λ > 1` 时取 θ = π（s² = 1）得系数
`2 − 4λ² < −2`——特征根一实一虚出单位圆。 -/
theorem wave_vn_unstable (lam : ℝ) (hlam : 1 < lam) :
    2 - 4 * lam ^ 2 * 1 < -2 := by
  nlinarith

end Pdenum.Ch10
