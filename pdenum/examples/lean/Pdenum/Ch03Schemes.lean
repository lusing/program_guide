import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# 第 03 章（Lean 通道）：差商对多项式的精确恒等式

Taylor 展开构造差分格式的可靠性基础是差商的截断误差公式。一般函数
上这些公式是余项形式的定理（分析范畴），但对**多项式**，截断误差
公式退化为可以 `ring` 闭核的代数恒等式——本章把三条核心恒等式作为
样张：

1. 前差商对二次多项式：`(P(x+h) − P(x))/h = P'(x) + (h/2)·P''(x)`；
2. 二阶中心差商对三次多项式**精确**：`(P(x+h) − 2P(x) + P(x−h))/h²
   = P''(x)`（这就是"五点格式对二次调和函数精确"的一维版本）；
3. 二阶中心差商对四次多项式的误差主项 `(h²/12)·P⁗(x)`。

这些恒等式是第 21/22 章九点格式、极值原理讨论的代数底座。
-/

open Real

namespace Pdenum.Ch03

/-! ## 前差商：主项带 `(h/2)·P''` -/

/-- 对 P(x) = x²：`(P(x+h) − P(x))/h = 2x + h`，即 `P'(x) + (h/2)P''(x)`。 -/
theorem forward_diff_quadratic (x h : ℝ) (hh : h ≠ 0) :
    ((x + h) ^ 2 - x ^ 2) / h = (2 * x + 1 * h) := by
  field_simp
  ring

/-- 主项恒等式：`2x + h = P'(x) + (h/2)·P''(x)` 对 `P = x²` 成立。 -/
theorem forward_diff_leading_term (x h : ℝ) :
    2 * x + h = 2 * x + (h / 2) * 2 := by ring

/-! ## 二阶中心差商：三次精确、四次带 `(h²/12)·P⁗` -/

/-- 对 P(x) = x³：二阶中心差商**精确**等于 P''(x) = 6x。 -/
theorem second_central_cubic_exact (x h : ℝ) (hh : h ≠ 0) :
    ((x + h) ^ 3 - 2 * x ^ 3 + (x - h) ^ 3) / h ^ 2 = 6 * x := by
  field_simp
  ring

/-- 对 P(x) = x⁴：二阶中心差商 = P''(x) + (h²/12)·P⁗(x)，
其中 P''(x) = 12x²，P⁗(x) = 24。 -/
theorem second_central_quartic_leading (x h : ℝ) (hh : h ≠ 0) :
    ((x + h) ^ 4 - 2 * x ^ 4 + (x - h) ^ 4) / h ^ 2
      = 12 * x ^ 2 + (h ^ 2 / 12) * 24 := by
  field_simp
  ring

/-! ## 网格上的格式恒等式：模板作用在模式解上 -/

/-- 模板恒等式：`sin((j−1)θ) + sin((j+1)θ) − 2·sin(jθ)
= (2cosθ − 2)·sin(jθ)`。

FTCS 热传导格式 `u_j^{n+1} = u_j + r·(u_{j+1} − 2u_j + u_{j−1})` 作用在
**离散采样**的模式 `v_j = sin(jθ)` 上因此退化为乘一个数
`1 + r·(2cosθ − 2) = 1 − 4r·sin²(θ/2)`——这是第 05 章 von Neumann
分析与第 06 章矩阵法特征值的共同代数内核。证明只用两角和差公式。 -/
theorem stencil_eigen_identity (j θ : ℝ) :
    sin ((j - 1) * θ) + sin ((j + 1) * θ) - 2 * sin (j * θ)
      = (2 * cos θ - 2) * sin (j * θ) := by
  have hj1 : (j - 1) * θ = j * θ - θ := by ring
  have hj2 : (j + 1) * θ = j * θ + θ := by ring
  rw [hj1, hj2, Real.sin_sub, Real.sin_add]
  ring

end Pdenum.Ch03
