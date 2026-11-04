import Mathlib.Tactic

/-!
# 第 137 章 选择公理（Lean）

Zorn 引理的 mathlib 形态（注意：根命名空间，且需要显式传递性）、
AC 在 Lean 逻辑地基中的位置（Classical.choice 与排中律）、以及
"有限选择不需要 AC"的构造性对照。
-/

/-! ## Zorn 引理（书 4.6.2(3)） -/

/- 若偏序的每个链有上界，则有极大元（注意 mathlib 把"极大"表述为
r m a → r a m——与 m 等价或反向）。 -/
#check @exists_maximal_of_chains_bounded

example (α : Type) (r : α → α → Prop) (trans : ∀ a b c, r a b → r b c → r a c)
    (h : ∀ c : Set α, IsChain r c → ∃ ub, ∀ a ∈ c, r a ub) :
    ∃ m, ∀ a, r m a → r a m :=
  exists_maximal_of_chains_bounded h (fun h1 h2 => trans _ _ _ h1 h2)

/-! ## AC 在 Lean 逻辑中的位置 -/

/- Lean 的选择公理：任意非空类型可选中元素。 -/
#check @Classical.choice

/- 它的第一个著名推论：排中律。 -/
#print axioms Classical.em

/- mathlib 的一切经典推理最终都踩在 propext、Classical.choice、
Quot.sound 三块砖上——第 126 章"两张地基图"的呼应：ZFC 的九条
公理在这里换成了三条逻辑公理，而 AC 是其中之一。 -/

/-! ## 有限选择：不需要 AC -/

/-- 对有限族，选择是**构造**：逐表取头。 -/
def chooseList : List (List ℕ) → List ℕ
  | [] => []
  | L :: Ls => L.head?.getD 0 :: chooseList Ls

/-- 选出的列表与族等长——有限选择的"产品合格证"之一。 -/
theorem chooseList_length (Ls : List (List ℕ)) :
    (chooseList Ls).length = Ls.length := by
  induction Ls with
  | nil => rfl
  | cons L Ls ih => simp [chooseList, ih]

/-- 非空列表的头确实是成员——选出的元素"选自"原集合。 -/
theorem head_mem (L : List ℕ) (h : L ≠ []) : L.head?.getD 0 ∈ L := by
  cases L with
  | nil => exact absurd rfl h
  | cons x xs => simp

/- AC 的公理性恰恰只体现在**无穷**族上：无限多个非空集合"同时"
取元素没有任何构造手段——这正是书 4.6 节全部争论的根源。 -/
