/- ex48_forking.lean —— 分叉与独立性（Marker GTM 217 §6.3-6.5），Coq 侧同构镜像 -/

def cl (x : Nat) : Nat := x / 10
def clsOf (A : List Nat) : List Nat := A.map cl

def rmTP (a : Nat) (A : List Nat) : Nat :=
  if A.contains a then 0
  else if (clsOf A).contains (cl a) then 1
  else 2

def indep (a : Nat) (A : List Nat) : Bool :=
  !((clsOf A).contains (cl a))

def forks (a : Nat) (A B : List Nat) : Bool := rmTP a B < rmTP a A

/-- 账一：秩的三级降落 -/
example : (rmTP 50 [10, 11], rmTP 50 [20, 21], rmTP 50 [50, 20],
    forks 50 [20, 21] [21, 50], forks 50 [30] [55]) = (2, 2, 0, true, true) := by
  native_decide

def maxl : List Nat → Nat
  | [] => 0
  | x :: t => max x (maxl t)

/-- 账二：不分叉延拓存在 -/
def nonforkW (_a : Nat) (A B : List Nat) : Nat :=
  10 * (maxl (clsOf B ++ clsOf A) + 2)

example : [ (([10, 11], [10, 11, 20]), 50), (([], [10, 20, 30]), 99),
    (([5], [5, 15, 25]), 42) ].all fun spec =>
    let A := spec.1.1; let B := spec.1.2; let a := spec.2
    !(rmTP a A == 2)
      || (rmTP (nonforkW a A B) B == 2 && rmTP (nonforkW a A B) A == 2)
    = true := by native_decide

/-- F₂⁴ 的维数公式账本 -/
def xorb4 (a b : Nat) : Nat :=
  [0, 1, 2, 3].foldl (fun acc i => acc + ((a / 2 ^ i + b / 2 ^ i) % 2) * 2 ^ i) 0

def lowbitF : Nat → Nat → Nat
  | 0, _ => 0
  | f + 1, x => if x == 0 then 0 else if x % 2 == 1 then 0 else lowbitF f (x / 2) + 1

def lowbit (x : Nat) : Nat := lowbitF 8 x

def addVec : List Nat → Nat → List Nat
  | [], v => if v == 0 then [] else [v]
  | p :: t, v =>
      if v / 2 ^ (lowbit p) % 2 == 1 then p :: addVec t (xorb4 v p)
      else p :: addVec t v

def dimOf (l : List Nat) : Nat :=
  (l.foldl (fun acc v => addVec acc v) []).length

def spanOf (s : List Nat) : List Nat :=
  let s0 := (0 :: s.map (· % 16)).eraseDups
  let rec step : Nat → List Nat → List Nat
    | 0, cur => cur
    | f + 1, cur =>
        let s' := (cur.flatMap fun x => cur.map fun y => xorb4 x y).foldl
          (fun acc v => if acc.contains v then acc else v :: acc) cur
        if s'.length == cur.length then s' else step f s'
  step 64 s0

def interL (l1 l2 : List Nat) : List Nat := l1.filter fun x => l2.contains x

def sampleGens : List (List Nat × List Nat) :=
  [ ([1, 2], [1, 3]), ([1, 2, 4], [3, 5]), ([1, 2, 4, 8], [3, 5, 6])
  , ([1, 2, 4], [4, 8]), ([3, 6, 12], [1, 5, 9]), ([7, 8], [1, 2, 4]) ]

/-- 维数公式：dim(U+V)+dim(U∩V)=dim U+dim V -/
example : sampleGens.all fun g =>
    let U := spanOf g.1; let V := spanOf g.2
    dimOf (U ++ V) + dimOf (interL U V) == dimOf U + dimOf V = true := by
  native_decide

/-- 独立性的维数刻画 -/
def ideq (spec : (List Nat × Nat) × Nat) : Bool :=
    let A := spec.1.1; let a := spec.1.2; let b := spec.2
    let lhs := dimOf (A ++ [a, b])
    let rhs := dimOf (A ++ [a]) + dimOf (A ++ [b]) - dimOf A
    (lhs == rhs)
      == (!(spanOf (A ++ [a])).any (fun x => xorb4 x b == 0)
            && !(spanOf (A ++ [b])).any (fun x => xorb4 x a == 0))

example : [ (([], 1), 2), (([], 1), 3), (([], 1), 1), (([1], 2), 3),
    (([1], 2), 2) ].all ideq = true := by native_decide

/-- Morley 序列构造器 -/
def morleySeq : List Nat → Nat → List Nat
  | _, 0 => []
  | A, k + 1 =>
      let prev := morleySeq A k
      (10 * (maxl (clsOf (A ++ prev)) + 1) + 1) :: prev

def eAtom (op x a : Nat) : Bool :=
  match op with
  | 0 => x == a
  | 1 => cl x == cl a
  | _ => !(cl x == cl a)

def eProf (A : List Nat) (x : Nat) : List Bool :=
  A.flatMap fun a => [eAtom 0 x a, eAtom 1 x a, eAtom 2 x a]

/-- Morley 序列两两不可辨+独立性逐元 -/
example :
    let A := [10, 21]
    let ms := morleySeq A 5
    ((List.range 5).all fun i => (List.range 5).all fun j =>
        !(i < j) || eProf A ms[i]! == eProf A ms[j]!)
    && ((List.range 5).all fun i => indep ms[i]! (A ++ (List.take i ms)))
    = true := by native_decide
