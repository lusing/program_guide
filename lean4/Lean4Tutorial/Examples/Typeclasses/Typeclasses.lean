/-
文件: 04_typeclasses/typeclasses.lean
描述: 第6章 类型类（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.Typeclasses.Typeclasses
-/

namespace Lean4Tutorial.Examples.Typeclasses.Ch6

/-! # 类型类基础 -/

class Printable (α : Type) where
  print : α → String

instance : Printable Nat where
  print n := toString n

instance : Printable Bool where
  print b := if b then "true" else "false"

def printTwice {α : Type} [Printable α] (x : α) : String :=
  Printable.print x ++ Printable.print x

#eval printTwice (5 : Nat)
#eval printTwice true

/-! # 实例解析 -/

instance {α : Type} [Printable α] : Printable (Option α) where
  print
    | some x => s!"some({Printable.print x})"
    | none   => "none"

#eval printTwice (some 5 : Option Nat)

#check (inferInstance : Printable (Option Bool))

def MyNatAlias := Nat
example : Add MyNatAlias := inferInstanceAs (Add Nat)

/-! # scoped 实例 -/

namespace RationalOps

scoped instance : Mul String where
  mul a b := a ++ "*" ++ b

end RationalOps

open RationalOps in
#eval "a" * "b"

/-! # 操作符重载 -/

structure Point where
  x : Nat
  y : Nat
  deriving Repr

instance : Add Point where
  add p1 p2 := { x := p1.x + p2.x, y := p1.y + p2.y }

instance : Zero Point where
  zero := { x := 0, y := 0 }

#eval ({ x := 1, y := 2 } : Point) + { x := 3, y := 4 }
#eval (0 : Point)

/-! # 类型类继承 -/

class MySemigroup (α : Type) extends Add α where
  add_assoc : ∀ (a b c : α), (a + b) + c = a + (b + c)

class MyMonoid (α : Type) extends MySemigroup α, Zero α where
  add_zero : ∀ (a : α), a + 0 = a
  zero_add : ∀ (a : α), 0 + a = a

/-! # 实例参数与命名实例 -/

def sumDouble [Add α] (x y : α) : α := x + y + x + y

#eval sumDouble 3 4

instance namedAdd : Add Nat where
  add := Nat.add

#check @sumDouble Nat namedAdd 3 4

end Lean4Tutorial.Examples.Typeclasses.Ch6
