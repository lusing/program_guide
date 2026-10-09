/- ex26 —— 完备理论与范畴性（Marker ch5）Lean 镜像
   F_3^2 换基排列+x^3 有限域单满射对账+n≤5 全图枚举 0-1 律频率。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. F_3^2 换基排列 ----------

def vaddp (a b : Nat × Nat) : Nat × Nat :=
  ((a.1 + b.1) % 3, (a.2 + b.2) % 3)
def smulp (k : Nat) (v : Nat × Nat) : Nat × Nat :=
  ((k * v.1) % 3, (k * v.2) % 3)

def iso2p (w0 w1 v : Nat × Nat) : Nat × Nat :=
  vaddp (smulp v.1 w0) (smulp v.2 w1)

def Vs2 : List (Nat × Nat) :=
  (List.range 3).flatMap fun i => (List.range 3).map fun j => (i, j)

def peqb (a b : Nat × Nat) : Bool :=
  (a.1 == b.1) && (a.2 == b.2)

def memb2 (x : Nat × Nat) : List (Nat × Nat) → Bool
  | [] => false
  | y :: t => peqb x y || memb2 x t

def nodupb2 : List (Nat × Nat) → Bool
  | [] => true
  | x :: t => !memb2 x t && nodupb2 t

example : nodupb2 (Vs2.map (iso2p (1,0) (1,1))) = true := by native_decide
example : (Vs2.map (iso2p (1,0) (1,1))).length = 9 := by rfl
example : !nodupb2 (Vs2.map (iso2p (1,0) (1,0))) = true := by native_decide

-- ---------- 2. x^3 的有限域单满射对账（Ax 脚印） ----------

def cubic (p x : Nat) : Nat := x * x * x % p

def injCubic (p : Nat) : Bool :=
  (List.range p).all fun x =>
    (List.range p).all fun y => x == y || !(cubic p x == cubic p y)

def surjCubic (p : Nat) : Bool :=
  (List.range p).all fun z => (List.range p).any fun x => cubic p x == z

example : injCubic 5 = true := by native_decide
example : surjCubic 5 = true := by native_decide
example : !injCubic 7 = true := by native_decide
example : !surjCubic 7 = true := by native_decide
example : injCubic 11 && surjCubic 11 = true := by native_decide
example : !(injCubic 13 || surjCubic 13) = true := by native_decide

-- 特征迁移表（素数行干净：p ≡ 1 mod 3 即失败）
#eval [2,3,5,7,11,13,17,19].map fun p => (p, injCubic p, surjCubic p)

-- ---------- 3. 随机图 0-1 律：n≤5 全图枚举 ----------

def bits : Nat → List (List Bool)
  | 0 => [[]]
  | m+1 => (bits m).map (fun l => false :: l) ++ (bits m).map (fun l => true :: l)

def pairsn (n : Nat) : List (Nat × Nat) :=
  (List.range n).flatMap fun i =>
    ((List.range n).filter fun j => i < j).map fun j => (i, j)

def posp (xy : Nat × Nat) : List (Nat × Nat) → Nat
  | [] => 0
  | y :: t => if peqb xy y then 0 else posp xy t + 1

def edgesn (n : Nat) (b : List Bool) (i j : Nat) : Bool :=
  b.getD (posp (i, j) (pairsn n)) false

def noIsolated (n : Nat) (b : List Bool) : Bool :=
  (List.range n).all fun i =>
    ((List.range n).filter fun j => i != j).any fun j =>
      edgesn n b i j || edgesn n b j i

def medges (n : Nat) : Nat := (pairsn n).length
def fracnum (n : Nat) : Nat :=
  ((bits (medges n)).filter (noIsolated n)).length

-- n=2..5 分子：1/2, 4/8, 41/64, 768/1024（递增趋 1）
example : [2,3,4,5].map fracnum = [1,4,41,768] := by native_decide
example : [2,3,4,5].map (fun n => (bits (medges n)).length) = [2,8,64,1024] := by
  native_decide

def exactly3 (n : Nat) (b : List Bool) : Bool :=
  (b.filter id).length == 3

-- 「恰好 3 条边」分子 = C(m,3)：0,1,20,120 —— 占 2^m 雪崩 → 0
example : [2,3,4,5].map
    (fun n => ((bits (medges n)).filter (exactly3 n)).length) = [0,1,20,120] := by
  native_decide

-- 冒烟
#eval [2,3,4,5].map fun n => (n, fracnum n, (bits (medges n)).length)
#eval nodupb2 (Vs2.map (iso2p (1,0) (1,1)))
