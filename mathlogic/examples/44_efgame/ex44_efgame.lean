/- ex24 —— EF 博弈与 Fraïssé 定理（EFT ch XII）Lean 镜像
   pi_ok 部分同构检查 + dup_wins 求解器 + (Z_n,<) 分离现场 +
   空/全关系对照 + 秩-轮对齐。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

structure FStruct where
  size : Nat
  rel : Nat → Nat → Bool

def domain (A : FStruct) : List Nat := List.range A.size

def Zord (n : Nat) : FStruct := ⟨n, fun a b => a < b⟩
def Zempty (n : Nat) : FStruct := ⟨n, fun _ _ => false⟩
def Zfull (n : Nat) : FStruct := ⟨n, fun _ _ => true⟩

-- 部分同构：两投影单射 + 关系一致
def inj_by (proj : Nat × Nat → Nat) (ps : List (Nat × Nat)) : Bool :=
  ps.all fun p => ps.all fun q =>
    !((proj p == proj q) && !((p.1 == q.1) && (p.2 == q.2)))

def rel_match (A B : FStruct) (ps : List (Nat × Nat)) : Bool :=
  ps.all fun p => ps.all fun q =>
    (A.rel p.1 q.1) == (B.rel p.2 q.2)

def pi_ok (A B : FStruct) (ps : List (Nat × Nat)) : Bool :=
  inj_by (·.1) ps && inj_by (·.2) ps && rel_match A B ps

-- n 轮 duplicator 赢策略
def dup_wins : Nat → FStruct → FStruct → List (Nat × Nat) → Bool
  | 0, A, B, ps => pi_ok A B ps
  | m + 1, A, B, ps =>
      (domain A).all fun a =>
        (domain B).any fun b => dup_wins m A B ((a, b) :: ps)
      && (domain B).all fun b =>
        (domain A).any fun a => dup_wins m A B ((a, b) :: ps)

-- (Z_n,<) 分离现场
example : !dup_wins 3 (Zord 1) (Zord 2) [] = true := by native_decide
example : ((List.range 4).all fun m =>
    dup_wins m (Zord 5) (Zord 5) []) = true := by native_decide
example : dup_wins 3 (Zord 7) (Zord 8) [] = true := by native_decide
example : !dup_wins 3 (Zord 3) (Zord 4) [] = true := by native_decide
example : dup_wins 2 (Zord 3) (Zord 4) [] = true := by native_decide

-- 空/全关系对照
example : ((List.range 4).all fun m =>
    dup_wins m (Zempty 3) (Zempty 3) []) = true := by native_decide
example : dup_wins 2 (Zempty 2) (Zempty 3) [] = true := by native_decide
example : !dup_wins 3 (Zempty 2) (Zempty 3) [] = true := by native_decide
example : !dup_wins 3 (Zfull 2) (Zfull 3) [] = true := by native_decide

-- 秩-轮对齐
example : !dup_wins 2 (Zord 1) (Zord 2) [] && dup_wins 1 (Zord 1) (Zord 2) []
    = true := by native_decide
example : !dup_wins 2 (Zord 2) (Zord 3) [] && dup_wins 1 (Zord 2) (Zord 3) []
    = true := by native_decide

-- 冒烟
#eval (List.range 4).map fun m => dup_wins m (Zord 2) (Zord 3) []
#eval (List.range 4).map fun m => dup_wins m (Zord 4) (Zord 5) []
#eval (List.range 4).map fun m => dup_wins m (Zempty 2) (Zempty 3) []

/- ---------- 5. Marker GTM 217 §2.4 深化：Scott 句与同构定理 ---------- -/

def bitOf : Nat → Nat → Bool
  | 0, _ => false
  | m + 1, 0 => (m + 1) % 2 == 1
  | m + 1, b + 1 => bitOf ((m + 1) / 2) b

def allStructs (n : Nat) : List FStruct :=
  (List.range (2 ^ (n * n))).map fun m =>
    ⟨n, fun a b => bitOf m (a * n + b)⟩

def insertVal (p : List Nat) (i v : Nat) : List Nat :=
  p.take i ++ [v] ++ p.drop i

def permuteAll : Nat → List (List Nat)
  | 0 => [[]]
  | k + 1 =>
      (permuteAll k).flatMap fun p =>
        ((List.range (k + 1)).map fun i => insertVal p i k)

def bijective (π : List Nat) : Bool :=
  (List.range π.length).all fun x => π.contains x

def relMatch (A B : FStruct) (π : List Nat) : Bool :=
  (domain A).all fun p => (domain A).all fun q =>
    A.rel p q == B.rel π[p]! π[q]!

def isoCheck (A B : FStruct) : Bool :=
  A.size == B.size && (permuteAll B.size).any fun π =>
    bijective π && relMatch A B π

example : (((allStructs 2).flatMap fun a => (allStructs 2).map fun b => (a, b))
    ++ ((allStructs 3).take 8).flatMap fun a => ((allStructs 3).take 8).map fun b => (a, b)).all
    fun p => isoCheck p.1 p.2 == dup_wins p.1.size p.1 p.2 [] = true := by
  native_decide

def dedupIso : List FStruct → List FStruct
  | [] => []
  | x :: t => if t.any fun y => isoCheck x y then dedupIso t else x :: dedupIso t

/-- Burnside：(16+4)/2=10 个轨道 -/
example : (dedupIso (allStructs 2)).length = 10 := by native_decide
