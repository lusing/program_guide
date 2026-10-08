
theorem sweep_inv {cs : List Horn} {m : List Nat} {v : Nat → Bool}
    (hsat : allsat v cs) (hm : ∀ n ∈ m, v n = true) :
    (∀ n ∈ (sweep cs m).1, v n = true) ∧ ((sweep cs m).2 = true → False) := by
  induction cs generalizing m with
  | nil =>
    exact ⟨fun n hn => hm n hn, fun hf => Bool.noConfusion hf⟩
  | cons c cs' ih =>
    have hsat' : allsat v cs' := fun c0 hc0 => hsat c0 (List.mem_cons_of_mem c hc0)
    have h1 := ih m hsat' hm
    cases hr1 : sweep cs' m with | mk m1 b1 =>
    rw [hr1] at h1
    have h2 := sweep1_inv (c := c) (m := m1) (v := v) (hsat c List.mem_cons_self) h1.1
    cases hr2 : sweep1 c m1 with | mk m2 b2 =>
    rw [hr2] at h2
    have hstep : sweep (c :: cs') m = (m2, b1 || b2) := by
      show (let r1 := sweep cs' m; let r2 := sweep1 c r1.1; (r2.1, r1.2 || r2.2)) =
        (m2, b1 || b2)
      simp only [hr1, hr2]
    rw [hstep]
    constructor
    · exact h2.1
    · intro hf
      have hf' : b1 || b2 = true := hf
      rw [Bool.or_eq_true] at hf'
      cases hf' with
      | inl hb1 => exact h1.2 hb1
      | inr hb2 => exact h2.2 hb2

theorem close_inv (fuel : Nat) (cs : List Horn) (m : List Nat) (v : Nat → Bool)
    (hsat : allsat v cs) (hm : ∀ n ∈ m, v n = true)
    (hc : (close fuel cs m).2 = true) : False := by
  induction fuel generalizing cs m with
  | zero => exact Bool.noConfusion hc
  | succ k ih =>
    cases hr : sweep cs m with | mk m1 b1 =>
    have h2 := sweep_inv hsat hm
    rw [hr] at h2
    rw [close_step, hr] at hc
    cases b1 with
    | true =>
      dsimp only at hc
      rw [if_pos rfl] at hc
      exact h2.2 rfl
    | false =>
      dsimp only at hc
      rw [if_neg_of_eq_false rfl] at hc
      cases hfx : m1.all (fun n => marked m n) with
      | true =>
        rw [hfx, if_pos rfl] at hc
        exact Bool.noConfusion hc
      | false =>
        rw [hfx, if_neg_of_eq_false rfl] at hc
        exact ih cs m1 hsat h2.1 hc

theorem hsatComplete {cs : List Horn} (h : hsat cs = false) : ¬ ∃ v, allsat v cs := by
  intro hv
  cases hv with | intro v hv =>
  unfold hsat at h
  cases hcl : close ((atomsOf cs).length + 1) cs [] with | mk mF b =>
  rw [hcl] at h
  have hb2 : !b = false := h
  cases b with
  | false => exact Bool.noConfusion hb2
  | true =>
    exact close_inv _ cs [] v hv (fun n hn => by cases hn) (by rw [hcl])

/- ---------- 单调性 / NoDup / 原子界 ---------- -/

theorem sweep1_subset (c : Horn) (m : List Nat) : m ⊆ (sweep1 c m).1 := by
  intro n hn
  cases c with | mk ps cq =>
  unfold sweep1
  cases ham : allMarked ps m with
  | false => rw [if_neg_of_eq_false rfl]; exact hn
  | true =>
    rw [if_pos rfl]
    cases cq with
    | none => exact hn
    | some q =>
      cases hq : marked m q with
      | true => rw [if_pos rfl]; exact hn
      | false => rw [if_neg_of_eq_false rfl]; exact List.mem_cons_of_mem q hn

theorem sweep_subset (cs : List Horn) (m : List Nat) : m ⊆ (sweep cs m).1 := by
  induction cs generalizing m with
  | nil => intro n hn; exact hn
  | cons c cs' ih =>
    intro n hn
    cases hr1 : sweep cs' m with | mk m1 b1 =>
    cases hr2 : sweep1 c m1 with | mk m2 b2 =>
    have hstep : sweep (c :: cs') m = (m2, b1 || b2) := by
      show (let r1 := sweep cs' m; let r2 := sweep1 c r1.1; (r2.1, r1.2 || r2.2)) =
        (m2, b1 || b2)
      simp only [hr1, hr2]
    rw [hstep]
    have h1 : n ∈ m1 := by
      have h := ih m hn; rw [hr1] at h; exact h
    have h2 : n ∈ m2 := sweep1_subset c m1 h1
    exact h2

theorem sweep1_nodup {c : Horn} {m : List Nat} (hnd : m.Nodup) : (sweep1 c m).1.Nodup := by
  cases c with | mk ps cq =>
  unfold sweep1
  cases ham : allMarked ps m with
  | false => rw [if_neg_of_eq_false rfl]; exact hnd
  | true =>
    rw [if_pos rfl]
    cases cq with
    | none => exact hnd
    | some q =>
      cases hq : marked m q with
      | true => rw [if_pos rfl]; exact hnd
      | false =>
        rw [if_neg_of_eq_false rfl, List.nodup_cons]
        exact ⟨marked_not_mem.mp hq, hnd⟩

theorem sweep_nodup (cs : List Horn) (m : List Nat) (hnd : m.Nodup) :
    (sweep cs m).1.Nodup := by
  induction cs generalizing m with
  | nil => exact hnd
  | cons c cs' ih =>
    cases hr1 : sweep cs' m with | mk m1 b1 =>
    cases hr2 : sweep1 c m1 with | mk m2 b2 =>
    have hstep : sweep (c :: cs') m = (m2, b1 || b2) := by
      show (let r1 := sweep cs' m; let r2 := sweep1 c r1.1; (r2.1, r1.2 || r2.2)) =
        (m2, b1 || b2)
      simp only [hr1, hr2]
    rw [hstep]
    have h1 : m1.Nodup := by have h := ih m hnd; rw [hr1] at h; exact h
    have h2 : m2.Nodup := by
      have h := sweep1_nodup (c := c) (m := m1) h1; rw [hr2] at h; exact h
    exact h2

theorem atomsOf_spec {cs : List Horn} {ps : List Nat} {q : Option Nat}
    (h : (ps, q) ∈ cs) :
    (∀ p ∈ ps, p ∈ atomsOf cs) ∧ (∀ q0, q = some q0 → q0 ∈ atomsOf cs) := by
  constructor
  · intro p hp
    unfold atomsOf; rw [List.mem_flatMap]
    exact ⟨(ps, q), h, List.mem_append.mpr (Or.inl hp)⟩
  · intro q0 hq
    unfold atomsOf; rw [List.mem_flatMap]
    refine ⟨(ps, q), h, ?_⟩
    rw [hq]
    exact List.mem_append.mpr (Or.inr List.mem_cons_self)

theorem sweep1_atoms {c : Horn} {m A : List Nat}
    (hm : m ⊆ A) (hps : ∀ p ∈ c.1, p ∈ A) (hq : ∀ q0, c.2 = some q0 → q0 ∈ A) :
    (sweep1 c m).1 ⊆ A := by
  intro n hn
  cases c with | mk ps cq =>
  unfold sweep1 at hn
  cases ham : allMarked ps m with
  | false => rw [if_neg_of_eq_false rfl] at hn; exact hm hn
  | true =>
    rw [if_pos rfl] at hn
    cases cq with
    | none => exact hm hn
    | some q =>
      cases hq2 : marked m q with
      | true => rw [if_pos rfl] at hn; exact hm hn
      | false =>
        rw [if_neg_of_eq_false rfl] at hn
        cases hn with
        | head _ => exact hq q rfl
        | tail _ hn' => exact hm hn'

theorem sweep_atoms {cs : List Horn} {m A : List Nat}
    (hm : m ⊆ A)
    (hcs : ∀ ps q, (ps, q) ∈ cs → (∀ p ∈ ps, p ∈ A) ∧ (∀ q0, q = some q0 → q0 ∈ A)) :
    (sweep cs m).1 ⊆ A := by
  induction cs generalizing m with
  | nil => intro n hn; exact hm hn
  | cons c cs' ih =>
    intro n hn
    cases c with | mk ps q =>
    cases hr1 : sweep cs' m with | mk m1 b1 =>
    cases hr2 : sweep1 (ps, q) m1 with | mk m2 b2 =>
    have hstep : sweep ((ps, q) :: cs') m = (m2, b1 || b2) := by
      show (let r1 := sweep cs' m; let r2 := sweep1 (ps, q) r1.1; (r2.1, r1.2 || r2.2)) =
        (m2, b1 || b2)
      simp only [hr1, hr2]
    rw [hstep] at hn
    have hm1 : m1 ⊆ A := by
      have h := ih m hm (fun ps0 q0 h0 => hcs ps0 q0 (List.mem_cons_of_mem _ h0))
      rw [hr1] at h; exact h
    have hn' : n ∈ (sweep1 (ps, q) m1).1 := by rw [hr2]; exact hn
    exact sweep1_atoms hm1 (fun p hp => (hcs ps q List.mem_cons_self).1 p hp)
      (fun q0 hq0 => (hcs ps q List.mem_cons_self).2 q0 hq0) hn'

/- ---------- 长度引理三条（裸 core 自证） ---------- -/

theorem mem_erase_of_ne_mem {l : List Nat} {a b : Nat} (hne : b ≠ a) (hb : b ∈ l) :
    b ∈ l.erase a := by
  induction l with
  | nil => cases hb
  | cons c l' ih =>
    unfold List.erase
    cases hca : (c == a) with
    | true =>
      rw [if_pos rfl]
      cases hb with
      | head _ => exact absurd (beq_iff_eq.mp hca) hne
      | tail _ h => exact h
    | false =>
      rw [if_neg_of_eq_false rfl]
      cases hb with
      | head _ => exact List.mem_cons_self
      | tail _ h => exact List.mem_cons_of_mem c (ih h)

theorem subset_length {l₁ l₂ : List Nat} (hnd : l₁.Nodup) (hsub : l₁ ⊆ l₂) :
    l₁.length ≤ l₂.length := by
  induction l₁ generalizing l₂ with
  | nil => exact Nat.zero_le _
  | cons a as ih =>
    rw [List.nodup_cons] at hnd
    have ha2 : a ∈ l₂ := hsub List.mem_cons_self
    have hsub' : as ⊆ l₂.erase a := by
      intro n hn
      apply mem_erase_of_ne_mem
      · intro hna; exact hnd.1 (hna ▸ hn)
      · exact hsub (List.mem_cons_of_mem a hn)
    have ih' := ih hnd.2 hsub'
    rw [List.length_erase_of_mem ha2] at ih'
    have hpos := List.length_pos_of_mem ha2
    show as.length + 1 ≤ l₂.length
    omega

theorem subset_lt {m m1 : List Nat} (hsub : m ⊆ m1) (hnd : m.Nodup)
    (x : Nat) (hx1 : x ∈ m1) (hxm : x ∉ m) : m.length < m1.length := by
  have hsub' : m ⊆ m1.erase x := by
    intro n hn
    apply mem_erase_of_ne_mem
    · intro hnx; exact hxm (hnx ▸ hn)
    · exact hsub hn
  have hle := subset_length hnd hsub'
  rw [List.length_erase_of_mem hx1] at hle
  have hpos := List.length_pos_of_mem hx1
  omega

/- ---------- 不动点引理 ---------- -/

theorem all_marked_subset {m1 m : List Nat} (h : m1.all (fun n => marked m n) = true) :
    m1 ⊆ m := by
  intro n hn
  rw [List.all_eq_true] at h
  exact marked_mem.mp (h n hn)

theorem exists_not_mem_of_all_false {m1 m : List Nat}
    (h : m1.all (fun n => marked m n) = false) : ∃ x, x ∈ m1 ∧ x ∉ m := by
  rw [List.all_eq_false] at h
  cases h with | intro x hx =>
  cases hx with | intro hx1 hx2 =>
  exact ⟨x, hx1, fun hxm => hx2 (marked_mem.mpr hxm)⟩

theorem close_fixpoint (fuel : Nat) (cs : List Horn) (m mF : List Nat) (b : Bool)
    (hnd : m.Nodup) (hincl : m ⊆ atomsOf cs)
    (hfuel : (atomsOf cs).length - m.length < fuel)
    (hc : close fuel cs m = (mF, b)) :
    b = true ∨ (sweep cs mF).2 = false ∧ (sweep cs mF).1 ⊆ mF := by
  induction fuel generalizing cs m mF b with
  | zero => exact absurd hfuel (Nat.not_lt_zero _)
  | succ k ih =>
    cases hr : sweep cs m with | mk m1 b1 =>
    have hmm1 : m ⊆ m1 := by have h := sweep_subset cs m; rw [hr] at h; exact h
    have hnd1 : m1.Nodup := by have h := sweep_nodup cs m hnd; rw [hr] at h; exact h
    have hincl1 : m1 ⊆ atomsOf cs := by
      have h := sweep_atoms hincl (fun ps q hq => atomsOf_spec (cs := cs) hq)
      rw [hr] at h; exact h
    rw [close_step, hr] at hc
    cases b1 with
    | true =>
      dsimp only at hc
      rw [if_pos rfl] at hc
      have h12 := Prod.mk.inj hc
      cases h12 with | intro h1 h2 =>
      subst mF; subst b
      exact Or.inl rfl
    | false =>
      dsimp only at hc
      rw [if_neg_of_eq_false rfl] at hc
      cases hfx : m1.all (fun n => marked m n) with
      | true =>
        rw [hfx, if_pos rfl] at hc
        have h12 := Prod.mk.inj hc
        cases h12 with | intro h1 h2 =>
        subst mF; subst b
        exact Or.inr ⟨by rw [hr], all_marked_subset hfx⟩
      | false =>
        rw [hfx, if_neg_of_eq_false rfl] at hc
        have hex := exists_not_mem_of_all_false hfx
        cases hex with | intro x hx =>
        cases hx with | intro hx1 hxm =>
        have hlt : m.length < m1.length := subset_lt hmm1 hnd x hx1 hxm
        have hle2 : m1.length ≤ (atomsOf cs).length := subset_length hnd1 hincl1
        exact ih cs m1 mF b hnd1 hincl1 (by omega) hc

theorem fixpoint_clause {cs : List Horn} {m : List Nat} :
    (sweep cs m).2 = false → (sweep cs m).1 ⊆ m →
    ∀ ps q, (ps, q) ∈ cs → allMarked ps m = true →
    (match q with | some q0 => q0 ∈ m | none => False) := by
  induction cs with
  | nil => intro _ _ ps q h; cases h
  | cons c cs' ih =>
    intro hsnd hincl ps q hin ham
    cases hr1 : sweep cs' m with | mk m1 b1 =>
    cases hr2 : sweep1 c m1 with | mk m2 b2 =>
    have hstep : sweep (c :: cs') m = (m2, b1 || b2) := by
      show (let r1 := sweep cs' m; let r2 := sweep1 c r1.1; (r2.1, r1.2 || r2.2)) =
        (m2, b1 || b2)
      simp only [hr1, hr2]
    rw [hstep] at hsnd hincl
    have hboth : b1 = false ∧ b2 = false := by
      cases b1 with
      | true =>
        have ht : true = false := hsnd
        exact Bool.noConfusion ht
      | false =>
        cases b2 with
        | false => exact ⟨rfl, rfl⟩
        | true =>
          have ht : true = false := hsnd
          exact Bool.noConfusion ht
    have hmm1 : m ⊆ m1 := by have h := sweep_subset cs' m; rw [hr1] at h; exact h
    have hm1m2 : m1 ⊆ m2 := by have h := sweep1_subset c m1; rw [hr2] at h; exact h
    cases hin with
    | head _ =>
      have ham1 : allMarked ps m1 = true := allMarked_mono hmm1 ham
      unfold sweep1 at hr2
      rw [if_pos ham1] at hr2
      cases q with
      | some q0 =>
        cases hq2 : marked m1 q0 with
        | true =>
          rw [if_pos rfl] at hr2
          have h12 := Prod.mk.inj hr2
          cases h12 with | intro h1 _ =>
          subst m2
          exact hincl (marked_mem.mp hq2)
        | false =>
          rw [if_neg_of_eq_false rfl] at hr2
          have h12 := Prod.mk.inj hr2
          cases h12 with | intro h1 _ =>
          subst m2
          have hx : q0 ∈ q0 :: m1 := List.mem_cons_self
          have hxm : q0 ∈ m := hincl hx
          have hxm1 : q0 ∈ m1 := hmm1 hxm
          exact absurd hxm1 (marked_not_mem.mp hq2)
      | none =>
        have h12 := Prod.mk.inj hr2
        cases h12 with | intro _ h2 =>
        have ht : true = false := by rw [h2]; exact hboth.2
        exact Bool.noConfusion ht
    | tail _ hin' =>
      have hsnd' : (sweep cs' m).2 = false := by rw [hr1]; exact hboth.1
      have hincl' : (sweep cs' m).1 ⊆ m := by
        rw [hr1]; intro n hn; exact hincl (hm1m2 hn)
      exact ih hsnd' hincl' ps q hin' ham

theorem hsatSound {cs : List Horn} (h : hsat cs = true) : ∃ v, allsat v cs := by
  unfold hsat at h
  cases hcl : close ((atomsOf cs).length + 1) cs [] with | mk mF b =>
  rw [hcl] at h
  have hb2 : !b = true := h
  cases b with
  | true => exact Bool.noConfusion hb2
  | false =>
    have h0 : ([] : List Nat).length = 0 := rfl
    have hfp := close_fixpoint ((atomsOf cs).length + 1) cs [] mF false
      List.Nodup.nil (List.nil_subset _) (by omega) hcl
    cases hfp with
    | inl hf => exact Bool.noConfusion hf
    | inr hfp =>
      cases hfp with | intro hsnd hincl =>
      refine ⟨fun n => marked mF n, ?_⟩
      intro c hin
      cases c with | mk ps q =>
      cases q with
      | some q0 =>
        intro hpre
        have ham : allMarked ps mF = true :=
          allMarked_true (fun p hp => marked_mem.mp (hpre p hp))
        have hq0 := fixpoint_clause hsnd hincl ps (some q0) hin ham
        exact marked_mem.mpr hq0
      | none =>
        intro hpre
        have ham : allMarked ps mF = true :=
          allMarked_true (fun p hp => marked_mem.mp (hpre p hp))
        exact fixpoint_clause hsnd hincl ps none hin ham

/- ---------- 现场（H&R §1.5.3 例题） ---------- -/

example : hsat [([2,3,5], some 13), ([], some 5), ([5,11], none)] = true := by decide
example : hsat [([2,3,5], some 13), ([], some 5), ([5,11], none), ([], some 11)] = false :=
  by decide

#print axioms hsatSound
#print axioms hsatComplete

end Ex09Horn
