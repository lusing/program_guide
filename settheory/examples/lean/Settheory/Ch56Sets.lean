import Mathlib.Data.Set.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Tactic

/-!
# 第 56 章 · 朴素集合：计算者的第一课（Makinson Ch1）

包含/外延/真包含三关系；交并差的代数定律；广义 De Morgan；
幂集的 2ⁿ 计数。`Set.Subset.trans`、`Set.inter_union_distrib_left`、
`Set.diff_union`、`Finset.card_powerset` 为官方锚点。
-/

namespace Settheory.Ch56

section Inclusion

variable {α : Type*}

-- (a) 包含的传递性：mathlib 官方锚点
theorem incl_trans {A B C : Set α} (h1 : A ⊆ B) (h2 : B ⊆ C) : A ⊆ C :=
  h1.trans h2

-- 循环链原则：A ⊆ B 且 B ⊆ A 推出 A = B（外延公理的双包含法）
theorem incl_cycle {A B : Set α} (h1 : A ⊆ B) (h2 : B ⊆ A) : A = B :=
  le_antisymm h1 h2

-- (b) 的反例：{1} ⊆ {1,2} 与 {2} ⊆ {1,2} 都成立，但 {1} ⊄ {2}
example : ¬ ({1} : Set ℕ) ⊆ {2} :=
  fun h => absurd (h (by decide)) (by decide)

-- (e) A ⊆ B ↔ (A ⊂ B ∨ A = B)
theorem subset_iff_ssubset_or_eq {A B : Set α} :
    A ⊆ B ↔ (A ⊂ B ∨ A = B) := by
  constructor
  · intro hsub
    by_cases hEq : A = B
    · exact Or.inr hEq
    · exact Or.inl ⟨hsub, hEq⟩
  · rintro (⟨hsub, _⟩ | rfl)
    · exact hsub
    · rfl

end Inclusion

section Boolean

variable {α : Type*}

-- 分配律（交对并）：官方锚点
theorem dist_meet_over_uni (A B C : Set α) :
    A ∩ (B ∪ C) = (A ∩ B) ∪ (A ∩ C) :=
  Set.inter_union_distrib_left

-- 分配律（并对交）：官方锚点
theorem dist_uni_over_meet (A B C : Set α) :
    A ∪ (B ∩ C) = (A ∪ B) ∩ (A ∪ C) :=
  Set.union_inter_distrib_left

-- 吸收律 A ∩ (A ∪ B) = A
theorem absorb_left (A B : Set α) : A ∩ (A ∪ B) = A := by
  ext x
  by_cases hx : x ∈ A <;> simp [hx]

-- 相对 De Morgan：A \ (B ∪ C) = (A \ B) ∩ (A \ C)——官方锚点
theorem demorgan_diff (A B C : Set α) :
    A \ (B ∪ C) = (A \ B) ∩ (A \ C) :=
  Set.diff_union

-- 相对 De Morgan 第二式：A \ (B ∩ C) = (A \ B) ∪ (A \ C)
theorem demorgan_diff' (A B C : Set α) :
    A \ (B ∩ C) = (A \ B) ∪ (A \ C) := by
  ext x
  simp only [Set.mem_diff, Set.mem_inter_iff, Set.mem_union, not_and_or,
    not_not]
  tauto

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

-- 广义分配：A ∩ ⋃ i, f i = ⋃ i, A ∩ f i
theorem gen_dist (A : Set α) (f : ι → Set α) :
    A ∩ ⋃ i, f i = ⋃ i, A ∩ f i := by
  ext x
  simp only [Set.mem_inter_iff, Set.mem_iUnion]
  constructor
  · rintro ⟨hA, i, hi⟩; exact ⟨i, hA, hi⟩
  · rintro ⟨i, hA, hi⟩; exact ⟨hA, i, hi⟩

-- 广义 De Morgan：A ∩ ⋂ i, f i = ⋂ i, A ∩ f i（注意空索引族时
-- 右边是全集——与 Makinson 书中"局部宇宙"版本一致，这里对类型索引）
theorem gen_dist' (A : Set α) (f : ι → Set α) :
    A ∪ ⋂ i, f i = ⋂ i, A ∪ f i := by
  ext x
  simp only [Set.mem_union, Set.mem_inter_iff, Set.mem_iInter]
  tauto

end General

section Powerset

-- |𝒫(A)| = 2^|A|：Finset 版官方锚点
theorem card_pow (s : Finset ℕ) : s.powerset.card = 2 ^ s.card :=
  Finset.card_powerset

-- 具体计算：𝒫({1,2,3}) 有 8 个元素
example : (Finset.powerset ({1, 2, 3} : Finset ℕ)).card = 8 := by
  rw [card_pow]; decide

end Powerset

end Settheory.Ch56
