/-
文件: 02_inductive_types/inductive_types.lean
描述: 第4章 归纳类型（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.InductiveTypes.InductiveTypes
-/

namespace Lean4Tutorial.Examples.InductiveTypes.Ch4

/-! # 枚举类型 -/

inductive Weekday where
  | monday | tuesday | wednesday | thursday | friday | saturday | sunday
  deriving Repr, DecidableEq

#check Weekday.monday
#eval Weekday.friday
#eval Weekday.friday == Weekday.monday

/-! # 参数化归纳类型：Option -/

#check (some 5 : Option Nat)
#check (none : Option Nat)
#eval (some 3).getD 0
#eval (none : Option Nat).getD 0
#eval (some 3).map (· * 2)
#eval (some 3).isSome

def head? {α : Type} : List α → Option α
  | []    => none
  | x::_  => some x
#eval head? [1, 2, 3]
#eval head? ([] : List Nat)

/-! # 递归归纳类型与递归子 -/

inductive MyNat where
  | zero : MyNat
  | succ : MyNat → MyNat
  deriving Repr

-- 递归子（消去子）就是归纳原理的类型化表达
#check @MyNat.rec

-- 用递归子直接定义加法（了解原理即可，实战用等式编译器）
-- 裸递归子没有代码生成支持，需标 noncomputable；用 #reduce 做纯归约演示
noncomputable def myAdd : MyNat → MyNat → MyNat :=
  fun m => MyNat.rec (motive := fun _ => MyNat)
    m (fun _ ih => MyNat.succ ih)

-- 裸递归子没有编译器支持，#eval 不可；用 #reduce 做纯归约演示
open MyNat in
#reduce myAdd (succ (succ zero)) (succ zero)   -- MyNat.succ (MyNat.succ (MyNat.succ MyNat.zero))

/-! # 参数 vs 索引 -/

inductive MyVec (α : Type) : Nat → Type where
  | nil  : MyVec α 0
  | cons : α → MyVec α n → MyVec α (n + 1)

#check MyVec.nil
#check MyVec.cons 1 MyVec.nil

/-! # 归纳命题 -/

inductive Even : Nat → Prop where
  | zero : Even 0
  | add2 : Even n → Even (n + 2)

example : Even 4 := Even.add2 (Even.add2 Even.zero)

mutual
  inductive Even' : Nat → Prop where
    | zero : Even' 0
    | succ : Odd' n → Even' (n + 1)
  inductive Odd' : Nat → Prop where
    | succ : Even' n → Odd' (n + 1)
end

example : Odd' 3 := Odd'.succ (Even'.succ (Odd'.succ Even'.zero))

/-! # deriving -/

inductive Color where
  | red | green | blue
  deriving Repr, DecidableEq, BEq, Inhabited, Ord, Hashable

#eval Color.red
#eval Color.red == Color.blue
#eval (default : Color)
#eval compare Color.red Color.blue

end Lean4Tutorial.Examples.InductiveTypes.Ch4
