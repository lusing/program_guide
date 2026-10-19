import Mathlib.MeasureTheory.OuterMeasure.Basic
import Mathlib.MeasureTheory.Measure.NullMeasurable

/-!
# 第 04 章 外测度与测度的扩张（Lean）

严书 §1.4。手工定义 Carathéodory 可测性谓词并证明：空集、全集可测，
可测集对补封闭，且对二元并封闭——这正是"可测集全体构成 σ-代数"
证明中不能用一次归纳带过的核心部分。

mathlib 侧的对应物：`OuterMeasure.caratheodory`（可测集全体，本身是
一个 MeasurableSpace）、`OuterMeasure.toMeasure`（把外测度限制成测度，
见 MeasureSpace.lean:779）、`Measure.completion`（完备化，
NullMeasurable.lean:454）。
-/

open MeasureTheory

variable {α : Type*} {m : OuterMeasure α}

/-- Carathéodory 可测性：s 把任何集合"切"成两片时测度可加。 -/
def IsCaratheodoryFor (m : OuterMeasure α) (s : Set α) : Prop :=
  ∀ t, m t = m (t ∩ s) + m (t \ s)

/-- 空集可测：t ∩ ∅ 与 t \ ∅ 退化。 -/
example : IsCaratheodoryFor m ∅ := by
  intro t
  simp

/-- 全集可测。 -/
example : IsCaratheodoryFor m Set.univ := by
  intro t
  simp

/-- 可测集的补可测：t ∩ sᶜ = t \ s 与 t \ sᶜ = t ∩ s 只是同一等式的
两个加项交换位置。 -/
theorem caratheodory_compl {s : Set α} (hs : IsCaratheodoryFor m s) :
    IsCaratheodoryFor m sᶜ := by
  intro t
  have h1 : t ∩ sᶜ = t \ s := by ext x; simp
  have h2 : t \ sᶜ = t ∩ s := by ext x; simp
  rw [h1, h2, hs t]
  ring

/-- 可测集对二元并封闭：四分分解 u = (u∩s) ⊎ (u\s∩t) ⊎ (u\s\t) 的
可加性由 s 与 t 各自的 Carathéodory 等式精确给出。 -/
theorem caratheodory_union {s t : Set α} (hs : IsCaratheodoryFor m s)
    (ht : IsCaratheodoryFor m t) : IsCaratheodoryFor m (s ∪ t) := by
  intro u
  -- 用 s 的可测性切 u ∩ (s ∪ t)
  have key1 : m (u ∩ (s ∪ t)) = m (u ∩ s) + m (u \ s ∩ t) := by
    have h := hs (u ∩ (s ∪ t))
    have e1 : (u ∩ (s ∪ t)) ∩ s = u ∩ s := by
      ext x; simp only [Set.mem_inter_iff, Set.mem_union]; tauto
    have e2 : (u ∩ (s ∪ t)) \ s = u \ s ∩ t := by
      ext x; simp only [Set.mem_inter_iff, Set.mem_union, Set.mem_sdiff]; tauto
    rw [h, e1, e2]
  -- 用 s 切 u，再用 t 切 u \ s
  have key2 : m u = m (u ∩ s) + m (u \ s ∩ t) + m ((u \ s) \ t) := by
    have h1 := hs u
    have h2 := ht (u \ s)
    rw [h1, h2]
    ring
  -- u \ (s ∪ t) = (u \ s) \ t
  have key3 : u \ (s ∪ t) = (u \ s) \ t := by
    ext x; simp only [Set.mem_sdiff, Set.mem_union]; tauto
  rw [key1, key3, key2]
