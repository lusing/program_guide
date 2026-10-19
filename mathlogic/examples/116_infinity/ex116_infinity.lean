/- ex47 —— 无穷集合与停机问题（Jongsma ch5）Lean 镜像
   Galileo 偶数双射、ℕ×ℕ ↪ ℕ（2^a·3^b 单射）、Cantor 对角线三形态、
   Russell 构造版、停机问题（公理记账）。账本见文件尾。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. Galileo：偶数与自然数等势（书例 5.1.1） ----------

def isEven (n : Nat) : Prop := ∃ k, n = 2 * k

def halfE : Nat → Nat
  | 0 => 0
  | 1 => 0
  | (y'+2) => halfE y' + 1

theorem halfE_eq : ∀ k, halfE (2 * k) = k := by
  intro k
  induction k with
  | zero => rfl
  | succ k' ih =>
    show halfE (2 * (k'+1)) = k'+1
    have e : 2 * (k'+1) = (2*k') + 2 := by omega
    rw [e]
    show halfE (2*k') + 1 = k' + 1
    rw [ih]

-- 乘法消去：走 Nat.eq_of_mul_eq_mul_left（core 自带）
theorem cancelL (p a b : Nat) (hp : 0 < p) (h : p * a = p * b) : a = b :=
  Nat.eq_of_mul_eq_mul_left hp h

theorem cancelR (p a b : Nat) (hp : 0 < p) (h : a * p = b * p) : a = b :=
  Nat.eq_of_mul_eq_mul_right hp h

theorem galileo_inj' : ∀ x y, 2 * x = 2 * y → x = y := by
  intro x y h
  exact cancelL 2 x y (by omega) h

theorem galileo_surj : ∀ y, isEven y → 2 * halfE y = y := by
  intro y ⟨k, hk⟩
  rw [hk, halfE_eq]

theorem galileo : ∃ f : Nat → Nat,
    (∀ x y, f x = f y → x = y) ∧ (∀ y, isEven y → ∃ x, f x = y) := by
  refine ⟨fun n => 2 * n, fun x y h => galileo_inj' x y h, ?_⟩
  intro y hy
  exact ⟨halfE y, galileo_surj y hy⟩

-- ---------- 2. ℕ×ℕ ↪ ℕ：2^a·3^b 单射 ----------

def pow : Nat → Nat → Nat
  | _, 0 => 1
  | b, e'+1 => b * pow b e'

theorem pow2_pos : ∀ e, 1 ≤ pow 2 e := by
  intro e
  induction e with
  | zero => exact Nat.le_refl 1
  | succ e' ih =>
    show 1 ≤ 2 * pow 2 e'
    have := ih
    omega

theorem pow3_pos : ∀ e, 1 ≤ pow 3 e := by
  intro e
  induction e with
  | zero => exact Nat.le_refl 1
  | succ e' ih =>
    show 1 ≤ 3 * pow 3 e'
    have := ih
    omega

theorem pow3_odd : ∀ e, ∃ o, pow 3 e = 2 * o + 1 := by
  intro e
  induction e with
  | zero => exact ⟨0, rfl⟩
  | succ e' ih =>
    match ih with
    | ⟨o, ho⟩ =>
      refine ⟨3 * o + 1, ?_⟩
      show 3 * pow 3 e' = 2 * (3 * o + 1) + 1
      rw [ho]
      omega

theorem pow2_add : ∀ x y, pow 2 (x + y) = pow 2 x * pow 2 y := by
  intro x
  induction x with
  | zero => intro y; simp [pow]
  | succ x' ih =>
    intro y
    have hxy : x' + 1 + y = x' + y + 1 := by omega
    rw [hxy]
    show 2 * pow 2 (x' + y) = 2 * pow 2 x' * pow 2 y
    rw [ih]
    simp [Nat.mul_add, Nat.add_mul, Nat.add_comm, Nat.add_assoc, Nat.add_left_comm,
      Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]

theorem pow3_add : ∀ x y, pow 3 (x + y) = pow 3 x * pow 3 y := by
  intro x
  induction x with
  | zero => intro y; simp [pow]
  | succ x' ih =>
    intro y
    have hxy : x' + 1 + y = x' + y + 1 := by omega
    rw [hxy]
    show 3 * pow 3 (x' + y) = 3 * pow 3 x' * pow 3 y
    rw [ih]
    simp [Nat.mul_add, Nat.add_mul, Nat.add_comm, Nat.add_assoc, Nat.add_left_comm,
      Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]

theorem pow2_inj : ∀ x y, pow 2 x = pow 2 y → x = y := by
  intro x y h
  have hp := pow2_pos x
  have hp' := pow2_pos y
  match Nat.lt_trichotomy x y with
  | .inl hlt =>
    exfalso
    have hj : y = x + (y - x) := by omega
    rw [hj] at h
    rw [pow2_add] at h
    have heven : pow 2 (y - x) = 2 * pow 2 (y - x - 1) := by
      have hz : y - x = (y - x - 1) + 1 := by omega
      rw [hz, pow2_add]
      simp [pow, Nat.mul_comm]
    rw [heven] at h
    have hc : 1 = 2 * pow 2 (y - x - 1) := by
      apply cancelL (pow 2 x) 1 _ (by omega)
      calc pow 2 x * 1 = pow 2 x := Nat.mul_one _
        _ = pow 2 x * (2 * pow 2 (y - x - 1)) := h
    have hq := pow2_pos (y - x - 1)
    omega
  | .inr (Or.inl heq) => exact heq
  | .inr (Or.inr hgt) =>
    exfalso
    have hj : x = y + (x - y) := by omega
    rw [hj] at h
    rw [pow2_add] at h
    have heven : pow 2 (x - y) = 2 * pow 2 (x - y - 1) := by
      have hz : x - y = (x - y - 1) + 1 := by omega
      rw [hz, pow2_add]
      simp [pow, Nat.mul_comm]
    rw [heven] at h
    have hc : 2 * pow 2 (x - y - 1) = 1 := by
      apply cancelL (pow 2 y) _ 1 (by omega)
      calc pow 2 y * (2 * pow 2 (x - y - 1)) = pow 2 y := h
        _ = pow 2 y * 1 := (Nat.mul_one _).symm
    have hq := pow2_pos (x - y - 1)
    omega

theorem pow3_inj : ∀ x y, pow 3 x = pow 3 y → x = y := by
  intro x y h
  have hp := pow3_pos x
  have hp' := pow3_pos y
  have hst : ∀ m, pow 3 (m + 1) = 3 * pow 3 m := fun m => rfl
  match Nat.lt_trichotomy x y with
  | .inl hlt =>
    exfalso
    have hj : y = x + (y - x - 1 + 1) := by omega
    rw [hj] at h
    rw [pow3_add, hst] at h
    match pow3_odd (y - x - 1) with
    | ⟨o, ho⟩ =>
      rw [ho] at h
      have hc : 1 = 3 * (2 * o + 1) :=
        cancelL (pow 3 x) 1 _ (by omega) (by rw [Nat.mul_one]; exact h)
      omega
  | .inr (Or.inl heq) => exact heq
  | .inr (Or.inr hgt) =>
    exfalso
    have hj : x = y + (x - y - 1 + 1) := by omega
    rw [hj] at h
    rw [pow3_add, hst] at h
    match pow3_odd (x - y - 1) with
    | ⟨o, ho⟩ =>
      rw [ho] at h
      have hc : 3 * (2 * o + 1) = 1 :=
        cancelL (pow 3 y) _ 1 (by omega) (by rw [Nat.mul_one]; exact h)
      omega

theorem pair_inj : ∀ a b c d,
    pow 2 a * pow 3 b = pow 2 c * pow 3 d → a = c ∧ b = d := by
  intro a b c d h
  have hpa := pow2_pos a
  have hpc := pow2_pos c
  have hst : ∀ m, pow 2 (m + 1) = 2 * pow 2 m := fun m => rfl
  have hac : a = c := by
    match Nat.lt_trichotomy a c with
    | .inl hlt =>
      exfalso
      have hj : c = a + (c - a - 1 + 1) := by omega
      rw [hj] at h
      rw [pow2_add, hst] at h
      match pow3_odd b with
      | ⟨o1, h1⟩ =>
        match pow3_odd d with
        | ⟨o2, h2⟩ =>
          rw [h1, h2] at h
          have h' : pow 2 a * (2 * pow 2 (c - a - 1) * (2 * o2 + 1))
                    = pow 2 a * (2 * o1 + 1) :=
            (Nat.mul_assoc (pow 2 a) (2 * pow 2 (c - a - 1)) (2 * o2 + 1)).symm.trans h.symm
          have hc : 2 * o1 + 1 = 2 * pow 2 (c - a - 1) * (2 * o2 + 1) :=
            (cancelL (pow 2 a) _ _ (by omega) h').symm
          have hlin : 2 * pow 2 (c - a - 1) * (2 * o2 + 1)
                      = 2 * (pow 2 (c - a - 1) * (2 * o2 + 1)) := Nat.mul_assoc _ _ _
          omega
    | .inr (Or.inl heq) => exact heq
    | .inr (Or.inr hgt) =>
      exfalso
      have hj : a = c + (a - c - 1 + 1) := by omega
      rw [hj] at h
      rw [pow2_add, hst] at h
      match pow3_odd b with
      | ⟨o1, h1⟩ =>
        match pow3_odd d with
        | ⟨o2, h2⟩ =>
          rw [h1, h2] at h
          have h' : pow 2 c * (2 * pow 2 (a - c - 1) * (2 * o1 + 1))
                    = pow 2 c * (2 * o2 + 1) :=
            (Nat.mul_assoc (pow 2 c) (2 * pow 2 (a - c - 1)) (2 * o1 + 1)).symm.trans h
          have hc : 2 * pow 2 (a - c - 1) * (2 * o1 + 1) = 2 * o2 + 1 :=
            cancelL (pow 2 c) _ _ (by omega) h'
          have hlin : 2 * pow 2 (a - c - 1) * (2 * o1 + 1)
                      = 2 * (pow 2 (a - c - 1) * (2 * o1 + 1)) := Nat.mul_assoc _ _ _
          omega
  rw [hac] at h
  have hc2 : pow 3 b = pow 3 d :=
    cancelL (pow 2 c) _ _ (by omega) h
  exact ⟨hac, pow3_inj b d hc2⟩

-- ---------- 3. Cantor 对角线 ----------

theorem cantor_prop : ¬ ∃ e : Nat → Nat → Prop,
    ∀ P : Nat → Prop, ∃ n : Nat, ∀ x : Nat, e n x ↔ P x := by
  intro he
  match he with
  | ⟨e, h⟩ =>
    match h (fun x => ¬ e x x) with
    | ⟨n, hn⟩ =>
      specialize hn n
      have d1 : e n n := hn.mpr (fun hev => (hn.mp hev) hev)
      exact (hn.mp d1) d1

theorem cantor_bool : ¬ ∃ e : Nat → Nat → Bool,
    ∀ g : Nat → Bool, ∃ n : Nat, ∀ x : Nat, e n x = g x := by
  intro he
  match he with
  | ⟨e, h⟩ =>
    match h (fun x => !e x x) with
    | ⟨n, hn⟩ =>
      have hnn : e n n = !e n n := hn n
      cases hev : e n n with
      | false => rw [hev] at hnn; simp at hnn
      | true => rw [hev] at hnn; simp at hnn

theorem cantor_general (A : Type) (F : A → A → Prop) :
    ¬ (∀ P : A → Prop, ∃ a : A, ∀ x : A, F a x ↔ P x) := by
  intro h
  match h (fun x => ¬ F x x) with
  | ⟨a, ha⟩ =>
    specialize ha a
    have d1 : F a a := ha.mpr (fun hev => (ha.mp hev) hev)
    exact (ha.mp d1) d1

theorem russell (A : Type) (R : A → A → Prop) :
    ¬ ∃ N : A, ∀ x : A, R x N ↔ ¬ R x x := by
  intro hN
  match hN with
  | ⟨N, h⟩ =>
    specialize h N
    have d1 : R N N := h.mpr (fun hev => (h.mp hev) hev)
    exact (h.mp d1) d1

-- ---------- 4. 停机问题（公理记账） ----------

axiom prog : Type
axiom halts_on : prog → prog → Prop
axiom H : prog → prog → Bool
axiom H_sound_true : ∀ p i, H p i = true → halts_on p i
axiom H_sound_false : ∀ p i, H p i = false → ¬ halts_on p i
axiom D : prog
axiom D_spec : ∀ i, halts_on D i ↔ (H i i = false)

theorem no_halting_checker : False := by
  cases hd : H D D with
  | true =>
      have ht : halts_on D D := H_sound_true D D hd
      have hf : H D D = false := (D_spec D).mp ht
      rw [hd] at hf
      exact absurd hf (by simp)
  | false =>
      have hf : ¬ halts_on D D := H_sound_false D D hd
      have ht : halts_on D D := (D_spec D).mpr hd
      exact hf ht

-- ---------- 5. 冒烟与账本 ----------

#eval pow 2 3 * pow 3 2
#eval pow 2 5 * pow 3 0

#print axioms galileo
#print axioms pair_inj
#print axioms cantor_prop
#print axioms cantor_bool
#print axioms cantor_general
#print axioms russell
#print axioms no_halting_checker
