/-
文件: 16_advanced_tactics/positivity_tactic.lean
描述: positivity 战术：正性证明
编译: lake build Lean4Tutorial.Examples.AdvancedTactics.PositivityTactic
依赖: Mathlib.Tactic.Positivity
-/

import Mathlib.Tactic.Positivity
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.AdvancedTactics.PositivityTactic

/-! # positivity 战术 -/

-- positivity 战术用于证明表达式的正性或非负性
-- 它可以证明 0 < e, 0 ≤ e, e ≠ 0 等目标
-- 通过组合基本的正性规则来证明复杂表达式的正性

/-! ## 基本用法 -/

variable (a b c : ℝ)

-- 正数
example (ha : 0 < a) : 0 < a := by positivity
example (ha : 0 < a) (hb : 0 < b) : 0 < a + b := by positivity
example (ha : 0 < a) (hb : 0 < b) : 0 < a * b := by positivity

-- 非负数
example (ha : 0 ≤ a) : 0 ≤ a := by positivity
example (ha : 0 ≤ a) (hb : 0 ≤ b) : 0 ≤ a + b := by positivity
example (ha : 0 ≤ a) (hb : 0 ≤ b) : 0 ≤ a * b := by positivity

-- 平方非负
example : 0 ≤ a ^ 2 := by positivity
example : 0 ≤ a ^ 4 := by positivity

-- 绝对值非负
example : 0 ≤ |a| := by positivity

/-! ## 更多正性规则 -/

variable (x y : ℝ)

-- 乘积的正性
example (hx : 0 < x) (hy : 0 < y) : 0 < x * y := by positivity
example (hx : 0 < x) (hy : 0 ≤ y) : 0 ≤ x * y := by positivity

-- 和的正性
example (hx : 0 < x) (hy : 0 ≤ y) : 0 < x + y := by positivity
example (hx : 0 ≤ x) (hy : 0 ≤ y) : 0 ≤ x + y := by positivity

-- 商的正性
example (hx : 0 < x) (hy : 0 < y) : 0 < x / y := by positivity

-- 逆元的正性
example (hx : 0 < x) : 0 < x⁻¹ := by positivity

-- 幂的正性
example (hx : 0 < x) (n : ℕ) : 0 < x ^ n := by positivity
example (hx : 0 ≤ x) (n : ℕ) : 0 ≤ x ^ n := by positivity

-- max 和 min
example (hx : 0 ≤ x) (hy : 0 ≤ y) : 0 ≤ max x y := by positivity
example (hx : 0 ≤ x) (hy : 0 ≤ y) : 0 ≤ min x y := by positivity

/-! ## 自然数和整数 -/

variable (m n : ℕ)

-- 自然数都是非负的
example : 0 ≤ m := by positivity

-- 正自然数
example (hm : 0 < m) : 0 < m := by positivity

-- 自然数运算
example (hm : 0 < m) (hn : 0 < n) : 0 < m + n := by positivity
example (hm : 0 < m) (hn : 0 < n) : 0 < m * n := by positivity

variable (i j : ℤ)

-- 正整数
example (hi : 0 < i) : 0 < i := by positivity
example (hi : 0 < i) (hj : 0 < j) : 0 < i * j := by positivity

/-! ## 有理数 -/

variable (p q : ℚ)

example (hp : 0 < p) (hq : 0 < q) : 0 < p + q := by positivity
example (hp : 0 < p) (hq : 0 < q) : 0 < p * q := by positivity
example : 0 ≤ p ^ 2 := by positivity

/-! ## 不等于 0 -/

-- positivity 也可以证明 ≠ 0 的目标
example (hx : 0 < x) : x ≠ 0 := by positivity
example (hx : x < 0) : x ≠ 0 := by positivity
example : (x ^ 2 + 1 : ℝ) ≠ 0 := by positivity

/-! ## 复杂表达式 -/

example (x y : ℝ) (hx : 0 < x) (hy : 0 < y) :
    0 < x ^ 2 + y ^ 2 + x * y := by positivity

example (x y z : ℝ) (hx : 0 < x) (hy : 0 < y) (hz : 0 < z) :
    0 < x * y * z / (x + y + z) := by positivity

-- 平方和总是非负的
example (x y z : ℝ) : 0 ≤ x ^ 2 + y ^ 2 + z ^ 2 := by positivity

example (x y : ℝ) : 0 ≤ x ^ 2 + y ^ 2 + 1 := by positivity

/-! ## positivity 的工作原理 -/

-- positivity 通过递归地应用正性规则来工作：
--
-- 原子：
--   - 正数常量：0 < 1, 0 < 2, ...
--   - 假设中的正性条件
--   - 平方：0 ≤ x²
--   - 绝对值：0 ≤ |x|
--   - 自然数：0 ≤ n
--
-- 组合规则：
--   - 和：如果 0 ≤ a 且 0 ≤ b，则 0 ≤ a + b
--          如果 0 < a 且 0 ≤ b，则 0 < a + b
--   - 积：如果 0 ≤ a 且 0 ≤ b，则 0 ≤ a * b
--          如果 0 < a 且 0 < b，则 0 < a * b
--   - 商：如果 0 ≤ a 且 0 < b，则 0 ≤ a / b
--   - 幂：如果 0 ≤ a，则 0 ≤ a ^ n
--   - 逆元：如果 0 < a，则 0 < a⁻¹

/-! ## 与其他战术结合 -/

-- positivity 常用于证明除法和平方根等操作的前提条件

example (x : ℝ) (hx : 0 < x) :
    x * (1 / x) = 1 := by
  have h₁ : x ≠ 0 := by positivity
  field_simp [h₁]
  <;> ring

-- positivity 也经常和 field_simp 一起使用
example (x y : ℝ) (hx : 0 < x) (hy : 0 < y) :
    x / y + y / x ≥ 2 := by
  have hxy : 0 < x * y := by positivity
  have h : x / y + y / x - 2 = (x - y) ^ 2 / (x * y) := by
    field_simp [hx.ne', hy.ne'] <;> ring
  have h' : 0 ≤ (x - y) ^ 2 / (x * y) := by
    apply div_nonneg
    · exact sq_nonneg (x - y)
    · positivity
  linarith [h]

/-! ## positivity 的局限性 -/

-- 1. 只能证明正性和非负性，不能证明一般的不等式
-- 2. 对于复杂的不等式，需要用 linarith 或 nlinarith
-- 3. 不能处理超越函数（sin, exp, log 等）
-- 4. 依赖于上下文中有足够的正性假设

-- positivity 通常作为辅助战术使用
-- 为其他战术（如 field_simp, rpow 等）提供正性前提

end Lean4Tutorial.Examples.AdvancedTactics.PositivityTactic
