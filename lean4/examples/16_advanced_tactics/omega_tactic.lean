/-
文件: 16_advanced_tactics/omega_tactic.lean
描述: omega 战术：整数线性算术
编译: lake build Lean4Tutorial.Examples.AdvancedTactics.OmegaTactic
依赖: Mathlib.Tactic.Omega
-/

import Mathlib.Tactic.Omega

namespace Lean4Tutorial.Examples.AdvancedTactics.OmegaTactic

/-! # omega 战术 -/

-- omega 战术用于解决整数和自然数上的线性算术问题
-- 它基于 Presburger 算术的决策过程
-- 名字来源于 William Pugh 的 Omega 测试
--
-- omega 可以处理：
--   - 等式和不等式
--   - 自然数和整数
--   - 量词消去（存在量词）

/-! ## 整数上的基本用法 -/

variable (a b c d : ℤ)

-- 简单的不等式
example (h1 : a ≤ b) (h2 : b ≤ c) : a ≤ c := by omega
example (h1 : a < b) (h2 : b < c) : a < c := by omega

-- 传递性混合
example (h1 : a ≤ b) (h2 : b < c) : a < c := by omega
example (h1 : a < b) (h2 : b ≤ c) : a < c := by omega

-- 线性组合
example (h1 : a ≤ b) (h2 : c ≤ d) : a + c ≤ b + d := by omega
example (h1 : a ≤ b) (h2 : c ≤ d) : a - d ≤ b - c := by omega

-- 三变量
example (x y z : ℤ)
    (h1 : x + y + z = 6)
    (h2 : x - y + z = 2)
    (h3 : 2 * x + y - z = 5) :
    x = 2 ∧ y = 2 ∧ z = 2 := by
  constructor
  · omega
  constructor
  · omega
  · omega

/-! ## 自然数上的 omega -/

variable (m n k : ℕ)

-- 自然数不等式
example (h1 : m ≤ n) (h2 : n ≤ k) : m ≤ k := by omega
example (h1 : m < n) (h2 : n < k) : m < k := by omega

-- 自然数加法
example (h : m + n ≤ 5) : m ≤ 5 := by omega
example (h : m + n = 0) : m = 0 ∧ n = 0 := by omega

-- 自然数减法（截断减法）
example (h : m ≥ n) : m - n + n = m := by omega
example (h : m ≤ n) : m - n = 0 := by omega

-- 注意：omega 正确处理自然数的截断减法
-- 这是它比 linarith 更适合自然数的地方

/-! ## 存在量词 -/

-- omega 可以处理存在量词
example : ∃ (x y : ℤ), 2 * x + 3 * y = 7 := by
  omega
  -- 找到解：x = 2, y = 1

example : ∃ (x y : ℤ), x + y = 5 ∧ x - y = 1 := by
  omega
  -- 找到解：x = 3, y = 2

-- 自然数上的存在量词
example : ∃ (m n : ℕ), m + n = 5 := by omega
example : ∃ (m n : ℕ), 2 * m + 3 * n = 7 := by omega

/-! ## 矛盾证明 -/

-- omega 可以从矛盾的假设推出任何结论
example (a : ℤ) (h1 : a > 0) (h2 : a < 0) : False := by omega

example (m n : ℕ) (h1 : m + n < m) : False := by omega
  -- 因为 n ≥ 0，所以 m + n ≥ m，与 h1 矛盾

/-! ## 整除与模运算 -/

-- omega 可以处理一些简单的整除和模运算性质

example (a b : ℤ) : (a + b) % 2 = 0 ∨ (a + b) % 2 = 1 := by omega

example (a : ℤ) : a % 2 = 0 ∨ a % 2 = 1 := by omega

/-! ## omega 与 linarith 的比较 -/

-- 相同点：
--   都能处理线性算术
--   都能证明等式和不等式

-- 不同点：
--   1. omega 专注于整数和自然数
--      linarith 支持更多类型（ℚ, ℝ 等）
--
--   2. omega 正确处理自然数的截断减法
--      linarith 对自然数减法的处理可能有问题
--
--   3. omega 可以处理存在量词
--      linarith 不能
--
--   4. omega 基于 Presburger 算术决策过程
--      linarith 基于 Fourier-Motzkin / 单纯形法

/-! ## omega 的工作原理 -/

-- omega 实现了 Omega 测试（William Pugh, 1991）
-- 这是一个整数线性规划的决策过程
--
-- 基本思想：
--   1. 将问题转化为整数线性不等式组
--   2. 逐次消去变量（Fourier-Motzkin 消元法的整数版本）
--   3. 如果最终得到矛盾（如 0 < 0），则系统无解

/-! ## omega 的局限性 -/

-- 1. 只能处理线性（一次）约束
-- 2. 只支持整数和自然数
-- 3. 变量太多时可能很慢（复杂度是指数级的）
-- 4. 不能处理乘法（除非有一边是常数）

-- 对于实数上的线性问题，用 linarith
-- 对于非线性问题，用 nlinarith

/-! ## 使用技巧 -/

-- 1. 如果目标是关于自然数或整数的，优先试试 omega
-- 2. omega 可以处理很多"显然"的算术事实
-- 3. 对于复杂问题，可以先手动化简，再用 omega
-- 4. 如果 omega 太慢，试试拆分问题

end Lean4Tutorial.Examples.AdvancedTactics.OmegaTactic
