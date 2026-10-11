/- ex85_interpolation.lean —— Craig 插值定理（马明辉 3.4）Lean 镜像
   Maehara 组合表 interp+三条件语义验证。 -/

set_option linter.unusedVariables false

inductive Fform where
  | pvar (n : Nat)
  | fbot
  | fand (a b : Fform)
  | forr (a b : Fform)
  | fimp (a b : Fform)
  deriving DecidableEq

def fneg (a : Fform) : Fform := .fimp a .fbot
def ftop : Fform := .fimp .fbot .fbot

inductive Mrule where
  | ax (a : Fform) (s1 s2 : Bool)
  | andL (i : Bool)
  | andR (s : Bool)
  | orL (s : Bool)
  | orR1 (s : Bool) | orR2 (s : Bool)
  | impL (s : Bool)
  | impR (s : Bool)

inductive Mder where
  | mnode (g1 d1 g2 d2 : List Fform) (r : Mrule) (ds : List Mder)

def interp : Mder → Fform
  | .mnode _ _ _ _ r ds =>
      match r, ds with
      | .ax a s1 s2, _ =>
          match s1, s2 with
          | true, false => a
          | true, true => .fbot
          | false, false => ftop
          | false, true => fneg a
      | .andL _, [d] => interp d
      | .orR1 _, [d] => interp d
      | .orR2 _, [d] => interp d
      | .impR _, [d] => interp d
      | .andR s, [d1, d2] =>
          if s then .forr (interp d1) (interp d2) else .fand (interp d1) (interp d2)
      | .orL s, [d1, d2] =>
          if s then .forr (interp d1) (interp d2) else .fand (interp d1) (interp d2)
      | .impL s, [d1, d2] =>
          if s then .forr (interp d1) (interp d2) else .fand (interp d1) (interp d2)
      | _, _ => .fbot

def ev (e : Nat → Bool) : Fform → Bool
  | .pvar n => e n
  | .fbot => false
  | .fand x y => ev e x && ev e y
  | .forr x y => ev e x || ev e y
  | .fimp x y => !ev e x || ev e y

def conjL (G : List Fform) : Fform := List.foldr Fform.fand ftop G
def disjL (D : List Fform) : Fform := List.foldr Fform.forr .fbot D

/-- 真值表全枚举（变元 ≤2） -/
def taut2 (a : Fform) : Bool :=
  [true, false].all (fun b0 =>
    [true, false].all (fun b1 =>
      ev (fun n => match n with
                   | 0 => b0 | 1 => b1 | _ => false) a))

def varsOf : Fform → List Nat
  | .pvar n => [n]
  | .fbot => []
  | .fand x y | .forr x y | .fimp x y => varsOf x ++ varsOf y

def varsL (G : List Fform) : List Nat := G.flatMap varsOf

def varsIn (l : List Nat) (f : Fform) : Bool :=
  (varsOf f).all (fun n => l.contains n)

def cond1 : Mder → Bool
  | d@(.mnode g1 d1 _ _ _ _) =>
      taut2 (.fimp (conjL g1) (disjL (d1 ++ [interp d])))

def cond2 : Mder → Bool
  | d@(.mnode _ _ g2 d2 _ _) =>
      taut2 (.fimp (.fand (interp d) (conjL g2)) (disjL d2))

def cond3 : Mder → Bool
  | d@(.mnode g1 d1 g2 d2 _ _) =>
      varsIn (varsL g1 ++ varsL d1) (interp d)
        && varsIn (varsL g2 ++ varsL d2) (interp d)

def p0 : Fform := .pvar 0
def p1 : Fform := .pvar 1

def mcond (d : Mder) : Bool := cond1 d && cond2 d && cond3 d

/-- 例 1：(p∧q)∨(¬p∧q) ⇒ q；插值子 q∨q -/
def exShare : Mder :=
  .mnode [.forr (.fand p0 p1) (.fand (fneg p0) p1)] [] [] [p1] (.orL true)
    [ .mnode [.fand p0 p1] [] [] [p1] (.andL true)
        [ .mnode [p1] [] [] [p1] (.ax p1 true false) [] ]
    , .mnode [.fand (fneg p0) p1] [] [] [p1] (.andL true)
        [ .mnode [p1] [] [] [p1] (.ax p1 true false) [] ] ]

example : interp exShare = .forr p1 p1 := by native_decide
example : mcond exShare = true := by native_decide

/-- 例 2：(p∧q) ⇒ (q∧p)；(⇒∧) 主公式在 Δ₂ → γ1∧γ2 = q∧p -/
def exSwap : Mder :=
  .mnode [.fand p0 p1] [] [] [.fand p1 p0] (.andR false)
    [ .mnode [.fand p0 p1] [] [] [p1] (.andL false)
        [ .mnode [p1] [] [] [p1] (.ax p1 true false) [] ]
    , .mnode [.fand p0 p1] [] [] [p0] (.andL false)
        [ .mnode [p0] [] [] [p0] (.ax p0 true false) [] ] ]

example : interp exSwap = .fand p1 p0 := by native_decide
example : mcond exSwap = true := by native_decide

/-- 例 3（常值流）：p ⇒ p 两份同侧 → γ=⊥ -/
def exConst : Mder := .mnode [p0] [p0] [] [] (.ax p0 true true) []

example : interp exConst = .fbot := by native_decide
example : mcond exConst = true := by native_decide
