import Mathlib.SetTheory.Ordinal.Basic
import Mathlib.Order.Filter.Cofinite
import Mathlib.Tactic

open Set Filter

/-!
# 第 78 章 · 奇异基数假设：银杰与嘎尔文-海纳（冯琦 §2.4）

嘎尔文-海纳范数（定义 2.29）的有秩性靠两件事：可数个 club 之交仍是
club（77 章 `IsClub.iInter_of_countable`，需 ω < cf(κ)），以及序数 `<`
上没有无穷递减链。第一条定理 `no_omega_descending` 把后者的序数端机器化：
取值域的最小元即与「逐点递减」矛盾。第二、三条定理展示**为什么 κ 必须
不可数**——把「模非荟萃」换成 ω 上唯一的候选（cofinite 滤子），递减链
`f_n(k) = k - n` 立刻出现，原因是可数个尾区间之交为空（cofinite 只是
ω-完全而非 ℵ₁-完全）。
-/

namespace Settheory.Ch78

/-- 序数 `<` 上没有 ω-递减链：定义 2.29 良基性证明的序数端。取
`f : ℕ → Ordinal` 值域的最小元 `f n`，与 `f (n+1) < f n` 矛盾。 -/
theorem no_omega_descending :
    ¬ ∃ f : ℕ → Ordinal, ∀ n, f (n + 1) < f n := by
  rintro ⟨f, hf⟩
  obtain ⟨m, hm, hmin⟩ :=
    (wellFounded_lt (α := Ordinal)).has_min (Set.range f) (Set.range_nonempty f)
  obtain ⟨n, rfl⟩ := hm
  exact hmin _ (Set.mem_range_self (n + 1)) (hf n)

/-- ω 处的退化（一）：`f_n(k) = k - n` 满足 `f_{n+1} <_cofinite f_n`——
尾部（`k ≥ n+1`，有限补集）逐点严格小。于是 `f₀ > f₁ > ⋯` 是无穷递减链，
说明 cofinite 滤子容得下递减链。 -/
theorem monus_descending (n : ℕ) :
    ∀ᶠ k in Filter.cofinite, k - (n + 1) < k - n := by
  have hfin : Set.Finite (Set.Iio (n + 1)) := Set.finite_Iio _
  filter_upwards [hfin.compl_mem_cofinite] with k hk
  rw [Set.mem_compl_iff, Set.mem_Iio] at hk
  have hle : n + 1 ≤ k := Nat.le_of_not_lt hk
  omega

/-- ω 处的退化（二）：可数个尾区间之交为空——这正是上一条能成立的原因，
也是 77 章定理 2.23 的 κ-完全性在 κ = ω 处失效的现场。 -/
theorem tails_empty : (⋂ n : ℕ, {k : ℕ | n ≤ k}) = ∅ := by
  ext k
  simp
  exact ⟨k + 1, Nat.lt_succ_self k⟩

end Settheory.Ch78
