import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Pdenum.Ch03Schemes

/-!
# 第 08 章（Lean 通道）：CFL 条件的算术与一阶模板恒等式

1. **CFL 条件**：差分格式 n 步的依赖区间是 `[x − n·h, x + n·h]`；
   a > 0 时微分方程的依赖足点是 `x − a·t_n = x − a·n·τ`。包含
   ⟺ `|a|nτ ≤ nh` ⟺ `|λ| ≤ 1`（λ = aτ/h）——纯线性算术（h > 0）。
2. **一阶中心模板恒等式**（蛙跳格式的内核，与第 03 章二阶恒等式配对）：
   `sin((j+1)θ) − sin((j−1)θ) = 2cos(jθ)·sinθ`。
   代入蛙跳格式得 `uⁿ⁺¹ = uⁿ⁻¹ − 2iλsinθ·uⁿ`，特征根方程
   `μ² + 2iλsinθ·μ − 1 = 0` 的两根在 `λ²sin²θ ≤ 1` 时模为 1。
-/

open Real

namespace Pdenum.Ch08

/-! ## CFL 的算术内核 -/

/-- 依赖区间包含条件：`|a·n·τ| ≤ n·h ⟺ |a·τ/h| ≤ 1`（h > 0，n > 0）。
`λ = aτ/h` 是网格比；两边约去正因子 n·h——CFL 条件的全部算术。
（注意 n = 0 时左端平凡成立而右端未必，故须 n > 0。） -/
theorem cfl_arithmetic (a τ h n : ℝ) (hh : 0 < h) (hn : 0 < n) :
    abs (a * (n * τ)) ≤ n * h ↔ abs (a * τ / h) ≤ 1 := by
  have key : abs (a * (n * τ)) = n * abs (a * τ / h) * h := by
    simp only [abs_mul, abs_div, abs_of_pos hh, abs_of_pos hn]
    field_simp
  have hpos : 0 < n * h := by nlinarith
  rw [key]
  constructor
  · intro Hle
    have hstep : (abs (a * τ / h) - 1) * (n * h) ≤ 0 := by nlinarith
    nlinarith
  · intro Hle
    have hstep : n * abs (a * τ / h) * h ≤ n * (1 : ℝ) * h := by nlinarith
    nlinarith

/-! ## 一阶模板恒等式（蛙跳内核） -/

/-- `sin((j+1)θ) − sin((j−1)θ) = 2·sinθ·cos(jθ)`。 -/
theorem stencil_first_difference (j θ : ℝ) :
    sin ((j + 1) * θ) - sin ((j - 1) * θ) = 2 * sin θ * cos (j * θ) := by
  have hj1 : (j + 1) * θ = j * θ + θ := by ring
  have hj2 : (j - 1) * θ = j * θ - θ := by ring
  rw [hj1, hj2, Real.sin_add, Real.sin_sub]
  ring

end Pdenum.Ch08
