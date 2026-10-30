import Mathlib.Data.List.Basic
import Mathlib.Data.Finset.Basic

/-!
# 第 107 章 · 恰当力迫

锚点（有限影子）：
- `Antichain`：M 内已知极大冲突子集（两两不相容）；
- `PredenseBelow`：A 在 q 之下准稠密——一切 r ≤ q 与 A
  中某元素相容（定义 2.21 主条件证书的内核）；
- `GenericCond`：(M,P)-泛型条件证书——对每个已知极大
  冲突子集都准稠密；
- `generic_strengthen`：更强的条件保持证书（Task 22
  Step 2 指定件：条件复合保持证书）；
- 三点样本宇宙：根 0 分叉到终端 1、2——反链 {1,2} 是
  M={0,1,2} 内唯一极大冲突子集，0 与 1 都是泛型条件。
本体（命题 2.1、引理 2.22-2.24、定理 2.13/2.14）留在正文。
-/

namespace Settheory.Ch107

open Finset

/-- 相容：两条件有公共延展。 -/
def Compat (ext : ℕ → Finset ℕ) (r p : ℕ) : Prop :=
  ∃ s, s ∈ ext r ∧ s ∈ ext p

/-- 冲突子集：两两不相容。 -/
def Antichain (ext : ℕ → Finset ℕ) (A : Finset ℕ) : Prop :=
  ∀ p ∈ A, ∀ q ∈ A, p ≠ q → ¬ Compat ext p q

/-- A 在 q 之下准稠密：一切 r ≤ q（r 延展 q）与 A 中
某元素相容。 -/
def PredenseBelow (ext : ℕ → Finset ℕ) (A : Finset ℕ) (q : ℕ) : Prop :=
  ∀ r ∈ ext q, ∃ p ∈ A, Compat ext r p

/-- (M,P)-泛型条件证书：对 M 的每个已知极大冲突子集
都准稠密（定义 2.21）。 -/
def GenericCond (ext : ℕ → Finset ℕ) (𝒜 : Finset (Finset ℕ)) (q : ℕ) : Prop :=
  ∀ A ∈ 𝒜, PredenseBelow ext A q

/-- 更强的条件保持证书（条件复合保持证书）：q' 延展 q
（q' 的一切延展也是 q 的延展）⟹ q 的证书下放给 q'。 -/
theorem generic_strengthen {ext : ℕ → Finset ℕ}
    {𝒜 : Finset (Finset ℕ)} {q q' : ℕ}
    (hsub : ext q' ⊆ ext q)
    (h : GenericCond ext 𝒜 q) : GenericCond ext 𝒜 q' := by
  intro A hA r hr'
  exact h A hA r (hsub hr')

/-- 样本宇宙：根 0 分叉到终端 1、2（0 可延展到 0/1/2，
1、2 各自终端）。 -/
def extT : ℕ → Finset ℕ
  | 0 => {0, 1, 2}
  | 1 => {1}
  | 2 => {2}
  | _ => ∅

theorem extT_mono_10 : extT 1 ⊆ extT 0 := by decide
theorem extT_mono_20 : extT 2 ⊆ extT 0 := by decide

theorem compat_10 : Compat extT 0 1 := ⟨1, by decide, by decide⟩
theorem compat_02 : Compat extT 0 2 := ⟨2, by decide, by decide⟩
theorem compat_11 : Compat extT 1 1 := ⟨1, by decide, by decide⟩
theorem compat_22 : Compat extT 2 2 := ⟨2, by decide, by decide⟩

/-- {1,2} 是反链（终端 1 与 2 不相容）。 -/
theorem antichain_12 : Antichain extT {1, 2} := by
  intro p hp q hq hpq hcp
  simp only [mem_insert, mem_singleton] at hp hq
  rcases hp with rfl | rfl <;> rcases hq with rfl | rfl
  · exact hpq rfl
  · obtain ⟨s, hs, hs'⟩ := hcp
    simp only [extT, mem_singleton] at hs hs'
    omega
  · obtain ⟨s, hs, hs'⟩ := hcp
    simp only [extT, mem_singleton] at hs hs'
    omega
  · exact hpq rfl

/-- {1,2} 在 q=0 之下准稠密。 -/
theorem predense_12_0 : PredenseBelow extT {1, 2} 0 := by
  intro r hr
  simp only [extT, mem_insert, mem_singleton] at hr
  rcases hr with rfl | rfl | rfl
  · exact ⟨1, by decide, compat_10⟩
  · exact ⟨1, by decide, compat_11⟩
  · exact ⟨2, by decide, compat_22⟩


/-- 0 是 (M,P)-泛型条件。 -/
theorem generic_0 : GenericCond extT {{1, 2}} 0 := by
  intro A hA
  simp only [mem_singleton] at hA
  rw [hA]
  exact predense_12_0

/-- 证书下放：1（强于 0）也是泛型条件。 -/
example : GenericCond extT {{1, 2}} 1 :=
  generic_strengthen extT_mono_10 generic_0

/-- 2 同样继承。 -/
example : GenericCond extT {{1, 2}} 2 :=
  generic_strengthen extT_mono_20 generic_0

end Settheory.Ch107
