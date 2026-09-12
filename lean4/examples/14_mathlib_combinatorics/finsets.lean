/-
文件: 14_mathlib_combinatorics/finsets.lean
描述: 有限集合 Finset
编译: lake build Lean4Tutorial.Examples.MathlibCombinatorics.Finsets
依赖: Mathlib.Data.Finset.Basic
-/

import Mathlib.Data.Finset.Basic

namespace Lean4Tutorial.Examples.MathlibCombinatorics.Finsets

/-! # 有限集合 Finset -/

-- Finset α 表示类型 α 的有限集合
-- 与 Set α 不同，Finset α 的元素个数一定是有限的
--
-- 在 Mathlib 中，Finset 是通过多重集定义的，
-- 保证了元素的无重复性和有限性

/-! ## Finset 的构造 -/

-- 空集
#check (∅ : Finset ℕ)

-- 单元素集
#check ({1} : Finset ℕ)

-- 有限集合
#check ({1, 2, 3} : Finset ℕ)

-- 例子
def s1 : Finset ℕ := {1, 2, 3}
def s2 : Finset ℕ := {2, 3, 4}
def s3 : Finset ℕ := {1, 2, 3, 4, 5}

-- 使用 #eval 查看
#eval ({1, 2, 3} : Finset ℕ)

/-! ## 元素属于关系 -/

-- x ∈ s 表示 x 是 s 的元素
theorem mem_insert {α : Type*} [DecidableEq α] (x y : α) (s : Finset α) :
    x ∈ insert y s ↔ x = y ∨ x ∈ s := by
  exact Finset.mem_insert

-- 空集没有元素
theorem not_mem_empty {α : Type*} (x : α) : x ∉ (∅ : Finset α) := by
  exact Finset.not_mem_empty x

-- 例子
example : 1 ∈ ({1, 2, 3} : Finset ℕ) := by simp
example : 4 ∉ ({1, 2, 3} : Finset ℕ) := by simp

/-! ## 集合运算 -/

variable (s t : Finset ℕ)

-- 并集
#check s ∪ t

theorem mem_union (x : ℕ) : x ∈ s ∪ t ↔ x ∈ s ∨ x ∈ t := by
  exact Finset.mem_union

-- 交集
#check s ∩ t

theorem mem_inter (x : ℕ) : x ∈ s ∩ t ↔ x ∈ s ∧ x ∈ t := by
  exact Finset.mem_inter

-- 差集
#check s \ t

theorem mem_sdiff (x : ℕ) : x ∈ s \ t ↔ x ∈ s ∧ x ∉ t := by
  exact Finset.mem_sdiff

-- 对称差
-- s ∆ t = (s \ t) ∪ (t \ s)

-- 计算例子
#eval ({1, 2, 3} : Finset ℕ) ∪ ({2, 3, 4} : Finset ℕ)  -- {1, 2, 3, 4}
#eval ({1, 2, 3} : Finset ℕ) ∩ ({2, 3, 4} : Finset ℕ)  -- {2, 3}
#eval ({1, 2, 3} : Finset ℕ) \ ({2, 3, 4} : Finset ℕ)  -- {1}

/-! ## 集合运算的性质 -/

variable {α : Type*} [DecidableEq α] (s t u : Finset α)

-- 交换律
theorem union_comm : s ∪ t = t ∪ s := by
  exact Finset.union_comm s t

theorem inter_comm : s ∩ t = t ∩ s := by
  exact Finset.inter_comm s t

-- 结合律
theorem union_assoc : (s ∪ t) ∪ u = s ∪ (t ∪ u) := by
  exact Finset.union_assoc s t u

theorem inter_assoc : (s ∩ t) ∩ u = s ∩ (t ∩ u) := by
  exact Finset.inter_assoc s t u

-- 分配律
theorem union_inter_distrib_left : s ∪ (t ∩ u) = (s ∪ t) ∩ (s ∪ u) := by
  exact Finset.union_inter_distrib_left s t u

theorem inter_union_distrib_left : s ∩ (t ∪ u) = (s ∩ t) ∪ (s ∩ u) := by
  exact Finset.inter_union_distrib_left s t u

-- 吸收律
theorem union_inter_cancel_left : s ∪ (s ∩ t) = s := by
  exact Finset.union_inter_cancel_left s t

theorem inter_union_cancel_left : s ∩ (s ∪ t) = s := by
  exact Finset.inter_union_cancel_left s t

-- 空集性质
theorem union_empty : s ∪ ∅ = s := by
  exact Finset.union_empty s

theorem inter_empty : s ∩ ∅ = ∅ := by
  exact Finset.inter_empty s

/-! ## 子集关系 -/

-- s ⊆ t 表示 s 是 t 的子集
-- 即 s 的每个元素都是 t 的元素

theorem subset_def : s ⊆ t ↔ ∀ x ∈ s, x ∈ t := by
  exact Finset.subset_iff

-- 子集的性质
theorem subset_refl : s ⊆ s := by
  exact Finset.Subset.refl s

theorem subset_trans (h1 : s ⊆ t) (h2 : t ⊆ u) : s ⊆ u := by
  exact Finset.Subset.trans h1 h2

theorem subset_antisymm (h1 : s ⊆ t) (h2 : t ⊆ s) : s = t := by
  exact Finset.Subset.antisymm h1 h2

-- 空集是任何集合的子集
theorem empty_subset : ∅ ⊆ s := by
  exact Finset.empty_subset s

-- 真子集
-- s ⊂ t 表示 s ⊆ t 且 s ≠ t

-- 并集和交集与子集的关系
theorem subset_union_left : s ⊆ s ∪ t := by
  exact Finset.subset_union_left s t

theorem subset_union_right : t ⊆ s ∪ t := by
  exact Finset.subset_union_right s t

theorem inter_subset_left : s ∩ t ⊆ s := by
  exact Finset.inter_subset_left s t

theorem inter_subset_right : s ∩ t ⊆ t := by
  exact Finset.inter_subset_right s t

/-! ## 基数（元素个数） -/

-- s.card 表示有限集合 s 的元素个数

#check Finset.card

-- 空集的基数为 0
theorem card_empty : (∅ : Finset α).card = 0 := by
  exact Finset.card_empty

-- 单元素集的基数为 1
theorem card_singleton (x : α) : ({x} : Finset α).card = 1 := by
  exact Finset.card_singleton x

-- 插入元素
theorem card_insert_of_not_mem {x : α} (h : x ∉ s) :
    (insert x s).card = s.card + 1 := by
  exact Finset.card_insert_of_not_mem h

-- 并集的基数（容斥原理的简单情况）
theorem card_union_add_card_inter :
    (s ∪ t).card + (s ∩ t).card = s.card + t.card := by
  exact Finset.card_union_add_card_inter s t

-- 即：|A ∪ B| = |A| + |B| - |A ∩ B|
theorem card_union : (s ∪ t).card = s.card + t.card - (s ∩ t).card := by
  rw [← card_union_add_card_inter s t]
  <;> omega

-- 例子
#eval ({1, 2, 3} : Finset ℕ).card  -- 3
#eval ({1, 2, 2, 3} : Finset ℕ).card  -- 3（重复元素只算一次）

/-! ## Finset 的构造方法 -/

-- range n = {0, 1, ..., n-1}
def range_example : Finset ℕ := Finset.range 5

#eval Finset.range 5  -- {0, 1, 2, 3, 4}
#eval (Finset.range 5).card  -- 5

-- Ico a b = {a, a+1, ..., b-1}（左闭右开区间）
def ico_example : Finset ℕ := Finset.Ico 2 5

#eval Finset.Ico 2 5  -- {2, 3, 4}

-- Icc a b = {a, a+1, ..., b}（闭区间）
def icc_example : Finset ℕ := Finset.Icc 2 5

#eval Finset.Icc 2 5  -- {2, 3, 4, 5}

-- Ioo a b = {a+1, ..., b-1}（开区间）
-- Ioc a b = {a+1, ..., b}（左开右闭）

/-! ## 集合的像与原像 -/

-- 函数下的像
-- f '' s = {f(x) | x ∈ s}

variable (f : ℕ → ℕ)

theorem mem_image (y : ℕ) : y ∈ Finset.image f s ↔ ∃ x ∈ s, f x = y := by
  exact Finset.mem_image

-- 像的基数
-- |f '' s| ≤ |s|
-- 当 f 是单射时等号成立

/-! ## 幂集 -/

-- 有限集合 s 的幂集是 s 的所有子集构成的集合
-- powerset s = {t | t ⊆ s}

#check Finset.powerset

-- 幂集的基数：|powerset s| = 2^|s|
theorem card_powerset (s : Finset ℕ) :
    (Finset.powerset s).card = 2 ^ s.card := by
  exact Finset.card_powerset s

-- 例子
#eval (Finset.powerset ({1, 2} : Finset ℕ)).card  -- 4

/-! ## 有限集合上的过滤 -/

-- filter p s 是 s 中满足性质 p 的元素构成的子集
def evens : Finset ℕ := Finset.filter (fun x => x % 2 = 0) (Finset.range 10)

#eval evens  -- {0, 2, 4, 6, 8}

end Lean4Tutorial.Examples.MathlibCombinatorics.Finsets
