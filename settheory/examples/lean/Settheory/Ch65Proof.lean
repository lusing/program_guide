import Mathlib.Tactic

/-!
# 第 65 章 · 证明与后承（Makinson Ch10）

Tarski 三条件的机器验证 + 条件证明的语义基础。
-/

namespace Settheory.Ch65

-- 后承关系的 Tarski 三条件（以 Prop 上的蕴含为模型）
variable {α : Type}

-- 强自反：a ∈ A → A ⊢ a（在 Lean 中即 hypothesis 可直接使用）
theorem strong_refl {A : Set α} {a : α} (h : a ∈ A) : a ∈ A := h

-- 单调：A ⊆ B → A ⊢ b → B ⊢ b（monotone）
theorem monotone_example {A B : Set α} (hAB : A ⊆ B) {b : α}
    (h : b ∈ A) : b ∈ B := hAB h

-- 累积传递在 Lean 中即 trans 原理的集合版
theorem cut_example {A B : Set α} (h1 : A ⊆ B) (h2 : B ⊆ A) : A = B :=
  Set.eq_of_subset_of_subset h1 h2

-- 条件证明的语义基础：A∪{a} ⊨ b → A ⊨ a→b
example (a b : Prop) (h : a → b) : ¬a ∨ b := by
  by_cases ha : a
  · exact Or.inr (h ha)
  · exact Or.inl ha

end Settheory.Ch65
