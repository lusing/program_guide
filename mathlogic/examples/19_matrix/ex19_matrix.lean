/- ex19_matrix.lean —— 有限矩阵与拓扑完备性（Mints ch8.5.3 + ch9 + 8.4 桥）
    与 Coq 侧同构：上集矩阵（单调数）、四连驳、IPC 可靠性侧账、锥拓扑
    内部算子对账、[0,1] 级数嵌入的精确整数分离引理。 -/

inductive FM : Type where
  | pv : Nat → FM
  | ff : FM
  | aand : FM → FM → FM
  | oor : FM → FM → FM
  | iimp : FM → FM → FM
  deriving Repr

def negf (a : FM) : FM := .iimp a .ff

/-- 帧：(世界数, 可达关系) -/
abbrev Frame := Nat × (Nat → Nat → Bool)

def worlds (F : Frame) : List Nat := List.range F.1
def rOf (F : Frame) : Nat → Nat → Bool := F.2

def chain2 : Frame := (2, fun i j => i <= j)
def vframe : Frame := (3, fun i j => i == j || i == 0)

def memN (x : Nat) (l : List Nat) : Bool := l.contains x
def inclb (l1 l2 : List Nat) : Bool := l1.all (fun x => memN x l2)
def eqSetL (l1 l2 : List Nat) : Bool := inclb l1 l2 && inclb l2 l1

def subsOf : List Nat → List (List Nat)
  | [] => [[]]
  | x :: t => let r := subsOf t
              r ++ r.map (x :: ·)

/-- 上集：S 的未来封闭 S（i∈S 才检查——空集空洞成立） -/
def upsetP (F : Frame) (S : List Nat) : Bool :=
  (worlds F).all fun i =>
    !(memN i S) ||
      (worlds F).all fun j => !(rOf F i j) || memN j S

def allUpsets (F : Frame) : List (List Nat) :=
  (subsOf (worlds F)).filter (upsetP F)

def mAnd (F : Frame) (A B : List Nat) : List Nat :=
  (worlds F).filter fun x => memN x A && memN x B
def mOr (F : Frame) (A B : List Nat) : List Nat :=
  (worlds F).filter fun x => memN x A || memN x B
def mImp (F : Frame) (A B : List Nat) : List Nat :=
  (worlds F).filter fun w =>
    (worlds F).all fun w' => !(rOf F w w') || (!(memN w' A) || memN w' B)

def val2 (F : Frame) (a b : List Nat) : Nat → List Nat
  | 0 => a | 1 => b | _ => worlds F

def mEval (F : Frame) (V : Nat → List Nat) : FM → List Nat
  | .pv n => V n
  | .ff => []
  | .aand x y => mAnd F (mEval F V x) (mEval F V y)
  | .oor x y => mOr F (mEval F V x) (mEval F V y)
  | .iimp x y => mImp F (mEval F V x) (mEval F V y)

def mValid2 (F : Frame) (a : FM) : Bool :=
  let U := allUpsets F
  (U.flatMap fun p1 => U.map fun p2 => (p1, p2)).all fun p =>
    eqSetL (mEval F (val2 F p.1 p.2) a) (worlds F)

def P : FM := .pv 0
def Q : FM := .pv 1

def bitmask (s : List Nat) : Nat := s.foldl (fun m i => m + 2 ^ i) 0

example : (allUpsets chain2).map bitmask == [0, 2, 3] := by native_decide
example : (allUpsets vframe).length == 5 := by native_decide

example : mValid2 chain2 (.oor P (negf P)) = false := by native_decide
example : mValid2 chain2 (.iimp (negf (negf P)) P) = false := by native_decide
example : mValid2 vframe (.oor (negf P) (negf (negf P))) = false := by native_decide
example : mValid2 vframe (.oor (.iimp P Q) (.iimp Q P)) = false := by native_decide

/-- IPC 定理库（可靠性侧账：全矩阵取顶值） -/
def ipcLib : List FM :=
  [ .iimp P P
  , negf (.aand P (negf P))
  , .iimp (.aand P Q) (.aand Q P)
  , .iimp P (.iimp Q P)
  , .iimp (.aand P (.iimp P Q)) Q
  , .iimp (.iimp P Q) (.iimp (negf Q) (negf P))    -- 逆否有效方向
  , negf (negf (.iimp P P)) ]

example : ipcLib.all fun a => mValid2 chain2 a && mValid2 vframe a := by
  native_decide

/- 节：锥拓扑 -/

/-- 节：Alexandrov 内部——未来全在 Y 里的点 -/
def interior (F : Frame) (Y : List Nat) : List Nat :=
  (worlds F).filter fun w =>
    (worlds F).all fun w' => !(rOf F w w') || memN w' Y

def topImp (F : Frame) (A B : List Nat) : List Nat :=
  interior F (mOr F ((worlds F).filter fun w => !(memN w A)) B)

example :
    (let U := allUpsets vframe
     (U.flatMap fun p1 => U.map fun p2 => (p1, p2)).all fun p =>
       eqSetL (topImp vframe p.1 p.2) (mImp vframe p.1 p.2)) = true := by
  native_decide

def force (F : Frame) (V : Nat → List Nat) (w : Nat) : FM → Bool
  | .pv n => memN w (V n)
  | .ff => false
  | .aand x y => force F V w x && force F V w y
  | .oor x y => force F V w x || force F V w y
  | .iimp x y =>
      (worlds F).all fun w' =>
        !(rOf F w w') || (!(force F V w' x) || force F V w' y)

def forcesSet (F : Frame) (V : Nat → List Nat) (a : FM) : List Nat :=
  (worlds F).filter fun w => force F V w a

def coneFms : List FM :=
  [ P, Q, negf P, .oor P Q, .iimp P Q, negf (.oor P (negf P))
  , .iimp (negf P) (negf (negf P)), .oor (.iimp P Q) (.iimp Q P)
  , .iimp (.iimp P Q) (.oor P (.iimp Q P)) ]

/-- 力迫集↔开集赋值：V(φ)={w|w⊩φ} 全公式对账 -/
example :
    (let U := allUpsets vframe
     (U.flatMap fun p1 => U.map fun p2 => (p1, p2)).all fun p =>
       let V := val2 vframe p.1 p.2
       coneFms.all fun a => eqSetL (forcesSet vframe V a) (mEval vframe V a))
      = true := by native_decide

/- 节：Thm 9.2：[0,1] 级数嵌入 -/

/-- β_s=Σ2·s(n)q^{n+1}（q=1/(2N−1)）：「前缀+稳定值」精确整数化，
    分母 D^m·(D−1)。 -/
def lastOf (l : List Nat) : Nat := l.foldl Nat.max 0

def monoPre : Nat → Nat → List (List Nat)
  | _, 0 => [[]]
  | N, m + 1 =>
      (monoPre N m).flatMap fun l =>
        (List.range' (lastOf l) (N - lastOf l)).map fun v => l ++ [v]

def allSeqs (N m : Nat) : List (List Nat × Nat) :=
  (monoPre N m).flatMap fun l =>
    (List.range' (lastOf l) (N - lastOf l)).map fun w => (l, w)

def betaN (D : Nat) (l : List Nat) (w : Nat) : Nat :=
  let m := l.length
  ((List.range m).zip l).foldl
    (fun acc iv => acc + 2 * iv.2 * D ^ (m - 1 - iv.1) * (D - 1))
    (2 * w)

def diffIx : List Nat → List Nat → Option Nat
  | [], [] => none
  | a :: s', b :: t' =>
      if a == b then (diffIx s' t').map (· + 1) else some 0
  | _, _ => none

/-- (b) 尾项界：2w ≤ D−1 -/
example : (allSeqs 3 2).all fun p => 2 * p.2 <= 2 * 3 - 1 - 1 := by
  native_decide

def closeCheck (D : Nat) (pp : (List Nat × Nat) × (List Nat × Nat)) : Bool :=
  match diffIx pp.1.1 pp.2.1 with
  | none =>
      (betaN D pp.1.1 pp.1.2 - betaN D pp.2.1 pp.2.2 <= D - 1) &&
      (betaN D pp.2.1 pp.2.2 - betaN D pp.1.1 pp.1.2 <= D - 1)
  | some _ => true

def farCheck (D : Nat) (pp : (List Nat × Nat) × (List Nat × Nat)) : Bool :=
  match diffIx pp.1.1 pp.2.1 with
  | some j =>
      !(pp.1.1.getD j 0 < pp.2.1.getD j 0) ||
        (D ^ (pp.1.1.length - (j + 1)) * (D - 1)
          < betaN D pp.2.1 pp.2.2 - betaN D pp.1.1 pp.1.2)
  | none => true

example :
    ((allSeqs 3 2).flatMap fun a => (allSeqs 3 2).map fun b => (a, b)).all
      (closeCheck 5) = true := by native_decide

example :
    ((allSeqs 3 2).flatMap fun a => (allSeqs 3 2).map fun b => (a, b)).all
      (farCheck 5) = true := by native_decide

example :
    ((allSeqs 2 2).flatMap fun a => (allSeqs 2 2).map fun b => (a, b)).all
      (farCheck 3) = true := by native_decide
