import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Sort

/-!
# 第 110 章 · NS 峭壁、饱和与投影光影原理

锚点（有限影子，沿 109 章宇宙 U₀={0,1,2}、I₀={∅,{0}}）：
- `Proj`：投影 π(X)=X∖{0}——光影原理 N ↦ N∩ω₁ 的有限影子
  （坐标 0 是被理想抹平的「非 ω₁ 部分」）；
- `mem_I₀_iff_proj`：核刻画 X∈I₀ ⟺ π(X)=∅——理想恰是投影的核，
  商代数 P(U₀)/I₀ ≅ P({1,2}) 的机制件；
- `incompat_proj_disjoint`：模 I 不相容 ⟹ 投影不交；
- `antichain_bound`：正测集的模 I 反链至多 2——有限饱和界
  （sat(I₀)=3），Gitik-Shelah 方向（NS_κ 不饱和）的对照件。
本体（定理 2.20/2.21 Mitchell-Magidor、定义 2.27-2.36、
定理 2.22-2.34 FMS-Woodin-冯-Jech）留在正文。
-/

namespace Settheory.Ch110

open Finset

/-! ## 一、样本宇宙（沿 109 章）与投影 -/

def U₀ : Finset ℕ := {0, 1, 2}

def I₀ : Finset (Finset ℕ) := {{}, {0}}

abbrev Pos (X : Finset ℕ) : Prop := X ∉ I₀

/-- 投影：抹掉坐标 0（被理想吞掉的坐标）——N ↦ N∩ω₁ 的影子。 -/
def Proj (X : Finset ℕ) : Finset ℕ := X \ {0}

/-! ## 二、π 与交交换 -/

theorem proj_inter (X Y : Finset ℕ) :
    Proj (X ∩ Y) = Proj X ∩ Proj Y := by
  ext a
  simp only [Proj, mem_sdiff, mem_inter, mem_singleton]
  constructor
  · rintro ⟨⟨h1, h2⟩, h3⟩
    exact ⟨⟨h1, h3⟩, h2, h3⟩
  · rintro ⟨⟨h1, h3⟩, h2, _⟩
    exact ⟨⟨h1, h2⟩, h3⟩

/-! ## 三、核刻画：理想 = 投影的核 -/

theorem mem_I₀_iff_proj (X : Finset ℕ) :
    X ∈ I₀ ↔ Proj X = ∅ := by
  constructor
  · intro h
    simp only [I₀, mem_insert, mem_singleton] at h
    rcases h with rfl | rfl
    · simp [Proj]
    · simp [Proj]
  · intro h
    have hsub : X ⊆ {0} := Finset.sdiff_eq_empty_iff_subset.mp h
    rcases Finset.subset_singleton_iff.mp hsub with rfl | rfl
    · simp [I₀]
    · simp [I₀]

/-! ## 四、不相容 ⟹ 投影不交；正测 ⟹ 投影非空 -/

theorem incompat_proj_disjoint {X Y : Finset ℕ}
    (hXY : X ∩ Y ∈ I₀) : Proj X ∩ Proj Y = ∅ := by
  have h1 : Proj (X ∩ Y) = ∅ := (mem_I₀_iff_proj _).mp hXY
  rw [proj_inter] at h1
  exact h1

theorem pos_proj_nonempty {X : Finset ℕ} (hX : Pos X) :
    Proj X ≠ ∅ := by
  intro h
  exact hX ((mem_I₀_iff_proj _).mpr h)

/-! ## 五、有限饱和界：反链至多 2 -/

/-- 正测集的模 I 反链至多 2 个——商代数只有两个原子，
投影把它们送到 {1,2} 的互异元素上（有限饱和界 sat(I₀)=3）。 -/
theorem antichain_bound (A : Finset (Finset ℕ))
    (hpos : ∀ X ∈ A, Pos X)
    (hsub : ∀ X ∈ A, X ⊆ U₀)
    (hincomp : ∀ X ∈ A, ∀ Y ∈ A, X ≠ Y → X ∩ Y ∈ I₀) :
    A.card ≤ 2 := by
  classical
  have hne : ∀ X ∈ A, (Proj X).Nonempty := fun X hX =>
    Finset.nonempty_iff_ne_empty.mpr (pos_proj_nonempty (hpos X hX))
  have hpsub : ∀ X ∈ A, Proj X ⊆ {1, 2} := by
    intro X hX a ha
    have hd : a ∈ X ∧ a ∉ ({0} : Finset ℕ) := Finset.mem_sdiff.mp ha
    have haU : a ∈ U₀ := hsub X hX hd.1
    simp only [U₀, mem_insert, mem_singleton] at haU
    rcases haU with rfl | rfl | rfl
    · exact absurd (Finset.mem_singleton.mpr rfl) hd.2
    · decide
    · decide
  have hkey : ∀ (X : Finset ℕ) (hX : X ∈ A) (Y : Finset ℕ) (hY : Y ∈ A),
      (Proj X).min' (hne X hX) = (Proj Y).min' (hne Y hY) → X = Y := by
    intro X hX Y hY heq
    by_cases hne' : X = Y
    · exact hne'
    have hm : (Proj X).min' (hne X hX) ∈ Proj X ∩ Proj Y := by
      rw [Finset.mem_inter]
      exact ⟨(Proj X).min'_mem (hne X hX),
        by rw [heq]; exact (Proj Y).min'_mem (hne Y hY)⟩
    have hd : Proj X ∩ Proj Y = ∅ :=
      incompat_proj_disjoint (hincomp X hX Y hY hne')
    rw [hd] at hm
    exact absurd hm (by simp)
  let e : ↥A ↪ ↥({1, 2} : Finset ℕ) :=
    ⟨fun a => ⟨(Proj (a : Finset ℕ)).min' (hne _ a.2),
        Finset.mem_of_subset (hpsub _ a.2)
          ((Proj (a : Finset ℕ)).min'_mem (hne _ a.2))⟩,
      fun a b hab => by
        have := hkey (a : Finset ℕ) a.2 (b : Finset ℕ) b.2 (congrArg Subtype.val hab)
        exact Subtype.ext this⟩
  have hle := Fintype.card_le_of_injective e e.inj'
  simpa using hle

/-! ## 六、样本账（决定性核查） -/

/-- 最大反链样本：{{1},{2}}——模 I 不相容，规模恰为界 2。 -/
example : ({{1}, {2}} : Finset (Finset ℕ)).card = 2 := by decide

example : ∀ X ∈ ({{1}, {2}} : Finset (Finset ℕ)), Pos X ∧ X ⊆ U₀ := by decide

example : ∀ X ∈ ({{1}, {2}} : Finset (Finset ℕ)), ∀ Y ∈ ({{1}, {2}} : Finset (Finset ℕ)),
    X ≠ Y → X ∩ Y ∈ I₀ := by decide

/-- 三个正测集必有相容对（鸽笼的反面核查）。 -/
example : ¬ ∃ A : Finset (Finset ℕ), A.card = 3 ∧
    (∀ X ∈ A, Pos X ∧ X ⊆ U₀) ∧
    (∀ X ∈ A, ∀ Y ∈ A, X ≠ Y → X ∩ Y ∈ I₀) := by
  intro h
  obtain ⟨A, hcard, hpos, hincomp⟩ := h
  have := antichain_bound A (fun X hX => (hpos X hX).1)
    (fun X hX => (hpos X hX).2) hincomp
  omega

/-- 投影样本：π(U₀)={1,2}、π({0,1})={1}、π({0})=∅。 -/
example : Proj U₀ = {1, 2} := by decide
example : Proj {0, 1} = {1} := by decide
example : Proj {0} = ∅ := by decide

/-- 提升样本：每个非空 Y ⊆ {1,2} 都有正测原像。 -/
example : Proj {1} = {1} ∧ Proj {2} = {2} ∧ Proj U₀ = {1, 2} := by decide

end Settheory.Ch110
