/- ex44_correspondence —— 对应理论（Lean 4 版，H&R §5.3.2-5.3.3）

   与 Coq 版同构：T/D/B/4/5 五条正向 + T 的逆（探针赋值）。 -/
namespace Ex44

inductive MForm where
  | mAtom (p : Nat) : MForm
  | mNeg (a : MForm) : MForm
  | mImp (a b : MForm) : MForm
  | mBox (a : MForm) : MForm
  | mDia (a : MForm) : MForm

open MForm

structure Frame where
  worlds : List Nat
  rel : Nat → Nat → Bool
  val : Nat → Nat → Bool

def msat (F : Frame) (w : Nat) : MForm → Prop
  | mAtom p => F.val w p = true
  | mNeg a => ¬ msat F w a
  | mImp a b => msat F w a → msat F w b
  | mBox a => ∀ v, v ∈ F.worlds → F.rel w v = true → msat F v a
  | mDia a => ∃ v, v ∈ F.worlds ∧ F.rel w v = true ∧ msat F v a

/-- T：自反 ⟹ □φ→φ -/
theorem T_valid (F : Frame)
    (hrefl : ∀ w, w ∈ F.worlds → F.rel w w = true)
    (w : Nat) (f : MForm) (hw : w ∈ F.worlds) :
    msat F w (mImp (mBox f) f) := by
  simp only [msat]
  intro hbox
  exact hbox w hw (hrefl w hw)

/-- D：serial ⟹ □φ→◇φ -/
theorem D_valid (F : Frame)
    (hser : ∀ w, w ∈ F.worlds → ∃ v, v ∈ F.worlds ∧ F.rel w v = true)
    (w : Nat) (f : MForm) (hw : w ∈ F.worlds) :
    msat F w (mImp (mBox f) (mDia f)) := by
  simp only [msat]
  intro hbox
  obtain ⟨v, hv, hr⟩ := hser w hw
  exact ⟨v, hv, hr, hbox v hv hr⟩

/-- B：对称 ⟹ φ→□◇φ -/
theorem B_valid (F : Frame)
    (hsym : ∀ x y, x ∈ F.worlds → y ∈ F.worlds →
      F.rel x y = true → F.rel y x = true)
    (w : Nat) (f : MForm) (hw : w ∈ F.worlds) :
    msat F w (mImp f (mBox (mDia f))) := by
  simp only [msat]
  intro hf v hv hr
  exact ⟨w, hw, hsym w v hw hv hr, hf⟩

/-- 4：传递 ⟹ □φ→□□φ -/
theorem four_valid (F : Frame)
    (htr : ∀ x y z, x ∈ F.worlds → y ∈ F.worlds → z ∈ F.worlds →
      F.rel x y = true → F.rel y z = true → F.rel x z = true)
    (w : Nat) (f : MForm) (hw : w ∈ F.worlds) :
    msat F w (mImp (mBox f) (mBox (mBox f))) := by
  simp only [msat]
  intro hbox v hv hr u hu hr2
  exact hbox u hu (htr w v u hw hv hu hr hr2)

/-- 5：欧性 ⟹ ◇φ→□◇φ -/
theorem five_valid (F : Frame)
    (heu : ∀ x y z, x ∈ F.worlds → y ∈ F.worlds → z ∈ F.worlds →
      F.rel x y = true → F.rel x z = true → F.rel y z = true)
    (w : Nat) (f : MForm) (hw : w ∈ F.worlds) :
    msat F w (mImp (mDia f) (mBox (mDia f))) := by
  simp only [msat]
  intro hdia u hu hru
  obtain ⟨v, hv, hrv, hfv⟩ := hdia
  exact ⟨v, hv, heu w u v hw hu hv hru hrv, hfv⟩

/-- T 的逆：公式对**一切赋值**有效 ⟹ 自反（探针赋值法） -/
theorem T_converse (ws : List Nat) (r : Nat → Nat → Bool)
    (hall : ∀ (V : Nat → Nat → Bool) (w : Nat) (f : MForm),
      w ∈ ws → msat (Frame.mk ws r V) w (mImp (mBox f) f)) :
    ∀ w, w ∈ ws → r w w = true := by
  intro w hw
  by_cases hne : r w w = true
  · exact hne
  exfalso
  -- 探针赋值 V₀：原子 0 恰在 w 假、别处真（Coq 版同款 match）
  have hall' := hall
    (fun x p => match Nat.beq x w, Nat.beq p 0 with
                | true, true => false
                | _, _ => true) w (mAtom 0) hw
  simp only [msat] at hall'
  have hbox : ∀ v, v ∈ ws → r w v = true →
      msat (Frame.mk ws r (fun x p => match Nat.beq x w, Nat.beq p 0 with
                | true, true => false
                | _, _ => true)) v (mAtom 0) := by
    intro v hv hr
    have hvw : v ≠ w := by
      intro heq; subst heq; exact hne hr
    have hbw : Nat.beq v w = false := by
      cases hb : Nat.beq v w with
      | true => exact absurd (Nat.beq_eq ▸ hb) hvw
      | false => rfl
    show (match Nat.beq v w, Nat.beq 0 0 with
          | true, true => false | _, _ => true) = true
    rw [hbw]
  have hp := hall' hbox
  rw [Nat.beq_refl w] at hp
  exact Bool.noConfusion hp

end Ex44
