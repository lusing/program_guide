/- ex97_axioms.lean —— 算术与几何的公理系统（张寅生 9.8/9.9+13.10+第 9 章）
   Lean 镜像：log 同构 Z₇*≅Z₆+解释函子保真+PA 1889 对照+ACA₀ 概括
   +欧几里得依赖链+希尔伯特关联公理 F₃² 模型。 -/

set_option linter.unusedVariables false

/- ---------- 1. log 同构 ---------- -/

def z7mul (x y : Nat) : Nat := x * y % 7
def z6add (x y : Nat) : Nat := (x + y) % 6

def log3 (x : Nat) : Nat :=
  match x with
  | 1 => 0 | 3 => 1 | 2 => 2 | 6 => 3 | 4 => 4 | 5 => 5 | _ => 99

example : ([1,2,3,4,5,6].flatMap (fun x =>
    [1,2,3,4,5,6].map (fun y => (x, y)))).all (fun p =>
    log3 (z7mul p.1 p.2) == z6add (log3 p.1) (log3 p.2)) = true := by
  native_decide

example : [1,2,3,4,5,6].map log3 = [0,2,1,4,5,3] := by native_decide

/- ---------- 2. 解释函子保真 ---------- -/

def embed2 (n : Nat) : Nat := 2 * n

example : [(0,(1,2)), (3,(5,4)), (2,(2,7))].all (fun t =>
    (!Nat.ble (embed2 t.1) (embed2 t.2.1) ||
      !Nat.ble (embed2 t.2.1) (embed2 t.2.2) ||
      Nat.ble (embed2 t.1) (embed2 t.2.2))) = true := by native_decide

/- ---------- 3. PA 1889 对照 ---------- -/

example : Nat.beq 0 0 = true := by native_decide
example : Nat.beq 1 0 = false := by native_decide
example : [(3,4), (7,7), (0,1)].all (fun p =>
    Nat.beq (p.1 + 1) (p.2 + 1) == Nat.beq p.1 p.2) = true := by native_decide

/-- (5)(6) 加法递推方程=nat 的定义方程 -/
example : [0,1,2,5].all (fun x =>
    (x + 0 == x) && (x + 4 == (x + 3) + 1)) = true := by native_decide

/-- (7)(8) 乘法递推方程 -/
example : [0,1,2,5].all (fun x =>
    (x * 0 == 0) && (x * 4 == x * 3 + x)) = true := by native_decide

/-- (9) 二阶归纳的机器化身=Lean 的 Nat.rec——「原文 vs 归纳类型」 -/
def pa9Induction (P : Nat → Prop) : Prop :=
  P 0 → (∀ k, P k → P (k + 1)) → ∀ n, P n

/- ---------- 4. ACA₀ 概括 ---------- -/

def arithSample (u : Nat) : Bool := u % 3 == 0
def compX (u : Nat) : Bool := arithSample u

example : [0,1,2,3,6,9].map compX = [true,false,false,true,true,true] := by
  native_decide

/- ---------- 5. 欧几里得 1.29 依赖链 ---------- -/

/-- (命题号, 依据列表)——1001=公设 I.5 等（1000 段=公设/公理） -/
def euclidDeps : List (Nat × List Nat) :=
  [ (129, [105, 113, 115, 1001]), (113, [101, 102, 1001]) ]

example : euclidDeps.length = 2 := by native_decide

/- ---------- 6. 希尔伯特关联公理 F₃² 模型 ---------- -/

def points : List (Nat × Nat) :=
  [ (0,0), (0,1), (0,2), (1,0), (1,1), (1,2), (2,0), (2,1), (2,2) ]

def onLine (l : Nat × (Nat × Nat)) (p : Nat × Nat) : Bool :=
  (l.2.1 * p.1 + l.2.2 * p.2 + l.1) % 3 == 0

def lines : List (Nat × (Nat × Nat)) :=
  [ (0,1), (1,0), (1,1), (1,2) ].flatMap (fun ab =>
    [0,1,2].map (fun c => (c, ab)))

example : lines.length = 12 := by native_decide

/- I.1 两点至少一线 -/
example : (points.flatMap (fun p => points.map (fun q => (p, q)))).all
    (fun pq => lines.any (fun l => onLine l pq.1 && onLine l pq.2))
    = true := by native_decide

def commonPts (l1 l2 : Nat × (Nat × Nat)) : Nat :=
  (points.filter (fun p => onLine l1 p && onLine l2 p)).length

def lineEqb (l1 l2 : Nat × (Nat × Nat)) : Bool :=
  l1.1 == l2.1 && l1.2.1 == l2.2.1 && l1.2.2 == l2.2.2

/- 两直线至多一交点（144 线对全枚举） -/
example : (lines.flatMap (fun l1 => lines.map (fun l2 => (l1, l2)))).all
    (fun ll => lineEqb ll.1 ll.2 || Nat.ble (commonPts ll.1 ll.2) 1)
    = true := by native_decide

/- I.3 每线至少两点（F₃ 恰 3 点） -/
example : lines.all (fun l => Nat.ble 2 (points.filter (onLine l)).length)
    = true := by native_decide

example : [ (points.filter (onLine (0,(1,0)))).length
           , (points.filter (onLine (0,(1,1)))).length ] = [3, 3] := by
  native_decide

#eval (lines.length, points.length)
