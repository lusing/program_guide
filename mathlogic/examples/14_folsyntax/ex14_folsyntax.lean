/- ex14 —— FOL 语法与代入（Lean 4 版） -/

namespace Ex14

inductive Term where
  | tvar (x : Nat) : Term
  | fapp (f : Nat) (t : Term) : Term

inductive Form where
  | atom (p : Nat) (t : Term) : Form
  | fimp (a b : Form) : Form
  | fneg (a : Form) : Form
  | fall (y : Nat) (a : Form) : Form

open Term Form

def fvTerm : Term → List Nat
  | tvar x => [x]
  | fapp _ t => fvTerm t

def substTerm (t : Term) (x : Nat) (s : Term) : Term :=
  match t with
  | tvar y => if y == x then s else tvar y
  | fapp f t' => fapp f (substTerm t' x s)

def substForm : Form → Nat → Term → Form
  | atom p t, x, s => atom p (substTerm t x s)
  | fimp a b, x, s => fimp (substForm a x s) (substForm b x s)
  | fneg a, x, s => fneg (substForm a x s)
  | fall y a, x, s => if y == x then fall y a else fall y (substForm a x s)

abbrev Fenv := Nat → Nat → Nat

def eterm (fe : Fenv) (e : Nat → Nat) : Term → Nat
  | tvar x => e x
  | fapp f t => fe f (eterm fe e t)

def eupd (e : Nat → Nat) (x v : Nat) : Nat → Nat :=
  fun m => if m == x then v else e m

/-- 旗舰：项代入与语义代入交换 -/
theorem substTermEval (fe : Fenv) (t : Term) (e : Nat → Nat) (x : Nat) (s : Term) :
    eterm fe e (substTerm t x s) = eterm fe (eupd e x (eterm fe e s)) t := by
  induction t with
  | tvar z =>
      by_cases hz : z = x
      · subst z; simp [substTerm, eterm, eupd]
      · simp [substTerm, eterm, eupd, hz]
  | fapp f t' ih =>
      simp [substTerm, eterm] at *; rw [ih]

/-- capture 规则现场：x 被束缚时代入不动 -/
example : substForm (fall 3 (atom 0 (tvar 3))) 3 (tvar 7)
    = fall 3 (atom 0 (tvar 3)) := by rfl

/- 坑位速记（Lean 侧）：
   - 陈述的环境级形态：eterm fe (eupd e x v) t——
     Coq 版曾把 RHS 写成 eupd e x v (eterm fe e t)（对 eupd 求函数值），
     被类型错误当场抓获——变元号与值域同型（nat）不挡这种混淆；
   - fapp 情况 simp at * + rw [ih] 两步收。 -/

end Ex14
