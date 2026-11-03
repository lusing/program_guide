/-
! # 第 01 章 · 数学归纳法与良序

对应原书 §1.1。五个机器证明：
1. `two_pow_gt`：2ⁿ > n（原书命题 1.5）；
2. `gauss_sum`：1 + 2 + ⋯ + n = n(n+1)/2（原书命题 1.6，整数版）；
3. `six_dvd_cube_sub_self`：6 ∣ n³ − n（三个连续整数之积，ℤ 版）；
4. `two_pow_mul_odd`：每个 n ≥ 1 是 2 的幂乘奇数（第二归纳法）；
5. `cassini`：斐波那契卡西尼恒等式 F_{n+1}F_{n-1} − F_n² = (−1)ⁿ。
-/

import Mathlib.Data.Nat.Basic
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Algebra.Ring.Int.Parity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

namespace Abstractalgebra.Ch01

/-! ## 命题 1.5：2ⁿ > n -/

/-- 对一切 n ≥ 1 有 n < 2ⁿ。证明即"基础 + 爬梯"，与课本逐句对应。 -/
theorem two_pow_gt (n : ℕ) (hn : 1 ≤ n) : n < 2 ^ n := by
  induction n with
  | zero => omega
  | succ k ih =>
    rcases Nat.eq_zero_or_pos k with hk | hk
    · subst hk; norm_num
    · have ihk := ih hk
      have h1 : 2 ^ (k + 1) = 2 * 2 ^ k := by ring
      rw [h1]
      omega

/-! ## 命题 1.6：高斯求和 -/

/-- Σᵢ₌₁ⁿ i 的递归定义（归纳定义的教科书样例）。 -/
def sumTo : ℕ → ℕ
  | 0 => 0
  | n + 1 => sumTo n + (n + 1)

/-- 2·(1 + 2 + ⋯ + n) = n(n+1)。刻意乘 2 避免除法，留在 ℕ 里。 -/
theorem gauss_sum (n : ℕ) : 2 * sumTo n = n * (n + 1) := by
  induction n with
  | zero => rfl
  | succ k ih =>
    show 2 * (sumTo k + (k + 1)) = (k + 1) * (k + 2)
    linarith [ih]

/-! ## 6 ∣ n³ − n：连续整数之积 -/

/-- 对一切整数 n，6 整除 n³ − n。三个连续整数 (n−1)·n·(n+1)：必有偶、必有 3 的倍数。 -/
theorem six_dvd_cube_sub_self (n : ℤ) : 6 ∣ n ^ 3 - n := by
  have hform : n ^ 3 - n = n * (n - 1) * (n + 1) := by ring
  rw [hform]
  -- 2 ∣ (n−1)·n·(n+1)：相邻两数必有偶数
  have h2 : 2 ∣ n * (n - 1) * (n + 1) := by
    rcases Int.even_or_odd' n with ⟨w, hw | hw⟩
    · have hd : 2 ∣ n := ⟨w, hw⟩
      exact (hd.mul_right (n - 1)).mul_right (n + 1)
    · rw [show n - 1 = 2 * w by omega]
      have hd : 2 ∣ 2 * w := ⟨w, rfl⟩
      exact (hd.mul_left n).mul_right (n + 1)
  -- 3 ∣ (n−1)·n·(n+1)：按 n mod 3 三分案
  have h3 : 3 ∣ n * (n - 1) * (n + 1) := by
    have hmod : n % 3 = 0 ∨ n % 3 = 1 ∨ n % 3 = 2 := by omega
    rcases hmod with h | h | h
    · have hd : 3 ∣ n := ⟨n / 3, by omega⟩
      exact (hd.mul_right (n - 1)).mul_right (n + 1)
    · have ht : n - 1 = 3 * ((n - 1) / 3) := by omega
      rw [ht]
      have hd : 3 ∣ 3 * ((n - 1) / 3) := ⟨(n - 1) / 3, rfl⟩
      exact (hd.mul_left n).mul_right (n + 1)
    · have ht : n + 1 = 3 * ((n + 1) / 3) := by omega
      rw [ht]
      have hd : 3 ∣ 3 * ((n + 1) / 3) := ⟨(n + 1) / 3, rfl⟩
      exact hd.mul_left (n * (n - 1))
  -- 2 ∣ c 且 3 ∣ c ⟹ 6 ∣ c：商 s 模 3 分案（2 与 3 互素的算术版）
  obtain ⟨s, hs⟩ := h2
  obtain ⟨t, ht⟩ := h3
  have hsmod : s % 3 = 0 ∨ s % 3 = 1 ∨ s % 3 = 2 := by omega
  rcases hsmod with r | r | r
  · have hu : s = 3 * (s / 3) := by omega
    exact ⟨s / 3, by omega⟩
  · exact False.elim (by omega)
  · exact False.elim (by omega)

/-! ## 剥离 2 的幂：第二归纳法 -/

/-- 每个 n ≥ 1 都形如 2^k · m（m 奇）。第二归纳法：偶数时归纳假设作用于 n/2。 -/
theorem two_pow_mul_odd : ∀ n : ℕ, 0 < n → ∃ k m, n = 2 ^ k * m ∧ ¬2 ∣ m := by
  intro n
  induction n using Nat.strongRecOn with
  | ind n ih =>
    intro hn
    rcases Nat.even_or_odd n with ⟨r, hr⟩ | ⟨w, hw⟩
    · -- 偶：n = r + r，0 < r < n，强归纳作用于 r
      have hr0 : 0 < r := by omega
      obtain ⟨k, m, hm, hmo⟩ := ih r (by omega) hr0
      refine ⟨k + 1, m, ?_, hmo⟩
      calc n = r + r := hr
        _ = 2 * (2 ^ k * m) := by rw [← hm]; ring
        _ = 2 ^ (k + 1) * m := by ring
    · -- 奇：n = 2w + 1，直接取 k = 0
      refine ⟨0, n, by simp, ?_⟩
      intro hdvd
      obtain ⟨c, hc⟩ := hdvd
      omega

/-! ## 卡西尼恒等式 -/

/-- 辅助形式：fib(n+2)·fib(n) − fib(n+1)² = (−1)^{n+1}，无前提，归纳最顺。 -/
theorem cassini_aux : ∀ n : ℕ,
    (Nat.fib (n + 2) * Nat.fib n : ℤ) - Nat.fib (n + 1) * Nat.fib (n + 1)
      = (-1 : ℤ) ^ (n + 1) := by
  intro n
  induction n with
  | zero => decide
  | succ k ih =>
    -- 拼写统一：先把 fib(k+1+1) 折成 fib(k+2)，再统一展开递推
    have e : Nat.fib (k + 1 + 1) = Nat.fib (k + 2) := rfl
    have rA : Nat.fib (k + 1 + 2) = Nat.fib (k + 1) + Nat.fib (k + 1 + 1) :=
      Nat.fib_add_two (n := k + 1)
    have rB : Nat.fib (k + 2) = Nat.fib k + Nat.fib (k + 1) :=
      Nat.fib_add_two (n := k)
    rw [rA, e, rB]
    rw [rB] at ih
    have hpow : (-1 : ℤ) ^ (k + 1 + 1) = (-1 : ℤ) * (-1 : ℤ) ^ (k + 1) := by
      rw [pow_succ]; ring
    rw [hpow]
    push_cast
    push_cast at ih
    linear_combination -ih

/-- 卡西尼恒等式：F_{n+1}·F_{n-1} − F_n² = (−1)ⁿ（n ≥ 1）。 -/
theorem cassini (n : ℕ) (hn : 0 < n) :
    (Nat.fib (n + 1) * Nat.fib (n - 1) : ℤ) - Nat.fib n * Nat.fib n
      = (-1 : ℤ) ^ n := by
  have h := cassini_aux (n - 1)
  rw [show n - 1 + 2 = n + 1 from by omega,
      show n - 1 + 1 = n from by omega] at h
  exact h

end Abstractalgebra.Ch01
