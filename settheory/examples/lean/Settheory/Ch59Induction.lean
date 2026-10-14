import Mathlib.Algebra.BigOperators.Group.Finset.Defs
import Mathlib.Data.Nat.Basic
import Mathlib.Tactic

/-!
# 第 59 章 · 归纳与递归（Makinson Ch4）

简单归纳（奇数和 = n²）、简单递归（fib）、良基递归（Ackermann，
字典序 termination_by）。阶梯：简单 → 累积 → 结构 → 良基。
-/

namespace Settheory.Ch59

-- ---------- 简单归纳：1+3+…+(2n-1) = n² ----------

theorem odd_sum (n : ℕ) : ∑ i ∈ Finset.range n, (2 * i + 1) = n * n := by
  induction n with
  | zero => simp
  | succ k ih =>
      rw [Finset.sum_range_succ, ih]
      ring

-- ---------- 简单递归：Fibonacci（结构递归自动通过） ----------

def fib : ℕ → ℕ
  | 0 => 0
  | 1 => 1
  | (k + 2) => fib (k + 1) + fib k

-- ---------- 良基递归：Ackermann（字典序） ----------

def ack : ℕ → ℕ → ℕ
  | 0, n => n + 1
  | (m + 1), 0 => ack m 1
  | (m + 1), (n + 1) => ack m (ack (m + 1) n)
termination_by m n => (m, n)

decreasing_by
  all_goals simp [Prod.lex_def]

-- ---------- 证书 ----------

example : fib 10 = 55 := by native_decide

example : fib 20 = 6765 := by native_decide

example : ack 2 3 = 9 := by native_decide

example : ack 3 3 = 61 := by native_decide

-- ---------- 累积归纳的使用：n! > 2^n（n ≥ 4） ----------

theorem fact_gt_pow (n : ℕ) (h : n ≥ 4) : n.factorial > 2 ^ n := by
  induction n with
  | zero => omega
  | succ k ih =>
      rw [Nat.factorial_succ]
      rcases Nat.lt_or_ge k 4 with hk | hk
      · match k with
        | 0 | 1 | 2 => omega
        | 3 => decide
      · have h1 : k.factorial > 2 ^ k := ih hk
        have h2 : (k + 1) * k.factorial ≥ 2 * 2 ^ k := by
          calc (k + 1) * k.factorial ≥ (k + 1) * 2 ^ k :=
                Nat.mul_le_mul_left _ (Nat.le_of_lt h1)
            _ ≥ 2 * 2 ^ k := Nat.mul_le_mul (by omega : 2 ≤ k + 1) (Nat.le_refl _)
        rw [Nat.pow_succ]
        nlinarith [h1, h2, hk, show (0:ℕ) < 2 ^ k by simp]

end Settheory.Ch59
