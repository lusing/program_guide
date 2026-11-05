import Mathlib.Logic.Equiv.Nat
import Mathlib.Basic.Denumerable
import Mathlib.Data.Rat.Encodable
import Mathlib.Analysis.Real.Cardinality
import Mathlib.Data.Set.Countable
import Mathlib.Tactic

/-!
# 第 08 章 可数性

对应原书第 8 章：势（双射等价）是等价关系、有限集的势就是元素个数、
可数 = 与 ℕ 等势、ℤ 的交错枚举、(0,1) 与 ℝ 不可数（对角线）、
可数并、ℚ 可数、无理数不可数。

命名对照：原书“可数”= 与 ℕ 等势（mathlib 的 `Denumerable`）；
原书“至多可数”= 有限或可数（mathlib 的 `Countable`，即存在单射进 ℕ）。
-/

namespace Realanalysis.Ch08

open Function Set Cardinal

/-! ## 8.1 势是等价关系 -/

/-- 定理 8.4 性质 1：恒等是双射，故 A ∼ A。 -/
example : ℕ ≃ ℕ := Equiv.refl ℕ

/-- 性质 2：双射可逆，故 A ∼ B ⇒ B ∼ A。 -/
example : ℕ ≃ ℤ := Equiv.intEquivNat.symm

/-- 性质 3：双射复合仍是双射。 -/
example : ℤ ≃ ℤ := Equiv.intEquivNat.trans Equiv.intEquivNat.symm

/-! ## 8.2 有限集：等势 ⟺ 元素个数相同 -/

/-- 定理 8.5：两个有限类型等势当且仅当基数相等。 -/
example : (Fin 3 ≃ Fin 3) := Equiv.refl _
example : Fintype.card (Fin 3) = Fintype.card (Fin 4) → Nonempty (Fin 3 ≃ Fin 4) := by
  intro h
  exact ⟨Fintype.equivOfCardEq h⟩
example : Fintype.card (Fin 3) ≠ Fintype.card (Fin 4) := by decide

/-! ## 8.3 例 8.8：ℤ 可数（交错枚举） -/

/-- 原书公式，下标从 1 起：偶数 n/2，奇数 -(n-1)/2。
    于是 1↦0，2↦1，3↦-1，4↦2，5↦-2。 -/
def bookF (n : ℕ) : ℤ :=
  if n % 2 = 0 then (n / 2 : ℤ) else -(((n - 1) / 2 : ℕ) : ℤ)

example : bookF 1 = 0 := by decide
example : bookF 2 = 1 := by decide
example : bookF 3 = -1 := by decide
example : bookF 4 = 2 := by decide
example : bookF 5 = -2 := by decide

/-- 逆：0↦1，正数 k↦2k，负数 -k↦2k+1。 -/
def bookInv : ℤ → ℕ
  | .ofNat 0 => 1
  | .ofNat (k + 1) => 2 * (k + 1)
  | .negSucc k => 2 * (k + 1) + 1

theorem bookF_bookInv (z : ℤ) : bookF (bookInv z) = z := by
  cases z with
  | ofNat n =>
    cases n with
    | zero => decide
    | succ k =>
      simp [bookInv, bookF, Nat.mul_mod_right]
  | negSucc k =>
    simp [bookInv, bookF, Int.negSucc_eq]

/-- 因此 bookF 在 {n | n ≥ 1} 上是满射，ℤ 与 ℕ 等势。
    mathlib 直接给出 `Denumerable ℤ`（原书意义下的可数）。 -/
example : Denumerable ℤ := inferInstance
example : ℤ ≃ ℕ := Equiv.intEquivNat

/-! ## 8.4 对角线：没有 ℕ → (ℕ → Bool) 的满射 -/

/-- 康托尔对角线的可计算内核：对任何枚举 f，对角翻转
    `d n = ¬ f n n` 不在值域里。这就是例 8.10 的骨架
    （把小数位收成 0/1）。 -/
theorem cantor (f : ℕ → ℕ → Bool) : ¬ Surjective f := by
  intro hf
  let d : ℕ → Bool := fun n => !(f n n)
  rcases hf d with ⟨n, hn⟩
  have := congrFun hn n
  cases h : f n n <;> simp [d, h] at this

/-- 推论 8.12：ℝ 不可数。`Uncountable` 是 `Countable` 的否定。 -/
example : Uncountable ℝ := inferInstance

example : ¬ (Set.univ : Set ℝ).Countable := Cardinal.not_countable_real

/-- 例 8.10：(0,1) 不可数。`Ioo_countable_iff` 已是 simp 引理。 -/
example : ¬ (Set.Ioo (0 : ℝ) 1).Countable := by simp

/-! ## 8.5 子集、可数并、ℚ -/

/-- 定理 8.11：至多可数集的子集仍至多可数（mathlib：`Countable`）。 -/
example {α : Type*} {s t : Set α} (ht : t.Countable) (hs : s ⊆ t) : s.Countable :=
  ht.mono hs

/-- 定理 8.13：可数并仍至多可数。 -/
example {α : Type*} (s : ℕ → Set α) (h : ∀ n, (s n).Countable) :
    (⋃ n, s n).Countable :=
  Set.countable_iUnion h

/-- 定理 8.16：ℚ 至多可数。它又是无限的，所以是原书意义下的可数。 -/
example : Countable ℚ := inferInstance
example : Infinite ℚ := inferInstance

/-- 推论 8.17：无理数集不可数。若可数，则 ℝ = ℚ ∪ 无理数
    是两个至多可数集之并，与 ℝ 不可数矛盾。 -/
example : ¬ (Set.range ((↑) : ℚ → ℝ))ᶜ.Countable := by
  intro h
  have hQ : (Set.range ((↑) : ℚ → ℝ)).Countable := countable_range _
  have hU : (Set.univ : Set ℝ).Countable := by
    rw [← Set.union_compl_self (Set.range ((↑) : ℚ → ℝ))]
    exact hQ.union h
  exact Cardinal.not_countable_real hU

end Realanalysis.Ch08
