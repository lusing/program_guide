/- ex38_omitprime.lean —— 省略型与素模型（Marker GTM 217 §4.2），Coq 侧同构镜像 -/

def litOK (asg : List Nat) (l : Nat × Nat × Bool) : Bool :=
  if l.2.2 then asg.getD l.1 0 == asg.getD l.2.1 0
  else !(asg.getD l.1 0 == asg.getD l.2.1 0)

def allAssigns : Nat → Nat → List (List Nat)
  | 0, _ => [[]]
  | k + 1, R =>
      (List.range (R + 1)).flatMap fun v =>
        (allAssigns k R).map fun t => v :: t

def satLits (R : Nat) (L : List (Nat × Nat × Bool)) : Bool :=
  (allAssigns 4 R).any fun asg => L.all (litOK asg)

/-- T_c = {c_i ≠ c_j}；阶段记录 (阶段号, 动作码, 追加文字)：
    0=init、1=完备、2=见证、3=省略 -/
def Tc : List (Nat × Nat × Bool) :=
  [(0,1,false),(0,2,false),(0,3,false),(1,2,false),(1,3,false),(2,3,false)]

def henkinTrace : List (Nat × Nat × List (Nat × Nat × Bool)) :=
  [ (0, 0, Tc)
  , (1, 1, [(0,0,true)])
  , (2, 2, [(1,0,false)])
  , (3, 3, [(0,0,true)])
  , (4, 1, [(1,1,true)])
  , (5, 2, [(2,1,false)])
  , (6, 3, [(1,1,true)])
  , (7, 3, [(2,2,true)])
  , (8, 3, [(3,3,true)]) ]

def stateAt (s : Nat) : List (Nat × Nat × Bool) :=
  henkinTrace.foldl (fun acc r => if r.1 ≤ s then acc ++ r.2.2 else acc) []

/-- 每阶段后状态可满足 -/
example : (List.range 9).all fun s => satLits 3 (stateAt s) = true := by
  native_decide

/-- 省略记账：每个 c_k 被 ¬φ（φ∈p）钉住 -/
example : (List.range 4).all fun k =>
    henkinTrace.any fun r => r.2.2.any fun l =>
      l.2.2 && l.1 == k && l.2.1 == k = true := by native_decide

/-- PA 端扩张的鸽洞账（Thm 4.2.5 (**)） -/
def thetaList : List (Nat → Nat → Bool) :=
  [ fun v y => v == y
  , fun v y => v < y
  , fun v y => y < v
  , fun v y => !(v < y)
  , fun v y => !(v == y)
  , fun v y => v < y || v == y ]

def aBound : Nat := 4
def kBound : Nat := 12

def pqPremise (th : Nat → Nat → Bool) : Bool :=
  (List.range kBound).all fun x =>
    ((List.range (kBound - x)).map (· + (x + 1))).any fun y =>
      x < y && (List.range aBound).any fun v => v < aBound && th v y

def pqConcl (th : Nat → Nat → Bool) : Bool :=
  (List.range aBound).any fun v =>
    v < aBound && (List.range kBound).all fun x =>
      ((List.range (kBound - x)).map (· + (x + 1))).any fun y =>
        x < y && th v y

example : thetaList.all fun th => (!(pqPremise th) || pqConcl th) = true := by
  native_decide

/-- 鸽洞必须用 y 无界 -/
example : ((List.range kBound).drop 1).all fun y =>
      (List.range aBound).any fun v => v < y
    && !((List.range aBound).any fun v =>
        (List.range kBound).all fun y => v < y) = true := by
  native_decide

/-- 素模型=项模型：(Z_6,S,0) -/
def step6 (x : Nat) : Nat := (x + 1) % 6

def iterK : Nat → (Nat → Nat) → Nat → Nat
  | 0, _, x => x
  | k + 1, f, x => iterK k f (f x)

def termClosure : List Nat :=
  (List.range 12).foldl (fun acc k =>
      let v := iterK k step6 0
      if acc.contains v then acc else acc ++ [v]) []

example : (termClosure.length, (List.range 6).all fun v => termClosure.contains v)
    = (6, true) := by native_decide

/-- 每个元素被 x=S^k 0 孤立——素模型只实现孤立型 -/
example : (List.range 6).all fun v =>
    (List.range 6).any fun k => iterK k step6 0 == v = true := by
  native_decide
