/- ex39_linear —— 线性逻辑的自然演绎（Lean 4 版）
   与 ex39_linear.v 同构：ILL {⊗,−∘,&,!} 的资源纪律证明搜索器。
   语境=多重集；⊗I 分裂（位掩码枚举）、−∘I 恰耗一束、&I 同一语境
   用两次（加性）、!I 提升、!E 三口（降 bang/收缩预算/弱化）。
   电池：可导七件 + 线性反例三件（A⊬A⊗A、A,B⊬A−∘B 资源不能闲置、
   A⊬B−∘A 即 K 公理失效）+ !A⊢!B−∘!A 对照。 -/

namespace Ex39

inductive Lf where
  | la (n : Nat)
  | ltens (a b : Lf)     -- A ⊗ B
  | llolli (a b : Lf)    -- A −∘ B
  | lwith (a b : Lf)     -- A & B
  | lbang (a : Lf)       -- ! A

def lfEq : Lf → Lf → Bool
  | .la n, .la m => n == m
  | .ltens x1 y1, .ltens x2 y2 => lfEq x1 x2 && lfEq y1 y2
  | .llolli x1 y1, .llolli x2 y2 => lfEq x1 x2 && lfEq y1 y2
  | .lwith x1 y1, .lwith x2 y2 => lfEq x1 x2 && lfEq y1 y2
  | .lbang x, .lbang y => lfEq x y
  | _, _ => false

def isBang : Lf → Bool
  | .lbang _ => true
  | _ => false

def rmv1 (a : Lf) : List Lf → List Lf
  | [] => []
  | x :: t => if lfEq x a then t else x :: rmv1 a t

def testb (m s : Nat) : Bool := (m >>> s) &&& 1 == 1

def filteri (G : List Lf) (i mask : Nat) : List Lf :=
  match G with
  | [] => []
  | x :: t =>
      if testb mask i then x :: filteri t (i + 1) mask
      else filteri t (i + 1) mask

def filteriDiff (G : List Lf) (i mask : Nat) : List Lf :=
  match G with
  | [] => []
  | x :: t =>
      if testb mask i then filteriDiff t (i + 1) mask
      else x :: filteriDiff t (i + 1) mask

def subOf (mask : Nat) (G : List Lf) : List Lf := filteri G 0 mask
def diffMask (mask : Nat) (G : List Lf) : List Lf := filteriDiff G 0 mask

/-- 资源纪律证明搜索器（单函数版：恒等/右规则/左规则全内联）。 -/
def der : Nat → Nat → List Lf → Lf → Bool
  | 0, _, _, _ => false
  | k + 1, budget, G, c =>
      -- 公理：语境恰为单目标
      (match G with
       | [x] => lfEq x c
       | _ => false)
      || (match c with                      -- 右规则
          | .ltens a b =>
              (List.range (2 ^ G.length)).any fun mask =>
                der k budget (subOf mask G) a
                  && der k budget (diffMask mask G) b
          | .llolli a b => der k budget (a :: G) b
          | .lwith a b => der k budget G a && der k budget G b
          | .lbang a => G.all isBang && der k budget G a
          | _ => false)
      || G.any fun x =>                     -- 左规则
          match x with
          | .ltens a b => der k budget (a :: b :: rmv1 x G) c
          | .llolli a b =>
              let rest := rmv1 x G
              (List.range (2 ^ rest.length)).any fun mask =>
                der k budget (subOf mask rest) a
                  && der k budget (b :: diffMask mask rest) c
          | .lwith a b =>
              der k budget (a :: rmv1 x G) c
                || der k budget (b :: rmv1 x G) c
          | .lbang a =>
              if budget == 0 then false
              else der k budget (a :: rmv1 x G) c
                || der k (budget - 1) (x :: x :: rmv1 x G) c
                || der k budget (rmv1 x G) c
          | _ => false

def derOK (G : List Lf) (c : Lf) : Bool := der 14 2 G c

/- ---------- 断言电池 ---------- -/

def A : Lf := .la 0
def B : Lf := .la 1

example : derOK [A] A = true := by decide

example : derOK [A, B] (.ltens A B) = true := by decide

example : derOK [.ltens A B] (.ltens B A) = true := by decide

example : derOK [.llolli A B, A] B = true := by decide

example : derOK [.lbang A] (.ltens A A) = true := by decide

/-- 加性复制：A ⊢ A & A——同一语境用两次。 -/
example : derOK [A] (.lwith A A) = true := by decide

example : derOK [.lwith A B] A = true := by decide

example : derOK [.lbang A] (.lbang A) = true := by decide

/-- 线性反例三件。 -/
example : derOK [A] (.ltens A A) = false := by decide

example : derOK [A, B] (.llolli A B) = false := by decide

example : derOK [A] (.llolli B A) = false := by decide

/-- 对照：!A ⊢ !B−∘!A（提升要求语境全 banged）。 -/
example : derOK [.lbang A] (.llolli (.lbang B) (.lbang A)) = true := by
  decide

end Ex39
