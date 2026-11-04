/-
! # 第 05 章 · 同余

对应原书 §1.5。机器验证：
1. 新生代梦 (a+b)³ ≡ a³+b³ (mod 3)：ZMod 3 上穷举证明；
2. 费马小定理：p = 5 的穷举版 + 一般版（ZMod 单位群）；
3. 线性同余：51x ≡ 10 (mod 94) 的解 x ≡ 26；
4. 孙子问题（CRT 三模联立）与两模构造解（Nat.chineseRemainder'）。
-/

import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.ModEq
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.Tactic.IntervalCases

namespace Abstractalgebra.Ch05

/-! ## 新生代梦（命题 1.60）与费马小定理（定理 1.61）：穷举证明 -/

-- ZMod 3 是有限环：9 对元素逐一代入，decide 完成"穷举即证明"
example : ∀ a b : ZMod 3, (a + b) ^ 3 = a ^ 3 + b ^ 3 := by
  decide

-- 费马 p = 5：5 个元素穷举（含 a = 0 的 a⁵ ≡ a 情形）
example : ∀ a : ZMod 5, a ^ 5 = a := by
  decide

/-! ## 费马小定理：一般版 -/

-- 模素数 p 的非零元素满足 a^(p−1) = 1（费马小定理的 ZMod 形式）
theorem fermat_general (p : ℕ) [Fact (Nat.Prime p)] (a : ZMod p) (ha : a ≠ 0) :
    a ^ (p - 1) = 1 :=
  ZMod.pow_card_sub_one_eq_one ha

/-! ## 线性同余（定理 1.65）：例 1.67 -/

-- 51x ≡ 10 (mod 94)：x = 26 确为解（正文手算：51⁻¹ ≡ 59，59·10 ≡ 26）
example : 51 * 26 % 94 = 10 := by decide

-- 唯一性（模 94 意义下）：94 个剩余类中只有 26 是解
example : ∀ r < 94, 51 * r % 94 = 10 ↔ r = 26 := by
  intro r hr
  interval_cases r <;> decide

/-! ## 中国剩余定理（定理 1.69） -/

-- 孙子问题：x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7) ⟹ x ≡ 23 (mod 105)
theorem sun_tzu (x : ℕ)
    (h1 : x % 3 = 2) (h2 : x % 5 = 3) (h3 : x % 7 = 2) : x % 105 = 23 := by
  omega

-- 两模构造：x ≡ 2 (mod 3), x ≡ 3 (mod 5) 的 CRT 构造解为 8 (mod 15)
example : (Nat.chineseRemainder'
    (show 2 ≡ 3 [MOD Nat.gcd 3 5] by decide)).val % 15 = 8 := by
  native_decide

end Abstractalgebra.Ch05
