/- ex41_ars —— 归约分解：抽象归约系统（Lean 4 版）
   与 ex41_ars.v 同构：3 点 ARS 全枚举（512 关系）；Newman 引理与
   Hindley-Rosen 合流转移的穷举式机器证明；定理 5 假设必要性现场；
   |A|=3 的红利（LC ⇒ Conf 无条件）。重账走 native_decide。 -/

namespace Ex41

def step (R x y : Nat) : Bool := (R >>> (3 * x + y)) &&& 1 == 1
def allRels : List Nat := List.range 512
def pts : List Nat := [0, 1, 2]

def succs (R x : Nat) : List Nat := pts.filter (step R x)

def removeDup : List Nat → List Nat
  | [] => []
  | x :: t => if t.any (· == x) then removeDup t else x :: removeDup t

def reachAux : Nat → Nat → Nat → List Nat
  | 0, _, x => [x]
  | n + 1, R, x =>
      let prev := reachAux n R x
      prev.foldl (fun acc y => acc ++ succs R y) prev

def reach (R x : Nat) : List Nat := removeDup (reachAux 4 R x)

def joinable (R y z : Nat) : Bool :=
  pts.any fun w => (reach R y).contains w && (reach R z).contains w

def locallyConfluent (R : Nat) : Bool :=
  pts.all fun x =>
    ((succs R x).flatMap fun y => (succs R x).map fun z => (y, z)).all
      fun p => joinable R p.1 p.2

def confluent (R : Nat) : Bool :=
  pts.all fun x =>
    ((reach R x).flatMap fun y => (reach R x).map fun z => (y, z)).all
      fun p => joinable R p.1 p.2

def reachNoSelf (R y : Nat) : List Nat :=
  (reach R y).filter fun w => !(w == y)

def terminatingR (R : Nat) : Bool :=
  !pts.any fun x =>
    pts.any fun y => step R x y && (reachNoSelf R y).contains x

/-- 交换（Hindley-Rosen）。 -/
def commutes (R1 R2 : Nat) : Bool :=
  pts.all fun x =>
    pts.all fun y =>
      pts.all fun z =>
        !(step R1 x y && step R2 x z)
          || pts.any fun w =>
              (reach R2 y).contains w && (reach R1 z).contains w

def unionR (R1 R2 : Nat) : Nat := R1 ||| R2

/- ---------- 断言电池 ---------- -/

/-- 电一：Newman 引理（3 点全枚举）。 -/
example : allRels.all fun R =>
      !(terminatingR R && locallyConfluent R) || confluent R
  = true := by native_decide

/-- 电二：|A|=3 的红利——LC ⇒ Conf 无条件。 -/
example : allRels.all fun R => !locallyConfluent R || confluent R
  = true := by native_decide

/-- 电三：Hindley-Rosen/定理 5（512×512 对全枚举）。 -/
example :
    (allRels.flatMap fun a => allRels.map fun b => (a, b)).all fun p =>
      !(confluent p.1 && confluent p.2 && commutes p.1 p.2)
        || confluent (unionR p.1 p.2)
  = true := by native_decide

/-- 电四：假设必要性——R1={0→1}、R2={0→2} 各自合流但不交换，
    并既非局部合流也非合流。 -/
def R1a : Nat := 1
def R2a : Nat := 4
def Ra : Nat := 5

example : confluent R1a && confluent R2a && !commutes R1a R2a
          && !locallyConfluent Ra && !confluent Ra = true := by decide

/-- 电五：正样本——R1={0→1,1→2}、R2={2→1}：vacuous 交换、并合流。 -/
def R1b : Nat := 17
def R2b : Nat := 128
def Rb : Nat := 145

example : confluent R1b && confluent R2b && commutes R1b R2b
          && confluent Rb = true := by decide

end Ex41
