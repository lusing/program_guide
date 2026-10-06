/- ex09_horn —— Horn 子句与线性可满足性求解器（Lean 4.25 裸 core 版，H&R §1.5.3）

   与 Coq 版同构：sweep/close 标记算法 + 双方向正确性（hsatSound/hsatComplete）。
   裸 core 无 Nodup 长度引理——mem_erase_of_ne_mem/subset_length/subset_lt 三条自证。
   无 rcases：全部 cases + 匿名构造子手写。Bool-if 的 condition 是 (· = true) 的 Prop 化。 -/

namespace Ex09Horn

/-- Bool 版 if_neg：条件按 (· = true) 强制成 Prop -/
theorem if_neg_of_eq_false {α : Type} {b : Bool} {x y : α} (h : b = false) :
    (if b then x else y) = y :=
  if_neg (fun hh => by rw [h] at hh; exact Bool.noConfusion hh)

def marked (m : List Nat) (n : Nat) : Bool := m.any (· == n)

theorem marked_mem {m : List Nat} {n : Nat} : marked m n = true ↔ n ∈ m := by
  unfold marked; rw [List.any_eq_true]
  constructor
  · intro h
    cases h with | intro x hx =>
    cases hx with | intro hx hxn =>
    have hxn' : x = n := beq_iff_eq.mp hxn
    rw [← hxn']; exact hx
  · intro h; exact ⟨n, h, beq_iff_eq.mpr rfl⟩

theorem marked_not_mem {m : List Nat} {n : Nat} : marked m n = false ↔ n ∉ m := by
  constructor
  · intro h1 h2
    have ht : marked m n = true := marked_mem.mpr h2
    rw [ht] at h1; exact Bool.noConfusion h1
  · intro h1
    cases hm : marked m n with
    | false => rfl
    | true => exact absurd (marked_mem.mp hm) h1

def allMarked : List Nat → List Nat → Bool
  | [], _ => true
  | p :: ps, m => marked m p && allMarked ps m

theorem allMarked_mem {ps m : List Nat} (h : allMarked ps m = true) :
    ∀ p ∈ ps, p ∈ m := by
  induction ps with
  | nil => intro p hp; cases hp
  | cons p ps' ih =>
    intro q hq
    simp only [allMarked] at h
    rw [Bool.and_eq_true] at h
    cases hq with
    | head _ => exact marked_mem.mp h.1
    | tail _ hq' => exact ih h.2 q hq'

theorem allMarked_true {ps m : List Nat} (h : ∀ p ∈ ps, p ∈ m) :
    allMarked ps m = true := by
  induction ps with
  | nil => rfl
  | cons p ps' ih =>
    simp only [allMarked]
    rw [Bool.and_eq_true]
    exact ⟨marked_mem.mpr (h p List.mem_cons_self),
           ih (fun q hq => h q (List.mem_cons_of_mem p hq))⟩

theorem allMarked_mono {ps m m' : List Nat} (hsub : m ⊆ m') (h : allMarked ps m = true) :
    allMarked ps m' = true :=
  allMarked_true (fun p hp => hsub (allMarked_mem h p hp))

/- ---------- 标记算法 ---------- -/

def sweep1 (c : List Nat × Option Nat) (m : List Nat) : List Nat × Bool :=
  if allMarked c.1 m then
    match c.2 with
    | none => (m, true)
    | some q => if marked m q then (m, false) else (q :: m, false)
  else (m, false)

theorem sweep1_some (ps : List Nat) (q : Nat) (m : List Nat) :
    sweep1 (ps, some q) m =
      (if allMarked ps m then (if marked m q then (m, false) else (q :: m, false))
       else (m, false)) := rfl

theorem sweep1_none (ps : List Nat) (m : List Nat) :
    sweep1 (ps, none) m = (if allMarked ps m then (m, true) else (m, false)) := rfl

def sweep : List (List Nat × Option Nat) → List Nat → List Nat × Bool
  | [], m => (m, false)
  | c :: cs', m =>
      let r1 := sweep cs' m
      let r2 := sweep1 c r1.1
      (r2.1, r1.2 || r2.2)

def close : Nat → List (List Nat × Option Nat) → List Nat → List Nat × Bool
  | 0, _, m => (m, false)
  | k + 1, cs, m =>
      if (sweep cs m).2 then ((sweep cs m).1, true)
      else if (sweep cs m).1.all (fun n => marked m n) then (m, false)
      else close k cs (sweep cs m).1

theorem close_step (k : Nat) (cs : List (List Nat × Option Nat)) (m : List Nat) :
    close (k + 1) cs m =
      (if (sweep cs m).2 then ((sweep cs m).1, true)
       else if (sweep cs m).1.all (fun n => marked m n) then (m, false)
       else close k cs (sweep cs m).1) := rfl

def atomsOf (cs : List (List Nat × Option Nat)) : List Nat :=
  cs.flatMap (fun c => c.1 ++ (match c.2 with | some q => [q] | none => []))

def hsat (cs : List (List Nat × Option Nat)) : Bool :=
  !(close ((atomsOf cs).length + 1) cs []).2

/- ---------- 语义 ---------- -/

def csat (v : Nat → Bool) (c : List Nat × Option Nat) : Prop :=
  match c.2 with
  | none => (∀ p ∈ c.1, v p = true) → False
  | some q => (∀ p ∈ c.1, v p = true) → v q = true

def allsat (v : Nat → Bool) (cs : List (List Nat × Option Nat)) : Prop := ∀ c ∈ cs, csat v c

/- ---------- 不变量（H&R 式 1.8） ---------- -/

theorem sweep1_inv {c : List Nat × Option Nat} {m : List Nat} {v : Nat → Bool}
    (hc : csat v c) (hm : ∀ n ∈ m, v n = true) :
    (∀ n ∈ (sweep1 c m).1, v n = true) ∧ ((sweep1 c m).2 = true → False) := by
  cases c with | mk ps cq =>
  unfold sweep1
  cases ham : allMarked ps m with
  | false =>
    rw [if_neg_of_eq_false rfl]
    exact ⟨fun n hn => hm n hn, fun hf => Bool.noConfusion hf⟩
  | true =>
    rw [if_pos rfl]
    cases cq with
    | none =>
      dsimp only
      constructor
      · intro n hn; exact hm n hn
      · intro _
        apply hc
        intro p hp; exact hm p (allMarked_mem ham p hp)
    | some q =>
      dsimp only
      cases hq : marked m q with
      | true =>
        rw [if_pos rfl]
        exact ⟨fun n hn => hm n hn, fun hf => Bool.noConfusion hf⟩
      | false =>
        rw [if_neg_of_eq_false rfl]
        constructor
        · intro n hn
          cases hn with
          | head _ => apply hc; intro p hp; exact hm p (allMarked_mem ham p hp)
          | tail _ hn' => exact hm n hn'
        · intro hf; exact Bool.noConfusion hf

theorem sweep_inv {v : Nat → Bool} :
    ∀ (cs : List (List Nat × Option Nat)) (m : List Nat),
    allsat v cs → (∀ n ∈ m, v n = true) →
    (∀ n ∈ (sweep cs m).1, v n = true) ∧ ((sweep cs m).2 = true → False) := by
  intro cs
  induction cs with
  | nil =>
    intro m _ hm
    exact ⟨fun n hn => hm n hn, fun hf => Bool.noConfusion hf⟩
  | cons c cs' ih =>
    intro m hsat hm
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
      cases b1 with
      | true => exact h1.2 hf
      | false => exact h2.2 hf

theorem close_inv (fuel : Nat) (cs : List (List Nat × Option Nat)) (m : List Nat) (v : Nat → Bool)
    (hsat : allsat v cs) (hm : ∀ n ∈ m, v n = true)
    (hc : (close fuel cs m).2 = true) : False := by
  induction fuel generalizing cs m with
  | zero => exact Bool.noConfusion hc
  | succ k ih =>
    have h2 := sweep_inv cs m hsat hm
    rw [close_step] at hc
    cases hb : (sweep cs m).2 with
    | true =>
      exact h2.2 hb
    | false =>
      rw [hb, if_neg_of_eq_false rfl] at hc
      cases hfx : (sweep cs m).1.all (fun n => marked m n) with
      | true =>
        rw [hfx, if_pos rfl] at hc
        exact Bool.noConfusion hc
      | false =>
        rw [hfx, if_neg_of_eq_false rfl] at hc
        exact ih cs (sweep cs m).1 hsat h2.1 hc

theorem hsatComplete {cs : List (List Nat × Option Nat)} (h : hsat cs = false) : ¬ ∃ v, allsat v cs := by
  intro hv
  cases hv with | intro v hv =>
  unfold hsat at h
  cases hcl : close ((atomsOf cs).length + 1) cs [] with | mk mF b =>
  rw [hcl] at h
  cases b with
  | false => exact Bool.noConfusion h
  | true =>
    exact close_inv _ cs [] v hv (fun n hn => by cases hn) (by rw [hcl])

/- ---------- 单调性 / NoDup / 原子界 ---------- -/

theorem sweep1_subset (c : List Nat × Option Nat) (m : List Nat) : m ⊆ (sweep1 c m).1 := by
  intro n hn
  cases c with | mk ps cq =>
  unfold sweep1
  cases ham : allMarked ps m with
  | false => rw [if_neg_of_eq_false rfl]; exact hn
  | true =>
    rw [if_pos rfl]
    cases cq with
    | none => dsimp only; exact hn
    | some q =>
      dsimp only
      cases hq : marked m q with
      | true => rw [if_pos rfl]; exact hn
      | false => rw [if_neg_of_eq_false rfl]; exact List.mem_cons_of_mem q hn

theorem sweep_subset (cs : List (List Nat × Option Nat)) (m : List Nat) : m ⊆ (sweep cs m).1 := by
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
    have h2 : n ∈ (sweep1 c m1).1 := sweep1_subset c m1 h1
    rw [hr2] at h2
    exact h2

theorem sweep1_nodup {c : List Nat × Option Nat} {m : List Nat} (hnd : m.Nodup) : (sweep1 c m).1.Nodup := by
  cases c with | mk ps cq =>
  unfold sweep1
  cases ham : allMarked ps m with
  | false => rw [if_neg_of_eq_false rfl]; exact hnd
  | true =>
    rw [if_pos rfl]
    cases cq with
    | none => dsimp only; exact hnd
    | some q =>
      dsimp only
      cases hq : marked m q with
      | true => rw [if_pos rfl]; exact hnd
      | false =>
        rw [if_neg_of_eq_false rfl, List.nodup_cons]
        exact ⟨marked_not_mem.mp hq, hnd⟩

theorem sweep_nodup (cs : List (List Nat × Option Nat)) (m : List Nat) (hnd : m.Nodup) :
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

theorem atomsOf_spec {cs : List (List Nat × Option Nat)} {ps : List Nat} {q : Option Nat}
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

theorem sweep1_atoms {c : List Nat × Option Nat} {m A : List Nat}
    (hm : m ⊆ A) (hps : ∀ p ∈ c.1, p ∈ A) (hq : ∀ q0, c.2 = some q0 → q0 ∈ A) :
    (sweep1 c m).1 ⊆ A := by
  intro n hn
  cases c with | mk ps cq =>
  unfold sweep1 at hn
  cases ham : allMarked ps m with
  | false => rw [ham, if_neg_of_eq_false rfl] at hn; exact hm hn
  | true =>
    rw [ham, if_pos rfl] at hn
    cases cq with
    | none => dsimp only at hn; exact hm hn
    | some q =>
      dsimp only at hn
      cases hq2 : marked m q with
      | true => rw [hq2, if_pos rfl] at hn; exact hm hn
      | false =>
        rw [hq2, if_neg_of_eq_false rfl] at hn
        cases hn with
        | head _ => exact hq _ rfl
        | tail _ hn' => exact hm hn'

theorem sweep_atoms {A : List Nat} :
    ∀ (cs : List (List Nat × Option Nat)) (m : List Nat),
    m ⊆ A →
    (∀ ps q, (ps, q) ∈ cs → (∀ p ∈ ps, p ∈ A) ∧ (∀ q0, q = some q0 → q0 ∈ A)) →
    (sweep cs m).1 ⊆ A := by
  intro cs
  induction cs with
  | nil => intro m hm _ n hn; exact hm hn
  | cons c cs' ih =>
    intro m hm hcs n hn
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
    have _hmUsed := hm
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
    cases hb with
    | head _ =>
      cases hba : (b == a) with
      | true => exact absurd (beq_iff_eq.mp hba) hne
      | false => exact List.mem_cons_self
    | tail _ h =>
      cases hca : (c == a) with
      | true => exact h
      | false => exact List.mem_cons_of_mem c (ih h)

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

theorem close_fixpoint (fuel : Nat) (cs : List (List Nat × Option Nat)) (m mF : List Nat) (b : Bool)
    (hnd : m.Nodup) (hincl : m ⊆ atomsOf cs)
    (hfuel : (atomsOf cs).length - m.length < fuel)
    (hc : close fuel cs m = (mF, b)) :
    b = true ∨ (sweep cs mF).2 = false ∧ (sweep cs mF).1 ⊆ mF := by
  induction fuel generalizing cs m mF b with
  | zero => exact absurd hfuel (Nat.not_lt_zero _)
  | succ k ih =>
    have hsub : m ⊆ (sweep cs m).1 := sweep_subset cs m
    have hnd1 : (sweep cs m).1.Nodup := sweep_nodup cs m hnd
    have hincl1 : (sweep cs m).1 ⊆ atomsOf cs :=
      sweep_atoms cs m hincl (fun ps q hq => atomsOf_spec (cs := cs) hq)
    rw [close_step] at hc
    cases hb : (sweep cs m).2 with
    | true =>
      rw [hb, if_pos rfl] at hc
      have h12 := Prod.mk.inj hc
      cases h12 with | intro h1 h2 =>
      subst mF; subst b
      exact Or.inl rfl
    | false =>
      rw [hb, if_neg_of_eq_false rfl] at hc
      cases hfx : (sweep cs m).1.all (fun n => marked m n) with
      | true =>
        rw [hfx, if_pos rfl] at hc
        have h12 := Prod.mk.inj hc
        cases h12 with | intro h1 h2 =>
        subst mF; subst b
        exact Or.inr ⟨hb, all_marked_subset hfx⟩
      | false =>
        rw [hfx, if_neg_of_eq_false rfl] at hc
        have hex := exists_not_mem_of_all_false hfx
        cases hex with | intro x hx =>
        cases hx with | intro hx1 hxm =>
        have hlt : m.length < (sweep cs m).1.length := subset_lt hsub hnd x hx1 hxm
        have hle2 : (sweep cs m).1.length ≤ (atomsOf cs).length :=
          subset_length hnd1 hincl1
        exact ih cs (sweep cs m).1 mF b hnd1 hincl1 (by omega) hc

theorem fixpoint_clause {cs : List (List Nat × Option Nat)} {m : List Nat} :
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
      cases q with
      | some q0 =>
        rw [sweep1_some ps q0 m1, if_pos ham1] at hr2
        cases hq2 : marked m1 q0 with
        | true =>
          rw [hq2, if_pos rfl] at hr2
          have h12 := Prod.mk.inj hr2
          cases h12 with | intro h1 _ =>
          subst m2
          exact hincl (marked_mem.mp hq2)
        | false =>
          rw [hq2, if_neg_of_eq_false rfl] at hr2
          have h12 := Prod.mk.inj hr2
          cases h12 with | intro h1 _ =>
          subst m2
          have hx : q0 ∈ q0 :: m1 := List.mem_cons_self
          have hxm : q0 ∈ m := hincl hx
          have hxm1 : q0 ∈ m1 := hmm1 hxm
          exact absurd hxm1 (marked_not_mem.mp hq2)
      | none =>
        rw [sweep1_none ps m1, if_pos ham1] at hr2
        have h12 := Prod.mk.inj hr2
        cases h12 with | intro _ h2 =>
        have ht : true = false := by rw [h2]; exact hboth.2
        exact Bool.noConfusion ht
    | tail _ hin' =>
      have hsnd' : (sweep cs' m).2 = false := by rw [hr1]; exact hboth.1
      have hincl' : (sweep cs' m).1 ⊆ m := by
        rw [hr1]; intro n hn; exact hincl (hm1m2 hn)
      exact ih hsnd' hincl' ps q hin' ham

theorem hsatSound {cs : List (List Nat × Option Nat)} (h : hsat cs = true) : ∃ v, allsat v cs := by
  unfold hsat at h
  cases hcl : close ((atomsOf cs).length + 1) cs [] with | mk mF b =>
  rw [hcl] at h
  cases b with
  | true => exact Bool.noConfusion h
  | false =>
    have h0 : ([] : List Nat).length = 0 := rfl
    have hfp := close_fixpoint ((atomsOf cs).length + 1) cs [] mF false
      List.nodup_nil (List.nil_subset _) (by omega) hcl
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
