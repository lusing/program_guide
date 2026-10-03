/- ex19 —— 合一与归结（Lean 4 版）：occurs check 与归结可靠性 -/
namespace Ex19

inductive UTerm where
  | uvar (x : Nat) : UTerm
  | ufun (f : Nat) (t : UTerm) : UTerm

open UTerm

def uoccurs : Nat → UTerm → Bool
  | x, uvar y => y == x
  | x, ufun _ t => uoccurs x t

def uapply (s : Nat → Option UTerm) : UTerm → UTerm
  | uvar x => match s x with
              | some t => t
              | none => uvar x
  | ufun f t => ufun f (uapply s t)

/-- 旗舰一：occurs check 结构健全性（ufun 原则上无法坍缩为变元） -/
theorem occursSound (s : Nat → Option UTerm) (x f : Nat) (t : UTerm) :
    uapply s (ufun f t) ≠ uvar x := by
  intro heq
  simp only [uapply] at heq
  exact UTerm.noConfusion heq

/-- occurs check 现场：x ↦ f(x) 被拒 -/
example : uoccurs 0 (ufun 0 (uvar 0)) = true := by rfl

inductive Literal where
  | mlit (b : Bool) (a : Nat) : Literal

open Literal

def latom : Literal → Nat
  | mlit _ a => a

def lpos : Literal → Bool
  | mlit b _ => b

def lsat (e : Nat → Bool) (C : List Literal) : Bool :=
  C.any (fun l => if lpos l then e (latom l) else !(e (latom l)))

def resolve (C1 C2 : List Literal) (a : Nat) : List Literal :=
  C1.filter (fun l => !(latom l == a)) ++ C2.filter (fun l => !(latom l == a))

/-- 旗舰二：filter 保成员 -/
theorem filterMember (C : List Literal) (a : Nat) (l : Literal)
    (hin : l ∈ C) (hne : latom l ≠ a) :
    l ∈ C.filter (fun x => !(latom x == a)) := by
  refine List.mem_filter.mpr ⟨hin, ?_⟩
  cases hbeq : (latom l == a) with
  | true => exact absurd (by simpa using hbeq) hne
  | false => rfl

/-- 旗舰三：归结可靠性（侧条件版——真文字非消去原子则保留） -/
theorem resolutionSound (e : Nat → Bool) (C1 C2 : List Literal)
    (a : Nat) (l1 : Literal)
    (hin : l1 ∈ C1) (hne : latom l1 ≠ a)
    (hv : (if lpos l1 then e (latom l1) else !(e (latom l1))) = true) :
    lsat e (resolve C1 C2 a) = true := by
  simp only [lsat, resolve, List.any_append, Bool.or_eq_true]
  left
  exact List.any_eq_true.mpr ⟨l1, filterMember C1 a l1 hin hne, hv⟩

end Ex19
