import Mathlib.Order.BooleanAlgebra.Basic
import Mathlib.Data.Set.Basic

/-!
# 第 47 章 · 布尔代数：恒等式、理想与素理想定理

Viale Ch3.1-3.7 的官方锚点挂接 + 𝒫(α) 原子刻画（Prop 3.5.3 的
原子半边）。mathlib 自带全部恒等式；本文件做两件事：
(1) 把 Viale Prop 3.3.1 的编号映射到 mathlib 引理名；
(2) 自证：𝒫(α) 的原子恰为单点集。
-/

namespace Settheory.Ch47

/-! ## 一、Viale Prop 3.3.1 ↔ mathlib 官方锚点 -/

-- (ii) 补唯一律
example {α : Type*} [BooleanAlgebra α] (a b : α)
    (h1 : a ⊓ b = ⊥) (h2 : a ⊔ b = ⊤) : b = aᶜ :=
  (compl_unique h1 h2).symm

-- (iii) 双重补
example {α : Type*} [BooleanAlgebra α] (a : α) : aᶜᶜ = a := compl_compl a

-- (iv) De Morgan 两律
example {α : Type*} [BooleanAlgebra α] (a b : α) :
    (a ⊔ b)ᶜ = aᶜ ⊓ bᶜ := compl_sup

example {α : Type*} [BooleanAlgebra α] (a b : α) :
    (a ⊓ b)ᶜ = aᶜ ⊔ bᶜ := compl_inf

-- (i) 幂等律
example {α : Type*} [BooleanAlgebra α] (a : α) : a ⊓ a = a := inf_idem a

/-! ## 二、𝒫(α) 的原子恰是单点集（Prop 3.5.3 原子半边） -/

/-- 𝒫(α) 中的原子：非空，且无非空真子集（极小性） -/
def IsAtomP {α : Type*} (S : Set α) : Prop :=
  S.Nonempty ∧ ∀ T ⊆ S, T.Nonempty → T = S

/-- 单点集是原子 -/
theorem singleton_atom {α : Type*} (a : α) : IsAtomP {a} := by
  refine ⟨⟨a, rfl⟩, ?_⟩
  intro T hT hne
  obtain ⟨x, hx⟩ := hne
  have hxa : x = a := hT hx
  apply Set.Subset.antisymm hT
  rintro y rfl
  exact hxa ▸ hx

/-- 原子必是单点集 -/
theorem atom_singleton {α : Type*} {S : Set α} (h : IsAtomP S) :
    ∃ a, S = {a} := by
  obtain ⟨a, ha⟩ := h.1
  refine ⟨a, ?_⟩
  apply Set.Subset.antisymm
  · intro y hy
    have hys : {y} ⊆ S := by
      intro z hz
      rw [hz]
      exact hy
    have h1 : {y} = S := h.2 {y} hys ⟨y, rfl⟩
    have : a ∈ {y} := h1 ▸ ha
    have hay : a = y := this
    rw [hay]
    rfl
  · intro y hy
    rw [hy]
    exact ha

end Settheory.Ch47
