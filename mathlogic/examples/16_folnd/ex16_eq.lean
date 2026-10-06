/- ex16_eq —— 等式的自然演绎规则 =i / =e（Lean 4 深嵌入版，H&R §2.3.1）

   与 Coq 版同构：form+FEq、nd 演算（=i 公理 / =e 闭项侧条件）、
   对称/传递/谓词等量代换三派生件。侧条件纪律与 15 章
   subst_all_eval 的 closedT 形态一致。
   经验复用（10 章坑）：可计算定义用 Nat.beq 直连，不经 == 实例。 -/

namespace Ex16Eq

inductive Term where
  | tvar (n : Nat) : Term
  | fapp (f : Nat) (t : Term) : Term

inductive Form where
  | atom (p : Nat) (t : Term) : Form
  | fimp (a b : Form) : Form
  | fneg (a : Form) : Form
  | fall (x : Nat) (a : Form) : Form
  | feq (t1 t2 : Term) : Form

open Term Form

theorem beq_refl (n : Nat) : Nat.beq n n = true := by
  induction n with
  | zero => rfl
  | succ n' ih => exact ih

def fvTerm : Term → List Nat
  | tvar n => [n]
  | fapp _ t' => fvTerm t'

def fv : Form → List Nat
  | atom _ t => fvTerm t
  | fimp a b => fv a ++ fv b
  | fneg a => fv a
  | fall y a => (fv a).eraseDups.erase y
  | feq t1 t2 => fvTerm t1 ++ fvTerm t2

def substTerm (t : Term) (x : Nat) (s : Term) : Term :=
  match t with
  | tvar y => if Nat.beq y x then s else tvar y
  | fapp f t' => fapp f (substTerm t' x s)

def substF : Form → Nat → Term → Form
  | atom p t, x, s => atom p (substTerm t x s)
  | fimp a b, x, s => fimp (substF a x s) (substF b x s)
  | fneg a, x, s => fneg (substF a x s)
  | fall y a, x, s => if Nat.beq y x then fall y a else fall y (substF a x s)
  | feq t1 t2, x, s => feq (substTerm t1 x s) (substTerm t2 x s)

/-- nd 演算：hyp / →i / →e / ∀i / ∀e / =i / =e -/
inductive Nd : List Form → Form → Prop
  | ndHyp {G : List Form} {f : Form} (h : f ∈ G) : Nd G f
  | ndImpI {G : List Form} {f g : Form} (d : Nd (f :: G) g) : Nd G (fimp f g)
  | ndImpE {G : List Form} {f g : Form}
      (d1 : Nd G (fimp f g)) (d2 : Nd G f) : Nd G g
  | ndAllI {G : List Form} {x : Nat} {a : Form}
      (hfresh : x ∉ G.flatMap fv)
      (d : ∀ v : Nat, Nd G (substF a x (tvar v))) :
      Nd G (fall x a)
  | ndAllE {G : List Form} {x : Nat} {a : Form} {t : Term}
      (d : Nd G (fall x a)) : Nd G (substF a x t)
  | ndEqI {G : List Form} {t : Term} : Nd G (feq t t)
  | ndEqE {G : List Form} {t1 t2 : Term} {x : Nat} {f : Form}
      (hc1 : fvTerm t1 = []) (hc2 : fvTerm t2 = [])
      (he : Nd G (feq t1 t2)) (hp : Nd G (substF f x t1)) :
      Nd G (substF f x t2)

/-- 闭项不怕代入 -/
theorem substTerm_closed_id (t : Term) (x : Nat) (s : Term)
    (hc : fvTerm t = []) : substTerm t x s = t := by
  cases t with
  | tvar n => simp only [fvTerm] at hc; exact absurd hc (by simp)
  | fapp f t' =>
    simp only [substTerm, fvTerm] at *
    rw [substTerm_closed_id t' x s hc]

theorem substTerm_self (x : Nat) (s : Term) : substTerm (tvar x) x s = s := by
  simp only [substTerm]
  rw [if_pos (beq_refl x)]

/-- 派生件一：对称（H&R 式 2.6） -/
theorem eqSymNd {G : List Form} {t1 t2 : Term}
    (h : Nd G (feq t1 t2)) (hc1 : fvTerm t1 = []) (hc2 : fvTerm t2 = []) :
    Nd G (feq t2 t1) := by
  have hpre : Nd G (substF (feq (tvar 0) t1) 0 t1) := by
    simp only [substF, substTerm]
    rw [if_pos (by rfl), substTerm_closed_id t1 0 t1 hc1]
    exact Nd.ndEqI
  have hconcl : substF (feq (tvar 0) t1) 0 t2 = feq t2 t1 := by
    simp only [substF, substTerm]
    rw [if_pos (by rfl), substTerm_closed_id t1 0 t2 hc1]
  rw [← hconcl]
  exact Nd.ndEqE (t1 := t1) (t2 := t2) (x := 0) (f := feq (tvar 0) t1)
    hc1 hc2 h hpre

/-- 派生件二：传递（H&R 式 2.7） -/
theorem eqTransNd {G : List Form} {t1 t2 t3 : Term}
    (h12 : Nd G (feq t1 t2)) (h23 : Nd G (feq t2 t3))
    (hc1 : fvTerm t1 = []) (hc2 : fvTerm t2 = []) (hc3 : fvTerm t3 = []) :
    Nd G (feq t1 t3) := by
  have hpre : Nd G (substF (feq t1 (tvar 0)) 0 t2) := by
    simp only [substF, substTerm]
    rw [if_pos (by rfl), substTerm_closed_id t1 0 t2 hc1]
    exact h12
  have hconcl : substF (feq t1 (tvar 0)) 0 t3 = feq t1 t3 := by
    simp only [substF, substTerm]
    rw [if_pos (by rfl), substTerm_closed_id t1 0 t3 hc1]
  rw [← hconcl]
  exact Nd.ndEqE (t1 := t2) (t2 := t3) (x := 0) (f := feq t1 (tvar 0))
    hc2 hc3 h23 hpre

/-- 派生件三：谓词等量代换 -/
theorem eqCongAtom {G : List Form} {p : Nat} {t1 t2 : Term}
    (hp : Nd G (atom p t1)) (heq : Nd G (feq t1 t2))
    (hc1 : fvTerm t1 = []) (hc2 : fvTerm t2 = []) :
    Nd G (atom p t2) := by
  have hpre : Nd G (substF (atom p (tvar 0)) 0 t1) := by
    simp only [substF, substTerm]
    rw [if_pos (by rfl)]
    exact hp
  have hconcl : substF (atom p (tvar 0)) 0 t2 = atom p t2 := by
    simp only [substF, substTerm]
    rw [if_pos (by rfl)]
  rw [← hconcl]
  exact Nd.ndEqE (t1 := t1) (t2 := t2) (x := 0) (f := atom p (tvar 0))
    hc1 hc2 heq hpre

end Ex16Eq
