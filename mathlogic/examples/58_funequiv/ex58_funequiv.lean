/- ex48 —— 函数与等价关系（Jongsma ch6）Lean 镜像
   inj/surj/复合、左逆右逆（搜索构造）、congN 正规形、良定义。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. 单射/满射/复合 ----------

def inj (f : Nat → Nat) : Prop := ∀ x y, f x = f y → x = y
def surj (f : Nat → Nat) : Prop := ∀ y, ∃ x, f x = y

theorem double_inj : inj (fun n => 2 * n) := by
  intro x y h
  have h2 : 2 * x = 2 * y := h
  omega

theorem succ_not_surj : ¬ surj (fun n => n + 1) := by
  intro h
  match h 0 with
  | ⟨x, hx⟩ =>
    cases x with
    | zero => simp at hx
    | succ x' => simp at hx

theorem inj_comp : ∀ f g, inj f → inj g → inj (fun x => f (g x)) := by
  intro f g hf hg x y h
  have h2 : f (g x) = f (g y) := h
  have h3 : g x = g y := hf (g x) (g y) h2
  exact hg x y h3

theorem surj_comp : ∀ f g, surj f → surj g → surj (fun x => f (g x)) := by
  intro f g hf hg y
  match hf y with
  | ⟨z, hz⟩ =>
    match hg z with
    | ⟨x, hx⟩ => exact ⟨x, by show f (g x) = y; rw [hx]; exact hz⟩

-- ---------- 2. 左逆/右逆（搜索构造） ----------

def searchPre : (Nat → Nat) → Nat → Nat → Option Nat
  | _, _, 0 => none
  | f, n, k'+1 => if f k' == n then some k' else searchPre f n k'

theorem searchPre_some : ∀ f n k x,
    searchPre f n (k+1) = some x → f x = n ∧ x ≤ k := by
  intro f n k
  induction k with
  | zero =>
    intro x h
    cases hc : (f 0 == n) with
    | true =>
      simp only [searchPre, hc, if_true] at h
      have hx : 0 = x := by simpa using h
      subst hx
      exact ⟨of_decide_eq_true hc, Nat.le_refl 0⟩
    | false =>
      simp only [searchPre, hc, if_false] at h
      cases h
  | succ k' ih =>
    intro x h
    cases hc : (f (k'+1) == n) with
    | true =>
      simp only [searchPre, hc, if_true] at h
      have hxe : k'+1 = x := by simpa using h
      subst hxe
      exact ⟨of_decide_eq_true hc, Nat.le_refl _⟩
    | false =>
      simp only [searchPre, hc, if_false] at h
      match ih x h with
      | ⟨h1, h2⟩ => exact ⟨h1, by omega⟩

theorem searchPre_notNone : ∀ f y x d,
    f x = y → x < d → searchPre f y d ≠ none := by
  intro f y x d hfx
  induction d with
  | zero => intro hlt _; omega
  | succ d' ih =>
    intro hlt hd
    have h2 : (if f d' == y then some d' else searchPre f y d') = none := hd
    match Nat.lt_trichotomy d' x with
    | .inl _ => omega
    | .inr (Or.inl he) =>
      subst d'
      rw [show (f x == y) = decide (f x = y) from rfl, decide_eq_true hfx] at h2
      exact Option.noConfusion h2
    | .inr (Or.inr _) =>
      rw [show (f d' == y) = decide (f d' = y) from rfl] at h2
      split at h2
      · exact Option.noConfusion h2
      · exact ih (by omega) h2

def pinvB (f : Nat → Nat) (y b : Nat) : Nat :=
  match searchPre f y b with
  | some x => x
  | none => 0

-- 满射 ⇒ 右逆存在（边界 S x：原像见证）
theorem surj_right_inv : ∀ f, surj f → ∀ y, ∃ b, f (pinvB f y b) = y := by
  intro f hsurj y
  match hsurj y with
  | ⟨x, hx⟩ =>
    refine ⟨x+1, ?_⟩
    unfold pinvB
    cases hE : searchPre f y (x+1) with
    | some x' =>
      match searchPre_some f y x x' hE with
      | ⟨h1, _⟩ => exact h1
    | none =>
      exfalso
      exact searchPre_notNone f y x (x+1) hx (by omega) hE

-- 单射 ⇒ 左逆
theorem inj_left_inv : ∀ f, inj f → ∀ x, pinvB f (f x) (x+1) = x := by
  intro f hinj x
  unfold pinvB
  cases hE : searchPre f (f x) (x+1) with
  | some y =>
    match searchPre_some f (f x) x y hE with
    | ⟨h1, _⟩ => exact hinj y x h1
  | none =>
    exfalso
    exact searchPre_notNone f (f x) x (x+1) rfl (by omega) hE

-- ---------- 3. 等价关系 ----------

def eqrel (R : Nat → Nat → Prop) : Prop :=
  (∀ x, R x x) ∧ (∀ x y, R x y → R y x) ∧ (∀ x y z, R x y → R y z → R x z)

-- ---------- 4. 同余 mod n ----------

def congN (n a b : Nat) : Prop :=
  ∃ k, a + k * n = b ∨ b + k * n = a

theorem congN_normal : ∀ n a b,
    congN n a b ↔ ∃ k1 k2, a + k1 * n = b + k2 * n := by
  intro n a b
  constructor
  · intro h
    match h with
    | ⟨k, Or.inl h'⟩ => clear h; exact ⟨k, 0, by omega⟩
    | ⟨k, Or.inr h'⟩ => clear h; exact ⟨0, k, by omega⟩
  · intro h
    match h with
    | ⟨k1, k2, hk⟩ =>
      clear h
      match Nat.lt_trichotomy k1 k2 with
      | .inl hlt =>
        have hle : k1 * n ≤ k2 * n := Nat.mul_le_mul_right _ (by omega)
        have e0 : k1 * n + (k2 - k1) * n = k2 * n := by
          have h1 : (k1 + (k2 - k1)) * n = k1 * n + (k2 - k1) * n :=
            Nat.add_mul k1 (k2 - k1) n
          have hj : k1 + (k2 - k1) = k2 := by omega
          rw [hj] at h1
          exact h1.symm
        exact ⟨k2 - k1, Or.inr (by omega)⟩
      | .inr (Or.inl heq) =>
        rw [heq] at hk
        exact ⟨0, Or.inl (by omega)⟩
      | .inr (Or.inr hgt) =>
        have hle : k2 * n ≤ k1 * n := Nat.mul_le_mul_right _ (by omega)
        have e0 : k2 * n + (k1 - k2) * n = k1 * n := by
          have h1 : (k2 + (k1 - k2)) * n = k2 * n + (k1 - k2) * n :=
            Nat.add_mul k2 (k1 - k2) n
          have hj : k2 + (k1 - k2) = k1 := by omega
          rw [hj] at h1
          exact h1.symm
        exact ⟨k1 - k2, Or.inl (by omega)⟩

theorem congN_eqrel : ∀ n, eqrel (congN n) := by
  intro n
  constructor
  · intro x; exact ⟨0, Or.inl (by omega)⟩
  constructor
  · intro x y h
    match h with
    | ⟨k, Or.inl h'⟩ => exact ⟨k, Or.inr h'⟩
    | ⟨k, Or.inr h'⟩ => exact ⟨k, Or.inl h'⟩
  · -- 传递：同向直接拼、混合走正规形（match 保留 ∃ 原假设——omega 前必须 clear）
    intro x y z hy hz
    match hy with
    | ⟨k, Or.inl h1⟩ =>
      match hz with
      | ⟨j, Or.inl h2⟩ =>
        clear hy hz
        refine ⟨k + j, Or.inl ?_⟩
        have e0 : (k + j) * n = k * n + j * n := Nat.add_mul k j n
        omega
      | ⟨j, Or.inr h2⟩ =>
        clear hy hz
        apply (congN_normal n x z).mpr
        match Nat.lt_trichotomy k j with
        | .inl _ =>
          refine ⟨0, j - k, ?_⟩
          have e0 : (k + (j - k)) * n = k * n + (j - k) * n :=
            Nat.add_mul k (j - k) n
          have hj : k + (j - k) = j := by omega
          rw [hj] at e0
          omega
        | .inr (Or.inl heq) =>
          refine ⟨0, 0, ?_⟩
          rw [heq] at h1
          omega
        | .inr (Or.inr _) =>
          refine ⟨k - j, 0, ?_⟩
          have e0 : (j + (k - j)) * n = j * n + (k - j) * n :=
            Nat.add_mul j (k - j) n
          have hj : j + (k - j) = k := by omega
          rw [hj] at e0
          omega
    | ⟨k, Or.inr h1⟩ =>
      match hz with
      | ⟨j, Or.inl h2⟩ =>
        clear hy hz
        apply (congN_normal n x z).mpr
        refine ⟨j, k, ?_⟩
        omega
      | ⟨j, Or.inr h2⟩ =>
        clear hy hz
        refine ⟨k + j, Or.inr ?_⟩
        have e0 : (k + j) * n = k * n + j * n := Nat.add_mul k j n
        omega

theorem congN_add_wd : ∀ n a b a' b',
    congN n a a' → congN n b b' → congN n (a + b) (a' + b') := by
  intro n a b a' b' ha hb
  have ha' := (congN_normal n a a').mp ha
  have hb' := (congN_normal n b b').mp hb
  clear ha hb
  apply (congN_normal n (a+b) (a'+b')).mpr
  match ha' with
  | ⟨j1, j2, h1⟩ =>
    match hb' with
    | ⟨j3, j4, h2⟩ =>
      clear ha' hb'
      refine ⟨j1 + j3, j2 + j4, ?_⟩
      -- 展开 (j1+j3)*n 与 (j2+j4)*n，线性化
      have E1 : (j1 + j3) * n = j1 * n + j3 * n := Nat.add_mul j1 j3 n
      have E2 : (j2 + j4) * n = j2 * n + j4 * n := Nat.add_mul j2 j4 n
      rw [E1, E2]
      omega

theorem congN_mul_wd : ∀ n a b a' b',
    congN n a a' → congN n b b' → congN n (a * b) (a' * b') := by
  intro n a b a' b' ha hb
  have ha' := (congN_normal n a a').mp ha
  have hb' := (congN_normal n b b').mp hb
  clear ha hb
  apply (congN_normal n (a*b) (a'*b')).mpr
  match ha' with
  | ⟨j1, j2, h1⟩ =>
    match hb' with
    | ⟨j3, j4, h2⟩ =>
      clear ha' hb'
      refine ⟨j1 * b + j3 * a', j2 * b + j4 * a', ?_⟩
      -- 缩放恒等式（h1 乘 b、h2 乘 a'），再线性组合
      have s1 : (a + j1 * n) * b = (a' + j2 * n) * b := by rw [h1]
      have s2 : a' * (b + j3 * n) = a' * (b' + j4 * n) := by rw [h2]
      rw [Nat.add_mul, Nat.add_mul] at s1
      rw [Nat.mul_add, Nat.mul_add] at s2
      -- 展开 (j1*b + j3*a')*n 与 (j2*b + j4*a')*n
      have E1 : (j1 * b + j3 * a') * n = j1 * b * n + j3 * a' * n :=
        Nat.add_mul _ _ _
      have E2 : (j2 * b + j4 * a') * n = j2 * b * n + j4 * a' * n :=
        Nat.add_mul _ _ _
      rw [E1, E2]
      -- 乘积顺序对齐（j1*n*b vs j1*b*n 等）
      simp only [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm] at s1 s2 E1 E2 ⊢
      omega

-- ---------- 5. 冒烟与账本 ----------

#eval 17 % 5
#eval 12 % 7

#print axioms inj_comp
#print axioms surj_comp
#print axioms surj_right_inv
#print axioms inj_left_inv
#print axioms congN_eqrel
#print axioms congN_add_wd
#print axioms congN_mul_wd
