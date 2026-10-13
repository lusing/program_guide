import Mathlib.SetTheory.ZFC.PSet
import Mathlib.Data.Set.Basic

/-!
# 第 01 章 · 公理：从 Cantor 到 Russell 悖论

ZFC 的公理在 Lean 的 Type 世界里大多"降格"为构造事实；
在 mathlib 的 PSet（预集合）世界里则以定理形态重现公理的内容。
-/

/-! ## 一、Type 世界：公理变定理 -/

section TypeWorld

variable {α : Type}

/-- **配对公理** → Type 世界的构造：{a, b} 直接存在。 -/
example (a b : α) : ∃ c : Set α, ∀ x, x ∈ c ↔ x = a ∨ x = b :=
  ⟨{a, b}, by simp⟩

/-- **并公理** → ⋃₀ X 直接存在（成员条件按定义成立）。 -/
example (X : Set (Set α)) : ∃ c : Set α, ∀ u, u ∈ c ↔ ∃ z, z ∈ X ∧ u ∈ z :=
  ⟨⋃₀ X, fun _ => Iff.rfl⟩

/-- **分离模式** → 对任何谓词 p，{x ∈ X | p x} 存在（setOf 构造）。 -/
example (p : α → Prop) (X : Set α) : ∃ Y : Set α, ∀ u, u ∈ Y ↔ u ∈ X ∧ p u :=
  ⟨{x ∈ X | p x}, fun _ => by simp⟩

/-- **幂集公理** → X.powerset 存在。 -/
example (X : Set α) : ∃ Y : Set (Set α), ∀ u, u ∈ Y ↔ u ⊆ X :=
  ⟨X.powerset, fun u => Set.mem_powerset_iff u X⟩

/-- **无穷公理** → ℕ 是归纳集：含 0 且对 succ 封闭。 -/
example : ∃ S : Set ℕ, (0 : ℕ) ∈ S ∧ ∀ n ∈ S, n + 1 ∈ S :=
  ⟨Set.univ, trivial, fun _ _ => trivial⟩

end TypeWorld

/-! ## 二、PSet 世界：公理的定理形态

mathlib 的 `PSet`（预集合）用"索引型 + 元素函数"表示集合：
`mk α A` 是"以 α 为下标集、第 i 个元素是 A i"的集合。
外延性对 PSet 不是免费的——`Equiv` 是"元素互相嵌入"的
弱形式，外延公理的内容变成了 `Mem.ext`。 -/

open PSet

/-- **外延公理** 的 PSet 形态：元素相同则等价。 -/
example {x y : PSet} (h : ∀ w, w ∈ x ↔ w ∈ y) : PSet.Equiv x y :=
  PSet.Mem.ext h

/-- **幂集** 的 PSet 形态：`powerset x` 的成员恰是子集。 -/
example (x : PSet) {w : PSet} : w ∈ x.powerset ↔ w ⊆ x :=
  PSet.mem_powerset

/-- **分离** 的 PSet 形态——注意 `mem_sep` 带良定义前提：
谓词 p 必须尊重 Equiv（证明相关性世界的"分离要收费"）。 -/
example (p : PSet → Prop) (hp : ∀ x y, PSet.Equiv x y → p x → p y)
    (x : PSet) {w : PSet} : w ∈ x.sep p ↔ w ∈ x ∧ p w :=
  PSet.mem_sep hp

/-- 外延性的直接应用：元素互为彼此的，两集等价。 -/
example {x y : PSet} (h₁ : x ⊆ y) (h₂ : y ⊆ x) : PSet.Equiv x y :=
  (PSet.Equiv.ext _ _).2 ⟨h₁, h₂⟩
