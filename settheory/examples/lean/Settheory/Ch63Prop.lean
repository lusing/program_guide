import Mathlib.Tactic

/-!
# 第 63 章 · 命题逻辑（Makinson Ch8）

自建命题公式归纳类型 + 赋值延拓 + 永真蕴含九条的语义验证。
-/

namespace Settheory.Ch63

inductive Form where
  | var : Nat → Form
  | neg : Form → Form
  | conj : Form → Form → Form
  | disj : Form → Form → Form

def eval : (Nat → Bool) → Form → Bool
  | v, .var p => v p
  | v, .neg a => !eval v a
  | v, .conj a b => eval v a && eval v b
  | v, .disj a b => eval v a || eval v b

def P : Form := .var 0
def Q : Form := .var 1

def arr (a b : Form) : Form := .disj (.neg a) b

def ev2 (b1 b2 : Bool) (f : Form) : Bool :=
  eval (fun n => if n == 0 then b1 else if n == 1 then b2 else false) f

def taut2 (f : Form) : Bool :=
  ev2 true true f && ev2 true false f && ev2 false true f && ev2 false false f

theorem mp_sem : taut2 (arr (Form.conj P (arr P Q)) Q) = true := by
  native_decide

theorem mt_sem : taut2 (arr (Form.conj (arr P Q) (Form.neg Q)) (Form.neg P)) = true := by
  native_decide

theorem ds_sem : taut2 (arr (Form.conj (Form.disj P Q) (Form.neg P)) Q) = true := by
  native_decide

theorem expl_right : taut2 (arr (Form.conj P (Form.neg P)) Q) = true := by
  native_decide

theorem expl_left : taut2 (arr P (Form.disj Q (Form.neg Q))) = true := by
  native_decide

theorem demorgan1 : taut2 (arr (Form.neg (Form.conj P Q)) (Form.disj (Form.neg P) (Form.neg Q))) = true := by
  native_decide

theorem demorgan2 : taut2 (arr (Form.disj (Form.neg P) (Form.neg Q)) (Form.neg (Form.conj P Q))) = true := by
  native_decide

theorem not_taut_witness : taut2 (arr (arr P Q) Q) = false := by
  native_decide

end Settheory.Ch63
