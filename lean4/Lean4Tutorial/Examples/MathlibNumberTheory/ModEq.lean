/-
文件: 10_mathlib_number_theory/modeq.lean
描述: 模运算与同余（ModEq）
编译: lake build Lean4Tutorial.Examples.MathlibNumberTheory.ModEq
依赖: Mathlib.Data.Nat.ModEq
-/

import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Int.Basic

namespace Lean4Tutorial.Examples.MathlibNumberTheory.ModEq

/-! # 模运算与同余 -/

-- a ≡ b [MOD n] 表示 a 和 b 模 n 同余
-- 即 n ∣ (a - b)，或者等价地 a % n = b % n

/-! ## 同余的定义 -/

-- ModEq n a b 表示 a ≡ b [MOD n]
-- 在 Mathlib 中记作 a ≡ b [MOD n]

#check Nat.ModEq

-- 同余的例子
example : 7 ≡ 1 [MOD 3] := by
  norm_num [Nat.ModEq, Nat.ModEq]

example : 10 ≡ 4 [MOD 6] := by
  norm_num [Nat.ModEq]

example : 15 ≡ 0 [MOD 5] := by
  norm_num [Nat.ModEq]

-- 同余等价于模相等
theorem modEq_iff_modEq (a b n : ℕ) : a ≡ b [MOD n] ↔ a % n = b % n := by
  exact Nat.modEq_iff_modEq

/-! ## 同余的基本性质 -/

-- 自反性
theorem modEq_refl (a n : ℕ) : a ≡ a [MOD n] := by
  exact Nat.ModEq.refl a

-- 对称性
theorem modEq_symm (a b n : ℕ) (h : a ≡ b [MOD n]) : b ≡ a [MOD n] := by
  exact Nat.ModEq.symm h

-- 传递性
theorem modEq_trans (a b c n : ℕ) (h1 : a ≡ b [MOD n]) (h2 : b ≡ c [MOD n]) :
    a ≡ c [MOD n] := by
  exact Nat.ModEq.trans h1 h2

/-! ## 同余的运算性质 -/

-- 加法：如果 a ≡ b [MOD n] 且 c ≡ d [MOD n]，则 a + c ≡ b + d [MOD n]
theorem modEq_add (a b c d n : ℕ) (h1 : a ≡ b [MOD n]) (h2 : c ≡ d [MOD n]) :
    a + c ≡ b + d [MOD n] := by
  exact Nat.ModEq.add h1 h2

-- 乘法：如果 a ≡ b [MOD n] 且 c ≡ d [MOD n]，则 a * c ≡ b * d [MOD n]
theorem modEq_mul (a b c d n : ℕ) (h1 : a ≡ b [MOD n]) (h2 : c ≡ d [MOD n]) :
    a * c ≡ b * d [MOD n] := by
  exact Nat.ModEq.mul h1 h2

-- 幂运算：如果 a ≡ b [MOD n]，则 a ^ k ≡ b ^ k [MOD n]
theorem modEq_pow (a b n k : ℕ) (h : a ≡ b [MOD n]) : a ^ k ≡ b ^ k [MOD n] := by
  exact Nat.ModEq.pow k h

-- 数乘：如果 a ≡ b [MOD n]，则 k * a ≡ k * b [MOD n]
theorem modEq_mul_left (a b k n : ℕ) (h : a ≡ b [MOD n]) : k * a ≡ k * b [MOD n] := by
  exact Nat.ModEq.mul_left k h

/-! ## 模运算的计算 -/

-- 使用 norm_num 可以计算具体的同余式
example : 23 ≡ 3 [MOD 5] := by norm_num [Nat.ModEq]
example : 100 ≡ 1 [MOD 9] := by norm_num [Nat.ModEq]
example : 2 ^ 10 ≡ 2 [MOD 10] := by norm_num [Nat.ModEq]

-- 快速幂取模
-- 计算 2^100 mod 7
#eval (2 ^ 100) % 7  -- 2

/-! ## 整数上的模运算 -/

-- 整数上也有同余关系
-- a ≡ b [ZMOD n] 表示整数 a 和 b 模 n 同余

section IntModEq
  variable (a b c d n : ℤ)

  -- 整数同余
  example : (7 : ℤ) ≡ 1 [ZMOD 3] := by
    simp [Int.ModEq, Int.emod_eq_emod_iff_emod_sub_eq_zero]
    <;> norm_num

  -- 整数同余的性质
  theorem int_modEq_add (h1 : a ≡ b [ZMOD n]) (h2 : c ≡ d [ZMOD n]) :
      a + c ≡ b + d [ZMOD n] := by
    exact Int.ModEq.add h1 h2

  theorem int_modEq_mul (h1 : a ≡ b [ZMOD n]) (h2 : c ≡ d [ZMOD n]) :
      a * c ≡ b * d [ZMOD n] := by
    exact Int.ModEq.mul h1 h2

  theorem int_modEq_neg (h : a ≡ b [ZMOD n]) : -a ≡ -b [ZMOD n] := by
    exact Int.ModEq.neg h

  theorem int_modEq_sub (h1 : a ≡ b [ZMOD n]) (h2 : c ≡ d [ZMOD n]) :
      a - c ≡ b - d [ZMOD n] := by
    exact Int.ModEq.sub h1 h2

end IntModEq

/-! ## 模 n 剩余类 -/

-- 模 n 的剩余类将整数分成 n 个等价类
-- 每个等价类中的数模 n 同余
-- 例如模 3 的剩余类：{..., -3, 0, 3, 6, ...}, {..., -2, 1, 4, 7, ...}, {..., -1, 2, 5, 8, ...}

-- Mathlib 中有 ZMod n，表示模 n 的整数环
-- ZMod n 有恰好 n 个元素

/-! ## 中国剩余定理 -/

-- 中国剩余定理：如果 m 和 n 互素，则对于任意 a, b，
-- 存在 x 使得 x ≡ a [MOD m] 且 x ≡ b [MOD n]
-- 并且解在模 m*n 下唯一

theorem chinese_remainder (m n a b : ℕ) (h : Nat.Coprime m n) :
    ∃ x : ℕ, x ≡ a [MOD m] ∧ x ≡ b [MOD n] := by
  exact?

/-! ## 乘法逆元 -/

-- 如果 a 和 n 互素，则存在 b 使得 a * b ≡ 1 [MOD n]
-- 这样的 b 称为 a 模 n 的乘法逆元

theorem mod_mul_inv (a n : ℕ) (h : Nat.Coprime a n) :
    ∃ b : ℕ, a * b ≡ 1 [MOD n] := by
  exact?

-- 例子：3 的模 7 逆元是 5，因为 3 * 5 = 15 ≡ 1 [MOD 7]
example : 3 * 5 ≡ 1 [MOD 7] := by
  norm_num [Nat.ModEq]

/-! ## 线性同余方程 -/

-- 方程 a * x ≡ b [MOD n] 有解当且仅当 gcd(a, n) ∣ b

/-! ## 模素数的特殊性质 -/

-- 如果 p 是素数且 p 不整除 a，则 a 有模 p 的乘法逆元
theorem prime_mod_inv (p a : ℕ) (hp : Nat.Prime p) (h : ¬ p ∣ a) :
    ∃ b : ℕ, a * b ≡ 1 [MOD p] := by
  have hcop : Nat.Coprime a p := by
    exact?
  exact?

-- 这是费马小定理的基础，将在下一节讨论

end Lean4Tutorial.Examples.MathlibNumberTheory.ModEq
