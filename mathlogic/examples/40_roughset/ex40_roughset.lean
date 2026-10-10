/- ex40_roughset —— 粗糙集、语用力与双直觉主义（Lean 4 版）
   与 ex40_roughset.v 同构：粗糙集实验室（5 等价关系枚举+对偶/双否定
   对/分配律+边界反例）、双模态 S4 引理 1 的穷举式机器证明（29 预序
   ×29、Ax.a ⟺ S⊆R 逐帧等价）、余直觉减法 Kripke 语义三电。 -/

namespace Ex40

set_option maxRecDepth 2000000

def relAt (E i j : Nat) : Bool := (E >>> (3 * i + j)) &&& 1 == 1

def allRels : List Nat := List.range 512

def reflOK (E : Nat) : Bool := [0, 1, 2].all fun i => relAt E i i

def symmOK (E : Nat) : Bool :=
  [0, 1, 2].all fun i => [0, 1, 2].all fun j => !relAt E i j || relAt E j i

def transOK (E : Nat) : Bool :=
  [0, 1, 2].all fun i =>
    [0, 1, 2].all fun j =>
      [0, 1, 2].all fun k =>
        !(relAt E i j && relAt E j k) || relAt E i k

def equivOK (E : Nat) : Bool := reflOK E && symmOK E && transOK E

def allEquivs : List Nat := allRels.filter equivOK

def memU (G x : Nat) : Bool := (G >>> x) &&& 1 == 1
def compU (G : Nat) : Nat := 7 ^^^ G
def allSubsU : List Nat := List.range 8

def cls (E x : Nat) : Nat :=
  (if relAt E x 0 then 1 else 0)
+ (if relAt E x 1 then 2 else 0)
+ (if relAt E x 2 then 4 else 0)

def subU (G H : Nat) : Bool :=
  [0, 1, 2].all fun x => !memU G x || memU H x

def intersects (G H : Nat) : Bool := (G &&& H) != 0

def interrE (E G : Nat) : Nat :=
  (if subU (cls E 0) G then 1 else 0)
+ (if subU (cls E 1) G then 2 else 0)
+ (if subU (cls E 2) G then 4 else 0)

def closrE (E G : Nat) : Nat :=
  (if intersects (cls E 0) G then 1 else 0)
+ (if intersects (cls E 1) G then 2 else 0)
+ (if intersects (cls E 2) G then 4 else 0)

/-- 账一：I(−G) = −C(G)。 -/
example : allEquivs.all fun E =>
      allSubsU.all fun G =>
        interrE E (compU G) == compU (closrE E G)
  = true := by decide

/-- 账二：negPair∘negPair=id。 -/
example : allEquivs.all fun E =>
      allSubsU.all fun G =>
        let X := interrE E G
        let Y := compU (closrE E G)
        (compU (compU X) == X) && (compU (compU Y) == Y)
  = true := by decide

/-- 账三：分配律 I(G∩H)=I(G)∩I(H)、C(G∪H)=C(G)∪C(H)。 -/
example : allEquivs.all fun E =>
      allSubsU.all fun G =>
        allSubsU.all fun H =>
          interrE E (G &&& H) == (interrE E G &&& interrE E H)
            && closrE E (G ||| H) == (closrE E G ||| closrE E H)
  = true := by decide

/-- 边界反例：BND 的交包含不成立（E=433 即 {0}|{1,2}）。 -/
def bnd (E G : Nat) : Nat := closrE E G &&& compU (interrE E G)

example : subU (bnd 433 2 &&& bnd 433 4) (bnd 433 (2 &&& 4)) = false := by
  decide

/- ---------- 双模态 S4 ---------- -/

def preordOK (E : Nat) : Bool := reflOK E && transOK E
def allPreords : List Nat := allRels.filter preordOK

def SRsub (S R : Nat) : Bool :=
  [0, 1, 2].all fun i => [0, 1, 2].all fun j => !relAt S i j || relAt R i j

inductive MForm where
  | mp
  | mimp (a b : MForm)
  | mboxR (a : MForm)
  | mboxS (a : MForm)

def evM (R S val : Nat) (w : Nat) : MForm → Bool
  | .mp => (val >>> w) &&& 1 == 1
  | .mimp a b => !evM R S val w a || evM R S val w b
  | .mboxR a => [0, 1, 2].all fun w' => !relAt R w w' || evM R S val w' a
  | .mboxS a => [0, 1, 2].all fun w' => !relAt S w w' || evM R S val w' a

def allVals3 : List Nat := List.range 8

def frameValid (R S : Nat) (f : MForm) : Bool :=
  allVals3.all fun val => [0, 1, 2].all fun w => evM R S val w f

def axA : MForm := .mimp (.mboxR .mp) (.mboxS (.mboxR .mp))

/-- 引理 1(ii)(a)：Ax.a 有效 ⟺ S⊆R——逐帧等价（841 帧全枚举，
    decide 核归约超时——native_decide 编译执行）。 -/
example :
    ((allPreords.flatMap fun R => allPreords.map fun S => (R, S))).all
      fun p => frameValid p.1 p.2 axA == SRsub p.2 p.1
  = true := by native_decide

/-- 引理 1(i)：传递性方向恒有效。 -/
example :
    ((allPreords.flatMap fun R => allPreords.map fun S => (R, S))).all
      fun p =>
        frameValid p.1 p.2 (.mimp (.mboxR (.mboxR .mp)) (.mboxR .mp))
          && frameValid p.1 p.2 (.mimp (.mboxS (.mboxS .mp)) (.mboxS .mp))
  = true := by native_decide

/- ---------- 余直觉减法 ---------- -/

inductive CForm where
  | ca (n : Nat)
  | cor_ (a b : CForm)
  | cdiff (a b : CForm)
  | cbot

def evC (R val : Nat) (w : Nat) : CForm → Bool
  | .ca n => (val >>> (3 * n + w)) &&& 1 == 1
  | .cor_ a b => evC R val w a || evC R val w b
  | .cdiff a b =>
      [0, 1, 2].any fun w' =>
        relAt R w w' && evC R val w' a && !evC R val w' b
  | .cbot => false

def cseq (a b : CForm) : Bool :=
  allPreords.all fun R =>
    (List.range 64).all fun val =>
      [0, 1, 2].all fun w => !evC R val w a || evC R val w b

/-- 电一：C ⊢ C∖⊥。 -/
example : cseq (.ca 0) (.cdiff (.ca 0) .cbot) = true := by decide

/-- 电二：C∖D ⊬ C。 -/
example : cseq (.cdiff (.ca 0) (.ca 1)) (.ca 0) = false := by decide

/-- 电三：分配律。 -/
example : cseq (.cdiff (.ca 0) (.cor_ (.ca 1) (.ca 2)))
                (.cor_ (.cdiff (.ca 0) (.ca 1)) (.cdiff (.ca 0) (.ca 2)))
  = true := by decide

end Ex40
