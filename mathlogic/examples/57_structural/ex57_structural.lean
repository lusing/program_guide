/- ex57_structural.lean —— 矢列演算的结构规则谱系（马明辉 3.1/4.1-4.5）Lean 镜像
   μ 权重+四不等式；G3ip 注记推导检查器（多重集前件+Ea 扩张）；
   G4ip 终止搜索器；Glivenko 嵌入双树。 -/

set_option linter.unusedVariables false

inductive Fform where
  | pvar (n : Nat)
  | fbot
  | fand (a b : Fform)
  | forr (a b : Fform)
  | fimp (a b : Fform)
  deriving DecidableEq

def fneg (a : Fform) : Fform := .fimp a .fbot

def Fform.eqb : Fform → Fform → Bool
  | .pvar m, .pvar n => m == n
  | .fbot, .fbot => true
  | .fand a1 a2, .fand b1 b2 => a1.eqb b1 && a2.eqb b2
  | .forr a1 a2, .forr b1 b2 => a1.eqb b1 && a2.eqb b2
  | .fimp a1 a2, .fimp b1 b2 => a1.eqb b1 && a2.eqb b2
  | _, _ => false

/-- Dyckhoff 权重 μ -/
def mu : Fform → Nat
  | .pvar _ | .fbot => 2
  | .fand x y => mu x * (1 + mu y)
  | .forr x y => mu x + mu y + 1
  | .fimp x y => mu x * mu y + 1

def smpl : List Fform :=
  let p := .pvar 0; let q := .pvar 1; let r := .pvar 2
  [ p, q, .fbot, .fimp p q, .fimp q p, .fand p q, .forr p q
  , .fimp (.fand p q) r, .fimp (.forr p q) r, .fimp (.fimp p q) r
  , .fimp p (.fimp q r), .fimp (.fimp q r) p, fneg p, fneg (fneg p)
  , .forr p (fneg p), .fimp (fneg p) (fneg (fneg p)) ]

def triples : List (Fform × Fform × Fform) :=
  smpl.flatMap (fun x => smpl.flatMap (fun y => smpl.map (fun z => (x, y, z))))

/-- 不等式 (1)：μ(a1→(a2→a)) < μ((a1∧a2)→a) -/
example : triples.all (fun t =>
    decide (mu (.fimp t.1 (.fimp t.2.1 t.2.2))
            < mu (.fimp (.fand t.1 t.2.1) t.2.2))) = true := by native_decide

/-- 不等式 (4)：μ(a2→a) < μ((a1→a2)→a) -/
example : triples.all (fun t =>
    decide (mu (.fimp t.2.1 t.2.2)
            < mu (.fimp (.fimp t.1 t.2.1) t.2.2))) = true := by native_decide

/-- (∨⇒→) 两支皆降权 -/
example : triples.all (fun t =>
    (decide (mu (.fimp t.1 t.2.2) < mu (.fimp (.forr t.1 t.2.1) t.2.2))
      && decide (mu (.fimp t.2.1 t.2.2) < mu (.fimp (.forr t.1 t.2.1) t.2.2))))
    = true := by native_decide

/- ---------- G3ip 注记推导检查器 ---------- -/

def Sq3 := List Fform × Fform

inductive Rname where
  | rId | rBotL | rAndL | rAndR | rOrL | rOrR1 | rOrR2
  | rImpL | rImpR | rEa
  deriving DecidableEq

inductive G3d where
  | gnode (s : Sq3) (r : Rname) (ds : List G3d)

def seqOf : G3d → Sq3
  | .gnode s _ _ => s

/-- 前件多重集比较 -/
def del1 (a : Fform) : List Fform → Option (List Fform)
  | [] => none
  | b :: l' => if a.eqb b then some l'
               else (del1 a l').map (fun r => b :: r)

def meqb : List Fform → List Fform → Bool
  | [], [] => true
  | a :: G', H => match del1 a H with
                  | some H' => meqb G' H'
                  | none => false
  | [], _ => false

def seqEqb (s t : Sq3) : Bool := meqb s.1 t.1 && s.2.eqb t.2

/-- 按规则名从结论矢列算前提矢列表（G3 风格：主公式重复于前提；
    主公式取前件首个同形公式——多重集语义下位置无关） -/
def premsOf (s : Sq3) (r : Rname) : List Sq3 :=
  match r with
  | .rId | .rBotL => []
  | .rAndL => match s.1.head? with
              | some (.fand a1 a2) => [ (a1 :: a2 :: s.1, s.2) ]
              | _ => [ s ]
  | .rAndR => match s.2 with
              | .fand a1 a2 => [ (s.1, a1), (s.1, a2) ]
              | _ => [ s ]
  | .rOrL => match s.1.head? with
             | some (.forr a1 a2) =>
                 [ (a1 :: s.1, s.2), (a2 :: s.1, s.2) ]
             | _ => [ s, s ]
  | .rOrR1 => match s.2 with
              | .forr a1 _ => [ (s.1, a1) ]
              | _ => [ s ]
  | .rOrR2 => match s.2 with
              | .forr _ a2 => [ (s.1, a2) ]
              | _ => [ s ]
  | .rImpL => match s.1.head? with
              | some (.fimp a1 a2) => [ (s.1, a1), (a2 :: s.1, s.2) ]
              | _ => [ s, s ]
  | .rImpR => match s.2 with
              | .fimp a1 a2 => [ (a1 :: s.1, a2) ]
              | _ => [ s ]
  | .rEa => [ (fneg (.pvar 0) :: s.1, s.2), (.pvar 0 :: s.1, s.2) ]

def axOK (s : Sq3) (r : Rname) : Bool :=
  match r with
  | .rId => s.1.any (fun a => match a with
                             | .pvar _ => a.eqb s.2
                             | _ => false)
  | .rBotL => s.1.any (fun a => match a with
                               | .fbot => true
                               | _ => false)
  | _ => true

def listSeqEqb : List Sq3 → List Sq3 → Bool
  | [], [] => true
  | s1 :: t1, s2 :: t2 => seqEqb s1 s2 && listSeqEqb t1 t2
  | _, _ => false

mutual
def g3chkList : List G3d → Bool → Bool
  | [], _ => true
  | d :: ds, kcEa => g3chk d kcEa && g3chkList ds kcEa

def g3chk : G3d → Bool → Bool
  | .gnode s r ds, kcEa =>
      (!(match r with | .rEa => true | _ => false) || kcEa)
        && axOK s r
        && g3chkList ds kcEa
        && listSeqEqb (ds.map seqOf) (premsOf s r)
end

/- ---------- G4ip 终止搜索器 ---------- -/

def isAxiom (G : List Fform) (b : Fform) : Bool :=
  G.any (fun a => match a with
                  | .fbot => true
                  | .pvar _ => a.eqb b
                  | _ => false)

def findAnd : List Fform → Option (Fform × Fform × List Fform)
  | [] => none
  | .fand a1 a2 :: G' => some (a1, a2, G')
  | a :: G' => (findAnd G').map (fun t => (t.1, t.2.1, a :: t.2.2))

def findOr : List Fform → Option (Fform × Fform × List Fform)
  | [] => none
  | .forr a1 a2 :: G' => some (a1, a2, G')
  | a :: G' => (findOr G').map (fun t => (t.1, t.2.1, a :: t.2.2))

def impChoices : List Fform → List (Fform × Fform × List Fform)
  | [] => []
  | .fimp a1 a2 :: G' =>
      (a1, a2, G')
        :: (impChoices G').map (fun t => (t.1, t.2.1, .fimp a1 a2 :: t.2.2))
  | a :: G' => (impChoices G').map (fun t => (t.1, t.2.1, a :: t.2.2))

def g4prove : Nat → Sq3 → Bool
  | 0, _ => false
  | f + 1, (G, b) =>
      if isAxiom G b then true
      else
        match findAnd G with
        | some (a1, a2, G') => g4prove f (a1 :: a2 :: G', b)
        | none =>
        match findOr G with
        | some (a1, a2, G') => g4prove f (a1 :: G', b) && g4prove f (a2 :: G', b)
        | none =>
        match b with
        | .fand a1 a2 => g4prove f (G, a1) && g4prove f (G, a2)
        | .forr a1 a2 => g4prove f (G, a1) || g4prove f (G, a2)
        | .fimp a1 a2 => g4prove f (a1 :: G, a2)
        | _ =>
          (impChoices G).any (fun t =>
            match t with
            | (.fbot, _, G') => g4prove f (G', b)
            | (.pvar k, a, G') => g4prove f (G', .pvar k) && g4prove f (a :: G', b)
            | (.fand a1 a2, a, G') => g4prove f (.fimp a1 (.fimp a2 a) :: G', b)
            | (.forr a1 a2, a, G') => g4prove f (.fimp a1 a :: .fimp a2 a :: G', b)
            | (.fimp a1 a2, a, G') =>
                g4prove f (a1 :: .fimp (.fimp a1 a2) a :: G', a2)
                  && g4prove f (a :: .fimp (.fimp a1 a2) a :: G', b))

def p0 : Fform := .pvar 0
def p1 : Fform := .pvar 1

example : g4prove 200 ([], .fimp p0 p0) = true := by native_decide
example : g4prove 400 ([], .fimp (.fimp p0 p1) (.fimp (.fimp p1 p0) (.fimp p0 p0)))
  = true := by native_decide
example : g4prove 400 ([], .fimp (.fand p0 p1) (.fand p1 p0)) = true := by
  native_decide
example : g4prove 400 ([], fneg (fneg (.forr p0 (fneg p0)))) = true := by
  native_decide
example : g4prove 400 ([], .fimp (fneg (fneg p0)) p0) = false := by native_decide
example : g4prove 400 ([], .forr p0 (fneg p0)) = false := by native_decide
example : g4prove 400 ([], .fimp (.fimp (.fimp p0 p1) p0) p0) = false := by
  native_decide

/- ---------- Glivenko 嵌入双树 ---------- -/

def eaLem : G3d :=
  .gnode ([], .forr p0 (fneg p0)) .rEa
    [ .gnode ([fneg p0], .forr p0 (fneg p0)) .rOrR2
        [ .gnode ([fneg p0], fneg p0) .rImpR
            [ .gnode ([fneg p0, p0], .fbot) .rImpL
                [ .gnode ([fneg p0, p0], p0) .rId []
                , .gnode ([.fbot, fneg p0, p0], .fbot) .rBotL [] ] ] ]
    , .gnode ([p0], .forr p0 (fneg p0)) .rOrR1
        [ .gnode ([p0], p0) .rId [] ] ]

example : g3chk eaLem true = true := by native_decide
example : g3chk eaLem false = false := by native_decide

def gGlivenko : G3d :=
  .gnode ([], fneg (fneg (.forr p0 (fneg p0)))) .rImpR
    [ .gnode ([fneg (.forr p0 (fneg p0))], .fbot) .rImpL
        [ .gnode ([fneg (.forr p0 (fneg p0))], .forr p0 (fneg p0)) .rOrR2
            [ .gnode ([fneg (.forr p0 (fneg p0))], fneg p0) .rImpR
                [ .gnode ([fneg (.forr p0 (fneg p0)), p0], .fbot) .rImpL
                    [ .gnode ([fneg (.forr p0 (fneg p0)), p0],
                              .forr p0 (fneg p0)) .rOrR1
                          [ .gnode ([fneg (.forr p0 (fneg p0)), p0], p0) .rId [] ]
                    , .gnode ([.fbot, fneg (.forr p0 (fneg p0)), p0], .fbot)
                        .rBotL [] ] ] ]
        , .gnode ([.fbot, fneg (.forr p0 (fneg p0))], .fbot) .rBotL [] ] ]

example : g3chk gGlivenko false = true := by native_decide

/-- 逐规则降权账 -/
example :
    (decide (mu (.fimp p0 (.fimp p1 p0)) < mu (.fimp (.fand p0 p1) p0))
      && decide (mu (.fimp p0 p0) < mu (.fimp (.forr p0 p1) p0))
      && decide (mu (.fimp p1 p0) < mu (.fimp (.forr p0 p1) p0))) = true := by
  native_decide
