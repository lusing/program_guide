/- ex40 —— SLD 与逻辑编程语义（Ben-Ari 3e ch11 + 2e §8.3/8.5）Lean 镜像
   常量+变元的最小合一 → SLD 步（子句变元换新鲜偏移）→ 答案枚举
   → 最左/最右两条计算规则 → 实例级独立性（祖先族谱）。 -/

inductive Tm : Type
  | c (n : Nat)   -- 常量 c_i
  | v (n : Nat)   -- 变元 x_i
  deriving Repr

abbrev Atom := Nat × List Tm
abbrev Clause := Atom × List Atom
abbrev Goal := List Atom
abbrev Subst := List (Nat × Tm)

open Tm

def substT (s : Subst) : Tm → Tm
  | v x => match s.find? (fun p => p.1 == x) with
           | some (_, t') => t'
           | none => .v x
  | .c n => .c n

def asub (s : Subst) (a : Atom) : Atom := (a.1, a.2.map (substT s))
def gsub (s : Subst) (g : Goal) : Goal := g.map (asub s)

def unify : Tm → Tm → Option Subst
  | c a, c b => if a == b then some [] else none
  | v x, v y => if x == y then some [] else some [(x, .v y)]
  | v x, u => some [(x, u)]
  | t, v y => some [(y, t)]

def unifyL : Subst → List Tm → List Tm → Option Subst
  | s, [], [] => some s
  | s, t1 :: r1, t2 :: r2 =>
      match unify (substT s t1) (substT s t2) with
      | some s1 => unifyL (s1 ++ s) r1 r2
      | none => none
  | _, _, _ => none

def unifyA (a b : Atom) : Option Subst :=
  if a.1 == b.1 then unifyL [] a.2 b.2 else none

/-- 子句变元换新鲜（偏移 k） -/
def toff (k : Nat) : Tm → Tm
  | .v x => .v (k + x)
  | .c n => .c n

def aoff (k : Nat) (a : Atom) : Atom := (a.1, a.2.map (toff k))
def coff (k : Nat) (cl : Clause) : Clause := (aoff k cl.1, cl.2.map (aoff k))

def removeFirst : Nat → Goal → Goal
  | 0, _ :: g' => g'
  | j + 1, a :: g' => a :: removeFirst j g'
  | _, [] => []

def resolve (c : Clause) (g : Goal) (i k : Nat) : Option (Goal × Subst) :=
  let (h, body) := coff k c
  match g[i]? with
  | none => none
  | some sel =>
      match unifyA sel h with
      | some s => some (gsub s (body ++ removeFirst i g), s)
      | none => none

/-- 答案枚举（DFS 按子句序；答案 = 沿链累积的代换） -/
def sldAll : Nat → (Nat → Nat) → List Clause → Nat → Goal → Subst → List Subst
  | 0, _, _, _, _, _ => []
  | _ + 1, _, _, _, [], acc => [acc]
  | fr + 1, rule, P, k, g, acc =>
      let i := rule g.length
      P.flatMap fun c =>
        match resolve c g i k with
        | some (g', s) => sldAll fr rule P (k + 1 + P.length) g' (s ++ acc)
        | none => []

def leftmost (_ : Nat) : Nat := 0
def rightmost (n : Nat) : Nat := n - 1

/- ---------- 现场程序（2e 例 8.19 的祖先族谱） ---------- -/

def bob : Tm := .c 100
def allen : Tm := .c 101
def fred : Tm := .c 102
def dave : Tm := .c 103
def catherine : Tm := .c 104
def george : Tm := .c 105
def ellen : Tm := .c 106
def harry : Tm := .c 107

def parentXY : Atom := (1, [.v 0, .v 1])
def ancXY : Atom := (2, [.v 0, .v 1])
def parXZ : Atom := (1, [.v 0, .v 2])
def ancZY : Atom := (2, [.v 2, .v 1])

def progA : List Clause :=
  [(ancXY, [parentXY]),                       -- ancestor(X,Y) :- parent(X,Y).
   (ancXY, [parXZ, ancZY])]                   -- ancestor(X,Y) :- parent(X,Z), ancestor(Z,Y).
  ++ [(bob, allen), (fred, dave), (catherine, allen),
      (harry, george), (dave, bob), (ellen, bob)].map
      (fun pr => ((1, [pr.1, pr.2]), []))

/-- 答案显示版：把 X（x_0）沿换名链追到常量 -/
def chaseX : Nat → Subst → Nat → Option Nat
  | 0, _, _ => none
  | fr + 1, s, x =>
      match s.find? (fun p => p.1 == x) with
      | some (_, .c n) => some n
      | some (_, .v y) => chaseX fr s y
      | none => none

def ansX (s : Subst) : Option Nat := chaseX 20 s 0
def answersX (l : List Subst) : List (Option Nat) := l.map ansX

def goalG : Goal := [(2, [.v 0, bob])]

/-- 独立性（实例级）：两种计算规则解出同一答案集 {dave, ellen, fred} -/
example :
    answersX (sldAll 30 leftmost progA 10 goalG [])
      = answersX (sldAll 30 rightmost progA 10 goalG []) := by
  rfl

example : answersX (sldAll 30 leftmost progA 10 goalG []) = [some 103, some 106, some 102] := by
  rfl
