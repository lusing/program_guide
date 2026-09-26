/-
文件: 18_mathlib_sets_functions/sets_functions.lean
描述: 第31章 集合与函数（与教程同步，Mathlib4 v4.35.0-rc3 验证）
编译: lake build Lean4Tutorial.Examples.MathlibSetsFunctions.SetsFunctions
-/

import Mathlib.Data.Set.Basic
import Mathlib.Data.Set.Image
import Mathlib.Data.Set.Lattice.Order
import Mathlib.Logic.Function.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Tactic

namespace Lean4Tutorial.Examples.MathlibSetsFunctions.Ch31

open Set Function

variable {α β γ : Type}

/-! # 31.1 Set 就是 α → Prop -/

#check (Set ℕ)                          -- Set ℕ : Type
#check ({n : ℕ | n % 2 = 0} : Set ℕ)    -- 集合构造记法

example : (2 : ℕ) ∈ {n | n % 2 = 0} := by decide
example : (3 : ℕ) ∉ {n | n % 2 = 0} := by decide

-- ∅ 与 univ 是两个极端
example (x : ℕ) : x ∈ (Set.univ : Set ℕ) := trivial
example (x : ℕ) : x ∉ (∅ : Set ℕ) := fun h => h

/-! # 31.2 集合运算与德摩根律 -/

example (s t : Set ℕ) : s ∩ t ⊆ s := inter_subset_left
example (x : ℕ) (s t : Set ℕ) : x ∈ s ∪ t ↔ x ∈ s ∨ x ∈ t := mem_union x s t
example (s t : Set ℕ) : s \ t = s ∩ tᶜ := Set.sdiff_eq s t

-- 德摩根律：ext 引入元素后化简。第一条构造性，simp 即可；第二条需经典逻辑，用 grind
example (s t : Set ℕ) : (s ∪ t)ᶜ = sᶜ ∩ tᶜ := by ext x; simp
example (s t : Set ℕ) : (s ∩ t)ᶜ = sᶜ ∪ tᶜ := by ext x; grind

-- 分配律
example (s t u : Set ℕ) : s ∩ (t ∪ u) = (s ∩ t) ∪ (s ∩ u) := by
  ext x
  grind

/-! # 31.3 子集、外延相等 -/

-- ⊆ 的定义：s ⊆ t 当且仅当每个 x ∈ s 也 ∈ t（Set.subset_def 现陈述为 Prop 等式）
example (s t : Set α) : s ⊆ t ↔ ∀ x ∈ s, x ∈ t := by
  constructor
  · intro h x hx
    exact h hx
  · intro h x hx
    exact h x hx

theorem set_ext_demo (s t : Set α) (h : ∀ x, x ∈ s ↔ x ∈ t) : s = t := by
  ext x
  exact h x

-- 证明集合相等：ext 引入元素，再逐点证 iff
example (s t : Set α) : s ∪ t = t ∪ s := by
  ext x
  grind

/-! # 31.4 像、原像、值域 -/

-- f '' s = {y | ∃ x ∈ s, f x = y}；f ⁻¹' t = {x | f x ∈ t}；range f = {y | ∃ x, f x = y}
example (f : α → β) (s : Set α) : f '' s = {y | ∃ x ∈ s, f x = y} := by
  ext y
  grind
example (f : α → β) (t : Set β) : f ⁻¹' t = {x | f x ∈ t} := rfl
example (f : α → β) : range f = {y | ∃ x, f x = y} := rfl

-- 像/原像与复合：image_comp、preimage_comp
example (f : α → β) (g : β → γ) (s : Set α) : g ∘ f '' s = g '' (f '' s) :=
  image_comp g f s
example (f : α → β) (g : β → γ) (t : Set γ) : (g ∘ f) ⁻¹' t = f ⁻¹' (g ⁻¹' t) :=
  preimage_comp

-- 单射 ⇒ 原像∘像 = 原集合；满射 ⇒ 像∘原像 = 原集合
example (f : α → β) (s : Set α) (h : Injective f) : f ⁻¹' (f '' s) = s :=
  preimage_image_eq s h
example (f : α → β) (t : Set β) (h : Surjective f) : f '' (f ⁻¹' t) = t :=
  image_preimage_eq t h

-- 具体集合用 Finset 才能 #eval（Set 是谓词，不可计算显示）
#eval (({1, 2, 3} : Finset ℕ).image (· * 2))         -- {2, 4, 6}
#eval (({1, 2, 3, 4} : Finset ℕ).filter (· % 2 = 0)) -- {2, 4}
#eval (({1, 2, 3} : Finset ℕ) ∪ {3, 4})              -- {1, 2, 3, 4}
#eval (({1, 2, 3} : Finset ℕ) \ {2})                 -- {1, 3}

/-! # 31.5 单射、满射、双射 -/

-- fun n => n + 1 在 ℕ 上单射但不满射（0 不在值域）
example : Injective (fun n : ℕ => n + 1) := fun _ _ h => Nat.succ.inj h
example : ¬ Surjective (fun n : ℕ => n + 1) := by
  intro h
  obtain ⟨n, hn⟩ := h 0
  have : n + 1 = 0 := hn   -- 先 beta-归约，omega 才认得
  omega

-- ℤ 上的后继是双射（注意：omega 不会自动 beta-归约 lambda，需先 show/have）
example : Surjective (fun n : ℤ => n + 1) := by
  intro b
  use b - 1
  show (b - 1) + 1 = b
  omega
example : Bijective (fun n : ℤ => n + 1) := by
  refine ⟨?_, ?_⟩
  · intro x y h
    have : x + 1 = y + 1 := h
    omega
  · intro b
    use b - 1
    show (b - 1) + 1 = b
    omega

-- 复合保持单射/满射
example (f : α → β) (g : β → γ) (hf : Injective f) (hg : Injective g) :
    Injective (g ∘ f) := Injective.comp hg hf
example (f : α → β) (g : β → γ) (hf : Surjective f) (hg : Surjective g) :
    Surjective (g ∘ f) := Surjective.comp hg hf

/-! # 31.6 左逆、右逆、等价 -/

-- LeftInverse g f 即 g ∘ f = id；有左逆 ⇒ 单射，有右逆 ⇒ 满射
example (f : α → β) (g : β → α) (h : LeftInverse g f) : Injective f :=
  LeftInverse.injective h
example (f : α → β) (g : β → α) (h : RightInverse g f) : Surjective f :=
  RightInverse.surjective h

-- Equiv α β 把双射打包成可逆映射（toFun / invFun / 两条逆律）
#check (Equiv.refl ℕ : ℕ ≃ ℕ)
#check (Equiv.symm : ℕ ≃ ℤ → ℤ ≃ ℕ)
example (e : ℕ ≃ ℤ) : ℤ ≃ ℕ := e.symm
example (e : ℕ ≃ ℤ) (n : ℕ) : e.symm (e n) = n := e.left_inv n
-- 由双射构造等价：Equiv.ofBijective（依赖经典选择，故 noncomputable）
#check @Equiv.ofBijective

end Lean4Tutorial.Examples.MathlibSetsFunctions.Ch31
