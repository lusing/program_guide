/- ex44_saturated.lean —— 饱和与齐次模型（Marker GTM 217 §4.3），Coq 侧同构镜像 -/

inductive Term : Type
  | tz (k : Nat)
  | tp (k i : Nat)
  | tx (k : Nat)

inductive Pf : Type
  | aEq (t1 t2 : Term)
  | not (p : Pf)
  | andP (p q : Pf)
  | orP (p q : Pf)

def iterK : Nat → (Nat → Nat) → Nat → Nat
  | 0, _, x => x
  | k + 1, f, x => iterK k f (f x)

def evT (t : Term) (x : Nat) (A : List Nat) (step : Nat → Nat) : Nat :=
  match t with
  | .tz k => iterK k step 0
  | .tp k i => iterK k step (A.getD i 0)
  | .tx k => iterK k step x

def evP : Pf → Nat → List Nat → (Nat → Nat) → Bool
  | .aEq t1 t2, x, A, step => evT t1 x A step == evT t2 x A step
  | .not q, x, A, step => !evP q x A step
  | .andP p q, x, A, step => evP p x A step && evP q x A step
  | .orP p q, x, A, step => evP p x A step || evP q x A step

def terms (nA B : Nat) : List Term :=
  ((List.range (B + 1)).map Term.tz
    ++ (List.range (B + 1)).flatMap fun k =>
        (List.range nA).map fun i => Term.tp k i)
  ++ (List.range (B + 1)).map Term.tx

def atoms (nA B : Nat) : List Pf :=
  (terms nA B).flatMap fun t1 => (terms nA B).map fun t2 => Pf.aEq t1 t2

def forms (nA B : Nat) : List Pf :=
  (atoms nA B) ++ (atoms nA B).map Pf.not
    ++ (atoms nA B).flatMap fun p => (atoms nA B).map fun q => Pf.andP p q

def profile (fs : List Pf) (x : Nat) (A : List Nat) (step : Nat → Nat) : List Bool :=
  fs.map fun p => evP p x A step

def realizedIn (fs : List Pf) (A dom : List Nat) (step : Nat → Nat) (x : Nat) : Bool :=
  dom.any fun w => profile fs x A step == profile fs w A step

def satCheck (fs : List Pf) (A dom evid : List Nat) (step : Nat → Nat) : Bool :=
  evid.all fun x => realizedIn fs A dom step x

def stepN (x : Nat) : Nat := x + 1
def stepClamp5 (x : Nat) : Nat := min (x + 1) 4

def rangeL (n : Nat) : List Nat := List.range n

/-- (N,S,0) 逐层饱和：B=3 层公式、A={0,2}、证据 0..14 全实现 -/
example : satCheck (forms 2 3) [0, 2] (rangeL 15) (rangeL 15) stepN = true := by
  native_decide

/-- 钳位 M₅ 的破口：∞ 型未实现=不饱和现场 -/
example : !realizedIn (forms 0 6) [] (rangeL 5) stepClamp5 7 = true := by
  native_decide

/-- DLO 有限影子：序原子 profile -/
def oprofile (x : Nat) (A : List Nat) : List Bool :=
  (List.range A.length).flatMap fun i => [A.getD i 0 < x, x < A.getD i 0]

def cutProfile (A : List Nat) (p : Nat) : List Bool :=
  (List.range A.length).flatMap fun i => [i < p, !(i < p)]

def dedupP : List (List Bool) → List (List Bool)
  | [] => []
  | pr :: t => if t.any (· == pr) then dedupP t else pr :: dedupP t

def dloTypes (A : List Nat) : List (List Bool) :=
  (List.range (A.length + 1)).map (cutProfile A)
  ++ (List.range A.length).map fun k => oprofile (A.getD k 0) A

/-- |A|=m 时 S₁(A)=2m+1（Ex 4.3.9） -/
example : ((dedupP (dloTypes [0,5])).length, (dedupP (dloTypes [0,3,5])).length)
    = (5, 7) := by native_decide

def cutRealized (A dom : List Nat) (p : Nat) : Bool :=
  dom.any fun w => cutProfile A p == oprofile w A

/-- 密度=实现：中割在稠密 dom 实现、在稀疏 dom 破口 -/
example : (cutRealized [0,5] [0,2,5] 1, cutRealized [0,5] [0,5] 1) = (true, false) := by
  native_decide

/-- (Q,<) 对有限 A 的 2m+1 型全实现 -/
example : (List.range 3).all fun p => cutRealized [1,5] [0,1,2,3,4,5,6] p = true := by
  native_decide

/-- 尾平移同型、命名点不可挪 -/
def sameType (fs : List Pf) (A : List Nat) (step : Nat → Nat) (x y : Nat) : Bool :=
  profile fs x A step == profile fs y A step

example : (sameType (forms 0 6) [] stepN 7 8
    && sameType (forms 0 6) [] stepN 9 10) = true := by native_decide

example : !(sameType (forms 0 6) [] stepN 0 1) = true := by native_decide

/-- 饱和⟹齐次的样本装配（Prop 4.3.3） -/
example : (rangeL 15).any fun c =>
    sameType (forms 0 6) [] stepN 7 8 && sameType (forms 0 6) [] stepN 9 c = true := by
  native_decide
