/- ex36_ars —— 归约分解：抽象归约系统（Lean 4 版）
   与 ex36_ars.v 同构：3 点 ARS 全枚举（512 关系）；Newman 引理与
   Hindley-Rosen 合流转移的穷举式机器证明；定理 5 假设必要性现场；
   |A|=3 的红利（LC ⇒ Conf 无条件）。重账走 native_decide。 -/

namespace Ex36

set_option maxRecDepth 4000000

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

/- 表驱动记忆化：每关系一次 reach 存掩码、纯位循环判定。 -/
def reachMask (R x : Nat) : Nat :=
  ((reach R x).foldl (fun acc y => acc ||| (2 ^ y)) 0)

def rmaskList : List (List Nat) :=
  allRels.map fun R => pts.map fun x => reachMask R x

def masksAt (R : Nat) : List Nat := rmaskList.getD R []

def mOf (ms : List Nat) (x : Nat) : Nat := ms.getD x 0

def bit3 (m x : Nat) : Bool := (m >>> x) &&& 1 == 1

def stepMask (R x : Nat) : Nat :=
  (if (R >>> (3 * x + 0)) &&& 1 == 1 then 1 else 0)
+ (if (R >>> (3 * x + 1)) &&& 1 == 1 then 2 else 0)
+ (if (R >>> (3 * x + 2)) &&& 1 == 1 then 4 else 0)

def joinMask (m1 m2 : Nat) : Bool := (m1 &&& m2) != 0

def locallyConfluentT (R : Nat) : Bool :=
  let ms := masksAt R
  pts.all fun x =>
    pts.all fun y =>
      pts.all fun z =>
        !(bit3 (stepMask R x) y && bit3 (stepMask R x) z)
          || joinMask (mOf ms y) (mOf ms z)

def confluentT (R : Nat) : Bool :=
  let ms := masksAt R
  pts.all fun x =>
    pts.all fun y =>
      pts.all fun z =>
        !(bit3 (mOf ms x) y && bit3 (mOf ms x) z)
          || joinMask (mOf ms y) (mOf ms z)

def terminatingR (R : Nat) : Bool :=
  let ms := masksAt R
  let selfloop := pts.any fun x => bit3 (stepMask R x) x
  let backedge :=
    pts.any fun x =>
      pts.any fun y =>
        bit3 (stepMask R x) y
          && (mOf ms y &&& (7 ^^^ 2 ^ y)) >>> x &&& 1 == 1
  !(selfloop || backedge)

def commutesT (R1 R2 : Nat) : Bool :=
  let ms1 := masksAt R1
  let ms2 := masksAt R2
  pts.all fun x =>
    pts.all fun y =>
      pts.all fun z =>
        !(bit3 (stepMask R1 x) y && bit3 (stepMask R2 x) z)
          || joinMask (mOf ms2 y) (mOf ms1 z)

def unionR (R1 R2 : Nat) : Nat := R1 ||| R2

/- ---------- 断言电池 ---------- -/

/-- 电一：Newman 引理（3 点全枚举）。 -/
example : allRels.all fun R =>
      !(terminatingR R && locallyConfluentT R) || confluentT R
  = true := by native_decide

/-- 电二：|A|=3 的红利——LC ⇒ Conf 无条件。 -/
example : allRels.all fun R => !locallyConfluentT R || confluentT R
  = true := by native_decide

/-- 电三：Hindley-Rosen/定理 5（512×512 对全枚举）。 -/
example :
    (allRels.flatMap fun a => allRels.map fun b => (a, b)).all fun p =>
      !(confluentT p.1 && confluentT p.2 && commutesT p.1 p.2)
        || confluentT (unionR p.1 p.2)
  = true := by native_decide

/-- 电四：假设必要性——R1={0→1}、R2={0→2} 各自合流但不交换，
    并既非局部合流也非合流。 -/
def R1a : Nat := 2   -- 0→1：bit(3·0+1)
def R2a : Nat := 4
def Ra : Nat := 6   -- 0→1,0→2

example : confluentT R1a && confluentT R2a && !commutesT R1a R2a
          && !locallyConfluentT Ra && !confluentT Ra = true := by decide

/-- 电五：正样本——R1={0→1,1→2}、R2={2→1}：vacuous 交换、并合流。 -/
def R1b : Nat := 34  -- 0→1,1→2
def R2b : Nat := 128
def Rb : Nat := 162  -- 0→1,1→2,2→1

example : confluentT R1b && confluentT R2b && commutesT R1b R2b
          && confluentT Rb = true := by decide

end Ex36
