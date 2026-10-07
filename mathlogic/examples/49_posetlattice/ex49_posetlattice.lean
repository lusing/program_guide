/- ex49 —— 偏序与格（Jongsma ch7 §7.1-7.2）Lean 镜像
   整除偏序三律+不连通、lub/glb 唯一性、(ℕ,≤) 格代数律全家
   （特征引理装配）、五点菱形非分配格反例。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. 整除偏序 ----------

def divides (a b : Nat) : Prop := ∃ k, b = a * k

theorem dvd_refl : ∀ n, divides n n := fun n => ⟨1, by omega⟩

theorem dvd_trans : ∀ a b c, divides a b → divides b c → divides a c := by
  intro a b c ⟨k1, h1⟩ ⟨k2, h2⟩
  exact ⟨k1 * k2, by rw [h2, h1]; simp [Nat.mul_assoc]⟩

theorem dvd_antisym : ∀ a b, divides a b → divides b a → a = b := by
  intro a b ⟨k1, h1⟩ ⟨k2, h2⟩
  cases a with
  | zero =>
      rw [h1, Nat.zero_mul]
  | succ a' =>
      -- a ≠ 0：a = b*k2 = (a*k1)*k2 = a*(k1*k2)，消去 a 得 k1*k2 = 1
      rw [h1] at h2
      have e0 : (a'+1) = (a'+1) * (k1 * k2) :=
        h2.trans (Nat.mul_assoc (a'+1) k1 k2)
      cases k1 with
      | zero =>
          rw [Nat.zero_mul] at e0
          omega
      | succ k1' =>
          cases k2 with
          | zero =>
              rw [Nat.mul_zero] at e0
              omega
          | succ k2' =>
              -- 乘法消去（a'+1 > 0）：(k1'+1)*(k2'+1) = 1
              have hS : (a'+1) * 1 = (a'+1) * ((k1'+1) * (k2'+1)) :=
                (Nat.mul_one (a'+1)).trans e0
              have hP : 1 = (k1'+1) * (k2'+1) :=
                Nat.mul_left_cancel (Nat.succ_pos a') hS
              -- succ_mul 展开；omega 会静默丢弃无非线性字面量的原子
              -- （hP 整条被扔）——先手工蒸成线性等式再交给 omega
              have e2 : (k1'+1) * (k2'+1) = k1' * (k2'+1) + (k2'+1) :=
                Nat.succ_mul k1' (k2'+1)
              have hLin : 1 = k1' * (k2'+1) + (k2'+1) := hP.trans e2
              -- omega 直证合取目标会拉 Classical.choice——拆成单目标
              have hT1 : k1' * (k2'+1) = 0 := by omega
              have hT2 : k2' = 0 := by omega
              have hk1 : k1' = 0 := by
                match Nat.mul_eq_zero.mp hT1 with
                | Or.inl h => exact h
                | Or.inr h => omega
              rw [hk1, Nat.zero_add, Nat.mul_one] at h1
              exact h1.symm

theorem not_conn : ¬ (divides 2 3) ∧ ¬ (divides 3 2) := by
  refine ⟨?_, ?_⟩
  · intro ⟨k, hk⟩
    match k with
    | 0 => omega
    | 1 => omega
    | 2 => omega
    | j+3 => omega
  · intro ⟨k, hk⟩
    match k with
    | 0 => omega
    | 1 => omega
    | j+2 => omega

-- ---------- 2. lub/glb 唯一性 ----------

def islub (R : Nat → Nat → Prop) (u x y : Nat) : Prop :=
  R x u ∧ R y u ∧ ∀ z, R x z → R y z → R u z

def isglb (R : Nat → Nat → Prop) (l x y : Nat) : Prop :=
  R l x ∧ R l y ∧ ∀ z, R z x → R z y → R z l

theorem lub_unique' : ∀ R x y u1 u2,
    (∀ a b, R a b → R b a → a = b) →
    islub R u1 x y → islub R u2 x y → u1 = u2 := by
  intro R x y u1 u2 hanti h1 h2
  have hu12 : R u1 u2 := h1.2.2 u2 h2.1 h2.2.1
  have hu21 : R u2 u1 := h2.2.2 u1 h1.1 h1.2.1
  exact hanti u1 u2 hu12 hu21

theorem glb_unique' : ∀ R x y l1 l2,
    (∀ a b, R a b → R b a → a = b) →
    isglb R l1 x y → isglb R l2 x y → l1 = l2 := by
  intro R x y l1 l2 hanti h1 h2
  have hl21 : R l1 l2 := h2.2.2 l1 h1.1 h1.2.1
  have hl12 : R l2 l1 := h1.2.2 l2 h2.1 h2.2.1
  exact hanti l1 l2 hl21 hl12

-- ---------- 3. (ℕ, ≤) 全序格 ----------

def mmax (x y : Nat) : Nat := if x ≤ y then y else x
def mmin (x y : Nat) : Nat := if x ≤ y then x else y

theorem mmax_big : ∀ x y, x ≤ y → mmax x y = y := by
  intro x y h
  show (if x ≤ y then y else x) = y
  rw [if_pos h]

theorem mmax_sml : ∀ x y, y ≤ x → mmax x y = x := by
  intro x y h
  show (if x ≤ y then y else x) = x
  match Nat.lt_trichotomy x y with
  | .inl hlt => omega
  | .inr (Or.inl heq) => rw [if_pos (by omega)]; exact heq.symm
  | .inr (Or.inr hgt) => rw [if_neg (by omega)]

theorem mmin_sml : ∀ x y, x ≤ y → mmin x y = x := by
  intro x y h
  show (if x ≤ y then x else y) = x
  rw [if_pos h]

theorem mmin_big : ∀ x y, y ≤ x → mmin x y = y := by
  intro x y h
  show (if x ≤ y then x else y) = y
  match Nat.lt_trichotomy x y with
  | .inl hlt => rw [if_neg (by omega)]
  | .inr (Or.inl heq) => rw [if_pos (by omega)]; exact heq
  | .inr (Or.inr hgt) => rw [if_neg (by omega)]

theorem mmax_ub : ∀ x y, x ≤ mmax x y ∧ y ≤ mmax x y := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      have hb : mmax x y = y := mmax_big x y (Nat.le_of_lt hlt)
      rw [hb]
      exact ⟨Nat.le_of_lt hlt, Nat.le_refl y⟩
  | .inr hge =>
      have hs : mmax x y = x := mmax_sml x y hge
      rw [hs]
      exact ⟨Nat.le_refl x, hge⟩

theorem mmin_lb : ∀ x y, mmin x y ≤ x ∧ mmin x y ≤ y := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      have hs : mmin x y = x := mmin_sml x y (Nat.le_of_lt hlt)
      rw [hs]
      exact ⟨Nat.le_refl x, Nat.le_of_lt hlt⟩
  | .inr hge =>
      have hb : mmin x y = y := mmin_big x y hge
      rw [hb]
      exact ⟨hge, Nat.le_refl y⟩

theorem mmax_islub : ∀ x y, islub Nat.le (mmax x y) x y := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      have hb : mmax x y = y := mmax_big x y (Nat.le_of_lt hlt)
      exact ⟨by rw [hb]; exact Nat.le_of_lt hlt,
             by rw [hb]; exact Nat.le_refl y,
             fun z hz1 hz2 => by rw [hb]; omega⟩
  | .inr hge =>
      have hs : mmax x y = x := mmax_sml x y hge
      exact ⟨by rw [hs]; exact Nat.le_refl x,
             by rw [hs]; exact hge,
             fun z hz1 hz2 => by rw [hs]; omega⟩

theorem mmin_isglb : ∀ x y, isglb Nat.le (mmin x y) x y := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      have hs : mmin x y = x := mmin_sml x y (Nat.le_of_lt hlt)
      exact ⟨by rw [hs]; exact Nat.le_refl x,
             by rw [hs]; exact Nat.le_of_lt hlt,
             fun z hz1 hz2 => by rw [hs]; omega⟩
  | .inr hge =>
      have hb : mmin x y = y := mmin_big x y hge
      exact ⟨by rw [hb]; exact hge,
             by rw [hb]; exact Nat.le_refl y,
             fun z hz1 hz2 => by rw [hb]; omega⟩

theorem mmax_comm : ∀ x y, mmax x y = mmax y x := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      rw [mmax_big x y (Nat.le_of_lt hlt), mmax_sml y x (Nat.le_of_lt hlt)]
  | .inr hge =>
      rw [mmax_sml x y hge, mmax_big y x hge]

theorem mmin_comm : ∀ x y, mmin x y = mmin y x := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      rw [mmin_sml x y (Nat.le_of_lt hlt), mmin_big y x (Nat.le_of_lt hlt)]
  | .inr hge =>
      rw [mmin_big x y hge, mmin_sml y x hge]

theorem mmax_idem : ∀ x, mmax x x = x := fun x => mmax_big x x (Nat.le_refl x)

theorem mmin_idem : ∀ x, mmin x x = x := fun x => mmin_sml x x (Nat.le_refl x)

theorem mmin_absorb : ∀ x y, mmin x (mmax x y) = x := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      rw [mmax_big x y (Nat.le_of_lt hlt), mmin_sml x y (Nat.le_of_lt hlt)]
  | .inr hge =>
      rw [mmax_sml x y hge, mmin_idem x]

theorem mmax_absorb : ∀ x y, mmax x (mmin x y) = x := by
  intro x y
  match Nat.lt_or_ge x y with
  | .inl hlt =>
      rw [mmin_sml x y (Nat.le_of_lt hlt), mmax_idem x]
  | .inr hge =>
      rw [mmin_big x y hge, mmax_sml x y hge]

theorem mmin_over_mmax : ∀ x y z,
    mmin x (mmax y z) = mmax (mmin x y) (mmin x z) := by
  intro x y z
  match Nat.lt_or_ge y z with
  | .inl hyz =>
      rw [mmax_big y z (Nat.le_of_lt hyz)]
      match Nat.lt_or_ge x z with
      | .inl hxz =>
          rw [mmin_sml x z (Nat.le_of_lt hxz)]
          match Nat.lt_or_ge x y with
          | .inl hxy =>
              rw [mmin_sml x y (Nat.le_of_lt hxy)]
              exact mmax_idem x |>.symm
          | .inr hge =>
              rw [mmin_big x y hge, mmax_big y x hge]
      | .inr hxz =>
          rw [mmin_big x z hxz]
          match Nat.lt_or_ge x y with
          | .inl hxy =>
              rw [mmin_sml x y (Nat.le_of_lt hxy)]
              omega
          | .inr hge =>
              rw [mmin_big x y hge, mmax_big y z (Nat.le_of_lt hyz)]
  | .inr hzy =>
      rw [mmax_sml y z hzy]
      match Nat.lt_or_ge x y with
      | .inl hxy =>
          rw [mmin_sml x y (Nat.le_of_lt hxy)]
          match Nat.lt_or_ge x z with
          | .inl hxz =>
              rw [mmin_sml x z (Nat.le_of_lt hxz)]
              exact mmax_idem x |>.symm
          | .inr hxz =>
              rw [mmin_big x z hxz, mmax_sml x z hxz]
      | .inr hxy =>
          rw [mmin_big x y hxy]
          match Nat.lt_or_ge x z with
          | .inl hxz =>
              rw [mmin_sml x z (Nat.le_of_lt hxz)]
              omega
          | .inr hxz =>
              rw [mmin_big x z hxz, mmax_sml y z hzy]

-- ---------- 4. 五点菱形非分配格 ----------

def dle (x y : Nat) : Prop :=
  x = y ∨ (x = 0 ∧ y ≠ 0) ∨ (y = 4 ∧ x ≠ 4)

def djn (x y : Nat) : Nat :=
  match x, y with
  | 0, w => w
  | w, 0 => w
  | 4, _ => 4
  | _, 4 => 4
  | w1, w2 => if w1 == w2 then w1 else 4

def dmt (x y : Nat) : Nat :=
  match x, y with
  | 0, _ => 0
  | _, 0 => 0
  | 4, w => w
  | w, 4 => w
  | w1, w2 => if w1 == w2 then w1 else 0

-- dle 确是偏序（三律）；djn/dmt 确是 1、2 的 join/meet（规格件）
theorem dle_refl : ∀ x, dle x x := fun x => Or.inl rfl

theorem dle_antisym : ∀ x y, dle x y → dle y x → x = y := by
  intro x y h1 h2
  match h1, h2 with
  | Or.inl e, _ => exact e
  | _, Or.inl e => exact e.symm
  | Or.inr (Or.inl p), Or.inr (Or.inl q) => omega
  | Or.inr (Or.inl p), Or.inr (Or.inr q) => omega
  | Or.inr (Or.inr p), Or.inr (Or.inl q) => omega
  | Or.inr (Or.inr p), Or.inr (Or.inr q) => omega

theorem dle_trans : ∀ x y z, dle x y → dle y z → dle x z := by
  intro x y z h1 h2
  -- 矛盾臂不能让 omega 直接面对 Prop 目标（会拉 Classical.choice）：
  -- 一律先 by omega 出 False 再 False.elim
  match h1, h2 with
  | Or.inl e, _ => rw [e]; exact h2
  | _, Or.inl e => rw [← e]; exact h1
  | Or.inr (Or.inl p), Or.inr (Or.inl q) => exact (by omega : False).elim
  | Or.inr (Or.inl p), Or.inr (Or.inr q) =>
      exact Or.inr (Or.inl ⟨p.1, by omega⟩)
  | Or.inr (Or.inr p), Or.inr (Or.inl q) => exact (by omega : False).elim
  | Or.inr (Or.inr p), Or.inr (Or.inr q) => exact (by omega : False).elim

theorem djn_islub_12 : islub dle (djn 1 2) 1 2 := by
  show islub dle 4 1 2
  refine ⟨?_, ?_, ?_⟩
  · exact Or.inr (Or.inr ⟨rfl, by omega⟩)
  · exact Or.inr (Or.inr ⟨rfl, by omega⟩)
  · intro z hz1 hz2
    match hz1 with
    | Or.inl e =>
        match hz2 with
        | Or.inl e2 => exact (by omega : False).elim
        | Or.inr (Or.inl q) => exact (by omega : False).elim
        | Or.inr (Or.inr q) => exact (by omega : False).elim
    | Or.inr (Or.inl p) => exact (by omega : False).elim
    | Or.inr (Or.inr p) => exact Or.inl (by omega)

theorem dmt_isglb_12 : isglb dle (dmt 1 2) 1 2 := by
  show isglb dle 0 1 2
  refine ⟨?_, ?_, ?_⟩
  · exact Or.inr (Or.inl ⟨rfl, by omega⟩)
  · exact Or.inr (Or.inl ⟨rfl, by omega⟩)
  · intro z hz1 hz2
    match hz1 with
    | Or.inl e =>
        match hz2 with
        | Or.inl e2 => exact (by omega : False).elim
        | Or.inr (Or.inl q) => exact (by omega : False).elim
        | Or.inr (Or.inr q) => exact (by omega : False).elim
    | Or.inr (Or.inl p) => exact Or.inl (by omega)
    | Or.inr (Or.inr p) => exact (by omega : False).elim

theorem diamond_nondist :
    dmt 1 (djn 2 3) ≠ djn (dmt 1 2) (dmt 1 3) := by
  show (1 : Nat) ≠ 0
  intro h
  simp at h

-- ---------- 5. 冒烟与账本 ----------

#eval Nat.gcd 6 20
#eval Nat.lcm 6 20
#eval Nat.gcd 12 (Nat.lcm 12 20)

#print axioms dvd_antisym
#print axioms lub_unique'
#print axioms mmax_islub
#print axioms mmin_absorb
#print axioms mmin_over_mmax
#print axioms dle_trans
#print axioms diamond_nondist
