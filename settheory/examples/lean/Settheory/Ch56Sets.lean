import Mathlib.Data.Set.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Tactic

/-!
# 第 56 章 · 朴素集合：计算者的第一课（Makinson Ch1）

包含/外延/真包含三关系；交并差的代数定律；广义分配与 De Morgan；
幂集的 2ⁿ 计数。`Set.subset_antisymm`、`Set.inter_union_distrib_left`、
`Set.inter_iUnion`、`Finset.card_powerset` 为官方锚点。
-/

namespace Settheory.Ch56

section Inclusion

variable {α : Type*}

-- (a) 包含的传递性：mathlib 官方锚点
theorem incl_trans {A B C : Set α} (h1 : A ⊆ B) (h2 : B ⊆ C) : A ⊆ C :=
  h1.trans h2

-- 循环链原则：A ⊆ B 且 B ⊆ A 推出 A = B（外延公理的双包含法）
theorem incl_cycle {A B : Set α} (h1 : A ⊆ B) (h2 : B ⊆ A) : A = B :=
  Set.eq_of_subset_of_subset h1 h2

-- (b) 的反例：{1} ⊆ {1,2} 与 {2} ⊆ {1,2} 都成立，但 {1} ⊄ {2}
example : ¬ ({1} : Set ℕ) ⊆ {2} := by
  intro h
  have h1 : (1 : ℕ) ∈ ({1} : Set ℕ) := by simp
  have h2 : (1 : ℕ) ∉ ({2} : Set ℕ) := by simp
  exact absurd (h h1) h2

-- (e) A ⊆ B ↔ (A ⊂ B ∨ A = B)
theorem subset_iff_ssubset_or_eq {A B : Set α} :
    A ⊆ B ↔ (A ⊂ B ∨ A = B) := by
  constructor
  · intro hsub
    by_cases hEq : A = B
    · exact Or.inr hEq
    · exact Or.inl ⟨hsub, fun hB => hEq (Set.eq_of_subset_of_subset hsub hB)⟩
  · rintro (⟨hsub, _⟩ | rfl)
    · exact hsub
    · rfl

end Inclusion

section Boolean

variable {α : Type*}

-- 分配律（交对并）：官方锚点
theorem dist_meet_over_uni (A B C : Set α) :
    A ∩ (B ∪ C) = (A ∩ B) ∪ (A ∩ C) :=
  Set.inter_union_distrib_left A B C

-- 分配律（并对交）：官方锚点
theorem dist_uni_over_meet (A B C : Set α) :
    A ∪ (B ∩ C) = (A ∪ B) ∩ (A ∪ C) :=
  Set.union_inter_distrib_left A B C

-- 吸收律 A ∩ (A ∪ B) = A
theorem absorb_left (A B : Set α) : A ∩ (A ∪ B) = A := by
  ext x
  by_cases hx : x ∈ A <;> simp [hx]

-- 相对 De Morgan：A \ (B ∪ C) = (A \ B) ∩ (A \ C)
theorem demorgan_diff (A B C : Set α) :
    A \ (B ∪ C) = (A \ B) ∩ (A \ C) := by
  ext x
  simp only [Set.mem_sdiff, Set.mem_union, Set.mem_inter_iff]
  tauto

-- 相对 De Morgan 第二式：A \ (B ∩ C) = (A \ B) ∪ (A \ C)
theorem demorgan_diff' (A B C : Set α) :
    A \ (B ∩ C) = (A \ B) ∪ (A \ C) := by
  ext x
  by_cases hA : x ∈ A <;> by_cases hB : x ∈ B <;> by_cases hC : x ∈ C <;>
    simp [hA, hB, hC]

-- 差不交换的具体反例（见证元素版）：1 ∈ {1,2} \ {2,3} 但 1 ∉ 反向差
example : (1 : ℕ) ∈ ({1, 2} : Set ℕ) \ {2, 3} ∧
    (1 : ℕ) ∉ ({2, 3} : Set ℕ) \ {1, 2} := by
  constructor
  · exact ⟨by decide, by decide⟩
  · intro h
    exact absurd h.1 (by decide)

end Boolean

section General

variable {ι : Type*}

-- 广义分配：A ∩ ⋃ i, f i = ⋃ i, A ∩ f i——官方锚点
theorem gen_dist (A : Set α) (f : ι → Set α) :
    A ∩ ⋃ i, f i = ⋃ i, A ∩ f i :=
  Set.inter_iUnion A f

-- 广义分配（并对交）：A ∪ ⋂ i, f i = ⋂ i, A ∪ f i——官方锚点
theorem gen_dist' (A : Set α) (f : ι → Set α) :
    A ∪ ⋂ i, f i = ⋂ i, A ∪ f i :=
  Set.union_iInter A f

end General

section Powerset

-- |𝒫(A)| = 2^|A|：Finset 版官方锚点
theorem card_pow (s : Finset ℕ) : s.powerset.card = 2 ^ s.card :=
  Finset.card_powerset s

-- 具体计算：𝒫({1,2,3}) 有 8 个元素
example : (Finset.powerset ({1, 2, 3} : Finset ℕ)).card = 8 := by
  rw [card_pow]; decide

end Powerset

end Settheory.Ch56
