/-
文件: 16_advanced_tactics/ring_tactic.lean
描述: ring 战术：环等式证明
编译: lake build Lean4Tutorial.Examples.AdvancedTactics.RingTactic
依赖: Mathlib.Tactic.Ring
-/

import Mathlib.Tactic.Ring
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.AdvancedTactics.RingTactic

/-! # ring 战术 -/

-- ring 战术用于证明环中的等式
-- 它通过将两边展开为标准形式来验证等式
-- 支持加法、乘法、幂运算等

/-! ## 基本用法 -/

variable (a b c d : ℤ)

-- 简单的环等式
example : (a + b) ^ 2 = a ^ 2 + 2 * a * b + b ^ 2 := by ring
example : (a - b) ^ 2 = a ^ 2 - 2 * a * b + b ^ 2 := by ring
example : (a + b) * (a - b) = a ^ 2 - b ^ 2 := by ring

-- 立方公式
example : (a + b) ^ 3 = a ^ 3 + 3 * a ^ 2 * b + 3 * a * b ^ 2 + b ^ 3 := by ring
example : (a - b) ^ 3 = a ^ 3 - 3 * a ^ 2 * b + 3 * a * b ^ 2 - b ^ 3 := by ring

-- 立方和、立方差
example : a ^ 3 + b ^ 3 = (a + b) * (a ^ 2 - a * b + b ^ 2) := by ring
example : a ^ 3 - b ^ 3 = (a - b) * (a ^ 2 + a * b + b ^ 2) := by ring

/-! ## 多个变量的复杂等式 -/

example : (a + b + c) ^ 2 = a ^ 2 + b ^ 2 + c ^ 2 + 2 * a * b + 2 * a * c + 2 * b * c := by ring

example : (a + b) * (c + d) = a * c + a * d + b * c + b * d := by ring

example : (a - b) * (c + d) = a * c + a * d - b * c - b * d := by ring

-- 四次方展开
example : (a + b) ^ 4 = a ^ 4 + 4 * a ^ 3 * b + 6 * a ^ 2 * b ^ 2 + 4 * a * b ^ 3 + b ^ 4 := by ring

/-! ## 在有理数和实数上使用 -/

variable (x y z : ℚ)

example : (x + y) * (x - y) = x ^ 2 - y ^ 2 := by ring

example : (x + y + z) * (x - y - z) = x ^ 2 - y ^ 2 - z ^ 2 - 2 * y * z := by ring

variable (r s t : ℝ)

example : (r + s) ^ 2 + (r - s) ^ 2 = 2 * r ^ 2 + 2 * s ^ 2 := by ring

example : (r + s + t) ^ 3 =
    r ^ 3 + s ^ 3 + t ^ 3 + 3 * r ^ 2 * s + 3 * r ^ 2 * t + 3 * s ^ 2 * r + 3 * s ^ 2 * t + 3 * t ^ 2 * r + 3 * t ^ 2 * s + 6 * r * s * t := by ring

/-! ## ring_nf 战术 -/

-- ring_nf 将表达式化为环标准形式
-- 它不会关闭目标，而是重写目标

example (a b : ℤ) : (a + b) ^ 2 - (a - b) ^ 2 = 4 * a * b := by
  ring_nf
  -- 目标变为 4 * a * b = 4 * a * b
  <;> rfl

-- ring_nf 也可以在假设中使用
example (a b c : ℤ) (h : (a + b) ^ 2 = c) : a ^ 2 + 2 * a * b + b ^ 2 = c := by
  ring_nf at h
  exact h

/-! ## 自然数上的 ring -/

variable (m n k : ℕ)

-- ring 也适用于自然数（半环）
example : (m + n) ^ 2 = m ^ 2 + 2 * m * n + n ^ 2 := by
  ring

example : m * (n + k) = m * n + m * k := by
  ring

example : (m + n) * (m + n) = m ^ 2 + 2 * m * n + n ^ 2 := by
  ring

-- 注意：自然数上没有减法（在 ring 的意义上）
-- 所以涉及减法的等式需要在整数上证明

/-! ## ring 与其他战术结合 -/

-- ring 常用于证明的最后一步
-- 或者与 rw, simp 等战术结合使用

example (a b : ℤ) (h : a = b + 1) : a ^ 2 = b ^ 2 + 2 * b + 1 := by
  rw [h]
  ring

example (x y : ℝ) (h1 : x + y = 5) (h2 : x - y = 1) : x ^ 2 - y ^ 2 = 5 := by
  have h3 : x ^ 2 - y ^ 2 = (x + y) * (x - y) := by ring
  rw [h3, h1, h2]
  <;> norm_num

/-! ## 非交换环 -/

-- ring 战术默认假设乘法是交换的
-- 对于非交换环，可以使用 noncomm_ring

-- noncomm_ring 处理非交换环中的等式
-- 它不使用乘法交换律

end Lean4Tutorial.Examples.AdvancedTactics.RingTactic
