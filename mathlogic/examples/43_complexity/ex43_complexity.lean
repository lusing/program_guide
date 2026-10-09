/- ex43 —— 复杂度：P 与 NP（Müller-Stach ch5）Lean 镜像
   证书验证 vs 蛮力步数双账 + SAT→3SAT 归约组合子双向对账 +
   3SAT→CLIQUE 文字图 + 团-赋值 witnessing + 归约复合传递。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

abbrev Lit := Nat × Bool   -- (变元号, 正负)
abbrev Clause := List Lit
abbrev Cnf := List Clause

def asgGet (a : List Bool) (v : Nat) : Bool := a.getD v false

def litSat (a : List Bool) (l : Lit) : Bool :=
  match l with
  | (v, true) => asgGet a v
  | (v, false) => !asgGet a v

def clauseSat (a : List Bool) (c : Clause) : Bool := (c.map (litSat a)).any id

def cnfSat (a : List Bool) (F : Cnf) : Bool := (F.map (clauseSat a)).all id

def litCount (F : Cnf) : Nat := (F.map (fun c => c.length)).sum

def pow2 : Nat → Nat
  | 0 => 1
  | n + 1 => 2 * pow2 n

def allAsg : Nat → List (List Bool)
  | 0 => [[]]
  | n + 1 => (allAsg n).map (fun l => false :: l) ++ (allAsg n).map (fun l => true :: l)

def satBrute (n : Nat) (F : Cnf) : Bool :=
  (allAsg n).any (fun a => cnfSat a F)

def bruteSteps (n : Nat) (F : Cnf) : Nat := pow2 n * litCount F

/-- 样本族（n 变元链式蕴含，唯一满足）与步数双账 -/
def fam (n : Nat) : Cnf :=
  [[(0, true)]] ++ (List.range (n - 1)).map (fun k => [(k + 1, false), (k + 2, true)])

example : (List.range 6).map (fun i =>
    let n := i + 3
    (litCount (fam n), bruteSteps n (fam n)))
    = [(5, 40), (7, 112), (9, 288), (11, 704), (13, 1664), (15, 3840)] := by
  native_decide

example : (List.range 6).all (fun i =>
    (allAsg (i + 3)).any (fun a => cnfSat a (fam (i + 3)))) := by native_decide

/- ---------- SAT → 3SAT 归约组合子 ---------- -/

def pad3 : Clause → Clause
  | [] => [(0, true), (0, true), (0, true)]
  | [l] => [l, l, l]
  | [l1, l2] => [l1, l2, l2]
  | c => c

/-- 长子句链式拆分：新变元从 base 起编号 -/
def chain (base : Nat) (l1 l2 : Lit) : Clause → List Clause
  | [] => [[l1, l2]]
  | [l3] => [[l1, l2, l3]]
  | l3 :: r => [[l1, l2, (base, true)]] ++ chain (base + 1) (base, false) l3 r

def clause3 (base : Nat) (c : Clause) : List Clause :=
  match c with
  | [] | [_] | [_, _] => [pad3 c]
  | l1 :: l2 :: l3 :: r => chain base l1 l2 (l3 :: r)

def maxVar (F : Cnf) : Nat :=
  F.foldl (fun m c => c.foldl (fun m l => max m (l.1 + 1)) m) 0

def sat3OfBase (base : Nat) : Cnf → Cnf
  | [] => []
  | c :: cs => clause3 base c ++ sat3OfBase (base + (c.length + 1)) cs

def sat3Of (F : Cnf) : Cnf := sat3OfBase (maxVar F) F

def sampleF : List Cnf :=
  [[[(0, true), (1, true), (0, false), (1, false)]],
   [[(0, true), (1, true), (0, false), (1, false), (0, true)]],
   [[(0, true)], [(0, false)]],
   [[(0, true), (1, true), (2, true)], [(0, false), (1, false)]],
   [[(0, true), (1, true), (2, true), (0, false), (1, false)]]]

example : sampleF.all (fun F => (sat3Of F).all (fun c => c.length == 3)) := by
  native_decide

example : sampleF.map (fun F => (satBrute 3 F) == (satBrute 6 (sat3Of F)))
    = [true, true, true, true, true] := by native_decide

/- ---------- 3SAT → CLIQUE ---------- -/

def litAt (F : Cnf) (p : Nat × Nat) : Lit :=
  (F.getD p.1 []).getD p.2 (0, true)

def complements (l1 l2 : Lit) : Bool := l1.1 == l2.1 && l1.2 != l2.2

def edgeOK (F : Cnf) (p q : Nat × Nat) : Bool :=
  p.1 != q.1 && !(complements (litAt F p) (litAt F q))

def cartProd : List (List (Nat × Nat)) → List (List (Nat × Nat))
  | [] => [[]]
  | l :: rest => l.flatMap (fun x => (cartProd rest).map (fun r => x :: r))

def clauseVerts (F : Cnf) : List (List (Nat × Nat)) :=
  (List.range F.length).map (fun i =>
    (List.range (F.getD i []).length).map (fun j => (i, j)))

def pairwiseOK (F : Cnf) : List (Nat × Nat) → Bool
  | [] | [_] => true
  | p :: t => t.all (fun q => edgeOK F p q) && pairwiseOK F t

def hasClique (F : Cnf) : Bool :=
  (cartProd (clauseVerts F)).any (pairwiseOK F)

def asgSet : List Bool → Nat → Bool → List Bool
  | [], _, _ => []
  | x :: t, 0, p => p :: t
  | x :: t, v + 1, p => x :: asgSet t v p

def cliqueToAsg (F : Cnf) (n : Nat) (comb : List (Nat × Nat)) : List Bool :=
  comb.foldl (fun a p => asgSet a (litAt F p).1 (litAt F p).2) (List.replicate n false)

def sample3 : List Cnf :=
  [[[(0, true), (1, true), (2, true)], [(0, false), (1, false), (2, false)]],
   [pad3 [(0, true)], pad3 [(0, false)]]]

example : sample3.map (fun F => (satBrute 3 F) == (hasClique F))
    = [true, true] := by native_decide

example : sample3.map (fun F =>
    (cartProd (clauseVerts F)).any (fun comb =>
      pairwiseOK F comb && cnfSat (cliqueToAsg F 3 comb) F))
    = [true, false] := by native_decide

/- ---------- 归约复合传递 ---------- -/

example : sampleF.map (fun F => (satBrute 3 F) == (hasClique (sat3Of F)))
    = [true, true, true, true, true] := by native_decide

#eval sampleF.map (fun F => (satBrute 3 F, hasClique (sat3Of F)))
