/- ex18 —— 前束范式构件：量词穿越（Lean 4 版）
    论域 bool，二元量词——一致性引理承担侧条件。 -/
namespace Ex18

inductive PForm where
  | patom (p x : Nat) : PForm
  | pand (a b : PForm) : PForm
  | por (a b : PForm) : PForm
  | pneg (a : PForm) : PForm
  | pall (y : Nat) (a : PForm) : PForm

open PForm

abbrev PEnv := Nat → Nat → Bool

def eupdb (e : Nat → Bool) (y : Nat) (v : Bool) : Nat → Bool :=
  fun m => if m == y then v else e m

def peval (pe : PEnv) (e : Nat → Bool) : PForm → Prop
  | patom p x => pe p x = true
  | pand a b => peval pe e a ∧ peval pe e b
  | por a b => peval pe e a ∨ peval pe e b
  | pneg a => ¬ peval pe e a
  | pall y a => ∀ v : Bool, peval pe (eupdb e y v) a

def pfv : PForm → List Nat
  | patom _ x => [x]
  | pand a b => pfv a ++ pfv b
  | por a b => pfv a ++ pfv b
  | pneg a => pfv a
  | pall y a => (pfv a).filter (· ≠ y)

/-- 一致性引理（15 章配方的布尔版） -/
theorem pevalCoincidence (pe : PEnv) :
    ∀ f : PForm, ∀ e1 e2 : Nat → Bool,
      (∀ m ∈ pfv f, e1 m = e2 m) →
      (peval pe e1 f ↔ peval pe e2 f) := by
  intro f
  induction f with
  | patom p x =>
      intro e1 e2 _
      simp only [peval]
  | pand a b iha ihb =>
      intro e1 e2 h
      simp only [peval]
      constructor
      · intro hab
        exact ⟨(iha e1 e2 (fun m hm => h m (by simp [pfv]; exact Or.inl hm))).mp hab.1,
               (ihb e1 e2 (fun m hm => h m (by simp [pfv]; exact Or.inr hm))).mp hab.2⟩
      · intro hab
        exact ⟨(iha e1 e2 (fun m hm => h m (by simp [pfv]; exact Or.inl hm))).mpr hab.1,
               (ihb e1 e2 (fun m hm => h m (by simp [pfv]; exact Or.inr hm))).mpr hab.2⟩
  | por a b iha ihb =>
      intro e1 e2 h
      simp only [peval]
      constructor
      · intro hc
        cases hc with
        | inl ha => exact Or.inl ((iha e1 e2 (fun m hm => h m (by simp [pfv]; exact Or.inl hm))).mp ha)
        | inr hb => exact Or.inr ((ihb e1 e2 (fun m hm => h m (by simp [pfv]; exact Or.inr hm))).mp hb)
      · intro hc
        cases hc with
        | inl ha => exact Or.inl ((iha e1 e2 (fun m hm => h m (by simp [pfv]; exact Or.inl hm))).mpr ha)
        | inr hb => exact Or.inr ((ihb e1 e2 (fun m hm => h m (by simp [pfv]; exact Or.inr hm))).mpr hb)
  | pneg a iha =>
      intro e1 e2 h
      simp only [peval]
      constructor
      · intro hn ha; exact hn ((iha e1 e2 h).mpr ha)
      · intro hn ha; exact hn ((iha e1 e2 h).mp ha)
  | pall y a iha =>
      intro e1 e2 h
      simp only [peval]
      have key : ∀ v m, m ∈ pfv a → eupdb e1 y v m = eupdb e2 y v m := by
        intro v m hm
        by_cases hmy : m = y
        · subst hmy; simp [eupdb]
        · rw [eupdb, eupdb, if_neg (by simp [hmy]), if_neg (by simp [hmy])]
          exact h m (by simp [pfv, hm, hmy])
      constructor
      · intro H v; exact (iha _ _ (fun m hm => key v m hm)).mp (H v)
      · intro H v; exact (iha _ _ (fun m hm => (key v m hm).symm)).mp (H v)

/-- 侧条件工具：y ∉ pfv f 时换 y 处赋值不改变语义 -/
theorem pevalIrrelevantAt (pe : PEnv) (f : PForm) (y : Nat) (v : Bool)
    (e : Nat → Bool) (hy : y ∉ pfv f) :
    peval pe e f ↔ peval pe (eupdb e y v) f := by
  apply pevalCoincidence
  intro m hm
  by_cases hmy : m = y
  · exact absurd (hmy ▸ hm) hy
  · simp only [eupdb]
    have : (m == y) = false := by
      cases hb : (m == y) with
      | true => exact absurd (by simpa using hb) hmy
      | false => rfl
    rw [this]
    simp

/-- 旗舰四条（零公理） -/
theorem allAndSplit (pe : PEnv) (e : Nat → Bool) (y : Nat) (P Q : PForm)
    (h : peval pe e (pall y (pand P Q))) :
    peval pe e (pand (pall y P) (pall y Q)) :=
  ⟨fun v => (h v).1, fun v => (h v).2⟩

theorem allOrMono (pe : PEnv) (e : Nat → Bool) (y : Nat) (P Q : PForm)
    (h : peval pe e (pall y P)) :
    peval pe e (pall y (por P Q)) :=
  fun v => Or.inl (h v)

theorem allAndJoin (pe : PEnv) (e : Nat → Bool) (y : Nat) (P Q : PForm)
    (hy : y ∉ pfv Q)
    (h : peval pe e (pand (pall y P) Q)) :
    peval pe e (pall y (pand P Q)) :=
  fun v => ⟨h.1 v, (pevalIrrelevantAt pe Q y v e hy).mp h.2⟩

theorem allOrSwap (pe : PEnv) (e : Nat → Bool) (y : Nat) (P Q : PForm)
    (hy : y ∉ pfv Q)
    (h : peval pe e (por (pall y P) Q)) :
    peval pe e (pall y (por P Q)) :=
  fun v => h.elim (fun hp => Or.inl (hp v))
                (fun hq => Or.inr ((pevalIrrelevantAt pe Q y v e hy).mp hq))

end Ex18
