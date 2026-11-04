import Mathlib.Basic.Real.Basic
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Algebra.Order.Archimedean.Basic

/-!
# 第 00 章 导言：实分析与机器证明

对应原书第 1 章《引言》。本章只做三件事：

1. 看清“数学实数”与“机器浮点”的差别——实分析的舞台是精确的 `ℝ`；
2. 让机器核对第一个非平凡事实：`√2` 不是有理数；
3. 预览实分析的核心问题（无穷情形的推广，如 Archimedean 性质）。
-/

namespace Realanalysis.Ch00

/-- 数学实数是精确的：1/3 连加三次严格等于 1，没有舍入。 -/
example : (1 : ℝ) / 3 + 1 / 3 + 1 / 3 = 1 := by norm_num

/-- 同理，根式运算是精确等式，而不是近似值。 -/
example : Real.sqrt 2 * Real.sqrt 2 = 2 := by
  have h : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  rw [← sq]
  exact h

/- 浮点对照：Float 是有限精度的近似实数。取消下一行注释可看到
   `0.30000000000000004`——这正是实分析不能直接建立在 Float 上的原因。 -/
-- #eval (0.1 : Float) + 0.2

/-- 原书第 2 章例 2.3 的机器版：√2 无理性在 mathlib 中有完整证明，
    `Irrational x` 的定义就是 `x` 不能等于任何有理数的实数嵌入。 -/
example : Irrational (Real.sqrt 2) := irrational_sqrt_two

/-- 把 `Irrational` 展开成原书的语言：不存在整数 m、n（n ≠ 0）使
    m/n = √2。由无理数定义直接推出。 -/
example : ¬ ∃ (m n : ℤ), n ≠ 0 ∧ (m : ℝ) / n = Real.sqrt 2 := by
  rintro ⟨m, n, hn, h⟩
  have hq : (Real.sqrt 2) ∈ Set.range (fun (q : ℚ) => (q : ℝ)) := by
    use (m : ℚ) / n
    simp
    exact h
  exact irrational_sqrt_two hq

/-- Archimedean 性质预览（原书第 5 章正式讨论）：任意实数都有自然数
    超过它。这是“无穷”能被有限步论证驾驭的底层机制之一。 -/
example (x : ℝ) : ∃ n : ℕ, x < (n : ℝ) := exists_nat_gt x

end Realanalysis.Ch00
