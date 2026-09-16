/-
文件: 07_structures/structures.lean
描述: 第9章 结构与记录（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.Structures.Structures
-/

namespace Lean4Tutorial.Examples.Structures.Ch9

/-! # 结构定义与三种构造语法 -/

structure Person where
  name : String
  age  : Nat
  deriving Repr

def alice : Person := { name := "Alice", age := 30 }
def bob : Person := ⟨"Bob", 25⟩
def carol : Person := Person.mk "Carol" 28

#eval alice.name
#eval bob.age

/-! # 点号记法 -/

def Person.greet (p : Person) : String := s!"Hi, I'm {p.name}"
#eval alice.greet

def Person.birthday (p : Person) : Person := { p with age := p.age + 1 }
#eval alice.birthday.age

/-! # 结构更新 -/

def alice' : Person := { alice with age := 31 }
#eval alice'.name

def alice'' := { alice with name := "Alice Smith", age := 32 }

structure Config where
  server : String
  port : Nat
deriving Repr

structure App where
  name : String
  cfg : Config
deriving Repr

def myApp : App := { name := "demo", cfg := { server := "localhost", port := 8080 } }
def myApp2 := { myApp with cfg.port := 9090 }
#eval myApp2.cfg.port

/-! # 参数化结构与字段依赖 -/

structure Point2D (α : Type) where
  x : α
  y : α
  deriving Repr

def p1 : Point2D Nat := { x := 1, y := 2 }
def p2 : Point2D Float := { x := 3.14, y := 2.718 }

structure BoundedVec where
  len : Nat
  data : Fin len → Nat

structure SortedList (α : Type) [LE α] where
  data : List α

/-! # 结构继承 -/

structure ColoredPoint (α : Type) extends Point2D α where
  color : String
  deriving Repr

def cp : ColoredPoint Nat := { x := 10, y := 20, color := "red" }

#eval cp.x
#eval cp.color
#eval cp.toPoint2D

structure Named where
  name : String

structure NamedColoredPoint (α : Type) extends Point2D α, Named where
  color : String

/-! # 匿名构造器模式匹配 -/

def getX (p : Point2D α) : α :=
  match p with
  | ⟨x, _⟩ => x

def printPoint (p : Point2D Nat) : String :=
  let ⟨x, y⟩ := p
  s!"({x}, {y})"

example (p : Point2D Nat) : p.x + p.y = p.y + p.x := by
  obtain ⟨x, y⟩ := p
  simp [Nat.add_comm]

/-! # 结构与类型类 -/

structure Point3D (α : Type) [Add α] where
  x : α
  y : α
  z : α

structure PointedType where
  carrier : Type
  pt : carrier

end Lean4Tutorial.Examples.Structures.Ch9
