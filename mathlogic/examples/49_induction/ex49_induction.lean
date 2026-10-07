/- ex43 —— 数学归纳与递归（Jongsma §3.1-3.2）Lean 镜像
   gauss/oddsum_sq/hanoi_pow/nat3_fact/strong_ind/bounded_dec/prime_divisor/
   firstUp/wop_bool/wop_classic/no_sqrt2/fib_3n——与 ex49_induction.v 对应。
   账本：除 wop_classic（Classical 三件套）外全部零公理（#print axioms 见文件尾）。 -/

-- ---------- 1. PMI 两件求和法宝 ----------

def sumn : Nat → Nat
  | 0 => 0
  | (k+1) => sumn k + (k+1)

theorem gauss : ∀ n, 2 * sumn n = n * (n+1) := by
  intro n
  induction n with
  | zero => rfl
  | succ k ih =>
    have en : k * (k+1) = k*k + k := by rw [Nat.mul_add, Nat.mul_one]
    have e : (k+1) * (k+1+1) = k*k + 3*k + 2 := by
      have s1 := Nat.add_mul k 1 (k+1+1)
      have s2 := Nat.mul_add k (k+1) 1
      have s2b := Nat.mul_add k k 1
      have s3 := Nat.mul_one k
      have s4 := Nat.one_mul (k+1+1)
      omega
    simp only [sumn]
    rw [en] at ih
    omega

def oddsum : Nat → Nat
  | 0 => 0
  | (k+1) => oddsum k + (2*k+1)

theorem oddsum_sq : ∀ n, oddsum n = n * n := by
  intro n
  induction n with
  | zero => rfl
  | succ k ih =>
    simp only [oddsum]
    have e : (k+1) * (k+1) = k*k + 2*k + 1 := by
      rw [Nat.add_mul, Nat.mul_add, Nat.one_mul, Nat.mul_one]; omega
    rw [e]
    omega

-- ---------- 2. 递归定义与递归定理：Hanoi ----------

def pow2 : Nat → Nat
  | 0 => 1
  | (k+1) => 2 * pow2 k

def hanoi : Nat → Nat
  | 0 => 0
  | (k+1) => 2 * hanoi k + 1

-- 书写 2^n - 1；nat 上改写为 +1 = 2^n 形态
theorem hanoi_pow : ∀ n, hanoi n + 1 = pow2 n := by
  intro n
  induction n with
  | zero => rfl
  | succ k ih => simp only [hanoi, pow2]; omega

-- ---------- 3. Mod PMI：n^3 < n! for 6 ≤ n ----------

def nfact : Nat → Nat
  | 0 => 1
  | (k+1) => nfact k * (k+1)

theorem mul_ge_self : ∀ d k, 1 ≤ k → d ≤ d * k := by
  intro d k hk
  match k, hk with
  | (j+1), _ =>
    have e : d * (j+1) = d * j + d := Nat.mul_succ d j
    omega

-- 严格乘法右单调：裸 core 没有，自造（对乘子归纳）
theorem mul_lt_pos (a b : Nat) (h : a < b) : ∀ c, 0 < c → a * c < b * c := by
  intro c
  induction c with
  | zero => intro hc; omega
  | succ j ih =>
    intro _
    rw [Nat.mul_succ, Nat.mul_succ]
    match j with
    | 0 => rw [Nat.mul_zero, Nat.mul_zero]; omega
    | j'+1 => have hprev := ih (by omega); omega

-- (k+1)^2 ≤ k^3 for 3 ≤ k：非线性目标先拆线性链（k*k 原子化）
theorem sq_le_cube : ∀ k, 3 ≤ k → (k+1) * (k+1) ≤ k * k * k := by
  intro k hk
  have h1 : 3 * k ≤ k * k := Nat.mul_le_mul_right k (by omega)
  have h2 : 2 * (k*k) ≤ k*k*k := by
    have t := Nat.mul_le_mul_right (k*k) (show 2 ≤ k by omega)
    rw [show k * (k*k) = k*k*k from (Nat.mul_assoc k k k).symm] at t
    exact t
  have h3 : (k+1) * (k+1) = k*k + 2*k + 1 := by
    have s1 := Nat.add_mul k 1 (k+1)
    have s2 := Nat.mul_add k (k+1) 1
    have s2b := Nat.mul_add k k 1
    have s3 := Nat.mul_one k
    have s4 := Nat.one_mul (k+1)
    omega
  omega

theorem nat3_fact : ∀ n, 6 ≤ n → n * n * n < nfact n := by
  intro n
  induction n with
  | zero => intro h; omega
  | succ k ih =>
    intro h6
    match Nat.lt_or_ge 6 (k+1) with
    | .inl hge6 =>
      have ihk : k * k * k < nfact k := ih (by omega)
      have hsq : (k+1) * (k+1) ≤ k * k * k := sq_le_cube k (by omega)
      have hmono1 : ((k+1)*(k+1)) * (k+1) ≤ (k*k*k) * (k+1) :=
        Nat.mul_le_mul_right _ hsq
      have hmono2 : (k*k*k) * (k+1) < nfact k * (k+1) :=
        mul_lt_pos _ _ ihk (k+1) (by omega)
      show (k+1)*(k+1)*(k+1) < nfact k * (k+1)
      exact Nat.lt_of_le_of_lt hmono1 hmono2
    | .inr hlt6 =>
      have hk5 : k = 5 := by omega
      subst hk5
      decide

-- ---------- 4. 强归纳：从弱归纳推出 ----------

theorem strong_ind {P : Nat → Prop}
    (h : ∀ n, (∀ m, m < n → P m) → P n) : ∀ n, P n := by
  have aux : ∀ k m, m ≤ k → P m := by
    intro k
    induction k with
    | zero => intro m hm; apply h; intro j hj; exact absurd (Nat.lt_of_lt_of_le hj hm) (Nat.not_lt_zero j)
    | succ k ih => intro m hm; apply h; intro j hj; apply ih; omega
  intro n
  exact aux n n (Nat.le_refl n)

-- 有界排中：bool 谓词在 [0,n] 上，「有真」与「全假」二择一可归纳构造
theorem bounded_dec (p : Nat → Bool) (n : Nat) :
    (∃ d, d ≤ n ∧ p d = true) ∨ (∀ d, d ≤ n → p d = false) := by
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
      cases hex with
      | intro d hd =>
        cases hd with
        | intro hd1 hd2 => exact Or.inl ⟨d, Nat.le_succ_of_le hd1, hd2⟩
    | inr hno =>
      cases hc : p (k+1) with
      | true => exact Or.inl ⟨k+1, Nat.le_refl _, hc⟩
      | false =>
        exact Or.inr (fun d hd => by
          match Nat.lt_or_ge d (k+1) with
          | .inl hlt => exact hno d (Nat.le_of_lt_succ hlt)
          | .inr hge => have : d = k+1 := Nat.le_antisymm hd hge
                        rw [this]; exact hc)

-- ---------- 5. 素因子存在（Euclid VII.31，构造路线） ----------

def divides (a b : Nat) : Prop := ∃ k, b = a * k

def prime (p : Nat) : Prop :=
  2 ≤ p ∧ ∀ d, divides d p → d = 1 ∨ d = p

-- 递归乘法表搜索：dvbAux d n j 判定「∃k ≤ j, d*k = n」
def dvbAux (d n : Nat) : Nat → Bool
  | 0 => decide (d * 0 = n)
  | (j+1) => decide (d * (j+1) = n) || dvbAux d n j

def dvb (d n : Nat) : Bool := dvbAux d n n

theorem dvbAux_true (d n : Nat) : ∀ j, dvbAux d n j = true → ∃ k, k ≤ j ∧ d * k = n := by
  intro j
  induction j with
  | zero =>
    intro h
    simp only [dvbAux] at h
    have e : d * 0 = n := of_decide_eq_true h
    exact ⟨0, Nat.zero_le 0, by omega⟩
  | succ j ih =>
    intro h
    simp only [dvbAux] at h
    cases hc : (decide (d * (j+1) = n)) with
    | true => exact ⟨j+1, Nat.le_refl _, of_decide_eq_true hc⟩
    | false =>
      rw [hc, Bool.false_or] at h
      cases ih h with
      | intro k hk =>
        cases hk with
        | intro hk1 hk2 => exact ⟨k, Nat.le_succ_of_le hk1, hk2⟩

theorem dvbAux_of (d n : Nat) : ∀ j k, k ≤ j → d * k = n → dvbAux d n j = true := by
  intro j
  induction j with
  | zero =>
    intro k hk hdk
    have hk0 : k = 0 := Nat.le_zero.mp hk
    subst hk0
    show (decide (d * 0 = n)) = true
    rw [decide_eq_true hdk]
  | succ j ih =>
    intro k hk hdk
    match Nat.lt_or_ge k (j+1) with
    | .inl hlt =>
      show (decide (d * (j+1) = n) || dvbAux d n j) = true
      have hprev := ih k (Nat.le_of_lt_succ hlt) hdk
      rw [hprev]
      exact Bool.or_true _
    | .inr hge =>
      have hke : k = j+1 := Nat.le_antisymm hk hge
      subst hke
      show (decide (d * (j+1) = n) || dvbAux d n j) = true
      rw [decide_eq_true hdk, Bool.true_or]

theorem dvb_true (d n : Nat) (h : dvb d n = true) : divides d n := by
  cases dvbAux_true d n n h with
  | intro k hk =>
    cases hk with
    | intro _ hdk => exact ⟨k, hdk.symm⟩

theorem divides_dvb (d n : Nat) (hd : 1 ≤ d) (h : divides d n) : dvb d n = true := by
  cases h with
  | intro k hk =>
    have hkn : k ≤ n := by
      have h1 := mul_ge_self k d (by omega)
      rw [hk, Nat.mul_comm d k]
      exact h1
    exact dvbAux_of d n n k hkn hk.symm

def properFac (d n : Nat) : Bool :=
  decide (2 ≤ d) && (decide (2 * d ≤ n) && dvb d n)

theorem prime_divisor : ∀ n, 2 ≤ n → ∃ p, prime p ∧ divides p n := by
  apply strong_ind (P := fun n => 2 ≤ n → ∃ p, prime p ∧ divides p n)
  intro n IH Hn
  cases bounded_dec (fun d => properFac d n) n with
  | inl hex =>
    cases hex with
    | intro d hd =>
      cases hd with
      | intro hdn hdq =>
        rw [properFac, Bool.and_eq_true] at hdq
        cases hdq with
        | intro ha hb =>
          have hd2 : 2 ≤ d := of_decide_eq_true ha
          rw [Bool.and_eq_true] at hb
          cases hb with
          | intro hbb hbe =>
            have h2d : 2 * d ≤ n := of_decide_eq_true hbb
            cases IH d (by omega) hd2 with
            | intro p hp =>
              cases hp with
              | intro hpr hpd =>
                refine ⟨p, hpr, ?_⟩
                cases hpd with
                | intro k1 hk1 =>
                  cases dvb_true d n hbe with
                  | intro k2 hk2 =>
                    exact ⟨k1 * k2, by
                      rw [hk1] at hk2
                      rw [hk2, Nat.mul_assoc]⟩
  | inr Hno =>
    refine ⟨n, ⟨Hn, ?_⟩, ⟨1, (Nat.mul_one n).symm⟩⟩
    intro d hd
    match d with
    | 0 =>
      cases hd with
      | intro k hk => omega
    | 1 => exact Or.inl rfl
    | (d'+2) =>
      cases hd with
      | intro k hk =>
        match k with
        | 0 => omega
        | 1 =>
          rw [Nat.mul_one] at hk
          exact Or.inr hk.symm
        | (j+2) =>
          have c1 : 2 * (d'+2) = (d'+2) * 2 := Nat.mul_comm 2 (d'+2)
          have c2 : (d'+2) * 2 ≤ (d'+2) * (j+2) :=
            Nat.mul_le_mul_left (d'+2) (by omega)
          have h2le : 2 * (d'+2) ≤ n := by omega
          have hdn2 : d'+2 ≤ n := by omega
          have hpf : properFac (d'+2) n = true := by
            show (decide (2 ≤ d'+2) &&
                  (decide (2 * (d'+2) ≤ n) && dvb (d'+2) n)) = true
            rw [decide_eq_true (show 2 ≤ d'+2 by omega),
                decide_eq_true h2le, Bool.true_and, Bool.true_and]
            exact divides_dvb (d'+2) n (by omega) ⟨j+2, hk⟩
          have hcontra := Hno (d'+2) hdn2
          rw [hpf] at hcontra
          exact Bool.noConfusion hcontra

-- ---------- 6. 良序原理：构造面与经典面 ----------

def firstUp (p : Nat → Bool) : Nat → Option Nat
  | 0 => match p 0 with
         | true => some 0
         | false => none
  | (k+1) =>
    match firstUp p k with
    | some m => some m
    | none => match p (k+1) with
              | true => some (k+1)
              | false => none

theorem firstUp_spec (p : Nat → Bool) : ∀ n,
    (∀ m, firstUp p n = some m → m ≤ n ∧ p m = true ∧ ∀ j, j < m → p j = false)
    ∧ (firstUp p n = none → ∀ j, j ≤ n → p j = false) := by
  intro n
  induction n with
  | zero =>
    cases hc : p 0 with
    | true =>
      refine ⟨fun m h => ?_, fun h => ?_⟩
      · simp only [firstUp, hc] at h
        have hm : 0 = m := Option.some.inj h
        subst hm
        exact ⟨Nat.le_refl 0, hc, fun j hj => by omega⟩
      · simp only [firstUp, hc] at h
        exact Option.noConfusion h
    | false =>
      refine ⟨fun m h => ?_, fun h j hj => ?_⟩
      · simp only [firstUp, hc] at h
        exact Option.noConfusion h
      · have hj0 : j = 0 := Nat.le_zero.mp hj
        rw [hj0]; exact hc
  | succ k ih =>
    cases ih with
    | intro IH1 IH2 =>
      cases hf : firstUp p k with
      | some e =>
        cases IH1 e hf with
        | intro hle hpr =>
          cases hpr with
          | intro hpm hfirst =>
            refine ⟨fun m h => ?_, fun h => ?_⟩
            · simp only [firstUp, hf] at h
              have hm : e = m := Option.some.inj h
              subst hm
              exact ⟨by omega, hpm, hfirst⟩
            · simp only [firstUp, hf] at h
              exact Option.noConfusion h
      | none =>
        cases hc : p (k+1) with
        | true =>
          refine ⟨fun m h => ?_, fun h => ?_⟩
          · simp only [firstUp, hf, hc] at h
            have hm : k+1 = m := Option.some.inj h
            subst hm
            exact ⟨Nat.le_refl _, hc, fun j hj => IH2 hf j (by omega)⟩
          · simp only [firstUp, hf, hc] at h
            exact Option.noConfusion h
        | false =>
          refine ⟨fun m h => ?_, fun h j hj => ?_⟩
          · simp only [firstUp, hf, hc] at h
            exact Option.noConfusion h
          · match Nat.lt_or_ge j (k+1) with
            | .inl hlt => exact IH2 hf j (Nat.le_of_lt_succ hlt)
            | .inr hge =>
              have hjk : j = k+1 := Nat.le_antisymm hj hge
              rw [hjk]; exact hc

-- 良序原理（可判定版）：零公理，线性搜索
theorem wop_bool (p : Nat → Bool) (n : Nat) (hn : p n = true) :
    ∃ m, m ≤ n ∧ p m = true ∧ ∀ k, k < m → p k = false := by
  cases firstUp_spec p n with
  | intro H1 _ =>
    cases hf : firstUp p n with
    | some m0 =>
      cases H1 m0 hf with
      | intro h1 h2 =>
        cases h2 with
        | intro h3 h4 => exact ⟨m0, h1, h3, h4⟩
    | none =>
      cases firstUp_spec p n with
      | intro _ H2 =>
        have hpn := (H2 hf) n (Nat.le_refl n)
        rw [hpn] at hn
        exact Bool.noConfusion hn

-- 良序原理（任意 Prop 版）：书 §3.2.4 论证的机器面——
-- 反设无最小元，强归纳证明每个 n 都不在 S 里，与非空矛盾。
-- 反设一步走 Classical；账本见文件尾 #print axioms。
open Classical in
theorem wop_classic {S : Nat → Prop} (hne : ∃ n, S n) :
    ∃ m, S m ∧ ∀ k, S k → m ≤ k := by
  refine Classical.byContradiction (fun hcon => ?_)
  have hall : ∀ j, ¬ S j := by
    apply strong_ind (P := fun j => ¬ S j)
    intro j IHj HjS
    apply hcon
    refine ⟨j, HjS, fun k Hk => ?_⟩
    refine Classical.byContradiction (fun hnk => ?_)
    exact IHj k (by omega) Hk
  cases hne with
  | intro n Hn => exact hall n Hn

-- ---------- 7. 无穷下降：sqrt(2) 无理性 ----------

theorem parity (n : Nat) : (∃ m, n = 2 * m) ∨ (∃ m, n = 2 * m + 1) := by
  induction n with
  | zero => exact Or.inl ⟨0, rfl⟩
  | succ k ih =>
    cases ih with
    | inl h =>
      cases h with
      | intro m hm => exact Or.inr ⟨m, by omega⟩
    | inr h =>
      cases h with
      | intro m hm => exact Or.inl ⟨m+1, by omega⟩

theorem two_sq (x : Nat) : (2*x)*(2*x) = 2*(2*(x*x)) := by
  simp [Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]

theorem odd_sq (m : Nat) : (2*m+1)*(2*m+1) = 2*(2*(m*m)) + 4*m + 1 := by
  rw [Nat.add_mul, Nat.mul_add, Nat.one_mul, Nat.mul_one]
  rw [two_sq]
  omega

theorem sq_even (p c : Nat) (h : p * p = 2 * c) : ∃ m, p = 2 * m := by
  cases parity p with
  | inl hp => exact hp
  | inr hp =>
    exfalso
    cases hp with
    | intro m hm =>
      rw [hm, odd_sq] at h
      omega

theorem no_sqrt2 : ∀ q p, q ≠ 0 → p * p ≠ 2 * (q * q) := by
  apply strong_ind (P := fun q => ∀ p, q ≠ 0 → p * p ≠ 2 * (q * q))
  intro q IH p0 hq0 hbad
  cases parity p0 with
  | inl hpe =>
    cases hpe with
    | intro r hr =>
      rw [hr, two_sq] at hbad
      cases parity q with
      | inl hqe =>
        cases hqe with
        | intro s hs =>
          rw [hs, two_sq] at hbad
          exact IH s (by omega) r (by omega) (by omega)
      | inr hqe =>
        exfalso
        cases hqe with
        | intro s hs =>
          rw [hs, odd_sq] at hbad
          omega
  | inr hpo =>
    exfalso
    cases hpo with
    | intro r hr =>
      rw [hr, odd_sq] at hbad
      omega

-- ---------- 8. Fibonacci：加强归纳命题 ----------

def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | (k+2) => fib (k+1) + fib k

theorem fib_step (n : Nat) : fib (n+3) = fib (n+2) + fib (n+1) := rfl

-- 形状引理提到顶层：omega 见到上下文有 ∃ 假设会拉 Classical.choice，
-- 所以这类「纯形状」等式不能在含 ∃ 的局部上下文里用 by omega 证。
theorem fib_shift2 (k : Nat) :
    fib (3*k+3+2) = fib (3*k+3+1) + fib (3*k+3) := by
  rw [show 3*k+3+2 = 3*k+2+3 from by omega, fib_step,
      show 3*k+2+2 = 3*k+3+1 from by omega,
      show 3*k+2+1 = 3*k+3 from by omega]

-- 书只证 F_{3n} 偶；机器必须三合一（偶、奇、奇）一起归纳
theorem fib_triple : ∀ n,
    (∃ a, fib (3 * n) = 2 * a)
    ∧ (∃ b, fib (3 * n + 1) = 2 * b + 1)
    ∧ (∃ c, fib (3 * n + 2) = 2 * c + 1) := by
  intro n
  induction n with
  | zero => exact ⟨⟨0, rfl⟩, ⟨0, rfl⟩, ⟨0, rfl⟩⟩
  | succ k ih =>
    cases ih with
    | intro Ha hbc =>
      cases hbc with
      | intro Hb Hc =>
        cases Ha with
        | intro a hac =>
          cases Hb with
          | intro b hbc2 =>
            cases Hc with
            | intro c hcc =>
              rw [Nat.mul_succ]
              have He3 : fib (3*k+3) = 2 * (c + b + 1) := by
                rw [fib_step]; omega
              have Ho4 : ∃ d, fib (3*k+3+1) = 2 * d + 1 := by
                rw [show 3*k+3+1 = 3*k+1+3 from by omega, fib_step,
                    show 3*k+1+2 = 3*k+3 from by omega,
                    show 3*k+1+1 = 3*k+2 from by omega]
                exact ⟨c + b + 1 + c, by omega⟩
              have Ho5 : ∃ d, fib (3*k+3+2) = 2 * d + 1 := by
                rw [fib_shift2]
                cases Ho4 with
                | intro d hd => exact ⟨d + c + b + 1, by omega⟩
              exact ⟨⟨c + b + 1, He3⟩, Ho4, Ho5⟩

theorem fib_3n : ∀ n, ∃ a, fib (3 * n) = 2 * a := fun n =>
  (fib_triple n).1

-- ---------- 9. 冒烟与账本 ----------

#eval (sumn 100, oddsum 7, hanoi 5, pow2 6)
#eval (List.range 10).map fib
#eval firstUp (fun d => properFac d 60) 60
#eval firstUp (fun d => properFac d 91) 91

#print axioms gauss
#print axioms prime_divisor
#print axioms wop_bool
#print axioms wop_classic
#print axioms no_sqrt2
#print axioms strong_ind
#print axioms bounded_dec
#print axioms fib_triple
