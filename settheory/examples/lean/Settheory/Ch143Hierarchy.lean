import Mathlib.Tactic
import Mathlib.SetTheory.ZFC.Rank

/-!
# 第 143 章 层垒谱系与绝对性（Lean）

mathlib 的 ZFC 子宇宙自带层垒谱系：`ZFSet.rank`（书 7.2.4）、
秩严格下降（书 7.2.5(3)），以及相对化/Δ₀ 绝对性的形态。
-/

/-! ## 秩函数（书 7.2.4-7.2.5） -/

#check @ZFSet.rank

/- x ∈ y ⟹ rank x < rank y（书 7.2.5(3)）——mathlib 原文。
这正是"基础公理在 WF 中成立"（书 7.2 节末）的引擎：
∈ 沿秩严格下降，故无 ∈-无穷下降链。 -/
#check @ZFSet.rank_lt_of_mem

example {x y : ZFSet} (h : y ∈ x) : ZFSet.rank y < ZFSet.rank x :=
  ZFSet.rank_lt_of_mem h

/-! ## 层垒谱系（书 7.2.2） -/

/- mathlib 用 PSet→ZFSet 商实现宇宙；分层性质（传递 7.2.3(1)、
单调 7.2.3(2)）按构造成立。rank 的定义即书 7.2.5(4) 的
sup{rank y + 1 | y ∈ x}。 -/

/-! ## 相对化（书 7.3.1）：把量词限制到 M -/

/- Lean 的受限量词记号就是相对化的日常形态：
"∀ x ∈ M, P x" 即 "(∀x P x)^M" 的 typeclass 版。 -/
example (M : Set ℕ) (P : ℕ → Prop) :
    (∀ x ∈ M, P x) ↔ ∀ x, x ∈ M → P x := Iff.rfl

/-! ## Δ₀ 公式（书 7.4.4）：受限量词对传递类绝对 -/

/- Δ₀ = 只含受囿量词的公式。mathlib 的基本集合引理
（如 mem_sep）全在受限量词内完成——Δ₀ 精神的日常体现。 -/
#check @Set.mem_sep

/- 定理 7.4.8 的头几个构造（配对/并/交/幂差）在 mathlib 中
以 definitional unfolding 的形态"绝对"——它们不引入无界量词。 -/
example (a : ℕ) (h₁ : a ∈ ({1, 2} : Set ℕ)) :
    a ∈ ({1, 2} : Set ℕ) ∪ ({2, 3} : Set ℕ) := Or.inl h₁
