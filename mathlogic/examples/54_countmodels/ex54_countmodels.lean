/- ex54_countmodels.lean —— 可数模型数：Ryll-Nardzewski（Marker GTM 217 §4.4），
    Coq 侧同构镜像 -/

def atomEv (mode i j : Nat) (asg : List Nat) (_step : Nat → Nat) : Bool :=
  match mode with
  | 0 => asg.getD i 0 == asg.getD j 0
  | 1 => asg.getD i 0 == j
  | _ => asg.getD i 0 < asg.getD j 0

def atomsOf (mode n : Nat) : List (Nat × Nat) :=
  match mode with
  | 1 => (List.range n).flatMap fun i => (List.range 9).map fun j => (i, j)
  | _ => (List.range n).flatMap fun i => (List.range n).map fun j => (i, j)

def profileOf (mode n : Nat) (asg : List Nat) (step : Nat → Nat) : List Bool :=
  (atomsOf mode n).map fun a => atomEv mode a.1 a.2 asg step

def dedupP : List (List Bool) → List (List Bool)
  | [] => []
  | pr :: t => if t.any (· == pr) then dedupP t else pr :: dedupP t

def iterA : Nat → (List (List Nat) → List (List Nat)) → List (List Nat) → List (List Nat)
  | 0, _, x => x
  | k + 1, f, x => iterA k f (f x)

def typeCount (mode n : Nat) (dom : List Nat) (step : Nat → Nat) : Nat :=
  let all := iterA n (fun L => L.flatMap fun b => dom.map fun v => b ++ [v]) [[]]
  (dedupP (all.map fun a => profileOf mode n a step)).length

def id1 (x : Nat) : Nat := x
def stepN (x : Nat) : Nat := x + 1

/-- RN 三例：纯等词 Bell 数 1/2/5/15 -/
example : (typeCount 0 1 (List.range 5) id1, typeCount 0 2 (List.range 5) id1,
    typeCount 0 3 (List.range 5) id1, typeCount 0 4 (List.range 5) id1)
    = (1, 2, 5, 15) := by native_decide

/-- DLO 无参数：弱序数 1/3/13 -/
example : (typeCount 2 1 (List.range 5) id1, typeCount 2 2 (List.range 5) id1,
    typeCount 2 3 (List.range 5) id1) = (1, 3, 13) := by native_decide

/-- (N,S,0)：|S₁| 随宇宙增长——型空间无限，非 ℵ₀-范畴 -/
example : 6 ≤ typeCount 1 1 (List.range 8) stepN := by native_decide

/-- Ehrenfeucht 三模型实验室 -/
abbrev St := List Nat × List Nat

def L1 : St := ([0,1,2,3], [0,1,2])   -- 有上确界、其上无点
def L2 : St := ([0,1,2,3,4], [0,1,2]) -- 有上确界、其上有点
def L3 : St := ([0,1,2,3], [1,2,3])   -- 链上无界（链在顶部）

def ltM (M : St) (a b : Nat) : Bool := M.1.contains a && a < b

def sigmaSup (M : St) : Bool :=
  M.1.any fun x => ltM M (M.2.getD 2 0) x && !M.1.any fun y => ltM M x y

def sigmaAbove (M : St) : Bool :=
  M.1.any fun x => M.1.any fun y => ltM M (M.2.getD 2 0) x && ltM M x y

/-- 分离账：L1=(T,F)、L2=(T,T)、L3=(F,F) -/
example : (sigmaSup L1, sigmaAbove L1, sigmaSup L2, sigmaAbove L2,
    sigmaSup L3, sigmaAbove L3) = (true, false, true, true, false, false) := by
  native_decide

def isoPres (M N : St) (f : List Nat) : Bool :=
  ((List.range 3).all fun i => M.2.getD i 0 == N.2.getD (f.getD i 0) 0)
  && M.1.all fun u => M.1.all fun v =>
      ltM M u v == ltM N (f.getD u 0) (f.getD v 0)

def perms4 : List (List Nat) :=
  (List.range 4).flatMap fun a => (List.range 4).flatMap fun b =>
    (List.range 4).flatMap fun c => (List.range 4).map fun d => [a,b,c,d]

/-- 同构搜索失败：保常量+保序的双射不存在 -/
example : !perms4.any fun f => isoPres L1 L3 f = true := by native_decide
