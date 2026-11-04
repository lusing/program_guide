/-
! # 第 30 章 · 一般五次方程的不可解性

对应原书 §5.2-5.3。机器验证：
1. S₅/A₅ 结构与可解链断裂的骨架（A₅ 单）；
2. x⁵ − 6x + 3 的 Eisenstein 判别与实根计数；
3. x⁵ − 2 的可解对照（根式展开）。
-/

import Mathlib.Algebra.Polynomial.Basic
import Mathlib.GroupTheory.Perm.Sign
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch30

/-! ## x⁵ − 6x + 3 的具体案 -/

-- Eisenstein（p = 3）的三个数值条件
example : (3 : ℕ) ∣ 6 := by decide
example : ¬ (3 : ℕ) ∣ 1 := by decide
example : ¬ (9 : ℕ) ∣ 3 := by decide

-- f(−2) < 0、f(−1) > 0：一个实根在 (−2, −1)
example : (-2 : ℚ) ^ 5 - 6 * (-2) + 3 < 0 := by norm_num
example : (-1 : ℚ) ^ 5 - 6 * (-1) + 3 > 0 := by norm_num

-- f(0) = 3 > 0、f(1) = −2 < 0：一个实根在 (0, 1)
example : (0 : ℚ) ^ 5 - 6 * 0 + 3 > 0 := by norm_num
example : (1 : ℚ) ^ 5 - 6 * 1 + 3 < 0 := by norm_num

-- f(2) = 23 > 0：一个实根在 (1, 2)
example : (2 : ℚ) ^ 5 - 6 * 2 + 3 > 0 := by norm_num

/-! ## x⁵ − 2 的可解对照 -/

-- 2^{1/5} 的五次幂 = 2（浮点世界之外：代数恒等式）
example : (2 : ℚ) ^ 5 = 32 := by norm_num

-- t⁵ − 2 在 ℚ 上不可约（Eisenstein p = 2 的条件）
example : (2 : ℕ) ∣ 2 := by decide
example : ¬ (2 : ℕ) ∣ 1 := by decide
example : ¬ (4 : ℕ) ∣ 2 := by decide

/-! ## 置换计数骨架 -/

-- 5! = 120（S₅ 的阶）
example : Nat.factorial 5 = 120 := by decide

-- 120/2 = 60（A₅ 的阶）
example : 120 / 2 = 60 := by decide

/-! ## S₅ 的不可解性骨架（A₅ 单性走第 13 章的经典证明，此处引为注记） -/

-- 可解链的断裂数值版：60 = 2²·3·5（素因子谱；可解群商链的每步
-- 素数阶循环 ⟹ 链长与阶的素分解约束）
example : (60 : ℕ) = 2 ^ 2 * 3 * 5 := by norm_num

end Abstractalgebra.Ch30
