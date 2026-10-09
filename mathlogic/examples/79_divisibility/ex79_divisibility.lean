/- ex45 —— 整除性与初等数论（Jongsma §3.5）Lean 镜像
   divides 基本律 / 除法算式 dm2 / 扩展 Euclid egcdf / Gcd 刻画 + Bézout 差形式 /
   Euclid 引理 / gcd·lcm / 素因子存在 + 素数无穷。账本见文件尾。
   裸 core 无 ring：多项式恒等式走 AC-simp。
   AC-simp 常态下会留「unused simp argument」linter 警告（规范化用不上全部引理），
   此处统一关闭该 linter——它们不是证明问题。 -/
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false

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

-- 燃料预算的纯算术引理：提到顶层避免 ∃-上下文里的 omega 拉经典
theorem egcdf_fuel_small (a b' f' : Nat)
    (Hf : a + 2 * (b'+1) + 1 ≤ f'+1)
    (hab : a ≤ b')
    (hs : dmrF a (b'+1) = a) :
    (b'+1) + 2 * dmrF a (b'+1) + 1 ≤ f' := by rw [hs]; omega

theorem egcdf_fuel_le (a b' f' : Nat)
    (Hf : a + 2 * (b'+1) + 1 ≤ f'+1)
    (hr : dmrF a (b'+1) < b'+1) (hb : b'+1 ≤ a) :
    (b'+1) + 2 * dmrF a (b'+1) + 1 ≤ f' := by omega

theorem egcdf_spec : ∀ f a b, a + 2 * b + 1 ≤ f →
    ∃ g x y s,
      egcdf f a b = (g, x, y, s) ∧ Gcd g a b ∧
      ((s = 0 ∧ x * a = y * b + g) ∨ (s = 1 ∧ x * b = y * a + g)) := by
  intro f
  induction f with
  | zero => intro a b hf; exact absurd hf (by omega)
  | succ f' ih =>
    intro a b _
    match b with
    | 0 =>
        refine ⟨a, 1, 0, 0, rfl, ⟨div_refl a, div_zero_r a, ?_⟩, Or.inl ⟨rfl, by omega⟩⟩
        intro c hc1 _
        exact hc1
    | b'+1 =>
        have haq : a = (b'+1) * dmqF a (b'+1) + dmrF a (b'+1) := dm_eq a (b'+1)
        have hr : dmrF a (b'+1) < b'+1 := dm_lt a (b'+1) (by omega)
        have hfuel : (b'+1) + 2 * dmrF a (b'+1) + 1 ≤ f' := by
          match Nat.lt_or_ge a (b'+1) with
          | .inl hab =>
              have hs : dmrF a (b'+1) = a := by
                show (dm2 a a (b'+1)).2 = a
                rw [dm2_small a a (b'+1) (by omega)]
              exact egcdf_fuel_small a b' f' (by omega) (by omega) hs
          | .inr hge =>
              exact egcdf_fuel_le a b' f' (by omega) hr (by omega)
        match ih (b'+1) (dmrF a (b'+1)) hfuel with
        | ⟨g, x, y, s, heq, hgcd, hform⟩ =>
          match hform with
          | Or.inl ⟨hs0, hbe⟩ =>
              subst hs0
              have hstep : Gcd g a (b'+1) :=
                gcd_step g (b'+1) (dmrF a (b'+1)) (dmqF a (b'+1)) a hgcd haq
              have eqn : (x + y * dmqF a (b'+1)) * (b'+1) = y * a + g := by
                have ha' : y * a = y * ((b'+1) * dmqF a (b'+1) + dmrF a (b'+1)) :=
                  congrArg (fun t => y * t) haq
                rw [ha', Nat.add_mul, hbe]
                simp [Nat.mul_add, Nat.add_comm, Nat.add_assoc, Nat.add_left_comm,
                      Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
              refine ⟨g, x + y * dmqF a (b'+1), y, 1, ?_, hstep, Or.inr ⟨rfl, eqn⟩⟩
              show (match egcdf f' (b'+1) (dmrF a (b'+1)) with
                    | (g0, x0, y0, 0) => (g0, x0 + y0 * dmqF a (b'+1), y0, 1)
                    | (g0, x0, y0, _) => (g0, x0, y0 + x0 * dmqF a (b'+1), 0)) = _
              rw [heq]
          | Or.inr ⟨hs1, hbe⟩ =>
              subst hs1
              have hstep : Gcd g a (b'+1) :=
                gcd_step g (b'+1) (dmrF a (b'+1)) (dmqF a (b'+1)) a hgcd haq
              have eqn : x * a = (y + x * dmqF a (b'+1)) * (b'+1) + g := by
                have ha' : x * a = x * ((b'+1) * dmqF a (b'+1) + dmrF a (b'+1)) :=
                  congrArg (fun t => x * t) haq
                rw [ha', Nat.mul_add, Nat.add_mul, hbe]
                simp [Nat.mul_add, Nat.add_mul, Nat.add_comm, Nat.add_assoc, Nat.add_left_comm,
                      Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
              refine ⟨g, x, y + x * dmqF a (b'+1), 0, ?_, hstep, Or.inl ⟨rfl, eqn⟩⟩
              show (match egcdf f' (b'+1) (dmrF a (b'+1)) with
                    | (g0, x0, y0, 0) => (g0, x0 + y0 * dmqF a (b'+1), y0, 1)
                    | (g0, x0, y0, _) => (g0, x0, y0 + x0 * dmqF a (b'+1), 0)) = _
              rw [heq]

def gcdn (a b : Nat) : Nat := (egcdf (a + 2 * b + 1) a b).1

theorem gcdn_gcd : ∀ a b, Gcd (gcdn a b) a b := by
  intro a b
  match egcdf_spec (a + 2 * b + 1) a b (by omega) with
  | ⟨g, x, y, s, heq, hgcd, _⟩ =>
    show Gcd (egcdf (a + 2 * b + 1) a b).1 a b
    rw [heq]
    exact hgcd

theorem bezout : ∀ a b,
    ∃ x y, (x * a = y * b + gcdn a b) ∨ (x * b = y * a + gcdn a b) := by
  intro a b
  match egcdf_spec (a + 2 * b + 1) a b (by omega) with
  | ⟨g, x, y, s, heq, _, hform⟩ =>
    have hg : gcdn a b = g := by unfold gcdn; rw [heq]
    refine ⟨x, y, ?_⟩
    rw [hg]
    exact hform.elim (fun ⟨_, h⟩ => Or.inl h) (fun ⟨_, h⟩ => Or.inr h)

-- ---------- 5. Euclid 引理 ----------

theorem euclid_lemma : ∀ d a b, Gcd 1 d a → divides d (a * b) → divides d b := by
  intro d a b hgcd hab
  match d with
  | 0 =>
      match hab with
      | ⟨k, hk⟩ =>
        match a with
        | 0 =>
            exfalso
            have hc : divides 2 1 := hgcd.2.2 2 ⟨0, by omega⟩ ⟨0, by omega⟩
            match hc with
            | ⟨k', hk'⟩ => omega
        | a'+1 =>
            match b with
            | 0 => exact ⟨0, by omega⟩
            | b'+1 =>
                exfalso
                have e : (a'+1) * (b'+1) = (a'+1) * b' + (a'+1) := by
                  rw [Nat.mul_add, Nat.mul_one]
                rw [hk] at e
                omega
  | d'+1 =>
      have h1 : gcdn (d'+1) a = 1 :=
        gcd_unique _ 1 (d'+1) a (gcdn_gcd _ _) hgcd (by omega)
      match bezout (d'+1) a with
      | ⟨x, y, Or.inl hf⟩ =>
          rw [h1] at hf
          have h1d : divides (d'+1) (x * (d'+1) * b) :=
            ⟨x * b, by simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]⟩
          have h2d : divides (d'+1) (y * (a * b)) := div_mul_l _ _ _ hab
          have step : x * (d'+1) * b = y * (a * b) + b := by
            rw [hf, Nat.add_mul]
            simp [Nat.mul_add, Nat.add_mul, Nat.add_comm, Nat.add_assoc, Nat.add_left_comm,
                  Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
          have hbd : b = x * (d'+1) * b - y * (a * b) := by omega
          rw [hbd]
          exact div_sub _ _ _ h1d h2d (by omega)
      | ⟨x, y, Or.inr hf⟩ =>
          rw [h1] at hf
          have h1d : divides (d'+1) (x * (a * b)) := div_mul_l _ _ _ hab
          have h2d : divides (d'+1) (y * (d'+1) * b) :=
            ⟨y * b, by simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]⟩
          have step : x * (a * b) = y * (d'+1) * b + b := by
            rw [← Nat.mul_assoc, hf, Nat.add_mul]
            simp [Nat.mul_add, Nat.add_mul, Nat.add_comm, Nat.add_assoc, Nat.add_left_comm,
                  Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
          have hbd : b = x * (a * b) - y * (d'+1) * b := by omega
          rw [hbd]
          exact div_sub _ _ _ h1d h2d (by omega)

def prime (p : Nat) : Prop :=
  2 ≤ p ∧ ∀ d, divides d p → d = 1 ∨ d = p

theorem euclid_prime : ∀ p a b,
    prime p → divides p (a * b) → ¬ divides p a → divides p b := by
  intro p a b ⟨hp, hd⟩ hab hpa
  have hg : Gcd (gcdn p a) p a := gcdn_gcd p a
  match hd (gcdn p a) hg.1 with
  | Or.inl h1 =>
      have hg' : Gcd 1 p a := by rw [← h1]; exact hg
      exact euclid_lemma p a b hg' hab
  | Or.inr hp0 =>
      exfalso
      exact hpa (by rw [← hp0]; exact hg.2.1)

-- ---------- 6. gcd·lcm = a·b ----------

def Lcm (l a b : Nat) : Prop :=
  divides a l ∧ divides b l ∧ (∀ q, divides a q → divides b q → divides l q)

theorem mul_cancel_r : ∀ x y d, d ≠ 0 → x * d = y * d → x = y := by
  intro x y d hd hxy
  match Nat.lt_trichotomy x y with
  | .inl hlt =>
      exfalso
      cases hji : (y - x) with
      | zero => omega
      | succ j' =>
        have hm : y = x + (j' + 1) := by omega
        have e2 : y * d = x * d + (j' + 1) * d := by rw [hm, Nat.add_mul]
        have e4 : (j' + 1) * d = j' * d + d := by rw [Nat.add_mul, Nat.one_mul]
        omega
  | .inr (Or.inl heq) => exact heq
  | .inr (Or.inr hgt) =>
      exfalso
      cases hji : (x - y) with
      | zero => omega
      | succ j' =>
        have hm : x = y + (j' + 1) := by omega
        have e2 : x * d = y * d + (j' + 1) * d := by rw [hm, Nat.add_mul]
        have e4 : (j' + 1) * d = j' * d + d := by rw [Nat.add_mul, Nat.one_mul]
        omega

theorem mul_cancel_l : ∀ d x y, d ≠ 0 → d * x = d * y → x = y := by
  intro d x y hd hxy
  exact mul_cancel_r x y d hd (by rw [Nat.mul_comm x d, Nat.mul_comm y d]; exact hxy)

theorem gcd_lcm_product : ∀ a b, 1 ≤ a → 1 ≤ b →
    ∃ l, Lcm l a b ∧ gcdn a b * l = a * b := by
  intro a b ha hb
  have hg : Gcd (gcdn a b) a b := gcdn_gcd a b
  match hg.1 with
  | ⟨m, hm⟩ =>
    match hg.2.1 with
    | ⟨n, hn⟩ =>
      have hd0 : gcdn a b ≠ 0 := by
        cases hE : (gcdn a b) with
        | zero =>
            rw [hE] at hm
            omega
        | succ g0' => omega
      have hla : gcdn a b * m * n = a * n := by rw [← hm]
      have hlb : gcdn a b * m * n = b * m := by
        rw [Nat.mul_assoc, Nat.mul_comm m n, ← Nat.mul_assoc, ← hn]
      have hp2 : a * b = gcdn a b * (gcdn a b * m * n) := by
        have e1 : a * b = (gcdn a b * m) * (gcdn a b * n) :=
          (congrArg (fun t => t * b) hm).trans (congrArg (fun t => (gcdn a b * m) * t) hn)
        rw [e1]
        simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
      refine ⟨gcdn a b * m * n, ⟨⟨n, hla⟩, ⟨m, hlb⟩, ?_⟩, hp2.symm⟩
      intro q hs ht
      match hs with
      | ⟨s, hs'⟩ =>
      match ht with
      | ⟨t, ht'⟩ =>
      match bezout a b with
      | ⟨x, y, Or.inl hf⟩ =>
          have hchain : (x * t) * (a * b) = (y * s) * (a * b) + gcdn a b * q := by
            have e1 : x * a * q = y * b * q + gcdn a b * q := by
              rw [hf, Nat.add_mul]
            have e2 : x * a * q = (x * t) * (a * b) := by
              rw [ht']
              simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
            have e3 : y * b * q = (y * s) * (a * b) := by
              rw [hs']
              simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
            omega
          have hab : a * b = gcdn a b * (gcdn a b * m * n) := hp2
          rw [hab] at hchain
          have hc : gcdn a b * (gcdn a b * m * n * (x * t))
                   = gcdn a b * (gcdn a b * m * n * (y * s)) + gcdn a b * q := by
            have ha' : gcdn a b * (gcdn a b * m * n * (x * t))
                       = (x * t) * (gcdn a b * (gcdn a b * m * n)) := by
              simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
            have hb' : gcdn a b * (gcdn a b * m * n * (y * s)) + gcdn a b * q
                       = (y * s) * (gcdn a b * (gcdn a b * m * n)) + gcdn a b * q := by
              simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
            rw [ha', hb']
            exact hchain
          have hcf : gcdn a b * (gcdn a b * m * n * (x * t))
                     = gcdn a b * (gcdn a b * m * n * (y * s) + q) := by
            rw [Nat.mul_add]; omega
          have h7 : gcdn a b * m * n * (x * t)
                    = gcdn a b * m * n * (y * s) + q :=
            mul_cancel_l _ _ _ hd0 hcf
          have hqXY : q = gcdn a b * m * n * (x * t) - gcdn a b * m * n * (y * s) := by omega
          rw [hqXY]
          exact div_sub _ _ _ ⟨x * t, rfl⟩ ⟨y * s, rfl⟩ (by omega)
      | ⟨x, y, Or.inr hf⟩ =>
          have hchain : (x * s) * (a * b) = (y * t) * (a * b) + gcdn a b * q := by
            have e1 : x * b * q = y * a * q + gcdn a b * q := by
              rw [hf, Nat.add_mul]
            have e2 : x * b * q = (x * s) * (a * b) := by
              rw [hs']
              simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
            have e3 : y * a * q = (y * t) * (a * b) := by
              rw [ht']
              simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
            omega
          have hab : a * b = gcdn a b * (gcdn a b * m * n) := hp2
          rw [hab] at hchain
          have hc : gcdn a b * (gcdn a b * m * n * (x * s))
                   = gcdn a b * (gcdn a b * m * n * (y * t)) + gcdn a b * q := by
            have ha' : gcdn a b * (gcdn a b * m * n * (x * s))
                       = (x * s) * (gcdn a b * (gcdn a b * m * n)) := by
              simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
            have hb' : gcdn a b * (gcdn a b * m * n * (y * t)) + gcdn a b * q
                       = (y * t) * (gcdn a b * (gcdn a b * m * n)) + gcdn a b * q := by
              simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]
            rw [ha', hb']
            exact hchain
          have hcf : gcdn a b * (gcdn a b * m * n * (x * s))
                     = gcdn a b * (gcdn a b * m * n * (y * t) + q) := by
            rw [Nat.mul_add]; omega
          have h7 : gcdn a b * m * n * (x * s)
                    = gcdn a b * m * n * (y * t) + q :=
            mul_cancel_l _ _ _ hd0 hcf
          have hqXY : q = gcdn a b * m * n * (x * s) - gcdn a b * m * n * (y * t) := by omega
          rw [hqXY]
          exact div_sub _ _ _ ⟨x * s, rfl⟩ ⟨y * t, rfl⟩ (by omega)

-- ---------- 7. 素因子存在与素数无穷 ----------

def dvbAux : Nat → Nat → Nat → Bool
  | 0, d, n => decide (d * 0 = n)
  | j'+1, d, n => decide (d * (j'+1) = n) || dvbAux j' d n

def dvb (d n : Nat) : Bool := dvbAux n d n

theorem dvbAux_true : ∀ j d n, dvbAux j d n = true → ∃ k, k ≤ j ∧ d * k = n := by
  intro j
  induction j with
  | zero =>
    intro d n h
    simp only [dvbAux] at h
    have e : d * 0 = n := of_decide_eq_true h
    exact ⟨0, by omega, by omega⟩
  | succ j' ih =>
    intro d n h
    simp only [dvbAux, Bool.or_eq_true] at h
    match h with
    | Or.inl hc => exact ⟨j'+1, Nat.le_refl _, of_decide_eq_true hc⟩
    | Or.inr hc =>
      match ih d n hc with
      | ⟨k, hk1, hk2⟩ => exact ⟨k, Nat.le_succ_of_le hk1, hk2⟩

theorem dvbAux_of : ∀ j d n k, k ≤ j → d * k = n → dvbAux j d n = true := by
  intro j d
  induction j with
  | zero =>
    intro n k hk hdk
    have hk0 : k = 0 := Nat.le_zero.mp hk
    show (decide (d * 0 = n)) = true
    rw [hk0] at hdk
    rw [decide_eq_true hdk]
  | succ j' ih =>
    intro n k hk hdk
    match Nat.lt_or_ge k (j'+1) with
    | .inl hlt =>
        have hkj' : k ≤ j' := by omega
        show (decide (d * (j'+1) = n) || dvbAux j' d n) = true
        rw [ih n k hkj' hdk]
        exact Bool.or_true _
    | .inr hge =>
        have heq : k = j'+1 := by omega
        subst heq
        show (decide (d * (j'+1) = n) || dvbAux j' d n) = true
        rw [decide_eq_true hdk]
        exact Bool.true_or _

theorem dvb_true : ∀ d n, dvb d n = true → divides d n := by
  intro d n h
  match dvbAux_true n d n h with
  | ⟨k, _, hk2⟩ => exact ⟨k, hk2.symm⟩

theorem bounded_dec : ∀ (p : Nat → Bool) n,
    (∃ d, d ≤ n ∧ p d = true) ∨ (∀ d, d ≤ n → p d = false) := by
  intro p n
  induction n with
  | zero =>
    cases hc : p 0 with
    | true => exact Or.inl ⟨0, Nat.zero_le 0, hc⟩
    | false =>
      exact Or.inr (fun d hd => by
        have : d = 0 := Nat.le_zero.mp hd
        rw [this]; exact hc)
  | succ k ih =>
    cases ih with
    | inl hex =>
      match hex with
      | ⟨d, hd1, hd2⟩ => exact Or.inl ⟨d, Nat.le_succ_of_le hd1, hd2⟩
    | inr hno =>
      cases hc : p (k+1) with
      | true => exact Or.inl ⟨k+1, Nat.le_refl _, hc⟩
      | false =>
        exact Or.inr (fun d hd => by
          match Nat.lt_or_ge d (k+1) with
          | .inl hlt => exact hno d (Nat.le_of_lt_succ hlt)
          | .inr hge => rw [Nat.le_antisymm hd hge]; exact hc)

theorem strong_ind45 {P : Nat → Prop}
    (h : ∀ n, (∀ m, m < n → P m) → P n) : ∀ n, P n := by
  have aux : ∀ k m, m ≤ k → P m := by
    intro k
    induction k with
    | zero =>
      intro m hm; apply h; intro j hj
      exact absurd (Nat.lt_of_lt_of_le hj hm) (Nat.not_lt_zero j)
    | succ k ih => intro m hm; apply h; intro j hj; apply ih; omega
  intro n
  exact aux n n (Nat.le_refl n)

def properFac (d n : Nat) : Bool :=
  decide (2 ≤ d) && (decide (2 * d ≤ n) && dvb d n)

theorem prime_fac : ∀ n, 2 ≤ n → ∃ p, prime p ∧ divides p n := by
  apply strong_ind45 (P := fun n => 2 ≤ n → ∃ p, prime p ∧ divides p n)
  intro n0 IH Hn
  cases bounded_dec (fun d => properFac d n0) n0 with
  | inl hex =>
    match hex with
    | ⟨d, _, hdq⟩ =>
      clear hex
      rw [properFac, Bool.and_eq_true] at hdq
      match hdq with
      | ⟨ha, hb⟩ =>
        rw [Bool.and_eq_true] at hb
        match hb with
        | ⟨hbb, hbe⟩ =>
          have hd2 : 2 ≤ d := of_decide_eq_true ha
          have h2d : 2 * d ≤ n0 := of_decide_eq_true hbb
          have hlt : d < n0 := by omega
          match IH d hlt hd2 with
          | ⟨p, hp, hpd⟩ =>
            match dvb_true d n0 hbe with
            | ⟨k2, hk2⟩ =>
              match hpd with
              | ⟨k1, hk1⟩ =>
                exact ⟨p, hp, k1 * k2, by
                  rw [hk1] at hk2
                  rw [hk2]
                  simp [Nat.mul_assoc]⟩
  | inr Hno =>
    refine ⟨n0, ⟨Hn, ?_⟩, 1, by rw [Nat.mul_one]⟩
    intro d hd
    match d with
    | 0 =>
      match hd with
      | ⟨k, hk⟩ => exfalso; omega
    | 1 => exact Or.inl rfl
    | d'+2 =>
      match hd with
      | ⟨k, hk⟩ =>
      clear hd
      match k with
        | 0 => exfalso; omega
        | 1 => rw [Nat.mul_one] at hk; exact Or.inr hk.symm
        | j+2 =>
          have hle2 : 2 * (d'+2) ≤ n0 := by
            have h1 : 2 * (d'+2) ≤ (j+2) * (d'+2) :=
              Nat.mul_le_mul_right _ (by omega)
            rw [Nat.mul_comm (j+2) (d'+2)] at h1
            omega
          have hle3 : (j+2) ≤ n0 := by
            rw [hk]
            exact Nat.le_mul_of_pos_left _ (by omega)
          have htrue : properFac (d'+2) n0 = true := by
            rw [properFac, Bool.and_eq_true]
            exact ⟨decide_eq_true (show 2 ≤ d'+2 by omega),
                   by rw [Bool.and_eq_true]
                      exact ⟨decide_eq_true hle2,
                              dvbAux_of n0 (d'+2) n0 (j+2) hle3 hk.symm⟩⟩
          have hle4 : d'+2 ≤ n0 := by
            rw [hk]
            exact Nat.le_mul_of_pos_right _ (by omega)
          have hcontra := Hno (d'+2) hle4
          rw [htrue] at hcontra
          exact Bool.noConfusion hcontra

-- 素数无穷：任意素数有限表之外必有素数
def prodL : List Nat → Nat
  | [] => 1
  | x :: t => x * prodL t

theorem div_prod_mem : ∀ (l : List Nat) d, d ∈ l → divides d (prodL l) := by
  intro l
  induction l with
  | nil => intro d h; cases h
  | cons x t ih =>
    intro d h
    match (List.mem_cons.mp h) with
    | Or.inl he => rw [he]; exact ⟨prodL t, rfl⟩
    | Or.inr ht =>
      match ih d ht with
      | ⟨k, hk⟩ =>
        refine ⟨x * k, ?_⟩
        show x * prodL t = d * (x * k)
        rw [hk]
        simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]

theorem prodL_pos : ∀ l : List Nat, (∀ n, n ∈ l → 2 ≤ n) → 1 ≤ prodL l := by
  intro l
  induction l with
  | nil => intro _; exact Nat.le_refl 1
  | cons x t ih =>
    intro h
    have hx2 : 2 ≤ x := h x (List.Mem.head _)
    have hx : 1 ≤ x := by omega
    have ht : 1 ≤ prodL t := ih (fun n hn => h n (List.Mem.tail _ hn))
    have hh : 1 * 1 ≤ x * prodL t := Nat.mul_le_mul hx ht
    show 1 ≤ x * prodL t
    omega

theorem inf_primes : ∀ L : List Nat, (∀ n, n ∈ L → prime n) →
    ∃ p, prime p ∧ ¬ (p ∈ L) := by
  intro L Hall
  have hp2 : ∀ n, n ∈ L → 2 ≤ n := fun n hn => (Hall n hn).1
  have h1 : 1 ≤ prodL L := prodL_pos L hp2
  have h2 : 2 ≤ prodL L + 1 := by omega
  match prime_fac (prodL L + 1) h2 with
  | ⟨p, hp, hpm⟩ =>
    refine ⟨p, hp, ?_⟩
    intro hin
    have hpp : divides p (prodL L) := div_prod_mem L p hin
    match hpm with
    | ⟨k1, hk1⟩ =>
      match hpp with
      | ⟨k2, hk2⟩ =>
        clear hpm hpp
        have hp2 : 2 ≤ p := hp.1
        have hle : p * k2 ≤ p * k1 := by omega
        have hk21 : k2 ≤ k1 := Nat.le_of_mul_le_mul_left hle (by omega)
        have h1eq : 1 = p * (k1 - k2) := by
          have hj : k1 = k2 + (k1 - k2) := by omega
          have e : p * k1 = p * k2 + p * (k1 - k2) :=
            (congrArg (fun t => p * t) hj).trans (Nat.mul_add p k2 (k1 - k2))
          omega
        cases hji : (k1 - k2) with
        | zero =>
            rw [hji, Nat.mul_zero] at h1eq
            omega
        | succ j' =>
            have e : p * (j' + 1) = p * j' + p := by rw [Nat.mul_add, Nat.mul_one]
            rw [hji, e] at h1eq
            omega

-- ---------- 8. 冒烟与账本 ----------

#eval gcdn 36 128
#eval gcdn 15 49
#eval gcdn 56 472
#eval (dmrF 128 36, dmqF 128 36)

#print axioms gcdn_gcd
#print axioms bezout
#print axioms euclid_prime
#print axioms gcd_lcm_product
#print axioms inf_primes
