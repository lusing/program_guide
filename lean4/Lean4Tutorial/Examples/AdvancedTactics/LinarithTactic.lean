/-
文件: 16_advanced_tactics/linarith_tactic.lean
描述: linarith 战术：线性算术
编译: lake build Lean4Tutorial.Examples.AdvancedTactics.LinarithTactic
依赖: Mathlib.Tactic.Linarith
-/

import Mathlib.Tactic.Linarith
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.AdvancedTactics.LinarithTactic

/-! # linarith 战术 -/

-- linarith 战术用于证明线性不等式
-- 它可以处理线性算术目标，包括等式和不等式
-- 支持自然数、整数、有理数、实数等

/-! ## 基本用法 -/

variable (a b c d : ℝ)

-- 简单的线性不等式
example (h : a ≤ b) (h2 : b ≤ c) : a ≤ c := by linarith
example (h : a < b) (h2 : b < c) : a < c := by linarith

-- 线性组合
example (h1 : a ≤ b) (h2 : c ≤ d) : a + c ≤ b + d := by linarith
example (h1 : a ≤ b) (h2 : c ≤ d) : a - d ≤ b - c := by linarith

-- 乘以正数
example (h : a ≤ b) (hc : 0 ≤ c) : c * a ≤ c * b := by linarith

-- 乘以负数
example (h : a ≤ b) (hc : c ≤ 0) : c * b ≤ c * a := by linarith

/-! ## 更复杂的例子 -/

example (x y : ℝ) (h1 : 2 * x + y ≤ 5) (h2 : x + 3 * y ≤ 6) : x + 2 * y ≤ 11 / 3 := by
  linarith

example (x y z : ℝ) (h1 : x + y ≥ 1) (h2 : y + z ≥ 1) (h3 : z + x ≥ 1) : x + y + z ≥ 3 / 2 := by
  linarith

-- 三变量系统
example (x y z : ℝ)
    (h1 : x + y + z = 6)
    (h2 : x - y + z = 2)
    (h3 : 2 * x + y - z = 5) :
    x = 2 ∧ y = 2 ∧ z = 2 := by
  constructor
  · linarith
  constructor
  · linarith
  · linarith

/-! ## 整数上的 linarith -/

variable (m n k : ℤ)

example (h1 : m ≤ n) (h2 : n ≤ k) : m ≤ k := by linarith

example (h : 2 * m + 3 * n = 7) : m ≤ 3 := by linarith

-- linarith 可以处理整数线性方程

/-! ## 自然数上的 linarith -/

variable (p q r : ℕ)

example (h1 : p ≤ q) (h2 : q ≤ r) : p ≤ r := by linarith

example (h : p + q ≤ 5) : p ≤ 5 := by linarith

-- 注意：自然数减法是截断减法（a - b = 0 如果 a ≤ b）
-- linarith 在处理自然数时要小心

/-! ## linarith 与假设 -/

-- linarith 会自动使用上下文中的所有线性假设

example (x y : ℝ)
    (h1 : 3 * x + 2 * y ≥ 6)
    (h2 : x - y ≤ 2)
    (h3 : x ≥ 0)
    (h4 : y ≥ 0) :
    x + y ≥ 2 := by
  linarith

-- 也可以指定使用哪些假设
example (x y : ℝ) (h1 : x + y = 5) (h2 : x - y = 1) (h3 : x = 100) : x = 3 := by
  linarith [h1, h2]  -- 只使用 h1 和 h2
  -- 注意：h3 与结论矛盾，但 linarith 只用了 h1 和 h2

/-! ## nlinarith -/

-- nlinarith 是 linarith 的非线性版本
-- 它可以处理一些非线性不等式
-- （详见 nlinarith_tactic.lean）

/-! ## linarith 的工作原理 -/

-- linarith 使用 Fourier-Motzkin 消元法或单纯形法
-- 来求解线性规划问题
-- 如果它能推出矛盾（0 < 0），则目标得证

-- 具体来说：
-- 1. 将所有不等式转化为标准形式
-- 2. 尝试通过线性组合导出 0 < 0
-- 3. 如果成功，则目标成立

/-! ## linarith 的局限性 -/

-- 1. 只能处理线性（一次）不等式
-- 2. 不能直接处理乘法（除非有符号信息）
-- 3. 不能处理超越函数

-- 对于非线性问题，需要使用 nlinarith 或其他方法

end Lean4Tutorial.Examples.AdvancedTactics.LinarithTactic
