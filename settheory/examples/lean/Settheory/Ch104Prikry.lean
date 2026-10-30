import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card

/-!
# 第 104 章 · Prikry 力迫

锚点（有限影子）：
- `stem`：严格递增的有限序列（Pairwise (·<·)）；
- `isPrefix`：stem 之间的初始段序（t ++ r = s）——自反/传递；
- `ple`：纯延长（同一 stem 上 A ⊆ B）——自反/传递
  （「不动 stem」的序结构，Task 19 Step 2 指定件）；
- `prikryLe`：定义 2.6 的全序 (s,A) ≤ (t,B)
  （t 是 s 的初始段 ∧ A ⊆ B ∧ 新增元素 ⊆ B）；
- `fact231`：事实 2.3.1 的 (s,A∩B) ≤ (s,A) ∧ ≤ (s,B)。
本体（引理 2.4/2.5 判定性、定理 2.6/2.7/2.8）留在正文。
-/

namespace Settheory.Ch104

open Finset

/-- stem：严格递增的有限序列。 -/
def Stem (l : List ℕ) : Prop := l.Pairwise (· < ·)

/-- 初始段序：t 是 s 的前段。 -/
def IsPrefix (t s : List ℕ) : Prop := ∃ r, t ++ r = s

theorem isPrefix_refl (s : List ℕ) : IsPrefix s s :=
  ⟨[], by simp⟩

theorem isPrefix_trans {t s u : List ℕ}
    (h₁ : IsPrefix t s) (h₂ : IsPrefix s u) : IsPrefix t u := by
  obtain ⟨r₁, rfl⟩ := h₁
  obtain ⟨r₂, rfl⟩ := h₂
  exact ⟨r₁ ++ r₂, by simp⟩

/-- Prikry 条件：stem + 测度一集（有限影子：Finset）。 -/
structure PCond where
  stem : List ℕ
  big : Finset ℕ

/-- 纯延长：不动 stem，只收窄测度一集。 -/
def ple (p q : PCond) : Prop :=
  p.stem = q.stem ∧ p.big ⊆ q.big

theorem ple_refl (p : PCond) : ple p p :=
  ⟨rfl, subset_refl _⟩

theorem ple_trans {p q r : PCond} (h₁ : ple p q) (h₂ : ple q r) :
    ple p r :=
  ⟨h₁.1.trans h₂.1, h₁.2.trans h₂.2⟩

/-- 定义 2.6 全序：(s,A) ≤ (t,B) ⟺ t 初始段于 s ∧ A ⊆ B
∧ s∖t 的元素都在 B 中。 -/
def prikryLe (p q : PCond) : Prop :=
  IsPrefix q.stem p.stem ∧ p.big ⊆ q.big ∧
    ∀ x ∈ p.stem.drop q.stem.length, x ∈ q.big

theorem prikryLe_refl (p : PCond) : prikryLe p p := by
  refine ⟨isPrefix_refl _, subset_refl _, ?_⟩
  simp

/-- 事实 2.3.1（前半）：(s,A∩B) 同时纯延长 (s,A) 与 (s,B)。 -/
theorem fact231 (s : List ℕ) (A B : Finset ℕ) :
    ple ⟨s, A ∩ B⟩ ⟨s, A⟩ ∧ ple ⟨s, A ∩ B⟩ ⟨s, B⟩ :=
  ⟨⟨rfl, Finset.inter_subset_left⟩, ⟨rfl, Finset.inter_subset_right⟩⟩

/-- 样本：stem [2,5] 是 [2,5,7] 的初始段。 -/
example : IsPrefix [2, 5] [2, 5, 7] :=
  ⟨[7], by simp⟩

/-- 冲突 stem：[2,5] 与 [2,6] 互非初始段（事实 2.3.1 的
不相容来源只在 stem）。 -/
example : ¬ IsPrefix [2, 6] [2, 5, 7] := by
  intro ⟨r, hr⟩
  simp only [List.cons_append] at hr
  cases hr

/-- 相容判定：同 stem 的两条件以 stem 为公共前段
（可比较性的最小样本）。 -/
example (A B : Finset ℕ) : prikryLe ⟨[2, 5], A⟩ ⟨[2, 5], B⟩ ↔ A ⊆ B := by
  constructor
  · intro h; exact h.2.1
  · intro h
    exact ⟨isPrefix_refl _, h, by simp⟩

end Settheory.Ch104
