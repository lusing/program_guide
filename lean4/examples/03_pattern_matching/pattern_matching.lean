/-
文件: 03_pattern_matching/pattern_matching.lean
描述: 第5章 模式匹配与递归（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.PatternMatching.PatternMatching
-/

namespace Lean4Tutorial.Examples.PatternMatching

/-! # match 基础 -/

def isZero : Nat → Bool
  | 0     => true
  | _ + 1 => false

#eval isZero 0
#eval isZero 5

def isEmpty {α : Type} : List α → Bool
  | []      => true
  | _ :: _  => false

def describe (n : Nat) : String :=
  match n with
  | 0 => "零"
  | 1 => "一"
  | _ => "很多"
#eval describe 2

/-! # 模式花样 -/

def second? {α : Type} : List α → Option α
  | _ :: x :: _ => some x
  | _           => none
#eval second? [1, 2, 3]

def isSmallPrime (n : Nat) : Bool :=
  match n with
  | 2 | 3 | 5 | 7 => true
  | _             => false
#eval isSmallPrime 5
#eval isSmallPrime 6

def tail? {α : Type} : List α → Option (List α)
  | []       => none
  | _ :: t   => some t
#eval tail? [1, 2, 3]

def sign (n : Int) : String :=
  match n with
  | Int.ofNat n => if n == 0 then "zero" else "positive"
  | _           => "negative"
#eval sign 5
#eval sign (-3)
#eval sign 0

/-! # if-let 与 let-else -/

def head? {α : Type} : List α → Option α
  | []    => none
  | x ::_ => some x

def printHead (l : List Nat) : String :=
  if let some h := head? l then
    s!"head = {h}"
  else
    "empty"

-- let ... else 是 do 记法的特性：模式失败时执行 | 后的分支
def headOrZero (l : List Nat) : Nat := Id.run do
  let some h := head? l | return 0
  return h

#eval printHead [7, 8]
#eval headOrZero []

/-! # 等式编译器 -/

def factorial : Nat → Nat
  | 0     => 1
  | n + 1 => (n + 1) * factorial n

#eval factorial 5
example : factorial 3 = 6 := by simp [factorial]
example : factorial 5 = 120 := rfl

def fib : Nat → Nat
  | 0     => 0
  | 1     => 1
  | n + 2 => fib (n + 1) + fib n

#eval fib 10

/-! # 尾递归与累加器 -/

def fibFast (n : Nat) : Nat :=
  go n 0 1
where
  go : Nat → Nat → Nat → Nat
    | 0,     a, _ => a
    | n + 1, a, b => go n b (a + b)

#eval fibFast 50

def quickreverse {α : Type} (l : List α) : List α := go l []
where
  go : List α → List α → List α
    | [],    acc => acc
    | x::xs, acc => go xs (x :: acc)

#eval quickreverse [1, 2, 3]

/-! # 有根递归 -/

def ackermann : Nat → Nat → Nat
  | 0,     n     => n + 1
  | m + 1, 0     => ackermann m 1
  | m + 1, n + 1 => ackermann m (ackermann (m + 1) n)
  termination_by m n => (m, n)

#eval ackermann 3 4

def myGcd : Nat → Nat → Nat
  | 0,     n => n
  | m + 1, n => myGcd (n % (m + 1)) (m + 1)
  termination_by m _ => m      -- 度量：第一个参数
  decreasing_by exact Nat.mod_lt _ (Nat.succ_pos _)   -- n % (m+1) < m+1

#eval myGcd 12 8

/-! # 互递归与 partial -/

mutual
  def isEven : Nat → Bool
    | 0     => true
    | n + 1 => isOdd n
  def isOdd : Nat → Bool
    | 0     => false
    | n + 1 => isEven n
end

#eval isEven 10
#eval isOdd 7

partial def collatz (n : Nat) (fuel : Nat) : List Nat :=
  match fuel with
  | 0 => []
  | fuel + 1 =>
    if n ≤ 1 then [n]
    else n :: collatz (if n % 2 == 0 then n / 2 else 3 * n + 1) fuel

#eval collatz 27 12

end Lean4Tutorial.Examples.PatternMatching
