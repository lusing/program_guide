/- ex45_pregeom.lean —— 强极小集的几何（Marker GTM 217 §8），Coq 侧同构镜像 -/

def forallb {A} (f : A → Bool) (l : List A) : Bool := l.all f
def existsb {A} (f : A → Bool) (l : List A) : Bool := l.any f

def inclb (l1 l2 : List Nat) : Bool := l1.all fun x => l2.contains x
def sameSet (l1 l2 : List Nat) : Bool := inclb l1 l2 && inclb l2 l1

def xor3 (x y : Nat) : Nat :=
  [0,1,2].foldl (fun acc i => acc + ((x / 2 ^ i + y / 2 ^ i) % 2) * 2 ^ i) 0

def remDupNat : List Nat → List Nat
  | [] => []
  | x :: t => if t.contains x then remDupNat t else x :: remDupNat t

/-- 线性张成（F₂³） -/
def linClF : Nat → List Nat → List Nat
  | 0, s => s
  | f + 1, s =>
      let s' := (s.flatMap fun x => s.map fun y => xor3 x y).foldl
        (fun acc v => if acc.contains v then acc else v :: acc) s
      if s'.length == s.length then s' else linClF f s'

def linCl (s : List Nat) : List Nat :=
  if s.contains 0 then linClF 32 s else linClF 32 (0 :: s)

/-- F₃² 仿射闭包：过两点的直线闭包 -/
def line3 (p q : Nat) : List Nat :=
  remDupNat ([0,1,2].map fun t =>
    ((p / 3 + t * ((q / 3 + 3 - p / 3) % 3)) % 3) * 3
    + (p % 3 + t * ((q % 3 + 3 - p % 3) % 3)) % 3)

def affClF : Nat → List Nat → List Nat
  | 0, s => s
  | f + 1, s =>
      let s' := (s.flatMap fun x => s.map fun y => (x, y)).foldl
        (fun acc p => (line3 p.1 p.2).foldl
          (fun acc2 v => if acc2.contains v then acc2 else v :: acc2) acc) s
      if s'.length == s.length then s' else affClF f s'

def affCl (s : List Nat) : List Nat := affClF 64 (remDupNat s)

def exchange (cl : List Nat → List Nat) (A : List Nat) (a b : Nat) : Bool :=
  !((cl (remDupNat (a :: A))).contains b && !((cl A).contains b))
    || (cl (remDupNat (b :: A))).contains a

def allSubsets : List Nat → List (List Nat)
  | [] => [[]]
  | b :: t => let rest := allSubsets t
              (rest.map fun s => b :: s) ++ rest

def cartNN (xs ys : List Nat) : List (Nat × Nat) :=
  xs.flatMap fun x => ys.map fun y => (x, y)

def exchCases2 : List (List Nat × (Nat × Nat)) :=
  (allSubsets [1,2,4,3]).flatMap fun A =>
    (cartNN [1,2,4,3,5,6,7] [1,2,4,3,5,6,7]).map fun p => (A, p)

/-- 线性交换律（Steinitz） -/
example : exchCases2.all fun c => exchange linCl c.1 c.2.1 c.2.2 = true := by
  native_decide

def exchCases3 : List (List Nat × (Nat × Nat)) :=
  (allSubsets [0,1,3,4]).flatMap fun A =>
    (cartNN (List.range 9) (List.range 9)).map fun p => (A, p)

/-- 仿射交换律 -/
example : exchCases3.all fun c => exchange affCl c.1 c.2.1 c.2.2 = true := by
  native_decide

/-- 平凡闭包 -/
example : exchCases2.all fun c =>
    exchange (fun l => l) c.1 c.2.1 c.2.2 = true := by native_decide

/-- Z₄ 群闭包：交换律破口 -/
def z4pairs (s : List Nat) : List Nat :=
  (s.flatMap fun x => s.map fun y => (x, y)).foldl
    (fun acc p =>
      let v1 := (p.1 + p.2) % 4
      let v2 := (p.1 + 4 - p.2) % 4
      (if acc.contains v1 then acc else v1 :: acc)
        |> fun acc' => if acc'.contains v2 then acc' else v2 :: acc') s

def z4ClF : Nat → List Nat → List Nat
  | 0, s => s
  | f + 1, s =>
      let s' := z4pairs s
      if s'.length == s.length then s' else z4ClF f s'

def z4Cl (s : List Nat) : List Nat := z4ClF 8 (remDupNat (0 :: s))

example : ((z4Cl [1]).contains 2 && !((z4Cl [2]).contains 1)) = true := by
  native_decide

/-- 偏序下闭包：交换律破口 -/
def downCl (A : List Nat) : List Nat :=
  A.foldl (fun acc a => (List.range (a + 1)).foldl
    (fun acc2 v => if acc2.contains v then acc2 else v :: acc2) acc) []

example : ((downCl [3]).contains 2 && !((downCl [2]).contains 3)) = true := by
  native_decide

/-- 维度版模律与局部化 -/
def sub3 (p q : Nat) : Nat :=
  ((p / 3 + 3 - q / 3) % 3) * 3 + (p % 3 + 3 - q % 3) % 3

def onLine0 (u v : Nat) : Bool :=
  v == 0 || u == 0 || [0,1,2].any fun t =>
    (t * (v / 3)) % 3 * 3 + (t * (v % 3)) % 3 == u

def dimL (S : List Nat) : Nat :=
  let nz := S.filter fun v => v != 0
  if nz.length == 0 then 0
  else match nz with
    | h :: _ => if nz.all fun v => onLine0 v h then 1 else 2
    | [] => 0

def dimA : List Nat → Option Nat
  | [] => none
  | s0 :: rest => some (dimL ((remDupNat (s0 :: rest)).map fun s => sub3 s s0))

def dimEq (a b : Option Nat) : Bool :=
  match a, b with
  | none, none => true
  | some x, some y => x == y
  | _, _ => false

def modDim (cl : List Nat → List Nat) (X Y : List Nat) : Bool :=
  let dX := dimA (cl X)
  let dY := dimA (cl Y)
  let dU := dimA (cl (remDupNat (X ++ Y)))
  let dI := dimA ((cl X).filter fun x => (cl Y).contains x)
  match dX, dY with
  | some a, some b =>
      match dI with
      | none => dimEq (some (a + b)) (match dU with | some u => some (u + 1) | none => none)
      | some i => dimEq (some (a + b)) (match dU with | some u => some (u + i) | none => none)
  | _, _ => true

/-- 仿射非模：平行线 {1,2} 与 {4,5}（x=0 与 x=1 两列）不相交 -/
example : !(modDim affCl [1, 2] [4, 5]) = true := by native_decide

/-- 相交线对照 -/
example : modDim affCl [1, 2] [1, 3] = true := by native_decide

/-- 局部化修复平行线破口 -/
def affCl0 (X : List Nat) : List Nat := affCl (remDupNat (0 :: X))

example : modDim affCl0 [1, 2] [4, 5] = true := by native_decide

example : ((allSubsets [1,2]).flatMap fun x => (allSubsets [4,5,3]).map fun y => (x, y)).all
    fun p => modDim affCl0 p.1 p.2 = true := by native_decide

/-- 线性 F₂³ 的模律（rank 机：redGo 全基重启版） -/
def lowbit2F : Nat → Nat → Nat
  | 0, _ => 0
  | f + 1, x => if x == 0 then 0 else if x % 2 == 1 then 0 else lowbit2F f (x / 2) + 1

def lowbit2 (x : Nat) : Nat := lowbit2F 8 x

def redGo : Nat → List Nat → List Nat → Nat → Nat
  | 0, _, _, v => v
  | _ + 1, _full, [], v => v
  | f + 1, full, p :: t, v =>
      if v / 2 ^ (lowbit2 p) % 2 == 1 then redGo f full full (xor3 v p)
      else redGo f full t v

def rank2 (S : List Nat) (basis : List Nat) : Nat :=
  match S with
  | [] => basis.length
  | v :: t =>
      let w := redGo 16 basis basis v
      if w == 0 then rank2 t basis else rank2 t (w :: basis)

def modDim2 (X Y : List Nat) : Bool :=
  rank2 (linCl X) [] + rank2 (linCl Y) []
    == rank2 (linCl (remDupNat (X ++ Y))) []
      + rank2 ((linCl X).filter fun x => (linCl Y).contains x) []

example : ((allSubsets [1,2]).flatMap fun x => (allSubsets [3,5,6]).map fun y => (x, y)).all
    fun p => modDim2 p.1 p.2 = true := by native_decide
