import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.Card
import Mathlib.Tactic

/-!
# 第 68 章 · 自然数与第一递归定义定理（冯琦 §1.3）

冯琦的加法定义（递归在第二变元）+ 定理 1.16(1) 双归纳交换律；
定理 1.10 鸽子笼（Fintype 官方）；定理 1.11 雪崩映射的名次函数。
-/

namespace Settheory.Ch68

-- ---------- 定理 1.15：加法 = 原始递归（递归在第二变元） ----------

/-- 书页 51：+(m,0)=m；+(m,n+1)=S(+(m,n))。Nat.rec 的展开即此。 -/
def bookAdd (m n : ℕ) : ℕ := Nat.rec m (fun _ acc => acc + 1) n

theorem bookAdd_zero (m : ℕ) : bookAdd m 0 = m := rfl

theorem bookAdd_succ (m n : ℕ) : bookAdd m (n + 1) = bookAdd m n + 1 := rfl

theorem bookAdd_eq_add (m n : ℕ) : bookAdd m n = m + n := by
  induction n with
  | zero => rfl
  | succ k ih => rw [bookAdd_succ, ih]; omega

-- 基础段：0 + m = m（对 m 归纳——书页 51 证明的第一段）
theorem bookAdd_zero_left (n : ℕ) : bookAdd 0 n = n := by
  induction n with
  | zero => rfl
  | succ k ih => rw [bookAdd_succ, ih]

-- ---------- 定理 1.16(1)：交换律的双归纳（六步推导的 Lean 形态） ----------

theorem bookAdd_comm (m n : ℕ) : bookAdd m n = bookAdd n m := by
  induction n generalizing m with
  | zero => rw [bookAdd_zero, bookAdd_zero_left]
  | succ k ih =>
      -- 内层对第一变元归纳（书页 51 的嵌套归纳；外层 IH 随取随用）
      have hl : ∀ j, bookAdd (k + 1) j = bookAdd j (k + 1) := by
        intro j
        induction j with
        | zero => rw [bookAdd_zero, bookAdd_zero_left]
        | succ i hi =>
            rw [bookAdd_succ, bookAdd_succ, hi, bookAdd_succ,
                ih i, ih (i + 1), bookAdd_succ]
      rw [hl m]

-- ---------- 定理 1.10：鸽子笼（Fintype 官方形态） ----------

/-- 单射 f : (n+1) → Fin n 不存在：card_le_of_injective 给 n+1 ≤ n。 -/
theorem noInjection_succ_le (n : Nat) :
    ¬ ∃ f : Fin (n + 1) → Fin n, Function.Injective f := by
  rintro ⟨f, hf⟩
  have h := Fintype.card_le_of_injective f hf
  simp only [Fintype.card_fin] at h
  omega

-- ---------- 定理 1.11：雪崩映射的名次函数 ----------

/-- π_X(k) = |{x ∈ X : x < k}|——k 在 X 中的"名次" -/
def rankIn (X : List ℕ) (k : ℕ) : ℕ := (X.takeWhile (· < k)).length

def primes : List ℕ := [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]

example : rankIn primes 13 = 5 := by decide

example : rankIn primes 37 = 11 := by decide

/-- 名次函数有界：π_X(k) ≤ |X|（引理 1.1 的影子） -/
-- 先证抽象谓词版（绕开 decide 实例的语法差；本版 takeWhile 负向
-- 引理给空表——"跳过即停"），再对 rankIn 一行特化
theorem takeWhile_len_le (p : ℕ → Bool) (l : List ℕ) :
    (l.takeWhile p).length ≤ l.length := by
  induction l with
  | nil => simp
  | cons a t ih =>
      by_cases h : p a = true
      · simp only [List.takeWhile_cons_of_pos h, List.length_cons]
        omega
      · simp only [List.takeWhile_cons_of_neg h, List.length_nil, List.length_cons]
        omega

theorem rankIn_le (X : List ℕ) (k : ℕ) : rankIn X k ≤ X.length := by
  simpa [rankIn] using takeWhile_len_le (fun x => decide (x < k)) X

end Settheory.Ch68
