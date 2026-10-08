/- ex47 —— 算术的模型（Marker ch16）Lean 镜像
   有限可满足+overspill 影子+R(3,3)=6+PH(2,2) 账。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

def bits : Nat → List (List Bool)
  | 0 => [[]]
  | m+1 => (bits m).map (fun l => false :: l) ++ (bits m).map (fun l => true :: l)

def edge (m : Nat) : List (Nat × Nat) :=
  (List.range m).flatMap (fun i =>
    ((List.range m).filter (fun j => j < i)).map (fun j => (j, i)))

def pos2 (p : Nat × Nat) : List (Nat × Nat) → Nat
  | [] => 0
  | h :: r => if p.1 == h.1 && p.2 == h.2 then 0 else pos2 p r + 1

def colorE (m : Nat) (b : List Bool) (i j : Nat) : Bool :=
  b.getD (pos2 (min i j, max i j) (edge m)) false

def triples (m : Nat) : List (Nat × Nat × Nat) :=
  (List.range m).flatMap (fun i =>
    ((List.range m).filter (fun j => j < i)).flatMap (fun j =>
      ((List.range m).filter (fun k => k < j)).map (fun k => (i, j, k))))

def hasTri (m : Nat) (b : List Bool) : Bool :=
  (triples m).any (fun t =>
    colorE m b t.1 t.2.1 == colorE m b t.1 t.2.2
      && colorE m b t.1 t.2.1 == colorE m b t.2.1 t.2.2)

-- K5：存在三角无关染色；K6：一切染色有单色三角
example : (bits 10).any (fun b => !hasTri 5 b) = true := by native_decide

example : (bits 15).all (fun b => hasTri 6 b) = true := by native_decide

-- ---------- PH(2,2)：min-homogeneous ----------

def pairsOf : List Nat → List (Nat × Nat)
  | [] | [_] => []
  | a :: t => t.map (fun x => (a, x)) ++ pairsOf t

def homPairs (m : Nat) (b : List Bool) (X : List Nat) : Bool :=
  (pairsOf X).all (fun p =>
    colorE m b p.1 p.2 == colorE m b (X.getD 0 0) (X.getD 1 0))

def minhom2 (m : Nat) (b : List Bool) (X : List Nat) : Bool :=
  homPairs m b X && (X.getD 0 0 < X.length)

def subsetsL : List Nat → List (List Nat)
  | [] => [[]]
  | a :: t => subsetsL t ++ (subsetsL t).map (fun l => a :: l)

def phHolds (m : Nat) : Bool :=
  (bits (edge m).length).all (fun b =>
    ((subsetsL (List.range m)).filter (fun X =>
      match X with | [] | [_] => false | _ => true)).any (minhom2 m b))

example : [3,4,5].map phHolds = [true, true, true] := by native_decide

-- overspill 有限影子
def Inf : Nat := 999

def evalF (f x : Nat) : Bool :=
  match f with
  | 0 => true
  | 1 => false
  | 2 => if x == 999 then false else x == 0
  | 3 => if x == 999 then false else x == 1
  | 4 => if x == 999 then false else x == 2
  | 8 => !(if x == 999 then false else x == 0)
  | 9 => !(if x == 999 then false else x == 1)
  | 10 => !(if x == 999 then false else x == 2)
  | _ => true

example : [0,8,9,10].all (fun f =>
    !(List.range 16).all (fun x => evalF f x) || evalF f Inf) = true := by
  native_decide

#eval ([3,4,5].map phHolds, (bits 10).length)
