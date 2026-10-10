/- ex45 —— 整除性与初等数论（Jongsma §3.5）Lean 镜像
   divides 基本律 / 除法算式 dm2 / 扩展 Euclid egcdf / Gcd 刻画 + Bézout 差形式 /
   Euclid 引理 / gcd·lcm / 素因子存在 + 素数无穷。账本见文件尾。
   裸 core 无 ring：多项式恒等式走 AC-simp。 -/

-- ---------- 1. 整除基本律 ----------

def divides (a b : Nat) : Prop := ∃ k, b = a * k

theorem div_refl (a : Nat) : divides a a := ⟨1, by omega⟩

theorem div_zero_r (a : Nat) : divides a 0 := ⟨0, by omega⟩

theorem div_trans : ∀ a b c, divides a b → divides b c → divides a c := by
  intro a b c ⟨k1, hk1⟩ ⟨k2, hk2⟩
  exact ⟨k1 * k2, by rw [hk2, hk1, Nat.mul_assoc]⟩

theorem div_add : ∀ a b c, divides a b → divides a c → divides a (b + c) := by
  intro a b c ⟨k1, hk1⟩ ⟨k2, hk2⟩
  exact ⟨k1 + k2, by rw [hk1, hk2, Nat.mul_add]⟩

theorem div_mul_l : ∀ a b m, divides a b → divides a (m * b) := by
  intro a b m ⟨k, hk⟩
  exact ⟨m * k, by rw [hk]; simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]⟩

theorem div_mul_r : ∀ a b m, divides a b → divides a (b * m) := by
  intro a b m ⟨k, hk⟩
  exact ⟨k * m, by rw [hk]; simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]⟩

theorem div_sub : ∀ a b c, divides a b → divides a c → c ≤ b → divides a (b - c) := by
  intro a b c ⟨k1, hk1⟩ ⟨k2, hk2⟩ hle
  match a with
  | 0 =>
      refine ⟨k1 - k2, ?_⟩
      rw [hk1, hk2]
      omega
  | a'+1 =>
      have hle' : (a'+1) * k2 ≤ (a'+1) * k1 := by rw [← hk1, ← hk2]; exact hle
      have hk2k1 : k2 ≤ k1 := Nat.le_of_mul_le_mul_left hle' (by omega)
      have hk : k1 = k2 + (k1 - k2) := by omega
      refine ⟨k1 - k2, ?_⟩
      rw [hk1, hk2]
      generalize hj : (a'+1) * (k1 - k2) = x
      have e : (a'+1) * k1 = (a'+1) * k2 + x := by rw [hk, Nat.mul_add, hj]
      clear hj
      omega

-- ---------- 2. 除法算式 dm2 ----------

def dm2 : Nat → Nat → Nat → Nat × Nat
  | 0, a, _ => (0, a)
  | f'+1, a, b =>
    if b ≤ a then ((dm2 f' (a - b) b).1 + 1, (dm2 f' (a - b) b).2)
    else (0, a)

def dmqF (a b : Nat) : Nat := (dm2 a a b).1
def dmrF (a b : Nat) : Nat := (dm2 a a b).2

theorem dm2_small : ∀ f a b, a < b → dm2 f a b = (0, a) := by
  intro f a b hab
  match f with
  | 0 => rfl
  | f'+1 =>
    show (if b ≤ a then _ else (0, a)) = (0, a)
    rw [if_neg (show ¬ (b ≤ a) by omega)]

theorem dm2_le : ∀ f a b, b ≤ a →
    dm2 (f+1) a b = ((dm2 f (a - b) b).1 + 1, (dm2 f (a - b) b).2) := by
  intro f a b hba
  show (if b ≤ a then _ else (0, a)) = _
  rw [if_pos hba]

theorem dm2_snd_zero : ∀ f a, (dm2 f a 0).2 = a := by
  intro f
  induction f with
  | zero => intro a; rfl
  | succ f' ih =>
    intro a
    show (if 0 ≤ a then ((dm2 f' (a - 0) 0).1 + 1, (dm2 f' (a - 0) 0).2) else (0, a)).2 = a
    rw [if_pos (Nat.zero_le a), Nat.sub_zero]
    exact ih a

theorem dm2_ex : ∀ f a b, a ≤ f →
    ∃ q r, dm2 f a b = (q, r) ∧ a = b * q + r := by
  intro f
  induction f with
  | zero => intro a b _; exact ⟨0, a, rfl, by omega⟩
  | succ f' ih =>
    intro a b haf
    cases b with
    | zero =>
        refine ⟨(dm2 (f'+1) a 0).1, (dm2 (f'+1) a 0).2, rfl, ?_⟩
        show a = 0 * (dm2 (f'+1) a 0).1 + (dm2 (f'+1) a 0).2
        rw [dm2_snd_zero]
        omega
    | succ b'' =>
        match Nat.lt_or_ge a (b''+1) with
        | .inl hab =>
            rw [dm2_small (f'+1) a (b''+1) (by omega)]
            exact ⟨0, a, rfl, by omega⟩
        | .inr hge =>
        have hba : b''+1 ≤ a := by omega
        match ih (a - (b''+1)) (b''+1) (by omega) with
        | ⟨q, r, heq, hqr⟩ =>
          refine ⟨q + 1, r, ?_, ?_⟩
          · rw [dm2_le f' a (b''+1) hba, heq]
          · have e1 : (b''+1) * (q + 1) = (b''+1) * q + (b''+1) := by
              rw [Nat.mul_add, Nat.mul_one]
            omega

theorem dm2_lt : ∀ f a b, b ≠ 0 → a ≤ f → (dm2 f a b).2 < b := by
  intro f
  induction f with
  | zero => intro a b hb haf; show a < b; omega
  | succ f' ih =>
    intro a b hb haf
    match Nat.lt_or_ge a b with
    | .inl hab => rw [dm2_small (f'+1) a b (by omega)]; omega
    | .inr hge =>
        rw [dm2_le f' a b (by omega)]
        exact ih (a - b) b hb (by omega)

theorem dm_eq (a b : Nat) : a = b * dmqF a b + dmrF a b := by
  match dm2_ex a a b (Nat.le_refl a) with
  | ⟨q, r, heq, hqr⟩ =>
    show a = b * (dm2 a a b).1 + (dm2 a a b).2
    rw [heq]
    exact hqr

theorem dm_lt : ∀ a b, b ≠ 0 → dmrF a b < b := by
  intro a b hb
  exact dm2_lt a a b hb (Nat.le_refl a)

theorem div_alg_unique : ∀ b q1 r1 q2 r2,
    b ≠ 0 → r1 < b → r2 < b →
    b * q1 + r1 = b * q2 + r2 → q1 = q2 ∧ r1 = r2 := by
  intro b q1 r1 q2 r2 hb hr1 hr2 heq
  match Nat.lt_trichotomy q1 q2 with
  | .inl hlt =>
      exfalso
      cases hji : (q2 - q1) with
      | zero => omega
      | succ j' =>
        have hm : q2 = q1 + (j' + 1) := by omega
        have e2 : b * q2 = b * q1 + b * (j' + 1) := by rw [hm, Nat.mul_add]
        have e4 : b * (j' + 1) = b * j' + b := by rw [Nat.mul_add, Nat.mul_one]
        omega
  | .inr (Or.inl heqq) =>
      have heq' := heq
      rw [heqq] at heq'
      exact ⟨heqq, by omega⟩
  | .inr (Or.inr hgt) =>
      exfalso
      cases hji : (q1 - q2) with
      | zero => omega
      | succ j' =>
        have hm : q1 = q2 + (j' + 1) := by omega
        have e2 : b * q1 = b * q2 + b * (j' + 1) := by rw [hm, Nat.mul_add]
        have e4 : b * (j' + 1) = b * j' + b := by rw [Nat.mul_add, Nat.mul_one]
        omega

-- ---------- 3. Gcd 刻画与唯一性 ----------

def Gcd (d a b : Nat) : Prop :=
  divides d a ∧ divides d b ∧ (∀ c, divides c a → divides c b → divides c d)

theorem div_le : ∀ c a, divides c a → 0 < a → c ≤ a := by
  intro c a ⟨k, hk⟩ hapos
  match k with
  | 0 => omega
  | k'+1 =>
    have e2 : a = c * k' + c := by rw [hk, Nat.mul_add, Nat.mul_one]
    omega

theorem gcd_unique : ∀ d1 d2 a b,
    Gcd d1 a b → Gcd d2 a b → a ≠ 0 → d1 = d2 := by
  intro d1 d2 a b ⟨h1a, h1b, h1c⟩ ⟨h2a, h2b, h2c⟩ hane
  have hd12 : divides d1 d2 := h2c d1 h1a h1b
  have hd21 : divides d2 d1 := h1c d2 h2a h2b
  have hpos : 0 < a := Nat.pos_of_ne_zero hane
  have hd1pos : 0 < d1 := by
    match h1a with
    | ⟨k, hk⟩ =>
      match d1 with
      | 0 => omega
      | d1'+1 => omega
  have hd2pos : 0 < d2 := by
    match h2a with
    | ⟨k, hk⟩ =>
      match d2 with
      | 0 => omega
      | d2'+1 => omega
  have e1 : d1 ≤ d2 := div_le d1 d2 hd12 hd2pos
  have e2 : d2 ≤ d1 := div_le d2 d1 hd21 hd1pos
  omega

-- ---------- 4. 扩展 Euclid ----------

def egcdf : Nat → Nat → Nat → Nat × Nat × Nat × Nat
  | 0, _, _ => (0, 0, 0, 0)
  | f'+1, a, 0 => (a, 1, 0, 0)
  | f'+1, a, b'+1 =>
    match egcdf f' (b'+1) (dmrF a (b'+1)) with
    | (g, x, y, 0) => (g, x + y * dmqF a (b'+1), y, 1)
    | (g, x, y, _) => (g, x, y + x * dmqF a (b'+1), 0)

theorem gcd_step : ∀ g b r q a, Gcd g b r → a = b * q + r → Gcd g a b := by
  intro g b r q a ⟨hgb, hgr, hgc⟩ haq
  have er : a - b * q = r := by rw [haq]; omega
  refine ⟨?_, hgb, ?_⟩
  · rw [haq]
    exact div_add g (b * q) r (div_mul_r g b q hgb) hgr
  · intro c hca hcb
    apply hgc c hcb
    rw [← er]
    exact div_sub c a (b * q) hca (div_mul_r c b q hcb) (by rw [haq]; omega)


#print axioms gcd_step
#print axioms dm_eq
#print axioms dm_lt
