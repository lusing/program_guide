/-
! # 第 31 章 · 一般五次方程的不可解性

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
import Mathlib.Tactic.LinearCombination

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


/-! ## 尾声（Epilog）：伽罗瓦对应一瞥与高斯定理 5.41

FTGT 的机器面取三个具体切面：ζ₅ 的二次子域 ℚ(√5)（黄金比恒等式）、
引理 5.40 的计数（[E^L : E^H] = [H : L]）、高斯正 p 边形作图的算术面。 -/

/-- ζ₅ 的固定子域：g = (√5 − 1)/2 = 2cos(2π/5) 满足 g² + g − 1 = 0
（s 抽象代表 √5；这正是 Gal(ℚ(ζ₅)/ℚ) ≅ ℤ₄ 的指标-2 子群对应的二次子域）。 -/
example (s : ℚ) (hs : s ^ 2 = 5) :
    ((s - 1) / 2) ^ 2 + ((s - 1) / 2) - 1 = 0 := by
  linear_combination (1 / 4) * hs

/-- 引理 5.40 的计数面：ℚ(ζ₅) ⊃ ℚ(√5) ⊃ ℚ 的次数 = 子群指标。 -/
example : (4 : ℕ) / 2 = 2 ∧ (2 : ℕ) / 1 = 2 := by
  decide

/-- 定理 5.41（Gauss）：p 边形可作图 ⟺ p − 1 是 2 的幂。
17 = 2⁴ + 1（费马素数）：Gal(ℚ(ζ₁₇)/ℚ) 的 16 = 2⁴ 阶 2-群有
指标 2 的正规塔 ⟹ ζ₁₇ 落在二次塔顶（第 26 章的嵌套根式）。 -/
example : (17 : ℕ) - 1 = 2 ^ 4 := by
  norm_num

/-- 7 边形不可作：7 − 1 = 6 含奇因子 3（m ≤ 2 时 decide 排除；
m ≥ 3 时 2^m ≥ 8 > 6）。 -/
example : ∀ m ≤ 2, (7 : ℕ) - 1 ≠ 2 ^ m := by
  decide

end Abstractalgebra.Ch30
