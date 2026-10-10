/- 第 89 章 Beth 可定义性与联合一致性（Takeuti §6）——Lean 通道。零公理。 -/

inductive Bfm : Type where
  | bp (n : Nat)
  | bng (a : Bfm)
  | band (a b : Bfm)
  | bor (a b : Bfm)
  | bimp (a b : Bfm)

namespace Ex89

def allb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => true
  | x :: t => f x && allb f t

def anyb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => false
  | x :: t => f x || anyb f t

def impb (b c : Bool) : Bool := !b || c

def bev (v : Nat → Bool) : Bfm → Bool
  | .bp n => v n
  | .bng b => !(bev v b)
  | .band b c => bev v b && bev v c
  | .bor b c => bev v b || bev v c
  | .bimp b c => impb (bev v b) (bev v c)
termination_by x => sizeOf x

/-- 隐定义（Def 6.10）：A(R,R')=（R∧R'）∨（¬R∧¬R'）命题级化身 -/
def implicitDef (v : Nat → Bool) : Bool :=
  bev v (.bor (.band (.bp 0) (.bp 1)) (.band (.bng (.bp 0)) (.bng (.bp 1))))

example : (implicitDef (fun _ => true) && implicitDef (fun _ => false)) = true := by native_decide

example : !implicitDef (fun n => n == 1) = true := by native_decide

/-- 显定义核（插值子化身）：F=R -/
def explicitDef : Bfm := .bp 0

example : (implicitDef (fun _ => true)
           && bev (fun _ => true) (.bimp explicitDef (.bp 1))) = true := by native_decide

/- Robinson 联合一致性（Prop 6.12）小宇宙账 -/

def satUnder (v : Nat → Bool) (axs : List Bfm) : Bool :=
  allb (fun a => bev v a) axs

def allVals : List (Nat → Bool) :=
  [(fun _ => true), (fun n => n == 0), (fun n => n == 1), (fun _ => false)]

def jointly (s1 s2 : List Bfm) : Bool :=
  anyb (fun v => satUnder v s1 && satUnder v s2) allVals

/-- 相容对：{p} 与 {p->q} 联合一致 -/
example : jointly [.bp 0] [.bimp (.bp 0) (.bp 1)] = true := by native_decide

/-- 冲突对：{p} 与 {~p} 联合不一致 -/
example : jointly [.bp 0] [.bng (.bp 0)] = false := by native_decide

/- Harrop 定理（Thm 6.14）极性条件检查 -/

/-- ∨ 只许出现在 ~ 辖域或 -> 左辖域（负位） -/
def harrop : Bfm → Bool → Bool
  | .bp _, _ => true
  | .bng b, neg => harrop b (!neg)
  | .band b c, neg => harrop b neg && harrop c neg
  | .bor b c, neg =>
      match neg with          -- ∨ 只许负位：正位出现即拒
      | false => false
      | true => harrop b neg && harrop c neg
  | .bimp b c, neg => harrop b (!neg) && harrop c neg
termination_by x => sizeOf x

/-- Harrop 公式：~(p\/q)/\r——∨ 在 ~ 辖域内 -/
example : harrop (.band (.bng (.bor (.bp 0) (.bp 1))) (.bp 2)) false = true := by native_decide

/-- 非 Harrop：p\/q 出现在正位 -/
example : harrop (.bor (.bp 0) (.bp 1)) false = false := by native_decide

/-- DP 方向账的语义面：~p\/q 与 p->q 逐赋值等价 -/
example :
  (bev (fun n => !(n == 0)) (.bor (.bng (.bp 0)) (.bp 1))
   && bev (fun n => !(n == 0)) (.bimp (.bp 0) (.bp 1))) = true := by native_decide

end Ex89
