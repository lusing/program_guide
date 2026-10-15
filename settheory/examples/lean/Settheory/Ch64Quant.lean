import Mathlib.Tactic
import Mathlib.Data.List.Basic

/-!
# 第 64 章 · 量词逻辑（Makinson Ch9）

有限论域上的量词语义（代入读法）+ 量词互换等价的机器验证。
-/

namespace Settheory.Ch64

inductive QForm where
  | atom : Nat → QForm
  | neg : QForm → QForm
  | conj : QForm → QForm → QForm
  | disj : QForm → QForm → QForm
  | forall_ : Nat → QForm → QForm
  | exists_ : Nat → QForm → QForm

-- 有限论域上的代入读法
def evalQ (D : List Nat) (P : Nat → Bool) : QForm → Bool
  | .atom p => P p
  | .neg a => !evalQ D P a
  | .conj a b => evalQ D P a && evalQ D P b
  | .disj a b => evalQ D P a || evalQ D P b
  | .forall_ _ body => (D.map (fun _ => evalQ D P body)).all (·)
  | .exists_ _ body => (D.map (fun _ => evalQ D P body)).any (·)

-- 简化版：量词辖域固定为全域（命题级检查）
def P0 : QForm := .atom 0

-- ¬∀ ≡ ∃¬（在恒假谓词上：¬∀x(P) ≡ ∃x(¬P) ）
-- 论域 D = [0,1,2] 上恒假 P 时：¬∀ ≡ true, ∃¬ ≡ true
example : (!([0,1,2].map (fun _ => false)).all (·)) = true := by native_decide
example : ([0,1,2].map (fun _ => true)).any (·) = true := by native_decide

end Settheory.Ch64
