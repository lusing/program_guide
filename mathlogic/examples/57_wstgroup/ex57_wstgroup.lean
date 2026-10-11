/- ex57_wstgroup.lean —— ω-稳定群（Marker GTM 217 §7），Coq 侧同构镜像 -/

/-- Z₆ -/
def mulZ6 (x y : Nat) : Nat := (x + y) % 6

/-- S₃：六个置换的复合（程序化生成） -/
def s3perms : List (List Nat) :=
  [[0,1,2],[1,0,2],[0,2,1],[2,1,0],[1,2,0],[2,0,1]]

def comp3 (p q : List Nat) : List Nat :=
  [0,1,2].map fun i => p[q[i]!]!

def lEq : List Nat → List Nat → Bool
  | [], [] => true
  | a :: t1, b :: t2 => (a == b) && lEq t1 t2
  | _, _ => false

def mulS3 (x y : Nat) : Nat :=
  let target := comp3 s3perms[x]! s3perms[y]!
  ((s3perms.zip (List.range 6)).filter fun e => lEq e.1 target).map (·.2) |>.headD 0

/-- (Z/2)³：逐位异或 -/
def xor3 (x y : Nat) : Nat :=
  [0,1,2].foldl (fun acc i => acc + ((x / 2 ^ i + y / 2 ^ i) % 2) * 2 ^ i) 0

def mulOf : Nat → Nat → Nat → Nat
  | 0 => mulZ6
  | 1 => mulS3
  | _ => xor3

def domOf : Nat → List Nat
  | 0 | 1 => List.range 6
  | _ => List.range 8

/-- 群公理抽样账 -/
example : [0, 1, 2].all fun g =>
    (domOf g).all fun x => (domOf g).all fun y => (domOf g).all fun z =>
      mulOf g (mulOf g x y) z == mulOf g x (mulOf g y z)
    && (mulOf g 0 x == x) = true := by native_decide

def remDup : List Nat → List Nat :=
  fun l => l.foldl (fun acc x => if acc.contains x then acc else x :: acc) []

def prodSet (g : Nat) (s : List Nat) : List Nat :=
  remDup (s.flatMap fun x => s.map fun y => mulOf g x y)

def sameSet (a b : List Nat) : Bool := a.all (· ∈ b) && b.all (· ∈ a)

def allSubsets : List Nat → List (List Nat)
  | [] => [[]]
  | b :: t => let rest := allSubsets t
              (rest.map fun s => b :: s) ++ rest

/-- 过半 ⟹ S·S=G（Lemma 7.2.8 鸽笼引擎） -/
example : [0, 1, 2].all fun g =>
    ((allSubsets (domOf g)).filter fun S => (domOf g).length / 2 < S.length).all
      fun S => sameSet (prodSet g S) (domOf g) = true := by native_decide

example : !(sameSet (prodSet 0 [0, 1]) (List.range 6)) = true := by native_decide

/-- 稳定子账 -/
def stabOf (g : Nat) (A : List Nat) : List Nat :=
  (domOf g).filter fun x => A.all fun a => (mulOf g x a) ∈ A

example : ((stabOf 1 [1,2,3]).length, (stabOf 1 [0,4,5]).length,
    (stabOf 1 (List.range 6)).length) = (3, 3, 6) := by native_decide

/-- 群块补全（Thm 7.5.3 有限影子） -/
def partialOp (x y : Nat) : Nat :=
  if x == 2 && y == 3 then 7
  else if x == 0 then y else if y == 0 then x
  else if x == 1 && y == 1 then 0 else if x == 1 && y == 2 then 3
  else if x == 1 && y == 3 then 2
  else if x == 2 && y == 1 then 3 else if x == 2 && y == 2 then 0
  else if x == 3 && y == 1 then 2 else if x == 3 && y == 2 then 7
  else if x == 3 && y == 3 then 0 else 7

example : ((List.range 4).flatMap fun x => (List.range 4).flatMap fun y =>
    (List.range 4).map fun z => (x, y, z)).all fun t =>
    let xy := partialOp t.1 t.2.1; let yz := partialOp t.2.1 t.2.2
    !(xy != 7 && yz != 7 && partialOp xy t.2.2 != 7 && partialOp t.1 yz != 7)
      || partialOp xy t.2.2 == partialOp t.1 yz = true := by native_decide

def fullOp (x y : Nat) : Nat :=
  if x == 0 then y else if y == 0 then x
  else if x == 1 && y == 1 then 0 else if x == 1 && y == 2 then 3
  else if x == 1 && y == 3 then 2
  else if x == 2 && y == 1 then 3 else if x == 2 && y == 2 then 0
  else if x == 2 && y == 3 then 1
  else if x == 3 && y == 1 then 2 else if x == 3 && y == 2 then 1
  else 0

/-- 补全兼容 + 全表是群 -/
example : (((List.range 4).flatMap fun x => (List.range 4).map fun y => (x, y)).all
      fun p => partialOp p.1 p.2 == 7 || partialOp p.1 p.2 == fullOp p.1 p.2)
    && ((List.range 4).flatMap fun x => (List.range 4).flatMap fun y =>
        (List.range 4).map fun z => (x, y, z)).all fun t =>
        fullOp (fullOp t.1 t.2.1) t.2.2 == fullOp t.1 (fullOp t.2.1 t.2.2)
    = true := by native_decide

/-- 和集稳定化（Zil'ber 有限影子） -/
def addSet (A B : List Nat) : List Nat :=
  (A.flatMap fun x => B.map fun y => xor3 x y).foldl
    (fun acc v => if acc.contains v then acc else v :: acc) []

def accumAdd (S : List Nat) : List Nat := remDup (S ++ addSet S S)

def sumIter : Nat → List Nat → List Nat
  | 0, S => S
  | f + 1, S =>
      let s' := accumAdd S
      if s'.length == S.length then s' else sumIter f s'

example : (sameSet (sumIter 8 [1, 3]) [0,1,2,3],
    sameSet (sumIter 8 [1]) [0,1], sameSet (sumIter 8 [1,2,4]) (List.range 8))
    = (true, true, true) := by native_decide
