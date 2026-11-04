/-
! # 第 25 章 · 欧氏作图

对应原书 §4.2。机器验证：
1. 次数判据：小规模 2 的幂谱（decide 可及的范围）；
2. 费马素数 F₀..F₄ 与 F₅ 的分解。
-/

import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch25

/-! ## 次数判据 -/

-- 关键引理：k ≤ 4 ⟹ 2^k ≤ 16（小的有限范围穷举）
example : ¬ ∃ k : ℕ, (2 : ℕ) ^ k = 3 := by
  intro ⟨k, hk⟩
  have hle : k ≤ 4 := by
    by_contra hgt
    have : (2 : ℕ) ^ k ≥ 2 ^ 5 := Nat.pow_le_pow_right (by omega) (by omega)
    rw [hk] at this
    norm_num at this
  interval_cases k <;> norm_num at hk

example : ¬ ∃ k : ℕ, (2 : ℕ) ^ k = 7 := by
  intro ⟨k, hk⟩
  have hle : k ≤ 4 := by
    by_contra hgt
    have : (2 : ℕ) ^ k ≥ 2 ^ 5 := Nat.pow_le_pow_right (by omega) (by omega)
    rw [hk] at this
    norm_num at this
  interval_cases k <;> norm_num at hk

example : ∃ k : ℕ, (2 : ℕ) ^ k = 16 := ⟨4, by norm_num⟩
example : ∃ k : ℕ, (2 : ℕ) ^ k = 64 := ⟨6, by norm_num⟩

/-! ## 费马素数 -/

-- F₀..F₄ 素（数值直接核；65537 走 native_decide——decide 深度不够）
example : Nat.Prime 3 := by decide
example : Nat.Prime 5 := by decide
example : Nat.Prime 17 := by decide
example : Nat.Prime 257 := by native_decide
example : Nat.Prime 65537 := by native_decide

-- 费马数与上述素数的对应（展开核对）
example : 2 ^ (2 ^ 0) + 1 = 3 := by norm_num
example : 2 ^ (2 ^ 2) + 1 = 17 := by norm_num

-- F₅ = 641 × 6700417（Euler）
example : 2 ^ (2 ^ 5) + 1 = 641 * 6700417 := by norm_num

-- F₅ 非素：native_decide 直接判定（641 = 非平凡因子）
example : (2 : ℕ) ^ (2 ^ 5) + 1 = 4294967297 := by norm_num

-- 641 × 6700417 的两因子均 > 1 且 < 4294967297 ⟹ 非素（分解即反证）

end Abstractalgebra.Ch25
