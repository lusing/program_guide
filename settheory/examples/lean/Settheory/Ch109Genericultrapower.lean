import Mathlib.Data.Finset.Basic

/-!
# 第 109 章 · 非荟萃理想与泛型超幂

锚点（有限影子）：
- `Forces`：理想力迫的序——C ≤ D ⟺ C − D ∈ I；
  `forces_refl`/`forces_trans`：自反与传递（理想向下/并闭）；
- `FilterCert` + `los_order`：滤子四公理下的**有限 Łoś**
  （原子公式的良定义性）：代表换元不改变 [f] <_G [g] 的裁决；
- 样本理想 I₀ = {∅, {0}} 与主滤子 G₁：真值集、商关系
  （X ≡ Y ⟺ X△Y ∈ I）与 [Id] 的取值（引理 2.29 的影子）。
本体（定义 2.23–2.26、引理 2.29/2.30、定理 2.18/2.19、
例 2.2–2.4）留在正文。
-/

namespace Settheory.Ch109

open Finset

/-! ## 一、理想力迫的序（正测集代数） -/

/-- 理想力迫 P(I) 的序：C ≤ D ⟺ C − D ∈ I。 -/
abbrev Forces (I : Finset (Finset ℕ)) (C D : Finset ℕ) : Prop :=
  C \ D ∈ I

theorem forces_refl {I : Finset (Finset ℕ)}
    (h0 : ∅ ∈ I) (C : Finset ℕ) : C \ C ∈ I := by
  rw [Finset.sdiff_self]
  exact h0

theorem forces_trans {I : Finset (Finset ℕ)}
    (hdown : ∀ X ∈ I, ∀ Y ⊆ X, Y ∈ I)
    (hun : ∀ X ∈ I, ∀ Y ∈ I, X ∪ Y ∈ I)
    {C D E : Finset ℕ}
    (h1 : C \ D ∈ I) (h2 : D \ E ∈ I) : C \ E ∈ I := by
  apply hdown _ (hun _ h1 _ h2)
  intro x hx
  simp only [Finset.mem_sdiff, Finset.mem_union] at hx ⊢
  obtain ⟨hC, hE⟩ := hx
  by_cases hD : x ∈ D
  · exact Or.inr ⟨hD, hE⟩
  · exact Or.inl ⟨hC, hD⟩

/-! ## 二、滤子四公理与有限 Łoś（原子公式的良定义性） -/

/-- 滤子证书：G 是 U 上的（超）滤子——书 p211 的 (a)–(d)。 -/
structure FilterCert (G : Finset ℕ → Prop) (U : Finset ℕ) : Prop where
  up : ∀ X, G X → X ⊆ U
  top : G U
  inter : ∀ X Y, G X → G Y → G (X ∩ Y)
  mono : ∀ X Y, G X → X ⊆ Y → Y ⊆ U → G Y
  ultra : ∀ X, X ⊆ U → G X ∨ G (U \ X)
  nempty : ¬ G ∅

/-- 有限 Łoś（原子公式的良定义性）：代表换元不改变 < 的裁决——
[f] <_G [g] 由 {a | f a < g a} ∈ G 定义，而等价的代表给同一裁决。 -/
theorem los_order {G : Finset ℕ → Prop} {U : Finset ℕ} (hc : FilterCert G U)
    (f g f' g' : ℕ → ℕ)
    (h1 : G {a ∈ U | f a = f' a})
    (h2 : G {a ∈ U | g a = g' a})
    (h3 : G {a ∈ U | f a < g a}) :
    G {a ∈ U | f' a < g' a} := by
  have hS : G ({a ∈ U | f a = f' a} ∩ {a ∈ U | g a = g' a} ∩ {a ∈ U | f a < g a}) :=
    hc.inter _ _ (hc.inter _ _ h1 h2) h3
  have hsub : ({a ∈ U | f a = f' a} ∩ {a ∈ U | g a = g' a} ∩ {a ∈ U | f a < g a})
      ⊆ {a ∈ U | f' a < g' a} := by
    intro x hx
    simp only [Finset.mem_inter, Finset.mem_filter] at hx ⊢
    obtain ⟨⟨⟨hu, heq1⟩, ⟨_, heq2⟩⟩, ⟨_, hlt⟩⟩ := hx
    refine ⟨hu, ?_⟩
    rw [← heq1, ← heq2]
    exact hlt
  refine hc.mono _ _ hS hsub ?_
  intro x hx
  exact (Finset.mem_filter.mp hx).1

/-! ## 三、样本理想与主滤子（决定性核查） -/

def U₀ : Finset ℕ := {0, 1, 2}

def I₀ : Finset (Finset ℕ) := {{}, {0}}

/-- 主滤子（在 1 处）：泛型超滤子候选。 -/
abbrev G₁ (X : Finset ℕ) : Prop := 1 ∈ X ∧ X ⊆ U₀

theorem filtercert_G₁ : FilterCert G₁ U₀ := by
  constructor
  · intro X hX; exact hX.2
  · show 1 ∈ U₀ ∧ U₀ ⊆ U₀
    exact ⟨by decide, subset_refl _⟩
  · intro X Y hX hY
    show 1 ∈ X ∩ Y ∧ X ∩ Y ⊆ U₀
    refine ⟨?_, subset_trans Finset.inter_subset_left hX.2⟩
    simp only [Finset.mem_inter]
    exact ⟨hX.1, hY.1⟩
  · intro X Y hX hXY hYU
    show 1 ∈ Y ∧ Y ⊆ U₀
    exact ⟨hXY hX.1, hYU⟩
  · intro X hXU
    by_cases h1 : 1 ∈ X
    · exact Or.inl ⟨h1, hXU⟩
    · exact Or.inr ⟨Finset.mem_sdiff.mpr ⟨by decide, h1⟩, Finset.sdiff_subset⟩
  · intro h
    exact absurd h.1 (by decide)

/-- 样本函数（U₀ → ℕ 的表）。 -/
def f₁ : ℕ → ℕ := fun a => if a = 0 then 3 else if a = 1 then 1 else 4
def g₁ : ℕ → ℕ := fun a => if a = 0 then 2 else if a = 1 then 2 else 0

/-- 真值集：{a | f₁ a < g₁ a} = {1}——同一份数据在 G₁ 下裁决为真。 -/
example : {a ∈ U₀ | f₁ a < g₁ a} = {1} := by decide

example : G₁ {a ∈ U₀ | f₁ a < g₁ a} := by decide

/-- 换元样本：f₂ 与 f₁ 只在 G₁-零测点 0 上不同。 -/
def f₂ : ℕ → ℕ := fun a => if a = 0 then 5 else if a = 1 then 1 else 4

/-- 有限 Łoś 的应用：等价代表换元后裁决保持（两边都由 decide 核账）。 -/
example : G₁ {a ∈ U₀ | f₂ a < g₁ a} := by
  have heq : G₁ {a ∈ U₀ | f₁ a = f₂ a} := by decide
  have hid : G₁ {a ∈ U₀ | g₁ a = g₁ a} := by decide
  have hlt : G₁ {a ∈ U₀ | f₁ a < g₁ a} := by decide
  exact los_order filtercert_G₁ f₁ g₁ f₂ g₁ heq hid hlt

/-- 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点。 -/
example : G₁ {a ∈ U₀ | (fun x => x) a = 1} := by decide

/-- 商关系样本：U₀ ≡ {1, 2}（mod I₀），对称差 {0} ∈ I₀。 -/
example : (U₀ \ {1, 2}) ∪ ({1, 2} \ U₀) ∈ I₀ := by decide

/-- 序样本：{1} ≤ {0,1}（差 ∅），U₀ ≰ {0,1}（差 {2} 为正）。 -/
example : Forces I₀ {1} {0, 1} := by decide
example : ¬ Forces I₀ U₀ {0, 1} := by decide

end Settheory.Ch109
