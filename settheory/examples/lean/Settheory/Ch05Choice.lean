import Mathlib.Order.Zorn
import Mathlib.Logic.Basic

/-!
# 第 05 章 · 选择公理：Zorn 与良序定理

选择公理在 Lean 类型论里的身份是 `Classical.choice`——三个
经典公理之一（choice / excludedMiddle / propext）。mathlib 的
Zorn 引理是 choice 公理的机器推论；良序定理由 Zorn 推出
（Jech §5 的路线在 Isabelle/ZF 的 AC 会话机器化，见 ST05）。
-/

/-! ## 一、choice 公理的本体 -/

/-- 非空类型可取元素：`Classical.choice` 的最直接化身。 -/
noncomputable def pick (α : Type) [Nonempty α] : α := Classical.choice ‹_›

/-- 数学家式的用法：从 ∀x ∃y 出发选函数。
    `Classical.choice` + `propext` + 排中律共同支撑"存在的
    东西可以选定"。 -/
noncomputable example (α : Type) (R : α → α → Prop)
    (h : ∀ x, ∃ y, R x y) : α → α :=
  fun x => Classical.choose (h x)

/-! ## 二、Zorn 引理（Jech 定理 16 的机器形态）-/

/-- 链有上界 ⟹ 有极大元：`zorn_le`。 -/
example (α : Type) [PartialOrder α]
    (h : ∀ c : Set α, IsChain (· ≤ ·) c → BddAbove c) : ∃ m : α, IsMax m :=
  zorn_le h

/-- 集合族的版本：`zorn_superset`（对偶序上的 zorn_le₀），
    数学实践里最常用的形态（基的存在性、理想扩张……）。 -/
example (α : Type) (S : Set (Set α))
    (h : ∀ c ⊆ S, IsChain (· ⊆ ·) c → ∃ lb ∈ S, ∀ s ∈ c, lb ⊆ s) :
    ∃ m, Minimal (· ∈ S) m :=
  zorn_superset S h
