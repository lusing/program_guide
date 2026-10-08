/- ex23 —— L-S、紧致性与初等等价（EFT ch VI）Lean 镜像
   DLO 无有限模型数值证词 + 「有限性不可单句定义」的 σₙ 族两端 +
   量化秩分离现场 + Skolem 闭包生成演示。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

inductive tm : Type
  | var (n : Nat) : tm
  | fsym (s : Nat) (ts : List tm) : tm

inductive fm : Type
  | rat (s : Nat) (ts : List tm)
  | eqf (t1 t2 : tm)
  | neg (φ : fm)
  | disj (φ ψ : fm)
  | conj (φ ψ : fm)
  | imp (φ ψ : fm)
  | exq (x : Nat) (φ : fm)
  | allq (x : Nat) (φ : fm)

def interp_fn := Nat → List Nat → Nat
def interp_rel := Nat → List Nat → Bool

def evt (f : interp_fn) (β : Nat → Nat) : tm → Nat
  | .var n => β n
  | .fsym s ts => f s (ts.map (evt f β))

def bump (β : Nat → Nat) (x a : Nat) : Nat → Nat :=
  fun n => if n = x then a else β n

def evf (f : interp_fn) (r : interp_rel) (D : List Nat)
    (β : Nat → Nat) : fm → Bool
  | .rat s ts => r s (ts.map (evt f β))
  | .eqf t1 t2 => evt f β t1 == evt f β t2
  | .neg ψ => !evf f r D β ψ
  | .disj ψ χ => evf f r D β ψ || evf f r D β χ
  | .conj ψ χ => evf f r D β ψ && evf f r D β χ
  | .imp ψ χ => !evf f r D β ψ || evf f r D β χ
  | .exq x ψ => D.any (fun a => evf f r D (bump β x a) ψ)
  | .allq x ψ => D.all (fun a => evf f r D (bump β x a) ψ)

-- Z_n：论域 [0..n)，R0 = <，R1 = ≡
def Zn (n : Nat) : List Nat := List.range n
def lt_r : interp_rel :=
  fun s args => match s, args with
  | 0, [a, b] => a < b
  | 1, [a, b] => a == b
  | _, _ => false
def fid : interp_fn := fun _ _ => 0

def trueZn (n : Nat) (φ : fm) : Bool :=
  evf fid lt_r (Zn n) (fun _ => 0) φ

-- DLO 公理化

def x : tm := .var 0
def y : tm := .var 1
def z : tm := .var 2
def lt (u v : tm) : fm := .rat 0 [u, v]

def ord_irrefl : fm := .allq 0 (.neg (lt x x))
def ord_trans : fm :=
  .allq 0 (.allq 1 (.allq 2 (.imp (.conj (lt x y) (lt y z)) (lt x z))))
def ord_total : fm :=
  .allq 0 (.allq 1 (.disj (lt x y) (.disj (.eqf x y) (lt y x))))
def dense : fm :=
  .allq 0 (.allq 1 (.imp (lt x y) (.exq 2 (.conj (lt x z) (lt z y)))))
def no_left : fm := .allq 0 (.exq 1 (.conj (lt y x) (.neg (.eqf y x))))
def no_right : fm := .allq 0 (.exq 1 (.conj (lt x y) (.neg (.eqf y x))))

def dlo_axioms : List fm :=
  [ord_irrefl, ord_trans, ord_total, dense, no_left, no_right]

example : [ord_irrefl, ord_trans, ord_total].all (fun φ => trueZn 3 φ) = true := by
  native_decide

example : ((List.range 7).all (fun n => !trueZn (n + 2) dense)) = true := by
  native_decide

example : ((List.range 7).all (fun n =>
    !dlo_axioms.all (fun φ => trueZn (n + 1) φ))) = true := by native_decide

-- σₙ：至少 n 个不同元素（σ₂σ₃σ₄ 手写）

def sigma2 : fm := .exq 0 (.exq 1 (.neg (.eqf (.var 0) (.var 1))))
def sigma3 : fm :=
  .exq 0 (.exq 1 (.exq 2 (
    .conj (.neg (.eqf (.var 0) (.var 1)))
      (.conj (.neg (.eqf (.var 0) (.var 2)))
             (.neg (.eqf (.var 1) (.var 2)))))))
def sigma4 : fm :=
  .exq 0 (.exq 1 (.exq 2 (.exq 3 (
    .conj (.neg (.eqf (.var 0) (.var 1)))
    (.conj (.neg (.eqf (.var 0) (.var 2)))
    (.conj (.neg (.eqf (.var 0) (.var 3)))
    (.conj (.neg (.eqf (.var 1) (.var 2)))
    (.conj (.neg (.eqf (.var 1) (.var 3)))
           (.neg (.eqf (.var 2) (.var 3)))))))))))

example : trueZn 2 sigma2 && (trueZn 3 sigma3 && trueZn 4 sigma4) = true := by
  native_decide
example : !trueZn 3 sigma4 = true := by native_decide
example : trueZn 3 sigma2 && trueZn 3 sigma3 = true := by native_decide

-- 量化秩分离：σ₃ 在 Z_2/Z_3 上异值
def eeq_pair (n m : Nat) (φ : fm) : Bool := trueZn n φ == trueZn m φ
example : !eeq_pair 2 3 sigma3 = true := by native_decide

-- rank0 同值抽样
def samples_rank0 : List fm :=
  [ lt x x, lt x y, .conj (lt x y) (.neg (lt x y)),
    .disj (lt x y) (.eqf x y), .imp (lt x y) (lt x z) ]
example : samples_rank0.all (eeq_pair 2 3) = true := by native_decide

-- Skolem 闭包：环绕后继下从种子的轨道
def succ_wrap (n a : Nat) : Nat := if a == n - 1 then 0 else a + 1

def nodup : List Nat → List Nat :=
  fun l => l.foldr (fun a acc =>
    if acc.contains a then acc else a :: acc) []

def skclose (n : Nat) : List Nat → Nat → List Nat
  | _, 0 => []
  | seed, fuel + 1 =>
      let S' := seed ++ seed.map (succ_wrap n)
      if S'.all (fun a => seed.contains a) then seed
      else skclose n (nodup S') fuel

example : ((List.range 5).all (fun a => (skclose 5 [1] 10).contains a)) = true := by
  native_decide
example : (skclose 6 [0] 10).length = 6 := by native_decide

-- 冒烟
#eval (List.range 6).map (fun n => dlo_axioms.all (fun φ => trueZn (n + 1) φ))
#eval [dense, no_left, ord_trans].map (fun φ => (trueZn 3 φ, trueZn 4 φ))
