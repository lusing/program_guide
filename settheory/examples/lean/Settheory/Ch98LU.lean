import Mathlib.Data.Finset.Filter
import Mathlib.Data.Fintype.Basic

open Finset

/-!
# 第 98 章 · 可测基数内模型 L[U]

有限版 Def 算子：布尔项（谓词原子 P a、自身原子 x∈P、相等原子
x=a、复合）的求值，及其两条内模型代数律——谓词外延性（P=Q ⟹
定义内容相同，即 L[U]=L[V] 当 U=V）与参数局部性（P、Q 在参数集
∪{x} 上一致 ⟹ 求值一致，即 L[U]=L[Ũ] 截断无歧义的影子）。
-/

namespace Settheory.Ch98

/-- 布尔项：`self` 是 x∈P；`mem a` 是参数 a∈P；`eq a` 是 x=a。 -/
inductive BTerm (α : Type) where
  | self : BTerm α
  | mem (a : α) : BTerm α
  | eq (a : α) : BTerm α
  | and : BTerm α → BTerm α → BTerm α
  | not : BTerm α → BTerm α

/-- 项的参数集。 -/
def params {α : Type} : BTerm α → List α
  | .self => []
  | .mem a => [a]
  | .eq a => [a]
  | .and l r => params l ++ params r
  | .not l => params l

/-- 布尔项在谓词 P、点 x 处的求值。 -/
def eval {α : Type} [DecidableEq α] (P : α → Bool)
    (t : BTerm α) (x : α) : Bool :=
  match t with
  | .self => P x
  | .mem a => P a
  | .eq a => decide (x = a)
  | .and l r => eval P l x && eval P r x
  | .not l => !eval P l x

/-- 谓词外延性：外延相等的超滤子给出完全相同的定义内容。
这是「L[U] 只依赖 U 的外延」的内核。 -/
theorem eval_ext {α : Type} [DecidableEq α] {P Q : α → Bool}
    (h : P = Q) (t : BTerm α) (x : α) :
    eval P t x = eval Q t x := by
  subst h; rfl

/-- 参数局部性：P、Q 在 R 上逐点相等、x 满足 R、参数都满足 R
⟹ 求值一致。这是 L[U]=L[Ũ]（Ũ=U∩L[U] 截断）的影子：
内部只看得到截断内的信息。 -/
theorem eval_local {α : Type} [DecidableEq α] {P Q : α → Bool}
    {R : α → Prop} (hR : ∀ a, R a → P a = Q a) {x : α} (hxR : R x)
    (t : BTerm α) (hsub : ∀ a ∈ params t, R a) :
    eval P t x = eval Q t x := by
  induction t with
  | self => exact hR x hxR
  | mem a => exact hR a (hsub a (List.mem_singleton.2 rfl))
  | eq a => rfl
  | and l r ih_l ih_r =>
      rw [eval, eval,
        ih_l (fun b hb => hsub b (List.mem_append.2 (Or.inl hb))),
        ih_r (fun b hb => hsub b (List.mem_append.2 (Or.inr hb)))]
  | not l ih => rw [eval, eval, ih hsub]

/-- 样本：三点宇宙上焦点 2 的主测度，项 (x=2 ∧ P x) 的定义集
恰为 {2}——主测度在 Def 算子下不产生新内容（DPow ⊆ Pow 的影子
由 eval 落在 Bool 即得）。 -/
example : (Finset.univ.filter (fun x : Fin 3 =>
    eval (fun y => y == 2)
      (BTerm.and (BTerm.eq 2) BTerm.self) x)) = {2} := by
  decide

end Settheory.Ch98
