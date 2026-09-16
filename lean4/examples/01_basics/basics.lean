/-
文件: 01_basics/basics.lean
描述: 第2章 基础类型与函数（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.Basics.Basics
-/

namespace Lean4Tutorial.Examples.Basics

/-! # 基本数据类型 -/

def n : Nat := 42
#check n
#eval n

def z : Int := -7
#check z
#eval Int.negSucc 6      -- -7

def b1 : Bool := true
def b2 : Bool := false
#eval b1 && !b2
#eval if 3 < 5 then "yes" else "no"

def s : String := "Lean 4"
#eval s.length

def c : Char := 'A'
#eval c.isUpper
#eval 'λ'.toNat

def f : Float := 3.14
#eval f * 2

def u : Unit := ()

#eval 2^64 + 1    -- 18446744073709551617

/-! # 数值字面量与 OfNat -/

#check (42 : Nat)
#check (42 : Int)
#check (42 : Float)

/-! # 函数定义 -/

def double (n : Nat) : Nat := n + n
#eval double 5

def add (m n : Nat) : Nat := m + n
#eval add 3 4

def add2 (m n : Nat) : Nat := m + n

-- 匿名函数
#check fun (x : Nat) => x + 1
#check fun x => x + (1 : Nat)
#eval (fun x y => x * y) 6 7
#check (· + 1)
#eval (· + 1) 5
#eval (· * ·) 3 4
#eval [1, 2, 3].map (· * 10)

-- 柯里化与部分应用
def adder (n : Nat) : Nat → Nat := fun m => n + m
#eval (adder 3) 4
#eval adder 3 4
def add10 : Nat → Nat := adder 10
#eval add10 5

-- 函数组合与管道
#eval ((· + 1) ∘ (· * 2)) 3
#eval 3 |> (· * 2) |> (· + 1)
#eval "hello" |> String.toUpper |> (String.dropRight · 2)
#eval List.length <| [1, 2, 3] ++ [4]

-- 高阶函数
def applyTwice (f : Nat → Nat) (x : Nat) : Nat := f (f x)
#eval applyTwice (· * 2) 3
#eval List.map (· ^ 2) [1, 2, 3, 4]
#eval List.filter (· % 2 == 0) [1,2,3,4,5]
#eval List.foldl (init := 0) (· + ·) [1,2,3,4,5]

/-! # 多态函数与隐式参数 -/

def identity {α : Type} (x : α) : α := x
#eval identity 5
#eval identity "hello"
#eval identity (3, 4)
#check @identity
#check @identity Nat

def compose {α β γ : Type} (g : β → γ) (f : α → β) : α → γ :=
  fun x => g (f x)
#eval compose (· + 1) (· * 2) 3
#check @id
#check @Function.comp

/-! # 类型推断 -/

def triple n := n * 3
#eval ([] : List Nat).length
def x : Nat := 5
def y := (5 : Nat)
def w : String := "anything"

/-! # 元组 -/

def p : Nat × String := (42, "answer")
#eval p.1
#eval p.2
#eval p.fst

def triple' : Nat × String × Bool := (1, "a", true)

def swap {α β : Type} : α × β → β × α
  | (a, b) => (b, a)
#eval swap (1, 2)

def demo : Nat :=
  let (a, b) := (3, 4)
  a * b
#eval demo

/-! # 字符串操作 -/

#eval "Hello" ++ " " ++ "world"
#eval String.length "Lean"
#eval "Lean".toUpper
#eval "Hello".dropRight 2
#eval "a,b,c".splitOn ","
def name := "Lean"
def version := 4
#eval s!"Hello, {name} {version}!"
#eval String.intercalate "\n" ["第一行", "第二行"]
#eval "λμ".toList
#eval String.mk ['a', 'b']
#eval "AB".utf8ByteSize

/-! # Array -/

#eval #[1, 2, 3]
#eval Array.mk [1, 2, 3]
#eval #[1, 2].push 3

def arr : Array Nat := #[10, 20, 30]
#eval arr[1]!
#eval arr[5]?
#eval arr.size

def sumArray (a : Array Nat) : Nat := Id.run do
  let mut total := 0
  for x in a do
    total := total + x
  return total
#eval sumArray #[1, 2, 3, 4]

end Lean4Tutorial.Examples.Basics
