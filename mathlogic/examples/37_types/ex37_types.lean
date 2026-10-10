/- ex37_types.lean —— 型与 Stone 空间（Marker GTM 217 §4.1），Coq 侧同构镜像 -/

inductive Term : Type
  | tz (k : Nat)              -- S^k 0
  | tx (k i : Nat)            -- S^k x_i

inductive Pf : Type
  | aEq (t1 t2 : Term)
  | not (p : Pf)
  | and (p q : Pf)
  | or (p q : Pf)

def iterK : Nat → (Nat → Nat) → Nat → Nat
  | 0, _, x => x
  | k + 1, f, x => iterK k f (f x)

def evT (t : Term) (asg : List Nat) (step : Nat → Nat) : Nat :=
  match t with
  | .tz k => iterK k step 0
  | .tx k i => iterK k step (asg.getD i 0)

def evP : Pf → List Nat → (Nat → Nat) → Bool
  | .aEq t1 t2, asg, step => evT t1 asg step == evT t2 asg step
  | .not q, asg, step => !evP q asg step
  | .and p q, asg, step => evP p asg step && evP q asg step
  | .or p q, asg, step => evP p asg step || evP q asg step

def terms (n B : Nat) : List Term :=
  Term.tz 0 :: ((List.range (B + 1)).flatMap fun k =>
      (List.range n).map fun i => Term.tx k i)
    ++ (List.range B).map fun k => Term.tz (k + 1)

def atomsOf (n B : Nat) : List Pf :=
  (terms n B).flatMap fun t1 => (terms n B).map fun t2 => .aEq t1 t2

def formsD (atoms : List Pf) : Nat → List Pf
  | 0 => atoms
  | _ + 1 =>
      let base := formsD atoms 0
      (base ++ base.map Pf.not
        ++ base.flatMap fun p => base.map fun q => Pf.and p q)
        ++ base.flatMap fun p => base.map fun q => Pf.or p q

def profile (fs : List Pf) (asg : List Nat) (step : Nat → Nat) : List Bool :=
  fs.map fun p => evP p asg step

def dedupProf : List (List Bool) → List (List Bool) :=
  fun l => l.foldl (fun acc pr => if acc.any (· == pr) then acc else pr :: acc) []

def iterK2 : Nat → (List (List Nat) → List (List Nat)) → List (List Nat) → List (List Nat)
  | 0, _, x => x
  | k + 1, f, x => iterK2 k f (f x)

def asgs (dom : List Nat) (n : Nat) : List (List Nat) :=
  iterK2 n (fun L => L.flatMap fun a => dom.map fun t => a ++ [t]) [[]]

def typeCount (dom : List Nat) (n B d : Nat) (step : Nat → Nat) : Nat :=
  (dedupProf ((asgs dom n).map fun a => profile (formsD (atomsOf n B) d) a step)).length

def typeCountNC (dom : List Nat) (n B d : Nat) (step : Nat → Nat) : Nat :=
  let termsNC := (List.range (B + 1)).flatMap fun k =>
    (List.range n).map fun i => Term.tx k i
  let atoms := termsNC.flatMap fun t1 => termsNC.map fun t2 => Pf.aEq t1 t2
  (dedupProf ((asgs dom n).map fun a => profile (formsD atoms d) a step)).length

def id1 (x : Nat) : Nat := x
def stepMod (m x : Nat) : Nat := (x + 1) % m
def stepN (x : Nat) : Nat := x + 1

/-- Bell 数对账：纯等词理论 S₁=1/S₂=2/S₃=5/S₄=15 -/
example : (typeCountNC (List.range 5) 1 0 0 id1,
    typeCountNC (List.range 5) 2 0 0 id1,
    typeCountNC (List.range 5) 3 0 0 id1,
    typeCountNC (List.range 5) 4 0 0 id1) = (1, 2, 5, 15) := by native_decide

/-- 跨结构不变性 -/
example : (typeCountNC (List.range 6) 3 0 0 id1,
    typeCountNC (List.range 7) 3 0 0 id1) = (5, 5) := by native_decide

/-- (Z_m,S,0)：常量+后继把型空间剁碎，|S₁|=m -/
example : (typeCount (List.range 4) 1 4 1 (stepMod 4),
    typeCount (List.range 6) 1 6 1 (stepMod 6)) = (4, 6) := by native_decide

/-- (N,S,0) 的 ∞ 型：B=8 截断宇宙型数=10（0..8+∞） -/
example : typeCount (List.range 12) 1 8 1 stepN = 10 := by native_decide

/-- 非孤立性：在 v=9 真的公式都在某个 v ≤ 8 真 -/
example : (formsD (atomsOf 1 8) 1).all fun f =>
    !(evP f [9] stepN)
      || (List.range 9).any fun v => evP f [v] stepN = true := by native_decide

/-- 孤立见证：每个 v ∈ Z₆ 有公式单点分离（[φ]={p}） -/
example : (List.range 6).all fun v =>
    (formsD (atomsOf 1 3) 1).any fun f =>
      evP f [v] (stepMod 6)
        && (List.range 6).all fun w =>
            !(evP f [w] (stepMod 6)) || w == v = true := by native_decide

/-- DLO 切割组合学：割形状与「割决定型」 -/
def cutOf (A : List Nat) (v : Nat) : Nat :=
  (A.filter fun a => a < v).length

example : [0,1,2,3,4,5,7,9].map (fun v => cutOf [1,3,4,7] v)
    = [0,0,1,1,2,3,3,4] := by native_decide

/-- Stone 代数：[φ∨ψ]=[φ]∪[ψ]、[φ∧ψ]=[φ]∩[ψ] -/
def bracket (f : Pf) (dom : List Nat) (step : Nat → Nat) : List Bool :=
  dom.map fun v => evP f [v] step

def stonePair (q r : Pf) : Bool :=
  (bracket (.or q r) (List.range 6) (stepMod 6)
      == (bracket q (List.range 6) (stepMod 6)).zipWith (· || ·)
        (bracket r (List.range 6) (stepMod 6)))
  && (bracket (.and q r) (List.range 6) (stepMod 6)
      == (bracket q (List.range 6) (stepMod 6)).zipWith (· && ·)
        (bracket r (List.range 6) (stepMod 6)))

def smallForms : List Pf := formsD (atomsOf 1 1) 1

example : smallForms.all fun q =>
    smallForms.all fun r => stonePair q r = true := by native_decide
