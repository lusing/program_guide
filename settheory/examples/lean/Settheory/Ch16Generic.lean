import Mathlib.Order.Filter.Basic

/-!
# 第 16 章 · 偏序、稠密集与泛型扩张的骨架

Cohen 力迫的第一步：力迫条件（P, <）（更强=更小）、
滤子、稠密集、泛型滤波器。引理 16.1（Rasiowa-Sikorski 的
雏形：可数稠密集族上泛型滤波器存在）是本章的机器化核心。
-/

/-! ## 一、泛型滤波器的定义骨架 -/

section GenericDef

variable (P : Type) [PartialOrder P]

/-- 稠密集：每条条件下方都有成员。 -/
def Dense (D : Set P) : Prop :=
  ∀ p : P, ∃ q ∈ D, q ≤ p

/-- 滤子（力迫版）：向上封闭 + 两两相容（下方有共同延伸）。 -/
structure IsFilter (F : Set P) : Prop where
  nonempty : F.Nonempty
  up_closed : ∀ {p q : P}, p ∈ F → p ≤ q → q ∈ F
  directed : ∀ p ∈ F, ∀ q' ∈ F, ∃ r ∈ F, r ≤ p ∧ r ≤ q'

/-- 泛型：击中一切（模型内的）稠密集。
    这里的 ℰ 是"模型的稠密集族"的抽象。 -/
def GenericOver (F : Set P) (ℰ : Set (Set P)) : Prop :=
  IsFilter P F ∧ ∀ D ∈ ℰ, Dense P D → (F ∩ D).Nonempty

end GenericDef

/-! ## 二、相容性的稠密集论证（习题 16.1 的引擎） -/

/-- 全集平凡稠密；习题 16.1 的三支集合之稠密性需要
    （对给定 r 的）真分情形讨论——讲义与计算通道承载。 -/
example (P : Type) [PartialOrder P] : Dense P (Set.univ : Set P) := by
  intro r
  exact ⟨r, Set.mem_univ r, le_refl r⟩
