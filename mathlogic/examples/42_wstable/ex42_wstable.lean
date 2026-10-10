/- ex42_wstable.lean —— ω-稳定与 Morley 秩（Marker GTM 217 §6.1-6.2），Coq 侧同构镜像 -/

/-- E_inf 可定义集范式 -/
structure DSet where
  inc : List (Nat × List Nat)
  rest : Bool
  pts : List (Nat × Nat)

def inD (D : DSet) (c j : Nat) : Bool :=
  D.inc.any fun e => c == e.1 && !e.2.any (j == ·)
  || D.pts.any fun e => c == e.1 && j == e.2
  || (D.rest && !D.inc.any fun e => c == e.1)

/-- Morley 秩的范式计算器 -/
def rmD (D : DSet) : Option Nat :=
  if D.rest then some 2
  else if D.inc.length != 0 then some 1
  else if D.pts.length != 0 then some 0
  else none

def degD (D : DSet) : Nat :=
  match rmD D with
  | some 1 => D.inc.length
  | _ => 1

def pt (c j : Nat) : DSet := ⟨[], false, [(c, j)]⟩
def cls (c : Nat) : DSet := ⟨[(c, [])], false, []⟩
def universeD : DSet := ⟨[], true, []⟩

/-- 三层账 -/
example : (rmD (pt 3 7), rmD (cls 5), rmD universeD,
    degD ⟨[(3,[]),(5,[]),(9,[]),(11,[])], false, [(7,0)]⟩, degD universeD)
    = (some 0, some 1, some 2, 4, 1) := by native_decide

/-- 分拆见证：全域拆 k 片两两不交 rank-1；类拆 k 片 rank-0 -/
def disjointPair (D D' : DSet) : Bool :=
  !((List.range 6).any fun x => (List.range 6).any fun y => inD D x y && inD D' x y)

example : (List.range 8).all fun k =>
    ((List.range k).map cls).all (rmD · == some 1)
    && ((List.range k).flatMap fun i => (List.range k).map fun j => (i, j)).all
        fun p => p.1 == p.2 || disjointPair (cls p.1) (cls p.2)
    = true := by native_decide

example : (List.range 12).all fun k =>
    ((List.range k).map (pt 5)).all fun D => rmD D == some 0 = true := by
  native_decide

/-- 新鲜类引理：maxl+1 永在有限表外 -/
def maxl : List Nat → Nat
  | [] => 0
  | x :: t => max x (maxl t)

example : [ [1,5,3], [0], [9,2,4,7] ].all fun l =>
    !l.contains (maxl l + 1) = true := by native_decide

/-- 覆盖泄漏账 -/
def bads (Ds : List DSet) : List Nat :=
  Ds.flatMap fun D => D.inc.map (·.1) ++ D.pts.map (·.1)

def leak (Ds : List DSet) : Nat × Nat := (maxl (bads Ds) + 1, 0)

example : [ [cls 0, cls 1, cls 2]
    , [cls 0, pt 1 0, ⟨[(3,[0,1])], false, []⟩]
    , [pt 0 0, pt 0 1, cls 5] ].all fun Ds =>
    (Ds.all fun D => !D.rest) → !Ds.any fun D => inD D (leak Ds).1 (leak Ds).2
    = true := by native_decide

/-- ω-稳定性对账：|S₁(A)| = 3k+1 线性增长 -/
def atomEv (op c j ci ji : Nat) : Bool :=
  match op with
  | 0 => c == ci && j == ji
  | 1 => c == ci
  | _ => !(c == ci)

def prof (A : List (Nat × Nat)) (c j : Nat) : List Bool :=
  A.flatMap fun a => [atomEv 0 c j a.1 a.2, atomEv 1 c j a.1 a.2, atomEv 2 c j a.1 a.2]

def dedupP : List (List Bool) → List (List Bool)
  | [] => []
  | p :: t => if t.any (· == p) then dedupP t else p :: dedupP t

def paramsOf (k : Nat) : List (Nat × Nat) :=
  (List.range k).flatMap fun c => [(c, 0), (c, 1)]

def evid (k : Nat) : List (Nat × Nat) :=
  (List.range k).flatMap fun c => [(c, 0), (c, 1), (c, 2)]
  ++ [(k, 0), (k, 1), (k + 1, 0), (k + 1, 1)]

def typeCountE (k : Nat) : Nat :=
  (dedupP ((evid k).map fun e => prof (paramsOf k) e.1 e.2)).length

example : ((List.range 6).map fun i => typeCountE (i + 1))
    = [4, 7, 10, 13, 16, 19] := by native_decide
