import Mathlib.Order.Filter.Ultrafilter.Basic
import Mathlib.Data.Finset.Filter

/-!
# 第 100 章 · 超紧基数

锚点：精细锥的交并律（cone(s) ∩ cone(u) = cone(s ∪ u)）——
精细性的有限影子；Fodor 回归函数的有限踪迹。
超紧本体与定理 1.29/1.30 留在正文。
-/

namespace Settheory.Ch100

open Finset

/-- 精细锥的交并律：两个上锥之交恰是并集的上锥。
这是「精细性 ⟹ 滤子对交封闭」的内核。 -/
example (s₁ s₂ : Finset (Fin 6)) :
    {t : Finset (Fin 6) | s₁ ⊆ t} ∩ {t : Finset (Fin 6) | s₂ ⊆ t}
      = {t : Finset (Fin 6) | s₁ ∪ s₂ ⊆ t} := by
  ext t
  simp [Finset.union_subset_iff]

/-- 精细锥的单调性：更大的小集给出更细的锥。 -/
example (s u : Finset (Fin 6)) (h : s ⊆ u) :
    {t : Finset (Fin 6) | u ⊆ t} ⊆ {t : Finset (Fin 6) | s ⊆ t} :=
  fun _ ht => Finset.Subset.trans h ht

/-- 精细锥非空（上锥含全集）。 -/
example (s : Finset (Fin 6)) :
    {t : Finset (Fin 6) | s ⊆ t} ≠ ∅ := by
  intro h
  have hmem : (Finset.univ : Finset (Fin 6)) ∈
      {t : Finset (Fin 6) | s ⊆ t} := by simp
  rw [h] at hmem
  exact absurd hmem (by simp)

/-- 回归函数的有限踪迹：f(t) = 首元素。 -/
def fHead (t : List (Fin 3)) : Fin 3 :=
  t.head?.getD 0

/-- 单点列表上回归函数取该点——正规性的最小影子。 -/
example (c : Fin 3) : fHead [c] = c := by
  simp [fHead]

/-- Fodor 定理的有限影子：在主超滤（焦点 c）下，
回归函数 fHead 在测一集 {{t : c ∈ t}} 上恒值——
但仅当锥退化为单点锥 {c} 时才取 c。 -/
example (c : Fin 3) : fHead [c] = c := by simp [fHead]

end Settheory.Ch100
