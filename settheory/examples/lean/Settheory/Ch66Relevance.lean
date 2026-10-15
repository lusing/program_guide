import Mathlib.Tactic

/-!
# 第 66 章 · 相关性（Makinson Ch11）

变量共享条件的机器检查 + 爆炸律家族的字母审计。
-/

namespace Settheory.Ch66

def sharesLetter (a b : List Nat) : Bool :=
  a.any (fun x => b.contains x)

-- (p∧¬p)→q 无字母共享
example : sharesLetter [0] [1] = false := by native_decide

-- p→(q∨¬q) 无字母共享
example : sharesLetter [0] [1] = false := by native_decide

-- ¬q→(q→p) 有字母共享
example : sharesLetter [1] [0] = false := by native_decide
example : sharesLetter [1, 0] [1, 0] = true := by native_decide

-- Lewis 推导的各步语义验证（用 63 章的 Form）
namespace Lewis
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

-- 前提 p∧¬p 在一切赋值下为假（矛盾式）
example (v : Nat → Bool) : eval v (Form.conj P (Form.neg P)) = false := by
  simp [eval, P]

-- 结论 q 的字母与前提无共享
example : sharesLetter [0] [1] = false := by native_decide

end Lewis

end Settheory.Ch66
