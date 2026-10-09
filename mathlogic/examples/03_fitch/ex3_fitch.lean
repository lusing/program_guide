/- ex3_fitch.lean —— 费奇式自然演绎 FJ/FK（马明辉 2.1）Lean 镜像
   级别纪律+作用域可达性（accSame/accUp）+依据逐行核+书例重演+FJ/FK 分隔。 -/

set_option linter.unusedVariables false

inductive Fform where
  | pvar (n : Nat)
  | fbot
  | fand (a b : Fform)
  | forr (a b : Fform)
  | fimp (a b : Fform)
  deriving Repr

def fneg (a : Fform) : Fform := .fimp a .fbot

def Fform.eqb : Fform → Fform → Bool
  | .pvar m, .pvar n => m == n
  | .fbot, .fbot => true
  | .fand a1 a2, .fand b1 b2 => a1.eqb b1 && a2.eqb b2
  | .forr a1 a2, .forr b1 b2 => a1.eqb b1 && a2.eqb b2
  | .fimp a1 a2, .fimp b1 b2 => a1.eqb b1 && a2.eqb b2
  | _, _ => false

inductive Just where
  | pre | hyp
  | reit (m : Nat)
  | ai (m n : Nat) | ael (m : Nat) | aer (m : Nat)
  | oi1 (m : Nat) | oi2 (m : Nat)
  | oe (m a b c d : Nat)
  | iif (a b : Nat)
  | ief (m n : Nat)
  | bote (m : Nat)
  | nef (a b : Nat)

def isHyp : Just → Bool
  | .hyp => true
  | _ => false

structure Fline where
  flv : Nat
  ffm : Fform
  fjt : Just

def getl (d : List Fline) (m : Nat) : Option Fline := d[m - 1]?
def getm (d : List Fline) (m : Nat) : Option Fform := (getl d m).map Fline.ffm
def getv (d : List Fline) (m : Nat) : Option Nat := (getl d m).map Fline.flv

def bimp (a b : Bool) : Bool := !a || b

/-- j..hi 中是否有级别 lv 的 Hyp（同级别框边界） -/
def anyHypLv (d : List Fline) (j hi lv : Nat) : Bool :=
  if j > hi then false
  else (List.range (hi - j + 1)).any (fun k =>
    match getl d (j + k) with
    | some l => isHyp l.fjt && (l.flv == lv)
    | none => false)

/-- j..hi 中是否有级别 < lv（父框闭合） -/
def anyBelow (d : List Fline) (j hi lv : Nat) : Bool :=
  if j > hi then false
  else (List.range (hi - j + 1)).any (fun k =>
    match getv d (j + k) with
    | some v => decide (v < lv)
    | none => false)

/-- 同框可达：同级、之前、中间无同级 Hyp -/
def accSame (d : List Fline) (m i : Nat) : Bool :=
  match getv d m, getv d i with
  | some vm, some vi => (vm == vi) && decide (m < i) && !anyHypLv d (m + 1) i vm
  | _, _ => false

/-- 上一级可达（Reit 专用）：恰差一级、父框未闭合 -/
def accUp (d : List Fline) (m i : Nat) : Bool :=
  match getv d m, getv d i with
  | some vm, some vi => (vi == vm + 1) && decide (m < i) && !anyBelow d (m + 1) i vm
  | _, _ => false

def firstOK (l : Fline) : Bool :=
  match l.fjt with
  | .pre => l.flv == 0
  | .hyp => l.flv == 1
  | _ => false

def stepOK (l1 l2 : Fline) : Bool :=
  (decide (l2.flv ≤ l1.flv + 1))
    && (bimp (l2.flv == l1.flv + 1) (isHyp l2.fjt))
    && (bimp (isHyp l2.fjt)
          (decide (1 ≤ l2.flv) && (l2.flv == l1.flv || l2.flv == l1.flv + 1)))
    && (bimp (match l2.fjt with | .pre => true | _ => false) (l2.flv == 0))

def stepsOK (d : List Fline) : Bool :=
  match d with
  | [] => true
  | [_] => true
  | l1 :: tl =>
      match tl with
      | [] => true
      | l2 :: _ => stepOK l1 l2 && stepsOK tl

def levelsOK (d : List Fline) : Bool :=
  match d with
  | [] => true
  | l :: _ => firstOK l && stepsOK d

def check1 (d : List Fline) (i kc : Nat) (l : Fline) : Bool :=
  match l.fjt with
  | .pre => l.flv == 0
  | .hyp => true
  | .reit m =>
      match getl d m with
      | some lm => l.ffm.eqb lm.ffm && (accSame d m i || accUp d m i)
      | none => false
  | .ai m n =>
      match getm d m, getm d n with
      | some a, some b => l.ffm.eqb (.fand a b) && accSame d m i && accSame d n i
      | _, _ => false
  | .ael m =>
      match getm d m with
      | some (.fand a _) => l.ffm.eqb a && accSame d m i
      | _ => false
  | .aer m =>
      match getm d m with
      | some (.fand _ b) => l.ffm.eqb b && accSame d m i
      | _ => false
  | .oi1 m =>
      match getm d m, l.ffm with
      | some a, .forr a' _ => a.eqb a' && accSame d m i
      | _, _ => false
  | .oi2 m =>
      match getm d m, l.ffm with
      | some b, .forr _ b' => b.eqb b' && accSame d m i
      | _, _ => false
  | .bote m =>
      match getm d m with
      | some .fbot => accSame d m i
      | _ => false
  | .ief m n =>
      match getm d m, getm d n with
      | some (.fimp a b), some a' =>
          a.eqb a' && l.ffm.eqb b && accSame d m i && accSame d n i
      | _, _ => false
  | .iif a b =>
      (b + 1 == i)
        && (match getl d a, getl d b with
            | some la, some lb =>
                (la.flv == l.flv + 1) && (lb.flv == la.flv)
                  && isHyp la.fjt && l.ffm.eqb (.fimp la.ffm lb.ffm)
            | _, _ => false)
  | .nef a b =>
      (kc == 1) && (b + 1 == i)
        && (match getl d a, getl d b with
            | some la, some lb =>
                (la.flv == l.flv + 1) && (lb.flv == la.flv)
                  && isHyp la.fjt && la.ffm.eqb (fneg l.ffm) && lb.ffm.eqb .fbot
            | _, _ => false)
  | .oe m a b c e =>
      (b + 1 == c) && (e + 1 == i) && accSame d m i
        && (match getl d m, getl d a, getl d b, getl d c, getl d e with
            | some lm, some la, some lb, some lc, some le =>
                (la.flv == l.flv + 1) && (lc.flv == l.flv + 1)
                  && (lb.flv == la.flv) && (le.flv == lc.flv)
                  && isHyp la.fjt && isHyp lc.fjt
                  && (match lm.ffm with
                      | .forr x y =>
                          x.eqb la.ffm && y.eqb lc.ffm
                            && lb.ffm.eqb l.ffm && le.ffm.eqb l.ffm
                      | _ => false)
            | _, _, _, _, _ => false)

def checkAll (d : List Fline) (kc : Nat) : Bool :=
  (List.range d.length).all (fun k =>
    match getl d (k + 1) with
    | some l => check1 d (k + 1) kc l
    | none => true)

def fitchOK (kc : Nat) (d : List Fline) : Bool :=
  levelsOK d && checkAll d kc

/- ---------- 书例 ---------- -/

def p0 : Fform := .pvar 0
def p1 : Fform := .pvar 1

def exIntro : List Fline :=
  [ ⟨0, p0, .pre⟩
  , ⟨0, .fimp p0 p1, .pre⟩
  , ⟨0, fneg p1, .pre⟩
  , ⟨0, p1, .ief 2 1⟩
  , ⟨0, .fbot, .ief 3 4⟩ ]

example : fitchOK 1 exIntro = true := by native_decide

def exId : List Fline :=
  [ ⟨1, p0, .hyp⟩
  , ⟨1, p0, .reit 1⟩
  , ⟨0, .fimp p0 p0, .iif 1 2⟩ ]

example : fitchOK 0 exId = true := by native_decide

/-- 例 2.1(3)：⊢FK ¬¬α→α（含跨级 Reit 与 ¬E 归谬） -/
def exDNE : List Fline :=
  [ ⟨1, fneg (fneg p0), .hyp⟩
  , ⟨2, fneg p0, .hyp⟩
  , ⟨2, fneg (fneg p0), .reit 1⟩
  , ⟨2, .fbot, .ief 3 2⟩
  , ⟨1, p0, .nef 2 4⟩
  , ⟨0, .fimp (fneg (fneg p0)) p0, .iif 1 5⟩ ]

example : fitchOK 1 exDNE = true := by native_decide
example : fitchOK 0 exDNE = false := by native_decide

/-- 引例：α∨β ⊢ β∨α（∨E 双并列框） -/
def exComm : List Fline :=
  [ ⟨0, .forr p0 p1, .pre⟩
  , ⟨1, p0, .hyp⟩
  , ⟨1, .forr p1 p0, .oi2 2⟩
  , ⟨1, p1, .hyp⟩
  , ⟨1, .forr p1 p0, .oi1 4⟩
  , ⟨0, .forr p1 p0, .oe 1 2 3 4 5⟩ ]

example : fitchOK 0 exComm = true := by native_decide

/-- 引例：⊢ (α→β)→((β→γ)→(α→γ))——级联 Reit -/
def exSyll : List Fline :=
  [ ⟨1, .fimp p0 p1, .hyp⟩
  , ⟨2, .fimp p1 (.pvar 2), .hyp⟩
  , ⟨2, .fimp p0 p1, .reit 1⟩
  , ⟨3, p0, .hyp⟩
  , ⟨3, .fimp p0 p1, .reit 3⟩
  , ⟨3, p1, .ief 5 4⟩
  , ⟨3, .fimp p1 (.pvar 2), .reit 2⟩
  , ⟨3, .pvar 2, .ief 7 6⟩
  , ⟨2, .fimp p0 (.pvar 2), .iif 4 8⟩
  , ⟨1, .fimp (.fimp p1 (.pvar 2)) (.fimp p0 (.pvar 2)), .iif 2 9⟩
  , ⟨0, .fimp (.fimp p0 p1) (.fimp (.fimp p1 (.pvar 2)) (.fimp p0 (.pvar 2))), .iif 1 10⟩ ]

example : fitchOK 0 exSyll = true := by native_decide

/-- ⊢FK p∨¬p；FJ 拒收 -/
def exLem : List Fline :=
  [ ⟨1, fneg (.forr p0 (fneg p0)), .hyp⟩
  , ⟨2, p0, .hyp⟩
  , ⟨2, fneg (.forr p0 (fneg p0)), .reit 1⟩
  , ⟨2, .forr p0 (fneg p0), .oi1 2⟩
  , ⟨2, .fbot, .ief 3 4⟩
  , ⟨1, fneg p0, .iif 2 5⟩
  , ⟨1, .forr p0 (fneg p0), .oi2 6⟩
  , ⟨1, .fbot, .ief 1 7⟩
  , ⟨0, .forr p0 (fneg p0), .nef 1 8⟩ ]

example : fitchOK 1 exLem = true := by native_decide
example : fitchOK 0 exLem = false := by native_decide

/-- 两点 Kripke 链 0R1、V(p)={1}：p∨¬p 在 0 点假 -/
def acc01 : Nat → Nat → Bool
  | 0, 0 | 0, 1 | 1, 1 => true
  | _, _ => false

def kforce (w : Nat) : Fform → Bool
  | .pvar n => (n == 0) && (w == 1)
  | .fbot => false
  | .fand x y => kforce w x && kforce w y
  | .forr x y => kforce w x || kforce w y
  | .fimp x y => [0,1].all (fun u => !acc01 w u || !kforce u x || kforce u y)

example : kforce 0 (.forr p0 (fneg p0)) = false := by native_decide
example : [0,1].all (fun w => kforce w (fneg (fneg (.forr p0 (fneg p0))))) = true := by
  native_decide

/-- 跨级引用抓错现场 -/
def badCross : List Fline :=
  [ ⟨1, .fimp p0 p1, .hyp⟩
  , ⟨2, p0, .hyp⟩
  , ⟨2, p1, .ief 1 2⟩
  , ⟨1, .fimp p0 p1, .iif 2 3⟩
  , ⟨0, .fimp (.fimp p0 p1) (.fimp p0 p1), .iif 1 4⟩ ]

example : fitchOK 1 badCross = false := by native_decide

def goodCross : List Fline :=
  [ ⟨1, .fimp p0 p1, .hyp⟩
  , ⟨2, p0, .hyp⟩
  , ⟨2, .fimp p0 p1, .reit 1⟩
  , ⟨2, p1, .ief 3 2⟩
  , ⟨1, .fimp p0 p1, .iif 2 4⟩
  , ⟨0, .fimp (.fimp p0 p1) (.fimp p0 p1), .iif 1 5⟩ ]

example : fitchOK 0 goodCross = true := by native_decide
