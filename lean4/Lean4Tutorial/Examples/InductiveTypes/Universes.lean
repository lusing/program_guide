/-
文件: 02_inductive_types/universes.lean
描述: 第3章 依赖类型与宇宙（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.InductiveTypes.Universes
-/

namespace Lean4Tutorial.Examples.InductiveTypes.Universes

/-! # Sort 分层 -/

#check Nat        -- Type
#check Type       -- Type 1
#check Type 1     -- Type 2
#check Prop       -- Type
#check Sort 0     -- Type

/-! # 宇宙多态 -/

def id' {α : Type u} (x : α) : α := x
#check @id'

#check @id        -- {α : Sort u} → α → α

def FuncType (α : Type u) (β : Type v) : Type (max u v) := α → β

universe a b
def Pair' (α : Type a) (β : Type b) : Type (max a b) := α × β

/-! # 依赖函数类型 -/

#check @List.length

inductive MyVec (α : Type) : Nat → Type where
  | nil  : MyVec α 0
  | cons : α → MyVec α n → MyVec α (n + 1)

-- 索引保持的映射：类型层面保证长度不变
def vMap {α β : Type} (f : α → β) : {n : Nat} → MyVec α n → MyVec β n
  | _, MyVec.nil       => MyVec.nil
  | _, MyVec.cons x xs => MyVec.cons (f x) (vMap f xs)

-- 安全取首元素：非空性是索引的一部分
def vHead {α : Type} {n : Nat} : MyVec α (n + 1) → α
  | MyVec.cons x _ => x

#eval vMap (· * 2) (MyVec.cons 1 (MyVec.cons 2 MyVec.nil))  -- cons 2 (cons 4 nil)
#eval vHead (MyVec.cons 7 MyVec.nil)                        -- 7

/-! # Prop 宇宙 -/

#check True
#check False
#check (2 + 2 = 4)
#check (∀ n : Nat, n ≥ 0)

-- 证明无关性
example (p q : 2 + 2 = 4) : p = q := rfl

/-! # Sigma 与子类型 -/

def pair : Σ n : Nat, List Nat := ⟨2, [1, 2]⟩
#eval pair.2

def PosNat := {n : Nat // n > 0}
def three : PosNat := ⟨3, by decide⟩
#eval three.1
#check three.2

/-! # show -/

example : 1 + 1 = 2 := show 2 = 2 from rfl

example : (fun x => x + 1) 2 = 3 := by
  show 2 + 1 = 3
  rfl

end Lean4Tutorial.Examples.InductiveTypes.Universes
