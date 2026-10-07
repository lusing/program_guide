/- ex42 —— 程序合成与形式语义（Ben-Ari 3e §15.4-15.5）Lean 镜像
   小步操作语义 step/steps + 倒数/乘法两程序的读出式正确性。 -/

abbrev State := Nat → Nat

def upd (x v : Nat) (s : State) : State :=
  fun y => if y == x then v else s y

theorem upd_eq (x v : Nat) (s : State) : (upd x v s) x = v := by
  show (if (x == x) = true then v else s x) = v
  have hx : (x == x) = true := by
    cases h : (x == x) with
    | true => rfl
    | false =>
      have : x ≠ x := by
        intro he; rw [he] at h; exact absurd h (by simp)
      exact absurd rfl this
  rw [hx]
  rfl

theorem upd_neq {x y : Nat} (h : x ≠ y) (v : Nat) (s : State) :
    (upd x v s) y = s y := by
  simp only [upd]
  have hne : (y == x) = false := by
    cases hc : (y == x) with
    | true =>
      have hyx : y = x := by
        simpa [Nat.beq_eq] using hc
      exact absurd (hyx ▸ rfl : x = y) h
    | false => rfl
  rw [hne]
  rfl

inductive Cmd : Type where
  | cskip : Cmd
  | assn : (State → State) → Cmd
  | cseq : Cmd → Cmd → Cmd
  | cwhile : (State → Bool) → Cmd → Cmd

open Cmd

def step : Cmd → State → Option (Cmd × State)
  | cskip, _ => none
  | assn f, s => some (cskip, f s)
  | cseq c1 c2, s =>
      match c1 with
      | cskip => some (c2, s)
      | _ => match step c1 s with
             | some (c1', s') => some (cseq c1' c2, s')
             | none => none
  | cwhile b c, s =>
      if b s then some (cseq c (cwhile b c), s)
      else some (cskip, s)

def steps : Nat → Cmd → State → Option State
  | 0, _, _ => none
  | k + 1, c, s =>
      match step c s with
      | none => match c with
                | cskip => some s
                | _ => none
      | some (c', s') => steps k c' s'

/- ---------- 现场一：倒数程序 ---------- -/

def countdown : Cmd :=
  cwhile (fun s => 0 < s 0) (assn (fun s => upd 0 (s 0 - 1) s))

theorem countdown_correct : ∀ (n : Nat) (s : State), s 0 = n →
    match steps (3 * n + 2) countdown s with
    | some s' => s' 0 = 0
    | none => False := by
  intro n
  induction n with
  | zero =>
    intro s hs
    have h0 : (fun t => decide (0 < t 0)) s = false := by simp [hs]
    simp only [countdown, step, steps, h0]
    exact hs
  | succ n ih =>
    intro s hs
    have h3 : (3 * (n + 1) + 2) = (3 * n + 2) + 3 := by omega
    rw [h3]
    have hg : (fun t => decide (0 < t 0)) s = true := by simp [hs]
    simp only [countdown, step, steps, hg]
    exact ih (upd 0 (s 0 - 1) s) (by rw [upd_eq]; simp only [hs]; omega)

/- ---------- 现场二：合成出的乘法器 ---------- -/

def mulBody : Cmd :=
  cseq (assn (fun s => upd 0 (s 0 + s 2) s))
       (assn (fun s => upd 1 (s 1 - 1) s))

def mul : Cmd :=
  cseq (assn (fun s => upd 0 0 s))
       (cwhile (fun s => 0 < s 1) mulBody)

theorem mulW : ∀ (b c : Nat) (s : State), s 1 = b → s 2 = c →
    ∃ s', steps (5 * b + 2) (cwhile (fun st => 0 < st 1) mulBody) s = some s'
          ∧ s' 0 = s 0 + b * c ∧ s' 1 = 0 := by
  intro b
  induction b with
  | zero =>
    intro c s h1 h2
    have hg : (fun t => decide (0 < t 1)) s = false := by simp [h1]
    refine ⟨s, ?_, ?_, h1⟩
    · simp only [mulBody, step, steps, hg]
      exact rfl
    · rw [Nat.zero_mul]; omega
  | succ b ih =>
    intro c s h1 h2
    have h5 : (5 * (b + 1) + 2) = (5 * b + 2) + 5 := by omega
    rw [h5]
    have hg : (fun t => decide (0 < t 1)) s = true := by simp [h1]
    simp only [mulBody, step, steps, hg]
    have ha : (upd 1 (s 1 - 1) (upd 0 (s 0 + s 2) s)) 1 = b := by
      rw [upd_eq]; simp only [h1]; omega
    have hb : (upd 1 (s 1 - 1) (upd 0 (s 0 + s 2) s)) 2 = s 2 := by
      rw [upd_neq (by omega), upd_neq (by omega)]
    obtain ⟨s'', hrun, hx, hy⟩ := ih c _ ha (by rw [hb]; exact h2)
    refine ⟨s'', hrun, ?_, hy⟩
    have hc : (upd 1 (s 1 - 1) (upd 0 (s 0 + s 2) s)) 0 = s 0 + s 2 := by
      rw [upd_neq (by omega), upd_eq]
    rw [hc] at hx
    rw [h2] at hx
    have h6 : (b + 1) * c = b * c + c := Nat.succ_mul b c
    omega

theorem mul_correct : ∀ (b c : Nat) (s : State), s 1 = b → s 2 = c →
    ∃ s', steps (5 * b + 4) mul s = some s'
          ∧ s' 0 = b * c ∧ s' 1 = 0 := by
  intro b c s h1 h2
  have h4 : (5 * b + 4) = (5 * b + 2) + 2 := by omega
  rw [h4]
  simp only [mul]
  simp only [step, steps, step, steps]
  have ha : (upd 0 0 s) 1 = b := by rw [upd_neq (by omega)]; exact h1
  have hb : (upd 0 0 s) 2 = c := by rw [upd_neq (by omega)]; exact h2
  obtain ⟨s'', hrun, hx, hy⟩ := mulW b c (upd 0 0 s) ha hb
  refine ⟨s'', hrun, ?_, hy⟩
  rw [upd_eq] at hx
  omega

/-- 语义现场：3 × 4 经小步语义得 (12, 0) -/
example :
    (match steps 21 mul (upd 1 3 (upd 2 4 (fun _ => 0))) with
     | some s' => (s' 0, s' 1) | none => (999, 999)) = (12, 0) := by
  rfl
