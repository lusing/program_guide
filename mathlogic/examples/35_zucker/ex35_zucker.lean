/- ex35_zucker —— Zucker 对应：截消与正规化（Lean 4 版）
   与 ex35_zucker.v 同构：ND 项（含 ∨ 侧）+ β/γ、矢列项（名字/余名，
   截公式显式携带）+ 自顶向下检查器、Prawitz 翻译 |·|、cut1 截消一步
   （逻辑截/名字截/换位截）、BFS 成员判定电池、对应断裂现场
   （怪规则缺失的机器证据）。 -/

namespace Ex35

inductive Tm where
  | var (n : Nat)
  | pr (a b : Tm)
  | fst (a : Tm)
  | snd (a : Tm)
  | inl (a : Tm)
  | inr (a : Tm)
  | case_ (d : Tm) (x y : Nat) (a b : Tm)  -- case d of x⇒a | y⇒b
  | lam (x : Nat) (a : Tm)
  | app (a b : Tm)

def subst (n : Nat) (T : Tm) : Tm → Tm
  | .var m => if m == n then T else .var m
  | .pr u v => .pr (subst n T u) (subst n T v)
  | .fst u => .fst (subst n T u)
  | .snd u => .snd (subst n T u)
  | .inl u => .inl (subst n T u)
  | .inr u => .inr (subst n T u)
  | .case_ d x y u v =>
      .case_ (subst n T d) x y
        (if x == n then u else subst n T u)
        (if y == n then v else subst n T v)
  | .lam x u => .lam x (if x == n then u else subst n T u)
  | .app u v => .app (subst n T u) (subst n T v)

def tmEq : Tm → Tm → Bool
  | .var n, .var m => n == m
  | .pr u1 v1, .pr u2 v2 => tmEq u1 u2 && tmEq v1 v2
  | .fst u, .fst v => tmEq u v
  | .snd u, .snd v => tmEq u v
  | .inl u, .inl v => tmEq u v
  | .inr u, .inr v => tmEq u v
  | .case_ d1 x1 y1 u1 v1, .case_ d2 x2 y2 u2 v2 =>
      x1 == x2 && y1 == y2 && tmEq d1 d2 && tmEq u1 u2 && tmEq v1 v2
  | .lam x1 u1, .lam x2 u2 => x1 == x2 && tmEq u1 u2
  | .app u1 v1, .app u2 v2 => tmEq u1 u2 && tmEq v1 v2
  | _, _ => false

inductive Form where
  | atom (n : Nat)
  | fand (a b : Form)
  | fimp (a b : Form)

def eqF : Form → Form → Bool
  | .atom n, .atom m => n == m
  | .fand x1 x2, .fand y1 y2 => eqF x1 y1 && eqF x2 y2
  | .fimp x1 x2, .fimp y1 y2 => eqF x1 y1 && eqF x2 y2
  | _, _ => false

def lookupF (x : Nat) : List (Nat × Form) → Option Form
  | [] => none
  | (y, A) :: t => if y == x then some A else lookupF x t

def remv (x : Nat) : List (Nat × Form) → List (Nat × Form)
  | [] => []
  | (y, A) :: t => if y == x then remv x t else (y, A) :: remv x t

/-- 矢列项：SAndiL i (x)M z 的 i=false 吃左分量；SCut 携带截公式。 -/
inductive St where
  | SAx (x a : Nat)
  | SAndR (a b c : Nat) (M N : St)
  | SAndiL (i : Bool) (x z : Nat) (M : St)
  | SImpR (x a c : Nat) (M : St)
  | SImpL (a x z : Nat) (M N : St)
  | SCut (A : Form) (a : Nat) (M : St) (x : Nat) (N : St)

/-- 自顶向下检查器：后件公式作输入。 -/
def stCheck (G : List (Nat × Form)) (M : St) (C : Form) : Bool :=
  match M with
  | .SAx x _ =>
      match lookupF x G with
      | some A => eqF A C
      | none => false
  | .SAndR _ _ _ M N =>
      match C with
      | .fand A B => stCheck G M A && stCheck G N B
      | _ => false
  | .SAndiL i x z M =>
      match lookupF z G with
      | some (.fand A1 A2) =>
          stCheck ((x, if i then A2 else A1) :: remv z G) M C
      | _ => false
  | .SImpR x _ _ M =>
      match C with
      | .fimp A B => stCheck ((x, A) :: remv x G) M B
      | _ => false
  | .SImpL _ x z M N =>
      match lookupF z G with
      | some (.fimp A B) =>
          stCheck (remv z G) M A
            && stCheck ((x, B) :: remv x (remv z G)) N C
      | _ => false
  | .SCut A _ M x N =>
      stCheck G M A && stCheck ((x, A) :: remv x G) N C

def stEq : St → St → Bool
  | .SAx x1 a1, .SAx x2 a2 => x1 == x2 && a1 == a2
  | .SAndR a1 b1 e1 M1 N1, .SAndR a2 b2 e2 M2 N2 =>
      a1 == a2 && b1 == b2 && e1 == e2 && stEq M1 M2 && stEq N1 N2
  | .SAndiL i1 x1 z1 M1, .SAndiL i2 x2 z2 M2 =>
      i1 == i2 && x1 == x2 && z1 == z2 && stEq M1 M2
  | .SImpR x1 a1 e1 M1, .SImpR x2 a2 e2 M2 =>
      x1 == x2 && a1 == a2 && e1 == e2 && stEq M1 M2
  | .SImpL a1 x1 z1 M1 N1, .SImpL a2 x2 z2 M2 N2 =>
      a1 == a2 && x1 == x2 && z1 == z2 && stEq M1 M2 && stEq N1 N2
  | .SCut A1 a1 M1 x1 N1, .SCut A2 a2 M2 x2 N2 =>
      eqF A1 A2 && a1 == a2 && x1 == x2 && stEq M1 M2 && stEq N1 N2
  | _, _ => false

/- ---------- Prawitz 翻译 ---------- -/

def trans : St → Tm
  | .SAx x _ => .var x
  | .SAndR _ _ _ M N => .pr (trans M) (trans N)
  | .SAndiL i x z M =>
      subst x (if i then .snd (.var z) else .fst (.var z)) (trans M)
  | .SImpR x _ _ M => .lam x (trans M)
  | .SImpL _ x z M N => subst x (.app (.var z) (trans M)) (trans N)
  | .SCut _ _ M x N => subst x (trans M) (trans N)

/- ---------- 截消一步 cut1 ---------- -/

def renConame (M : St) (c d : Nat) : St :=
  match M with
  | .SAx x a => .SAx x (if a == c then d else a)
  | .SAndR a b e M N =>
      .SAndR (if a == c then d else a) (if b == c then d else b) e
        (renConame M c d) (renConame N c d)
  | .SAndiL i x z M => .SAndiL i x z (renConame M c d)
  | .SImpR x a e M =>
      .SImpR x (if a == c then d else a) e (renConame M c d)
  | .SImpL a x z M N =>
      .SImpL (if a == c then d else a) x z (renConame M c d) (renConame N c d)
  | .SCut A a M x N =>
      .SCut A (if a == c then d else a) (renConame M c d) x (renConame N c d)

def cut1 : St → St
  | .SCut CA c (.SAndR a b e M N) x P =>
      match P with
      | .SAndiL i x' z Q =>
          if z == x
          then (if i then .SCut CA b N x' Q else .SCut CA a M x' Q)
          else .SCut CA c (.SAndR a b e (cut1 M) (cut1 N)) x (cut1 P)
      | _ => .SCut CA c (.SAndR a b e (cut1 M) (cut1 N)) x (cut1 P)
  | .SCut CA c (.SImpR x a e M) z P =>
      match P with
      | .SImpL a' y z' N Q =>
          if z' == z
          then .SCut CA a (.SCut CA a' N x M) y Q
          else .SCut CA c (.SImpR x a e (cut1 M)) z (cut1 P)
      | _ => .SCut CA c (.SImpR x a e (cut1 M)) z (cut1 P)
  | .SCut CA a (.SAx x a') y P =>
      if a' == a then renConame P a y else .SCut CA a (.SAx x a') y (cut1 P)
  | .SCut CA c (.SAndiL i x z M) y P =>
      .SAndiL i x z (.SCut CA c M y P)
  | .SCut CA c (.SImpL a x z M N) y P =>
      .SImpL a x z (.SCut CA c M y P) (.SCut CA c N y P)
  | .SCut CA c (.SCut A2 a2 M2 x2 N2) y P =>
      .SCut A2 a2 M2 x2 (.SCut CA c N2 y P)
  | .SAx x a => .SAx x a
  | .SAndR a b e M N => .SAndR a b e (cut1 M) (cut1 N)
  | .SAndiL i x z M => .SAndiL i x z (cut1 M)
  | .SImpR x a e M => .SImpR x a e (cut1 M)
  | .SImpL a x z M N => .SImpL a x z (cut1 M) (cut1 N)

/- ---------- ND 归约 BFS：β∪γ 成员判定 ---------- -/

def betaCtx : Tm → List Tm
  | .fst u =>
      (match u with
       | .pr x _ => [x]
       | _ => []) ++ (betaCtx u).map .fst
  | .snd u =>
      (match u with
       | .pr _ y => [y]
       | _ => []) ++ (betaCtx u).map .snd
  | .app u v =>
      (match u with
       | .lam x b => [subst x v b]
       | _ => [])
        ++ (betaCtx u).map (·.app v)
        ++ (betaCtx v).map (u.app ·)
  | .case_ d x y u v =>
      (match d with
       | .inl s => [subst x s u]
       | .inr s => [subst y s v]
       | _ => [])
        ++ (betaCtx d).map (fun w => .case_ w x y u v)
        ++ (betaCtx u).map (fun w => .case_ d x y w v)
        ++ (betaCtx v).map (fun w => .case_ d x y u w)
  | .pr u v =>
      (betaCtx u).map (.pr · v) ++ (betaCtx v).map (.pr u ·)
  | .inl u => (betaCtx u).map .inl
  | .inr u => (betaCtx u).map .inr
  | .lam x u => (betaCtx u).map (.lam x ·)
  | .var _ => []

def gammaCtx : Tm → List Tm
  | .fst u =>
      (match u with
       | .case_ d x y p q => [.case_ d x y (.fst p) (.fst q)]
       | _ => []) ++ (gammaCtx u).map .fst
  | .snd u =>
      (match u with
       | .case_ d x y p q => [.case_ d x y (.snd p) (.snd q)]
       | _ => []) ++ (gammaCtx u).map .snd
  | .app u v =>
      (match u with
       | .case_ d x y p q => [.case_ d x y (.app p v) (.app q v)]
       | _ => [])
        ++ (gammaCtx u).map (·.app v)
        ++ (gammaCtx v).map (u.app ·)
  | .case_ d x y u v =>
      (match d with
       | .case_ e s t p q =>
           [.case_ e s t (.case_ p x y u v) (.case_ q x y u v)]
       | _ => [])
        ++ (gammaCtx d).map (fun w => .case_ w x y u v)
        ++ (gammaCtx u).map (fun w => .case_ d x y w v)
        ++ (gammaCtx v).map (fun w => .case_ d x y u w)
  | .pr u v =>
      (gammaCtx u).map (.pr · v) ++ (gammaCtx v).map (.pr u ·)
  | .inl u => (gammaCtx u).map .inl
  | .inr u => (gammaCtx u).map .inr
  | .lam x u => (gammaCtx u).map (.lam x ·)
  | .var _ => []

def stepsOf (a : Tm) : List Tm := betaCtx a ++ gammaCtx a

def bfsReach : Nat → Tm → List Tm → Bool
  | 0, target, frontier => frontier.any (tmEq target)
  | n + 1, target, frontier =>
      if frontier.any (tmEq target) then true
      else bfsReach n target (frontier.flatMap stepsOf)

def betaGammaStar (target a : Tm) : Bool := bfsReach 7 target [a]

/- ---------- 断言电池 ---------- -/

def fA : Form := .atom 0
def fB : Form := .atom 1

def Gand : List (Nat × Form) := [(0, fA), (1, fB), (2, .fand fA fB)]

def andCut : St :=
  .SCut (.fand fA fB) 3 (.SAndR 0 1 3 (.SAx 0 0) (.SAx 1 1)) 2
        (.SAndiL false 0 2 (.SAx 0 4))

example : stCheck Gand andCut fA = true := by decide

example : tmEq (trans andCut) (.fst (.pr (.var 0) (.var 1))) = true := by
  decide

/-- 换位截步 |M|≡|N|。 -/
def commCut : St :=
  .SCut fA 5 (.SAndiL false 0 2 (.SAx 0 5)) 3 (.SAx 3 6)

example : tmEq (trans commCut) (trans (cut1 commCut)) = true := by decide

/-- 逻辑截步 |M| β→*|N|（定理 4 逻辑侧）。 -/
example : betaGammaStar (trans (cut1 andCut)) (trans andCut) = true := by
  decide

/-- 引理 5 样本面：ND 一步 β 对应矢列截步。 -/
example : tmEq (trans andCut) (.fst (.pr (.var 0) (.var 1)))
          && tmEq (trans (cut1 andCut)) (.var 0) = true := by decide

def Gimp : List (Nat × Form) :=
  [(0, .fimp fA fB), (1, fA), (2, fB)]

def impCut : St :=
  .SCut (.fimp fA fB) 3 (.SImpR 1 2 3 (.SAx 2 2)) 0
        (.SImpL 1 3 0 (.SAx 1 1) (.SAx 3 4))

example : stCheck Gimp impCut fB = true := by decide

example : tmEq (trans impCut) (.app (.lam 1 (.var 2)) (.var 1))
          && betaGammaStar (trans (cut1 impCut)) (trans impCut) = true := by
  decide

/- ---------- 对应断裂现场 ---------- -/

def t1 : Tm :=
  .pr (.case_ (.var 9) 1 2 (.var 3) (.var 4))
      (.case_ (.var 9) 1 2 (.var 5) (.var 6))

def t2 : Tm :=
  .case_ (.var 9) 1 2 (.pr (.var 3) (.var 5)) (.pr (.var 4) (.var 6))

/-- 怪规则：∧I 与 ∨E 换位（需「两 P 相等」测试，破坏合流）。 -/
def strangeStep : Tm → Tm
  | .pr (.case_ d x y u v) (.case_ d' z w s t) =>
      if tmEq d' d
      then .case_ d x y (.pr u (subst z (.var x) s))
                      (.pr v (subst w (.var y) t))
      else .pr (.case_ d x y u v) (.case_ d' z w s t)
  | a => a

example : betaGammaStar t2 t1 = false := by decide

example : tmEq (strangeStep t1) t2 = true := by decide

end Ex35
