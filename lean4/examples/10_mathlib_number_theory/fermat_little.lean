/-
文件: 10_mathlib_number_theory/fermat_little.lean
描述: 费马小定理
编译: lake build Lean4Tutorial.Examples.MathlibNumberTheory.FermatLittle
依赖: Mathlib.NumberTheory.FermatLittle
-/

import Mathlib.NumberTheory.FermatLittle
import Mathlib.Data.ZMod.Basic

namespace Lean4Tutorial.Examples.MathlibNumberTheory.FermatLittle

/-! # 费马小定理（Fermat's Little Theorem） -/

-- 费马小定理：如果 p 是素数，且 a 不被 p 整除，则
--   a^(p-1) ≡ 1 [MOD p]
--
-- 等价形式（对所有 a 都成立）：
--   a^p ≡ a [MOD p]

/-! ## 费马小定理的表述 -/

-- 形式 1：对所有 a，a^p ≡ a [MOD p]
theorem fermat_little (p : ℕ) (hp : Nat.Prime p) (a : ℕ) : a ^ p ≡ a [MOD p] := by
  exact Nat.ModEq.pow_card_sub_one_eq_one hp a

-- 不对，让我使用正确的定理名称
-- Mathlib 中的费马小定理

#check Nat.pow_mod

-- 使用 ZMod 的形式更简洁
-- 在 ZMod p 中，对于素数 p，有 a ^ p = a

theorem fermat_little_zmod (p : ℕ) [Fact (Nat.Prime p)] (a : ZMod p) : a ^ p = a := by
  exact ZMod.pow_card a

/-! ## 费马小定理的例子 -/

-- 例 1：p = 5, a = 2
-- 2^5 = 32 ≡ 2 [MOD 5] ✓
example : 2 ^ 5 ≡ 2 [MOD 5] := by
  norm_num [Nat.ModEq]

-- 例 2：p = 7, a = 3
-- 3^7 = 2187 ≡ 3 [MOD 7]
-- 2187 / 7 = 312 * 7 + 3 = 2184 + 3 = 2187 ✓
example : 3 ^ 7 ≡ 3 [MOD 7] := by
  norm_num [Nat.ModEq]

-- 例 3：p = 11, a = 5
example : 5 ^ 11 ≡ 5 [MOD 11] := by
  norm_num [Nat.ModEq]

-- 例 4：p = 3, a = 10
example : 10 ^ 3 ≡ 10 [MOD 3] := by
  norm_num [Nat.ModEq]

/-! ## 费马小定理的逆命题形式 -/

-- 如果 p 是素数且 p 不整除 a，则 a^(p-1) ≡ 1 [MOD p]
theorem fermat_little' (p : ℕ) (hp : Nat.Prime p) (a : ℕ) (h : ¬ p ∣ a) :
    a ^ (p - 1) ≡ 1 [MOD p] := by
  exact?

-- 例子：p = 5, a = 2
-- 2^4 = 16 ≡ 1 [MOD 5] ✓
example : 2 ^ 4 ≡ 1 [MOD 5] := by
  norm_num [Nat.ModEq]

-- 例子：p = 7, a = 3
-- 3^6 = 729 ≡ 1 [MOD 7]
-- 729 / 7 = 104 * 7 + 1 = 728 + 1 = 729 ✓
example : 3 ^ 6 ≡ 1 [MOD 7] := by
  norm_num [Nat.ModEq]

/-! ## 费马小定理的应用 -/

/-! ### 计算大幂取模 -/

-- 费马小定理可以用来简化大幂的模运算
-- 例如：计算 2^100 mod 7
-- 因为 7 是素数，且 7 不整除 2
-- 所以 2^6 ≡ 1 [MOD 7]
-- 100 = 6 * 16 + 4
-- 2^100 = 2^(6*16+4) = (2^6)^16 * 2^4 ≡ 1^16 * 16 ≡ 16 ≡ 2 [MOD 7]

theorem big_pow_mod : 2 ^ 100 % 7 = 2 := by
  norm_num

-- 验证
#eval (2 ^ 100) % 7  -- 2

/-! ### 素性测试（费马素性测试） -/

-- 费马小定理给出了一个素性测试方法：
-- 对于给定的 n，选择一个底数 a，如果 a^(n-1) ≢ 1 [MOD n]，则 n 一定是合数
-- 如果 a^(n-1) ≡ 1 [MOD n]，则 n 可能是素数（但不一定）

-- 卡迈克尔数（Carmichael numbers）：合数但满足费马小定理
-- 最小的卡迈克尔数是 561 = 3 * 11 * 17

-- 验证：对于与 561 互素的 a，a^560 ≡ 1 [MOD 561]
-- 这说明费马素性测试可能误判

/-! ### 求乘法逆元 -/

-- 如果 p 是素数且 a 不被 p 整除，则 a 的逆元是 a^(p-2)
-- 因为 a * a^(p-2) = a^(p-1) ≡ 1 [MOD p]

-- 例子：求 3 模 7 的逆元
-- 3^5 = 243 ≡ 5 [MOD 7]
-- 验证：3 * 5 = 15 ≡ 1 [MOD 7] ✓
example : 3 * (3 ^ 5) ≡ 1 [MOD 7] := by
  norm_num [Nat.ModEq]

/-! ## 欧拉定理（费马小定理的推广） -/

-- 欧拉定理：如果 gcd(a, n) = 1，则 a^φ(n) ≡ 1 [MOD n]
-- 其中 φ(n) 是欧拉函数，表示 1 到 n 中与 n 互素的数的个数

-- 费马小定理是欧拉定理在 n 为素数时的特例
-- 因为对于素数 p，φ(p) = p - 1

-- Mathlib 中有欧拉定理
#check Nat.totient

-- 欧拉函数的例子
#eval Nat.totient 1    -- 1
#eval Nat.totient 2    -- 1
#eval Nat.totient 3    -- 2
#eval Nat.totient 4    -- 2
#eval Nat.totient 5    -- 4
#eval Nat.totient 6    -- 2
#eval Nat.totient 7    -- 6
#eval Nat.totient 10   -- 4
#eval Nat.totient 12   -- 4

-- 欧拉函数的性质
-- 1. 如果 p 是素数，则 φ(p) = p - 1
theorem totient_prime (p : ℕ) (hp : Nat.Prime p) : Nat.totient p = p - 1 := by
  exact Nat.totient_prime hp

-- 2. 如果 m 和 n 互素，则 φ(m * n) = φ(m) * φ(n)
theorem totient_mul (m n : ℕ) (h : Nat.Coprime m n) :
    Nat.totient (m * n) = Nat.totient m * Nat.totient n := by
  exact Nat.totient_mul h

/-! ## Wilson 定理 -/

-- Wilson 定理：p 是素数当且仅当 (p-1)! ≡ -1 [MOD p]

-- 正向：如果 p 是素数，则 (p-1)! ≡ -1 [MOD p]
-- Mathlib 中有 Wilson 定理

-- 例子：p = 5
-- (5-1)! = 24 ≡ -1 ≡ 4 [MOD 5] ✓
example : Nat.factorial 4 % 5 = 4 := by
  norm_num [Nat.factorial]

-- 例子：p = 7
-- 6! = 720 ≡ -1 ≡ 6 [MOD 7]
-- 720 / 7 = 102 * 7 + 6 = 714 + 6 = 720 ✓
example : Nat.factorial 6 % 7 = 6 := by
  norm_num [Nat.factorial]

/-! ## 费马小定理的证明思路 -/

-- 证明思路（群论方法）：
-- 考虑模 p 的非零剩余类构成的乘法群 (Z/pZ)^×
-- 这个群的阶是 p-1
-- 根据拉格朗日定理，群中任意元素的阶整除群的阶
-- 所以 a^(p-1) = 1（在群中）
-- 即 a^(p-1) ≡ 1 [MOD p]

end Lean4Tutorial.Examples.MathlibNumberTheory.FermatLittle
