import Mathlib.Order.WellFounded
import Mathlib.SetTheory.Ordinal.Basic

/-!
# 第 11 章 · 传递模型：Mostowski 坍缩与反射原理

定理 28（良基+外延 ⟹ 同构于传递类）与定理 29（反射原理）
是 L 篇的方法论双璧。mathlib 没有现成的 Mostowski 坍缩；
本章展示它的两个官方组件：良基递归（坍缩函数的定义机制）
与序数特例（定理 2 的推广方向）。
-/

/-! ## 一、良基递归：坍缩函数的定义机制 -/

/-- Mostowski 坍缩的核心 π(x) = π[ext(x)] 是良基递归——
    mathlib 的 `WellFounded.fix` 是其一般形态。 -/
example {α : Type} {r : α → α → Prop} (hwf : WellFounded r)
    (F : (α → β) → α → β) : α → β :=
  hwf.fix F

/-! ## 二、定理 2 回顾：良序集坍缩到序数 -/

/-- 良序集同构于唯一序数——Mostowski 坍缩在 ∈-良序下的特例
    （π 恰是枚举函数）。 -/
example (w : Type) [wo : IsWellOrder w (· < ·)] : ∃ o : Ordinal, Nonempty (w ≃o o.out) :=
  ⟨Ordinal.type (· < ·), Ordinal.typein_iso (· < ·)⟩

/-! ## 三、反射原理（讲义对照） -/
/-
定理 29：对每个公式 φ 与每个 M₀，存在传递集 M ⊇ M₀（甚至
M = V_α）反射 φ：M ⊨ φ[a] ⟺ φ[a]（V 中真）。
推论 4：ZF 不可有限公理化（有限多条定理有反射模型，
而"ZF 有模型"不可证）。
Isabelle/ZF 的 Reflection.thy 是官方机器化（ST11）。 -/
