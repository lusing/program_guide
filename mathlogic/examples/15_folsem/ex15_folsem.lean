/- ex15 —— FOL 语义：一致性引理与理论样例（Lean 4 版） -/
namespace Ex15

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

def fv : Form → List Nat
  | atom _ t => fvTerm t
  | fimp a b => fv a ++ fv b
  | fneg a => fv a
  | fall y a => (fv a).filter (· ≠ y)

abbrev Fenv := Nat → Nat → Nat
abbrev Penv := Nat → Nat → Bool

def eterm (fe : Fenv) (e : Nat → Nat) : Term → Nat
  | tvar x => e x
  | fapp f t => fe f (eterm fe e t)

def eupd (e : Nat → Nat) (x v : Nat) : Nat → Nat :=
  fun m => if m == x then v else e m

def eform (fe : Fenv) (pe : Penv) (e : Nat → Nat) : Form → Prop
  | atom p t => pe p (eterm fe e t)
  | fimp a b => eform fe pe e a → eform fe pe e b
  | fneg a => ¬ eform fe pe e a
  | fall y a => ∀ v : Nat, eform fe pe (eupd e y v) a

theorem eupdEq (e : Nat → Nat) (x v : Nat) : eupd e x v x = v := by
  simp [eupd]

theorem eupdOther (e : Nat → Nat) (x v m : Nat) (h : m ≠ x) :
    eupd e x v m = e m := by
  simp [eupd, h]

/-- 项层一致性 -/
theorem etermCoincidence (fe : Fenv) (t : Term) (e1 e2 : Nat → Nat)
    (h : ∀ m ∈ fvTerm t, e1 m = e2 m) :
    eterm fe e1 t = eterm fe e2 t := by
  induction t with
  | tvar x => exact h x (by simp [fvTerm])
  | fapp f t' ih =>
      simp only [eterm]
      rw [ih (fun m hm => h m (by simpa [fvTerm] using hm))]

/-- 旗舰：满足一致性（EFT III.5） -/
theorem eformCoincidence (fe : Fenv) (pe : Penv) :
    ∀ f : Form, ∀ e1 e2 : Nat → Nat,
      (∀ m ∈ fv f, e1 m = e2 m) →
      (eform fe pe e1 f ↔ eform fe pe e2 f) := by
  intro f
  induction f with
  | atom p t =>
      intro e1 e2 h
      simp only [eform]
      rw [etermCoincidence fe t e1 e2
            (fun m hm => h m (by simpa [fv] using hm))]
  | fimp a b iha ihb =>
      intro e1 e2 h
      constructor
      · intro Hab H1
        exact (ihb e1 e2 (fun m hm => h m (by simp [fv]; exact Or.inr hm))).mp
                (Hab ((iha e1 e2 (fun m hm => h m (by simp [fv]; exact Or.inl hm))).mpr H1))
      · intro Hab H1
        exact (ihb e1 e2 (fun m hm => h m (by simp [fv]; exact Or.inr hm))).mpr
                (Hab ((iha e1 e2 (fun m hm => h m (by simp [fv]; exact Or.inl hm))).mp H1))
  | fneg a iha =>
      intro e1 e2 h
      simp only [eform]
      constructor
      · intro H H1; exact H ((iha e1 e2 h).mpr H1)
      · intro H H1; exact H ((iha e1 e2 h).mp H1)
  | fall y a iha =>
      intro e1 e2 h
      simp only [eform]
      have key : ∀ v m, m ∈ fv a → eupd e1 y v m = eupd e2 y v m := by
        intro v m hm
        by_cases hmy : m = y
        · subst hmy; simp [eupd]
        · rw [eupdOther e1 y v m hmy, eupdOther e2 y v m hmy]
          apply h m
          simp only [fv, List.mem_filter, hm]
          simp [hmy]
      constructor
      · intro H v
        exact (iha (eupd e1 y v) (eupd e2 y v) (fun m hm => key v m hm)).mp (H v)
      · intro H v
        exact (iha (eupd e2 y v) (eupd e1 y v)
                (fun m hm => (key v m hm).symm)).mp (H v)

/- ---------- 理论样例：严格偏序 ---------- -/

/-- 严格偏序公理 -/
structure StrictOrder (R : Nat → Nat → Prop) : Prop where
  irrefl : ∀ x, ¬ R x x
  trans : ∀ {x y z}, R x y → R y z → R x z

/-- 理论内推理：无 2-环 -/
theorem noCycle2 {R} (so : StrictOrder R) {x y} :
    ¬ (R x y ∧ R y x) := by
  intro ⟨h1, h2⟩
  exact so.irrefl x (so.trans h1 h2)

/-- 「小于」实例 -/
theorem ltNoCycle2 {x y : Nat} : ¬ (x < y ∧ y < x) :=
  noCycle2 ⟨fun _ h => Nat.lt_irrefl _ h, fun h1 h2 => Nat.lt_trans h1 h2⟩

#print axioms eformCoincidence

/- 坑位速记（Lean 侧）：
   - fv (fall y a) 用 filter (· ≠ y) 而非 remove——
     List.mem_filter 配 by_cases hmy 分派；
   - eupd 的 m = y 分支 simp [eupd] 直接把两个 if 同时消掉；
   - 匿名构造子 ⟨irrefl, trans⟩ 一行实例化结构。 -/

end Ex15
