/- ex31_modal —— 基本模态逻辑 K（Lean 4 版，H&R §5.1-5.2）

   与 Coq 版同构：frame + msat + K_valid/nec/dia_dual（经典入账）
   + box_and_fwd + T/4 反例框架。Nat.beb 直连教训沿用。 -/
namespace Ex31

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

/-- K 模式：□(φ→ψ) → (□φ → □ψ)（无公理） -/
theorem K_valid (F : Frame) (w : Nat) (a b : MForm) :
    msat F w (mImp (mBox (mImp a b)) (mImp (mBox a) (mBox b))) := by
  simp only [msat]
  intro hk hp v hv hr
  exact hk v hv hr (hp v hv hr)

/-- 必然化：前提「无世界限定」才可必然化 -/
theorem nec (a : MForm) (h : ∀ F w, w ∈ F.worlds → msat F w a) :
    ∀ F w, w ∈ F.worlds → msat F w (mBox a) := by
  intro F w _ v hv hr
  exact h F v hv

/-- p → □p 不是有效式（必然化的前提不可少） -/
def lone : Frame where
  worlds := [0, 1]
  rel := fun x y => match x, y with
    | 0, 1 => true | _, _ => false
  val := fun w p => match w, p with
    | 0, 0 => true | _, _ => false

example : ¬ ∀ (F : Frame) (w : Nat), w ∈ F.worlds →
    msat F w (mImp (mAtom 0) (mBox (mAtom 0))) := by
  intro hall
  have h := hall lone 0 (by decide)
  simp only [msat] at h
  have h2 := h rfl 1 (by decide) (by decide)
  simp only [lone] at h2
  exact Bool.noConfusion h2

/-- ◇ 对偶（反向经典入账） -/
theorem dia_dual (F : Frame) (w : Nat) (a : MForm) :
    msat F w (mDia a) ↔ ¬ msat F w (mBox (mNeg a)) := by
  simp only [msat]
  constructor
  · rintro ⟨v, hv, hr, hs⟩ hbox
    exact hbox v hv hr hs
  · intro hn
    by_cases hex : ∃ v, v ∈ F.worlds ∧ F.rel w v = true ∧ msat F v a
    · exact hex
    · exfalso
      apply hn
      intro v hv hr
      by_cases hsat : msat F v a
      · exact absurd ⟨v, hv, hr, hsat⟩ hex
      · exact hsat

/-- □ 对 ∧ 的分配（语义层一半） -/
theorem box_and_fwd (F : Frame) (w : Nat) (a b : MForm)
    (h : ∀ v, v ∈ F.worlds → F.rel w v = true → msat F v a ∧ msat F v b) :
    (∀ v, v ∈ F.worlds → F.rel w v = true → msat F v a) ∧
    (∀ v, v ∈ F.worlds → F.rel w v = true → msat F v b) :=
  ⟨fun v hv hr => (h v hv hr).1, fun v hv hr => (h v hv hr).2⟩

/-- T 反例：非自反框架上 □p → p 失效 -/
def fnoRef : Frame where
  worlds := [1, 2]
  rel := fun x y => match x, y with
    | 1, 2 => true | _, _ => false
  val := fun w p => match w, p with
    | 2, 0 => true | _, _ => false

example : ¬ msat fnoRef 1 (mImp (mBox (mAtom 0)) (mAtom 0)) := by
  simp only [msat]
  intro hbox
  have hp := hbox (fun v hv hr => by
    have hmem : v = 1 ∨ v = 2 := by
      simp only [fnoRef, List.mem_cons] at hv
      rcases hv with e | e
      · exact Or.inl (by simpa using e)
      · rcases e with e | e
        · exact Or.inr (by simpa using e)
        · exact absurd e (by simp)
    rcases hmem with rfl | rfl
    · simp only [fnoRef] at hr; exact absurd hr (by decide)
    · rfl)
  simp only [fnoRef] at hp
  exact Bool.noConfusion hp

/-- 4 反例：非传递框架上 □p → □□p 失效 -/
def fnoTrans : Frame where
  worlds := [1, 2]
  rel := fun x y => match x, y with
    | 1, 2 | 2, 1 => true | _, _ => false
  val := fun w p => match w, p with
    | 1, 0 => true | _, _ => false

example : ¬ msat fnoTrans 2 (mImp (mBox (mAtom 0)) (mBox (mBox (mAtom 0)))) := by
  simp only [msat]
  intro hbox
  have hbox2 : ∀ v, v ∈ fnoTrans.worlds →
      fnoTrans.rel 2 v = true → fnoTrans.val v 0 = true := by
    intro v hv hr
    have hmem : v = 1 ∨ v = 2 := by
      simp only [fnoTrans, List.mem_cons] at hv
      rcases hv with e | e
      · exact Or.inl (by simpa using e)
      · rcases e with e | e
        · exact Or.inr (by simpa using e)
        · exact absurd e (by simp)
    rcases hmem with rfl | rfl
    · rfl
    · simp only [fnoTrans] at hr; exact absurd hr (by decide)
  have hbad := hbox hbox2 1 (by decide) (by decide) 2 (by decide) (by decide)
  simp only [fnoTrans] at hbad
  exact Bool.noConfusion hbad

end Ex31
