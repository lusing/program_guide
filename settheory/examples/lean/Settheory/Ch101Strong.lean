import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Image
import Mathlib.Order.Interval.Finset.Nat

/-!
# 第 101 章 · 强基数与超强基数

锚点（有限影子）：
- 位编码有限累积层次 `level`：|V₁|=1、|V₂|=2、|V₃|=4、|V₄|=16
  （beth 递归在有限层的精确复现）与层包含链；
- 单射保交 `Finset.image_inter`——导出张子记账
  「X∈E_a ⟺ a∈j(X)」中超滤子对交封闭的内核；
- `Wit` 见证结构与 `not_strong_finite`：有限捕获集上
  「对所有 λ 都有见证」恒假——不把有限矩阵当强度证明。
张子本体（定义 1.19-1.23、定理 1.31-1.35）留在正文。
-/

namespace Settheory.Ch101

open Finset

section FiniteV

/-- 位编码成员表：x 的元素 = 使 x 的第 i 位为 1 的 i。
宇宙取 Fin 16（编码 0..15），足以承载前四层。 -/
def elems (x : Fin 16) : Finset (Fin 16) :=
  Finset.univ.filter (fun i => x.val.testBit i.val)

/-- 有限累积层次：level 0 = ∅，level (n+1) = {x : elems x ⊆ level n}。
这就是 V_{n+1} = P(V_n) 的位编码影子。 -/
def level : ℕ → Finset (Fin 16)
  | 0 => ∅
  | n + 1 => Finset.univ.filter (fun x => elems x ⊆ level n)

/-- 第一层恰为 {∅}（编码 0）。 -/
theorem level_one : level 1 = {0} := by decide

/-- 第二层 = {∅, {∅}}（编码 0, 1）。 -/
theorem level_two : level 2 = {0, 1} := by decide

/-- 第三层有四个元素——V₃ = P(V₂)。 -/
theorem level_three : level 3 = {0, 1, 2, 3} := by decide

/-- 第四层填满整个 16 编码宇宙——|V₄| = 2^4 = 16。 -/
theorem level_four : level 4 = Finset.univ := by decide

/-- beth 尺寸链的有限复现：1, 2, 4, 16。 -/
theorem level_card_chain :
    (level 1).card = 1 ∧ (level 2).card = 2 ∧
    (level 3).card = 4 ∧ (level 4).card = 16 := by decide

/-- 层包含链 V_n ⊆ V_{n+1} 的前四环。 -/
theorem level_mono_chain :
    level 0 ⊆ level 1 ∧ level 1 ⊆ level 2 ∧
    level 2 ⊆ level 3 ∧ level 3 ⊆ level 4 := by decide

end FiniteV

section DerivedBookkeeping

/-- 导出记账内核：单射保持交。
张子公理 (a) 中「E_a 是超滤子」的对交封闭部分
正是 j 单射 + j``(X∩Y) = j``X ∩ j``Y。 -/
example (j : ℕ → ℕ) (hj : Function.Injective j) (X Y : Finset ℕ) :
    Finset.image j (X ∩ Y) = Finset.image j X ∩ Finset.image j Y :=
  Finset.image_inter X Y hj

/-- 单条目记账：a ∈ j``(X∩Y) ⟺ a∈j``X ∧ a∈j``Y——
导出族 {X : a ∈ j``X} 对交封闭的直接形式。 -/
example (j : ℕ → ℕ) (hj : Function.Injective j) (a : ℕ) (X Y : Finset ℕ)
    (hX : a ∈ Finset.image j X) (hY : a ∈ Finset.image j Y) :
    a ∈ Finset.image j (X ∩ Y) := by
  rw [Finset.image_inter X Y hj]
  exact mem_inter.2 ⟨hX, hY⟩

end DerivedBookkeeping

section Witness

/-- 有限见证：临界点、j(κ)、目标模型捕获的秩层号集合。 -/
structure Wit where
  crit : ℕ
  jk : ℕ
  captured : Finset ℕ

/-- λ-强见证条款：j(κ) > λ 且第 λ 层被捕获。 -/
def Wit.lamStrong (w : Wit) (l : ℕ) : Prop :=
  w.crit ≤ l ∧ l < w.jk ∧ l ∈ w.captured

/-- 超强见证条款：第 j(κ) 层被捕获（V_{j(κ)} ⊆ M 的影子）。 -/
def Wit.superstrong (w : Wit) : Prop :=
  w.jk ∈ w.captured

/-- 强见证条款：对所有 λ ≥ κ 都 λ-强。 -/
def Wit.isStrong (w : Wit) : Prop :=
  ∀ l ≥ w.crit, w.lamStrong l

/-- 有限捕获集不可能承载「对所有 λ 的见证」——
鸽笼：captured 有限而 {l : l ≥ crit} 无穷。 -/
theorem Wit.not_strong_finite (w : Wit) : ¬ w.isStrong := by
  intro hstr
  have hsub : Finset.Ico w.crit (w.crit + w.captured.card + 1) ⊆ w.captured := by
    intro l hl
    simp only [Finset.mem_Ico] at hl
    exact (hstr l (by omega)).2.2
  have hcard : (Finset.Ico w.crit (w.crit + w.captured.card + 1)).card ≤
      w.captured.card := Finset.card_le_card hsub
  rw [Nat.card_Ico w.crit (w.crit + w.captured.card + 1)] at hcard
  omega

/-- 单 λ 见证可成：临界 2、j(κ)=5、捕获 {3} 是 λ=3 的强见证。 -/
example : Wit.lamStrong { crit := 2, jk := 5, captured := {3} } 3 := by
  simp [Wit.lamStrong]

/-- 同一见证不是 λ=4 的强见证（j(κ) ≤ 4 一款失败）。 -/
example : ¬ Wit.lamStrong { crit := 2, jk := 5, captured := {3} } 4 := by
  simp [Wit.lamStrong]

/-- 该见证也非超强（j(κ)=5 未被捕获）。 -/
example : ¬ Wit.superstrong { crit := 2, jk := 5, captured := {3} } := by
  simp [Wit.superstrong]

/-- 超强见证样本：临界 2、j(κ)=4、捕获 {4}。 -/
example : Wit.superstrong { crit := 2, jk := 4, captured := {4} } := by
  simp [Wit.superstrong]

end Witness

end Settheory.Ch101
