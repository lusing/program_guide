import Mathlib

/-!
# 第 95 章 · 0# 与 Silver 不可辨别元

不可辨别元的有限框架：封闭律（子集仍是不可辨别元）、保序平移不改变
取值（平移嵌入无歧义性的有限种子），以及 R(3,3)=6 的穷举见证
（定理 1.14 拉姆齐供给的有限前身）。0# 本体是无限对象，不在机器范围内。
-/

namespace Settheory.Ch95

/-- 递增元组：表内每个位置都小于所有靠后的元素。 -/
def Inc {α : Type*} [LT α] (t : List α) : Prop := t.Pairwise (· < ·)

/-- 有限结构的染色：每个「表达式代码」φ 给每个元组一个布尔值。 -/
abbrev Coloring (α Φ : Type*) := Φ → List α → Bool

/-- s 是（关于 f 的）不可辨别元列表：s 自身递增，且 s 中任何两个
等长的递增元组在每个表达式下取值相同。 -/
def IsIndiscernible {α : Type*} [LinearOrder α] {Φ : Type*}
    (f : Coloring α Φ) (s : List α) : Prop :=
  Inc s ∧ ∀ φ {t u : List α}, Inc t → Inc u → t.length = u.length →
    (∀ x ∈ t, x ∈ s) → (∀ x ∈ u, x ∈ s) → f φ t = f φ u

/-- 保序映射保持递增性。 -/
theorem Inc.map {α β : Type*} [LT α] [LT β] {σ : α → β}
    (hmono : ∀ a b, a < b → σ a < σ b) {t : List α} (h : Inc t) :
    Inc (t.map σ) := by
  induction t with
  | nil => exact List.Pairwise.nil
  | cons a t ih =>
      rw [List.map_cons]
      show List.Pairwise (· < ·) (σ a :: List.map σ t)
      rw [List.pairwise_cons]
      refine ⟨fun b hb => ?_, ih h.tail⟩
      rcases List.mem_map.mp hb with ⟨c, hc, rfl⟩
      exact hmono _ _ (List.rel_of_pairwise_cons h hc)

/-- 封闭律：不可辨别元集合的（递增）子列表仍是不可辨别元集合。 -/
theorem IsIndiscernible.sublist {α : Type*} [LinearOrder α] {Φ : Type*}
    {f : Coloring α Φ} {s t : List α} (h : IsIndiscernible f s)
    (ht : Inc t) (hsub : ∀ x ∈ t, x ∈ s) :
    IsIndiscernible f t :=
  ⟨ht, fun φ (_u _v : List α) hu hv hlen h1 h2 =>
    h.2 φ hu hv hlen (fun x hx => hsub x (h1 x hx))
      (fun x hx => hsub x (h2 x hx))⟩

/-- 平移不变性：保序自嵌入 σ 下，任何递增元组的取值不变。
这是「σ:I→I 诱导 j 且无歧义」（定理 1.17 (3)→(1)）的有限种子。 -/
theorem IsIndiscernible.shift {α : Type*} [LinearOrder α] {Φ : Type*}
    {f : Coloring α Φ} {s : List α} (h : IsIndiscernible f s)
    (φ : Φ) (σ : α → α) (hmono : ∀ a b, a < b → σ a < σ b)
    (hmap : ∀ x ∈ s, σ x ∈ s) {t : List α}
    (ht : Inc t) (hsub : ∀ x ∈ t, x ∈ s) :
    f φ (t.map σ) = f φ t :=
  h.2 φ (Inc.map hmono ht) ht (by simp)
    (fun x hx => by
      rcases List.mem_map.mp hx with ⟨c, hc, rfl⟩
      exact hmap c (hsub c hc)) hsub

/-- R(3,3) ≤ 6：六点上任何对染色都有三元齐一集，即单表达式语言下的
三元不可辨别集。这是定理 1.14 的有限前身，由 native_decide 穷举
2^15 种染色见证。 -/
example : ∀ f : Sym2 (Fin 6) → Bool, ∃ x y z : Fin 6,
    x < y ∧ y < z ∧
    f (Sym2.mk x y) = f (Sym2.mk x z) ∧
    f (Sym2.mk x z) = f (Sym2.mk y z) := by
  native_decide

/-- 五边形染色（模 5 相邻为红、对角为蓝）没有齐一三元组：6 不能降为 5。 -/
def red5 (x y : ℕ) : Bool :=
  (x + 5 - y) % 5 == 1 || (x + 5 - y) % 5 == 4

example : ¬ ∃ x y z : Fin 5,
    x.val < y.val ∧ y.val < z.val ∧
    (red5 x.val y.val = red5 x.val z.val ∧
     red5 x.val z.val = red5 y.val z.val) := by
  decide

end Settheory.Ch95
