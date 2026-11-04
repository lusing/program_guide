import Mathlib.Tactic
import Mathlib.SetTheory.Cardinal.SchroederBernstein
import Mathlib.Data.Fintype.Card

/-!
# 第 130 章 等势与可数（Lean）

康托-伯恩斯坦定理、鸽笼原理、可数性的 typeclass 形态。
-/

/-! ## 康托-伯恩斯坦（书 3.3.3） -/

/- 两个方向的单射合出一个双射——mathlib 的证明与书的"交替序列"
构造同源（正式版在 `Function.Embedding.antisymm`：单射序的反对称）。 -/
#check @Function.Embedding.schroeder_bernstein

example {α β : Type} (f : α → β) (g : β → α)
    (hf : Function.Injective f) (hg : Function.Injective g) :
    ∃ h : α → β, Function.Bijective h :=
  Function.Embedding.schroeder_bernstein hf hg

/-! ## 鸽笼原理（书 3.3.5）：有限集上单射即满射 -/

example (α : Type) [Fintype α] (f : α → α) (h : Function.Injective f) :
    Function.Surjective f :=
  Finite.injective_iff_surjective.mp h

/-- 鸽笼的直接见证：5 到 2 的常值映射不单——两点同像。 -/
example : ¬ Function.Injective (fun _ : Fin 5 => (0 : Fin 2)) := by
  intro h
  have h01 : (0 : Fin 5) = 1 := h rfl
  exact absurd h01 (by decide)

/-! ## 可数性：书 3.3.4 的 typeclass 形态 -/

/-- ℕ×ℕ 可数（书 3.3.9 的 2^k(2n+1)−1 配对在库里以 instance 形态存在）。 -/
example : Countable (ℕ × ℕ) := by infer_instance

/-- ℚ 可数（书 3.4-3.5 的构造完成后的红利）。 -/
example : Countable ℚ := by infer_instance

/-- 可数集的并可数（书 3.3.7/3.3.10(1)）。 -/
example (s t : Set ℕ) (hs : s.Countable) (ht : t.Countable) :
    (s ∪ t).Countable := hs.union ht

/-- 可数集的像可数（3.3.10 的常用推论）。 -/
example (f : ℕ → ℕ) (s : Set ℕ) (hs : s.Countable) : (f '' s).Countable :=
  hs.image f

/-! ## Cantor 定理的预演（第 132 章主角） -/

/- 没有 α → Set α 型的满射——第 132 章对角线论证的基数版。 -/
#check @Cardinal.cantor'
