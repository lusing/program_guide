/- ex38_lcube —— λ-立方与定理证明器（Lean 4 版）
   与 ex38_lcube.v 同构：三开关 PTS 检查器（燃料版 inferF，lam 分支
   查「体类型的类型」）、八系统、id 要多态、Leibniz 要依值+多态
   （λP2/λC）、⊥ 在 λ2 是合法命题、基系统无 ⊥ 候选居元、坏假设
   立即爆 ⊥、conversion 的 β 面。 -/

namespace Ex38

inductive Tm where
  | var (n : Nat)
  | srt (b : Bool)          -- false=Prop(∗) true=Type(□)
  | app (a b : Tm)
  | lam (x : Nat) (A b : Tm)
  | pi (x : Nat) (A B : Tm)

def subst (x : Nat) (T : Tm) : Tm → Tm
  | .var m => if m == x then T else .var m
  | .srt b => .srt b
  | .app u v => .app (subst x T u) (subst x T v)
  | .lam y A u => .lam y (subst x T A) (if y == x then u else subst x T u)
  | .pi y A B => .pi y (subst x T A) (if y == x then B else subst x T B)

def tmEq : Tm → Tm → Bool
  | .var n, .var m => n == m
  | .srt x, .srt y => x == y
  | .app u1 v1, .app u2 v2 => tmEq u1 u2 && tmEq v1 v2
  | .lam y1 A1 u1, .lam y2 A2 u2 => y1 == y2 && tmEq A1 A2 && tmEq u1 u2
  | .pi y1 A1 B1, .pi y2 A2 B2 => y1 == y2 && tmEq A1 A2 && tmEq B1 B2
  | _, _ => false

def whnfF : Nat → Tm → Tm
  | 0, a => a
  | n + 1, .app u v =>
      match whnfF n u with
      | .lam x _ b => whnfF n (subst x v b)
      | u' => .app u' v
  | _, a => a

def whnf (a : Tm) : Tm := whnfF 400 a

def convF : Nat → Tm → Tm → Bool
  | 0, a, b => tmEq a b
  | n + 1, a, b =>
      match whnf a, whnf b with
      | .app u1 v1, .app u2 v2 => convF n u1 u2 && convF n v1 v2
      | .lam y1 A1 u1, .lam y2 A2 u2 =>
          tmEq A1 A2 && convF n u1 (subst y2 (.var y1) u2)
      | .pi y1 A1 B1, .pi y2 A2 B2 =>
          tmEq A1 A2 && convF n B1 (subst y2 (.var y1) B2)
      | a', b' => tmEq a' b'

def conv (a b : Tm) : Bool := convF 400 a b

def nfF : Nat → Tm → Tm
  | 0, a => a
  | n + 1, .app u v =>
      match nfF n u with
      | .lam x _ b => nfF n (subst x (nfF n v) b)
      | u' => .app u' (nfF n v)
  | _, a => a

def nf (a : Tm) : Tm := nfF 400 a

/-- 三开关：多态 (□,∗) / 依值 (∗,□) / 类型算子 (□,□)。 -/
structure Flags where
  poly : Bool
  dep : Bool
  tops : Bool

def ruleOK (fl : Flags) (s1 s2 : Bool) : Bool :=
  match s1, s2 with
  | false, false => true
  | true, false => fl.poly
  | false, true => fl.dep
  | true, true => fl.tops

def Ctx := List (Nat × Tm)

def look (x : Nat) : Ctx → Option Tm
  | [] => none
  | (y, A) :: t => if y == x then some A else look x t

def asSort (T : Tm) : Option Bool :=
  match whnf T with
  | .srt b => some b
  | _ => none

/-- 燃料版推断。 -/
def inferF : Nat → Flags → Ctx → Tm → Option Tm
  | 0, _, _, _ => none
  | k + 1, fl, G, a =>
      match a with
      | .var x => look x G
      | .srt false => some (.srt true)
      | .srt true => none
      | .app u v =>
          match inferF k fl G u with
          | some (.pi x A B) =>
              match inferF k fl G v with
              | some Tv => if conv Tv A then some (subst x v B) else none
              | none => none
          | _ => none
      | .lam x A b =>
          match inferF k fl G A with
          | some sA =>
              match asSort sA with
              | some s1 =>
                  match inferF k fl ((x, A) :: G) b with
                  | some TB =>
                      /- Πx:A.TB : s2 需要 TB : s2——查 TB 的类型 -/
                      match inferF k fl ((x, A) :: G) TB with
                      | some (.srt s2) =>
                          if ruleOK fl s1 s2 then some (.pi x A TB) else none
                      | _ => none
                  | none => none
              | none => none
          | none => none
      | .pi x A B =>
          match inferF k fl G A with
          | some sA =>
              match asSort sA with
              | some s1 =>
                  match inferF k fl ((x, A) :: G) B with
                  | some TB =>
                      match asSort TB with
                      | some s2 => if ruleOK fl s1 s2 then some (.srt s2) else none
                      | none => none
                  | none => none
              | none => none
          | none => none

def infer (fl : Flags) (G : Ctx) (a : Tm) : Option Tm := inferF 200 fl G a

def inferOK (fl : Flags) (G : Ctx) (a T : Tm) : Bool :=
  match infer fl G a with
  | some U => conv U T
  | none => false

/-- 八系统。 -/
def lArrow : Flags := ⟨false, false, false⟩   -- λ→
def lPoly : Flags := ⟨true, false, false⟩     -- λ2
def lDep : Flags := ⟨false, true, false⟩      -- λP
def lPolyDep : Flags := ⟨true, true, false⟩   -- λP2
def lTops : Flags := ⟨false, false, true⟩     -- λω̄
def lFomega : Flags := ⟨true, false, true⟩    -- λω (Fω)
def lDepTops : Flags := ⟨false, true, true⟩   -- λPω
def lCoc : Flags := ⟨true, true, true⟩        -- λC

/- ---------- 断言电池 ---------- -/

def A : Tm := .var 0

def idTerm : Tm := .lam 0 (.srt false) (.lam 1 A (.var 1))
def idType : Tm := .pi 0 (.srt false) (.pi 1 A A)

/-- 电一：id 只有多态收。 -/
example : !inferOK lArrow [] idTerm idType
          && inferOK lPoly [] idTerm idType
          && inferOK lCoc [] idTerm idType = true := by decide

/-- 电二：Leibniz 相等需要依值+多态（λP2/λC）。 -/
def G2 : Ctx := [(0, .srt false), (5, A)]
def arrT : Tm := .pi 3 A (.srt false)
def eqTy : Tm :=
  .pi 2 arrT (.pi 4 (.app (.var 2) (.var 5)) (.app (.var 2) (.var 5)))
def eqRefl : Tm :=
  .lam 2 arrT (.lam 4 (.app (.var 2) (.var 5)) (.var 4))

example : !inferOK lPoly G2 eqRefl eqTy
          && !inferOK lDep G2 eqRefl eqTy
          && inferOK lPolyDep G2 eqRefl eqTy
          && inferOK lCoc G2 eqRefl eqTy = true := by decide

/-- 电三：⊥ := Πx:Prop.x 在 λ2 是合法命题，λ→ 不收。 -/
def botT : Tm := .pi 9 (.srt false) (.var 9)

def isPropIn (fl : Flags) (G : Ctx) (T : Tm) : Bool :=
  match infer fl G T with
  | some U => match whnf U with
              | .srt false => true
              | _ => false
  | none => false

example : isPropIn lPoly [] botT && !isPropIn lArrow [] botT = true := by
  decide

/-- 电四：基系统 ⊥ 无候选居元；坏假设立即爆 ⊥。 -/
example : !(inferOK lCoc [] (.lam 9 (.srt false) (.var 9)) botT
            || inferOK lCoc [] (.var 0) botT) = true := by decide

def negT (C : Tm) : Tm := .pi 10 C botT
def badCtx : Ctx := [(0, .srt false), (1, .var 0), (2, negT (.var 0))]

example : inferOK lCoc badCtx (.app (.var 2) (.var 1)) botT = true := by
  decide

/-- 电五：conversion 的 β 面。 -/
example : conv (.app (.lam 9 (.srt false) (.var 9)) botT) botT
          && tmEq (nf (.app (.lam 9 (.srt false) (.var 9)) botT)) botT
          = true := by decide

end Ex38
