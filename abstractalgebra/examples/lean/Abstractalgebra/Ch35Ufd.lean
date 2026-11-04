/-
! # 第 35 章 · 唯一分解整环

对应原书 §7.2。机器验证：
1. ℤ 分解的唯一性数值面；
2. 高斯引理（内容乘积）的具体恒等式；
3. ℤ[√−5] 非唯一分解的范数论证。
-/

import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

namespace Abstractalgebra.Ch35

/-! ## ℤ：UFD 原型 -/

-- 360 = 2³·3²·5；两套分解重组相等
example : (360 : ℕ) = 2 ^ 3 * 3 ^ 2 * 5 := by norm_num
example : (360 : ℕ) = 2 * 2 * 90 ∧ 90 = 2 * 45 ∧ 45 = 3 * 15 ∧ 15 = 3 * 5 := by
  norm_num

-- gcd 是 min 指数（数值面）：gcd(72, 108) = 2²·3 = 12
example : (72 : ℕ) = 2 ^ 3 * 3 ^ 2 := by norm_num
example : (108 : ℕ) = 2 ^ 2 * 3 ^ 3 := by norm_num
example : Nat.gcd 72 108 = 2 ^ 2 * 3 ^ 2 := by decide

/-! ## 高斯引理（引理 7.19）：本原多项式之积本原 -/

-- (2x + 2)(3x + 3) = 6(x+1)²：内容 2·3 = 6
example : ∀ x : ℚ, (2 * x + 2) * (3 * x + 3) = 6 * (x + 1) * (x + 1) := by
  intro x; ring

-- (4x + 6)(10x + 15) 的内容：gcd(4,6)·gcd(10,15) = 2·5 = 10；
-- 展开 40x² + 150x + 90，gcd = 10 ✓
example : Nat.gcd 40 150 = 10 := by decide
example : Nat.gcd 10 90 = 10 := by decide

/-! ## ℤ[√−5]：非 UFD（范数论证） -/

-- 范数 N(a + b√−5) = a² + 5b²；(1+√−5)(1−√−5) = 6 = 2·3
-- 数值面：N(2) = 4、N(3) = 9、N(1±√−5) = 6，且 4、9、6 都不能写成
-- 两个 >1 的"ℤ[√−5] 范数"之积（范数 2、3 无解）
example : (1:ℚ)^2 + 5*(1:ℚ)^2 = 6 := by norm_num
example : (2:ℚ)^2 + 5*(0:ℚ)^2 = 4 := by norm_num

-- a² + 5b² = 2 无有理解（b = 0 ⟹ a² = 2 非平方；|b| ≥ 1 ⟹ ≥ 5）
-- 有理数的平方非 2：√2 无理性的数值面（整数情形枚举）
example : ∀ a < 2, ∀ b < 2, (a * a + 5 * b * b ≠ 2) := by decide
example : ∀ a < 4, ∀ b < 2, (a * a + 5 * b * b ≠ 3) := by decide

end Abstractalgebra.Ch35
