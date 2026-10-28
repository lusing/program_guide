import Mathlib

/-!
# 第 94 章 · 可测基数、正规超滤子与超幂

有限幂集代数与主超滤求值。`principal` 是具体的主超滤；有限模型只用于
核对定义和商退化，不提供可测基数的非平凡 κ-完全超滤。
-/

namespace Settheory.Ch94

open Finset

variable {α β : Type*}

/-- 有限类型幂集代数中，坐标 `a` 的主超滤。 -/
def principal [Fintype α] [DecidableEq α] (a : α) : Finset (Finset α) :=
  Finset.univ.filter (fun s => a ∈ s)

/-- 本书使用的五条有限超滤公理（不包含无限完全性、正规性）。 -/
def IsFiniteUF [Fintype α] [DecidableEq α]
    (U : Finset (Finset α)) : Prop :=
  ∅ ∉ U ∧ Finset.univ ∈ U ∧
  (∀ A ∈ U, ∀ B ∈ U, A ∩ B ∈ U) ∧
  (∀ A ∈ U, ∀ B : Finset α, A ⊆ B → B ∈ U) ∧
  (∀ A : Finset α, A ∈ U ∨ Aᶜ ∈ U)

/-- 两函数在 `a` 的主超滤意义下相等，当且仅当在 `a` 处相等。 -/
def agreeSet [Fintype α] [DecidableEq β] (f g : α → β) : Finset α :=
  Finset.univ.filter (fun x => f x = g x)

theorem mem_principal [Fintype α] [DecidableEq α]
    (a : α) {s : Finset α} : s ∈ principal a ↔ a ∈ s := by
  simp [principal]

theorem agree_mem_principal [Fintype α] [DecidableEq α] [DecidableEq β]
    (a : α) (f g : α → β) :
    agreeSet f g ∈ principal a ↔ f a = g a := by
  simp [agreeSet, mem_principal]

/-- 主超幂没有新元素：每个函数都等价于取值处的常值函数。 -/
theorem principal_ultrapower_degenerates [Fintype α] [DecidableEq α]
    [DecidableEq β] (a : α) (f : α → β) :
    agreeSet f (fun _ => f a) ∈ principal a := by
  rw [agree_mem_principal]

example : IsFiniteUF (principal (2 : Fin 3)) := by
  unfold IsFiniteUF
  native_decide

example : (principal (2 : Fin 3)).card = 4 := by
  native_decide

end Settheory.Ch94
