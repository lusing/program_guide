import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# 第 24 章（Lean 通道）：能量泛函的直接法核

变分问题必要条件之后的第二块代数基石是**直接法**：极值曲线的能量
最小性可以分解为

    J(y* + w) = J(y*) + 2·交叉项(w) + Q(w)，Q(w) = ∫(w′² + w²) ≥ 0，

交叉项在 Euler 方程 + 齐次边界差下化为零（分部积分），于是
J(y*+w) − J(y*) = Q(w) ≥ 0。本章证明这个分解的**逐点代数核**——
展开恒等式与平方和的非负性，全部 `ring`/`linarith` 级。
-/

open Real

namespace Pdenum.Ch24

/-- **能量核的非负性**：`w'² + w² ≥ 0`（Q(w) ≥ 0 的逐点内核）。 -/
theorem energy_kernel_nonneg (w w' : ℝ) : 0 ≤ w' ^ 2 + w ^ 2 := by
  have h1 := sq_nonneg w'
  have h2 := sq_nonneg w
  linarith

/-- **展开恒等式**（J 的二次结构）：
`(y*' + w')² + (y* + w)² = (y*'² + y*²) + 2(y*'w' + y*w) + (w'² + w²)`——
J(y*+w) − J(y*) − 2·交叉 = Q(w) 的被积函数版，`ring` 一步。 -/
theorem energy_expansion (ystar w ystar' w' : ℝ) :
    (ystar' + w') ^ 2 + (ystar + w) ^ 2
      = (ystar' ^ 2 + ystar ^ 2) + 2 * (ystar' * w' + ystar * w)
        + (w' ^ 2 + w ^ 2) := by
  ring

/-- **最小性的代数形态**：交叉项为零时（Euler 方程吸收），
`J(y*+w) − J(y*) = Q(w) ≥ 0`——把两件事实拼起来。 -/
theorem energy_minimality (ystar w ystar' w' : ℝ)
    (hcross : ystar' * w' + ystar * w = 0) :
    (ystar' + w') ^ 2 + (ystar + w) ^ 2
      ≥ ystar' ^ 2 + ystar ^ 2 := by
  rw [energy_expansion ystar w ystar' w', hcross, mul_zero, add_zero]
  linarith [energy_kernel_nonneg w w']

end Pdenum.Ch24
