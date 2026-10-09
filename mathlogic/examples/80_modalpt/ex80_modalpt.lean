/- ex80_modalpt.lean —— 模态证明论：矢列与超矢列（马明辉 6.2/6.3）
   GI 规则检查器+书例 6.4+超矢列分量级一步关系账。 -/

set_option linter.unusedVariables false

inductive Mform where
  | mvar (n : Nat)
  | mbot
  | mand (a b : Mform)
  | mor (a b : Mform)
  | mimp (a b : Mform)
  | mbox (a : Mform)
  deriving DecidableEq

def negm (a : Mform) : Mform := .mimp a .mbot
def diam (a : Mform) : Mform := negm (.mbox (negm a))

def Mform.eqb : Mform → Mform → Bool
  | .mvar m, .mvar n => m == n
  | .mbot, .mbot => true
  | .mand a1 a2, .mand b1 b2 => a1.eqb b1 && a2.eqb b2
  | .mor a1 a2, .mor b1 b2 => a1.eqb b1 && a2.eqb b2
  | .mimp a1 a2, .mimp b1 b2 => a1.eqb b1 && a2.eqb b2
  | .mbox a1, .mbox b1 => a1.eqb b1
  | _, _ => false

mutual
def delm (a : Mform) : List Mform → Option (List Mform)
  | [] => none
  | b :: l' => if a.eqb b then some l'
               else (delm a l').map (fun r => b :: r)

def meql : List Mform → List Mform → Bool
  | [], [] => true
  | a :: G', H => match delm a H with
                  | some H' => meql G' H'
                  | none => false
  | [], _ => false
end

/- ---------- GI 组规则检查器 ---------- -/

def Mseq := List Mform × Mform

inductive Mr where
  | mId | mBotL | mK | mT | mS4

inductive Mder where
  | mnode (s : Mseq) (r : Mr) (ds : List Mder)

def mseqOf : Mder → Mseq
  | .mnode s _ _ => s

def unbox : Mform → Option Mform
  | .mbox x => some x
  | _ => none

def unboxL : List Mform → Option (List Mform)
  | [] => some []
  | a :: G' => match unbox a, unboxL G' with
               | some x, some L => some (x :: L)
               | _, _ => none

def meqS (s t : Mseq) : Bool := meql s.1 t.1 && s.2.eqb t.2

def meqlS : List Mseq → List Mseq → Bool
  | [], [] => true
  | s1 :: t1, s2 :: t2 => meqS s1 s2 && meqlS t1 t2
  | _, _ => false

def mprems (s : Mseq) (r : Mr) : List Mseq :=
  match r with
  | .mId | .mBotL => []
  | .mT => match s.1.head? with
           | some (.mbox a) => [ (a :: s.1.tail!, s.2) ]
           | _ => [ s ]
  | .mK => match s.1.head?, s.2 with
           | some (.mbox a), .mbox c =>
               match unboxL s.1.tail! with
               | some L => [ (a :: L, c) ]
               | none => [ s ]
           | _, _ => [ s ]
  | .mS4 => match s.1.head?, s.2 with
            | some (.mbox a), .mbox c =>
                match unboxL s.1.tail! with
                | some L => [ (.mbox a :: L, c) ]
                | none => [ s ]
            | _, _ => [ s ]

mutual
def mchkList : List Mder → Bool
  | [] => true
  | d :: ds => mchk d && mchkList ds

def mchk : Mder → Bool
  | .mnode s r ds =>
      (match r with
       | .mId => s.1.any (fun a => match a with
                                  | .mvar _ => a.eqb s.2
                                  | _ => false)
       | .mBotL => s.1.any (fun a => match a with
                                   | .mbot => true
                                   | _ => false)
       | _ => true)
        && mchkList ds
        && meqlS (ds.map mseqOf) (mprems s r)
end

def p : Mform := .mvar 0
def q : Mform := .mvar 1

/-- 例 6.4(2)：GKT ⊢ □α⇒α——一步 (T) 自公理 -/
example :
    mchk (.mnode ([.mbox p], p) .mT [ .mnode ([p], p) .mId [] ]) = true := by
  native_decide

/-- 例 6.4(5) 链形实例：GS4 ⊢ □p,□□p ⇒ □p（T→S4 链=(K) 结论形状） -/
def chainGS4 : Mder :=
  .mnode ([.mbox p, .mbox (.mbox p)], .mbox p) .mS4
    [ .mnode ([.mbox p, .mbox p], p) .mT
        [ .mnode ([p, .mbox p], p) .mId [] ] ]

example : mchk chainGS4 = true := by native_decide

/-- 六系统-框架条件对应表数据影子 -/
def giTable : List (Nat × Nat) :=
  [ (1, 0), (2, 1), (3, 2), (4, 3), (5, 4), (6, 5) ]

example : giTable.length = 6 := by native_decide

/- ---------- 超矢列分量级一步关系账 ---------- -/

def Comp := List Mform × List Mform
def Hseq := List Comp

def compAxiom (s : Comp) : Bool :=
  s.1.any (fun a => match a with
                    | .mvar _ => s.2.any (fun b => a.eqb b)
                    | _ => false)
    || s.1.any (fun a => match a with | .mbot => true | _ => false)

mutual
def delComp (s : Comp) : Hseq → Option Hseq
  | [] => none
  | t :: k' => if meql s.1 t.1 && meql s.2 t.2 then some k'
               else (delComp s k').map (fun r => t :: r)

def hEqb : Hseq → Hseq → Bool
  | [], [] => true
  | s :: h', k => match delComp s k with
                  | some k' => hEqb h' k'
                  | none => false
  | [], _ => false
end

def removeAt (n : Nat) (h : Hseq) : Hseq := h.take n ++ h.drop (n + 1)

def ewRel (h k : Hseq) : Bool :=
  (List.range h.length).any (fun n => hEqb (removeAt n h) k)

def ecRel (h k : Hseq) : Bool :=
  (List.range k.length).any (fun n => hEqb (removeAt n k) h)

def mgRel (h k : Hseq) : Bool :=
  match h, k with
  | (g, dl) :: h', (g1, d1) :: (g2, d2) :: k' =>
      meql g (g1 ++ g2) && meql dl (d1 ++ d2) && hEqb h' k'
  | _, _ => false

def unboxOne : List Mform → List (List Mform)
  | [] => []
  | .mbox x :: g' => (x :: g') :: (unboxOne g').map (fun r => .mbox x :: r)
  | a :: g' => (unboxOne g').map (fun r => a :: r)

def b1Rel : Hseq → Hseq → Bool
  | (gh, dh) :: h', (gk, dk) :: k' =>
      meql dh dk
        && ((unboxOne gh).any (fun g => meql g gk) || (meql gh gk && b1Rel h' k'))
  | _, _ => false

example : compAxiom ([p], [p]) = true := by native_decide
example : compAxiom ([.mbot, p], []) = true := by native_decide
example : ewRel [([p], [p]), ([q], [q])] [([p], [p])] = true := by native_decide
example : ecRel [([p], [p])] [([p], [p]), ([p], [p])] = true := by native_decide
example : mgRel [([p, q], [p, q])] [([p], [p]), ([q], [q])] = true := by
  native_decide
example : b1Rel [([.mbox p], [p])] [([p], [p])] = true := by native_decide
example : compAxiom ([p], [p]) && b1Rel [([.mbox p], [p])] [([p], [p])]
  = true := by native_decide
