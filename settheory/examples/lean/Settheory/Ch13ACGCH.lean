import Mathlib.SetTheory.Ordinal.Enum

/-!
# 第 13 章 · AC 与 GCH 在 L 中

定理 33：V=L ⟹ AC（L 的典范良序 <_L）。
定理 34：V=L ⟹ GCH（Condensation 论证）。
mathlib 无 L 的构造；本章锚定良序枚举的机制侧面。
-/

/-! ## 一、良序 = 可枚举（<_L 的机制侧影） -/

/-- 良序集的枚举函数：每个元素有其"序位"。
    <_L 的本质：L 的全体元素按（构造层， Gödel 分解）的
    字典序获得枚举。 -/
example (α : Type) (r : α → α → Prop) [IsWellOrder α r] (x : α) :
    ∃ o : Ordinal, o < Ordinal.type r := by
  exact ⟨Ordinal.typein r x, Ordinal.typein_lt_type r x⟩

/-! ## 二、定理 33/34 的证明骨架（讲义） -/
/-
定理 33：在 L 中定义 <_L：
  x <_L y ⟺ x 的（构造层 α，Gödel 分解序 i，分解分量 u,v）的
  字典序 < y 的对应三元组。<_L 良序 L ⟹ L ⊨ AC。

定理 34（引理 13.1 的 Condensation 论证）：
  X ⊆ ω_α 时取可数充分集 M ∋ X, ω_α；
  反射原理选 M；Mostowski 坍缩 M ≅ 传递 N；
  绝对性（引理 13.2）给 N = L_γ（γ 可数，γ < ω_{α+1}）；
  X ∈ N = L_γ。于是 P(ω_α) ⊆ L_{ω_{α+1}}，
  |P(ω_α)| ≤ |L_{ω_{α+1}}| = ℵ_{α+1}。
  Cantor：2^{ℵ_α} ≥ ℵ_{α+1}。合流：2^{ℵ_α} = ℵ_{α+1}。∎

Isabelle/ZF 的 AC_in_L 是定理 33 的官方机器化（ST13）；
GCH 的机器化由讲义与计算通道承载（数值侧影：<_L 的
构造序比较器，见 Julia 通道）。 -/
