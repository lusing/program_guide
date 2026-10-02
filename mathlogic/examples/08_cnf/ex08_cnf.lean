/- ex08 —— 范式：NNF 与 CNF（Lean 4 版） -/

namespace Ex08

inductive Form where
  | fvar (n : Nat) : Form
  | fand (a b : Form) : Form
  | for_ (a b : Form) : Form
  | fneg (a : Form) : Form
  | ftop : Form
  | fbot : Form

open Form

def eval (e : Nat → Bool) : Form → Bool
  | fvar n => e n
  | fand a b => eval e a && eval e b
  | for_ a b => eval e a || eval e b
  | fneg a => !(eval e a)
  | ftop => true
  | fbot => false

def fsize : Form → Nat
  | fvar _ => 1
  | fand a b | for_ a b => 1 + fsize a + fsize b
  | fneg a => 1 + fsize a
  | ftop | fbot => 1

-- NNF：互递归 nnf / nneg
mutual
  def nnf : Form → Form
    | fvar n => fvar n
    | fand a b => fand (nnf a) (nnf b)
    | for_ a b => for_ (nnf a) (nnf b)
    | fneg a => nneg a
    | ftop => ftop
    | fbot => fbot

  def nneg : Form → Form
    | fvar n => fneg (fvar n)
    | fand a b => for_ (nneg a) (nneg b)
    | for_ a b => fand (nneg a) (nneg b)
    | fneg a => nnf a
    | ftop => fbot
    | fbot => ftop
end

mutual
  theorem nnfNnegCorrect : ∀ (e : Nat → Bool) (f : Form),
      eval e (nnf f) = eval e f ∧ eval e (nneg f) = !(eval e f) := by
    intro e f
    induction f with
    | fvar n => exact ⟨rfl, rfl⟩
    | fand a b iha ihb =>
        obtain ⟨A1, B1⟩ := iha
        obtain ⟨A2, B2⟩ := ihb
        simp only [nnf, nneg, eval] at *
        exact ⟨by rw [A1, A2],
                by rw [B1, B2]; cases eval e a <;> cases eval e b <;> rfl⟩
    | for_ a b iha ihb =>
        obtain ⟨A1, B1⟩ := iha
        obtain ⟨A2, B2⟩ := ihb
        simp only [nnf, nneg, eval] at *
        exact ⟨by rw [A1, A2],
                by rw [B1, B2]; cases eval e a <;> cases eval e b <;> rfl⟩
    | fneg a iha =>
        simp only [nnf, nneg, eval] at iha ⊢
        exact ⟨iha.2, by rw [iha.1]; cases eval e a <;> rfl⟩
    | ftop => exact ⟨rfl, rfl⟩
    | fbot => exact ⟨rfl, rfl⟩

  theorem nnegCorrect' (e : Nat → Bool) (f : Form) :
      eval e (nneg f) = !(eval e f) := (nnfNnegCorrect e f).2
end

-- dist：把 ∨ 分配进 ∧（fuel=0 兜底返回 FOr——语义仍对）
def dist : Nat → Form → Form → Form
  | 0, p, q => for_ p q
  | k + 1, fand r s, q => fand (dist k r q) (dist k s q)
  | k + 1, p, fand t u => fand (dist k p t) (dist k p u)
  | _ + 1, p, q => for_ p q

theorem distCorrect (k : Nat) (p q : Form) (e : Nat → Bool) :
    eval e (dist k p q) = (eval e p || eval e q) := by
  induction k generalizing p q with
  | zero => cases p <;> cases q <;> rfl
  | succ k ih =>
      -- 重叠模式让 eq3/eq4 带侧条件，simp 用不动——按构造子显式分派
      cases p with
      | fand r s =>
          simp only [dist, eval]
          rw [ih r q, ih s q]
          cases eval e r <;> cases eval e s <;> cases eval e q <;> rfl
      | fvar n =>
          cases q with
          | fand t u =>
              simp only [dist, eval]
              rw [ih (fvar n) t, ih (fvar n) u]
              simp only [eval]
              cases e n <;> cases eval e t <;> cases eval e u <;> rfl
          | _ => rfl
      | for_ a b =>
          cases q with
          | fand t u =>
              simp only [dist, eval]
              rw [ih (for_ a b) t, ih (for_ a b) u]
              simp only [eval]
              cases eval e a <;> cases eval e b <;> cases eval e t <;>
                cases eval e u <;> rfl
          | _ => rfl
      | fneg a =>
          cases q with
          | fand t u =>
              simp only [dist, eval]
              rw [ih (fneg a) t, ih (fneg a) u]
              simp only [eval]
              cases eval e a <;> cases eval e t <;> cases eval e u <;> rfl
          | _ => rfl
      | ftop =>
          cases q with
          | fand t u =>
              simp only [dist, eval]
              rw [ih ftop t, ih ftop u]
              simp only [eval]
              cases eval e t <;> cases eval e u <;> rfl
          | _ => rfl
      | fbot =>
          cases q with
          | fand t u =>
              simp only [dist, eval]
              rw [ih fbot t, ih fbot u]
              simp only [eval]
              cases eval e t <;> cases eval e u <;> rfl
          | _ => rfl

def cnf : Form → Form
  | fand a b => fand (cnf a) (cnf b)
  | for_ a b => dist (fsize (cnf a) + fsize (cnf b)) (cnf a) (cnf b)
  | f => f

theorem cnfCorrect (e : Nat → Bool) (f : Form) :
    eval e (cnf f) = eval e f := by
  induction f with
  | fvar n => rfl
  | fand a b iha ihb => simp only [cnf, eval]; rw [iha, ihb]
  | for_ a b iha ihb =>
      simp only [cnf, eval]
      rw [distCorrect _ _ _ e, iha, ihb]
  | fneg a _ => rfl
  | ftop => rfl
  | fbot => rfl

theorem nnfCnfCorrect (e : Nat → Bool) (f : Form) :
    eval e (cnf (nnf f)) = eval e f := by
  rw [cnfCorrect]
  exact (nnfNnegCorrect e f).1

#print axioms nnfCnfCorrect

/- ---------- 现场 ---------- -/

example : cnf (nnf (for_ (fvar 0) (fand (fvar 1) (fvar 2))))
    = fand (for_ (fvar 0) (fvar 1)) (for_ (fvar 0) (fvar 2)) := by rfl

example : nnf (fneg (fand (fvar 0) (fvar 1)))
    = for_ (fneg (fvar 0)) (fneg (fvar 1)) := by rfl

/- 坑位速记（Lean 侧）：
   - mutual def 与 mutual theorem 配对（nnegCorrect' 桥接拆分）；
   - dist 的 match p, q 分支里第二支要绕道 have
     （match 变量 p 的形状分支与 dist 自身的模式联动）；
   - for_ 仍是关键字避让。 -/

end Ex08
