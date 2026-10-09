/- ex20 —— EFT 矢列演算 S 的 FOL 版（Lean 镜像）
   语法（¬∨∃≡ 最小语言）+ der 全规则构造子（∃A 带侧条件）+ 可导规则
   （TND/链式/等词对称传递/∀实例化/同余）+ 群论例（右幺+右逆+结合 ⇒
   存在左逆）+ 协调性 + 命题片段可靠性。与 Coq 版逐件对应。
   注意：tm 是嵌套归纳类型（fsym 挂 List tm），Lean 的 induction 不支持，
   代入引理按 tsize 测度归纳。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

inductive tm : Type
  | var (n : Nat) : tm
  | fsym (f : Nat) (ts : List tm) : tm

def substt (t : tm) (x : Nat) (u : tm) : tm :=
  match t with
  | .var n => if n = x then u else .var n
  | .fsym f ts => .fsym f (ts.map (fun t => substt t x u))

def fvt : tm → List Nat
  | .var n => [n]
  | .fsym _ ts => ts.flatMap fvt

inductive fm : Type
  | rat (r : Nat) (ts : List tm)
  | eqf (t1 t2 : tm)
  | neg (φ : fm)
  | disj (φ ψ : fm)
  | exq (x : Nat) (φ : fm)

def wipe : Nat → List Nat → List Nat
  | _, [] => []
  | x, a :: l => if a = x then wipe x l else a :: wipe x l

def fv : fm → List Nat
  | .rat _ ts => ts.flatMap fvt
  | .eqf t1 t2 => fvt t1 ++ fvt t2
  | .neg ψ => fv ψ
  | .disj ψ χ => fv ψ ++ fv χ
  | .exq x ψ => wipe x (fv ψ)

def substf (φ : fm) (x : Nat) (u : tm) : fm :=
  match φ with
  | .rat r ts => .rat r (ts.map (fun t => substt t x u))
  | .eqf t1 t2 => .eqf (substt t1 x u) (substt t2 x u)
  | .neg ψ => .neg (substf ψ x u)
  | .disj ψ χ => .disj (substf ψ x u) (substf χ x u)
  | .exq y ψ => if y = x then .exq y ψ else .exq y (substf ψ x u)

def all (x : Nat) (φ : fm) : fm := .neg (.exq x (.neg φ))

def fv_l (Γ : List fm) : List Nat := Γ.flatMap fv

inductive der : List fm → fm → Prop
  | Assm {Γ} φ (h : φ ∈ Γ) : der Γ φ
  | Ant {Γ} {Γ'} φ (h : Γ ⊆ Γ') (d : der Γ φ) : der Γ' φ
  | PC {Γ} ψ φ (d1 : der (ψ :: Γ) φ) (d2 : der (.neg ψ :: Γ) φ) : der Γ φ
  | Ctr {Γ} φ ψ (d1 : der (.neg φ :: Γ) ψ) (d2 : der (.neg φ :: Γ) (.neg ψ)) :
      der Γ φ
  | OrA {Γ} φ ψ χ (d1 : der (φ :: Γ) χ) (d2 : der (ψ :: Γ) χ) :
      der (.disj φ ψ :: Γ) χ
  | OrSl {Γ} φ ψ (d : der Γ φ) : der Γ (.disj φ ψ)
  | OrSr {Γ} φ ψ (d : der Γ ψ) : der Γ (.disj φ ψ)
  | ExS {Γ} x φ t (d : der Γ (substf φ x t)) : der Γ (.exq x φ)
  | ExA {Γ} x φ ψ y (h : y ∉ fv_l (.exq x φ :: ψ :: Γ))
      (d : der (substf φ x (.var y) :: Γ) ψ) : der (.exq x φ :: Γ) ψ
  | Ref {Γ} t : der Γ (.eqf t t)
  | Sub {Γ} x φ t t' (d : der Γ (substf φ x t)) :
      der (.eqf t t' :: Γ) (substf φ x t')

-- ---------- 代入引理 ----------

def tsize : tm → Nat
  | .var _ => 1
  | .fsym _ ts => ts.foldr (fun a m => tsize a + m) 1

theorem fr_pos (ts : List tm) : 1 ≤ ts.foldr (fun a m => tsize a + m) 1 := by
  induction ts with
  | nil => simp
  | cons a l ih => simp only [List.foldr_cons]; omega

theorem tsize_elem : ∀ ts f t, t ∈ ts → tsize t < tsize (.fsym f ts) := by
  intro ts f t ht
  induction ts with
  | nil => cases ht
  | cons a l ih =>
      rcases List.mem_cons.mp ht with rfl | ht
      · have := fr_pos l
        simp only [tsize, List.foldr_cons] at this ⊢
        omega
      · have h2 := ih ht
        have := fr_pos l
        simp only [tsize, List.foldr_cons] at h2 this ⊢
        omega

theorem map_self_gen : ∀ (ts : List tm) (x : Nat) (u : tm),
    (∀ t, t ∈ ts → substt t x u = t) →
    ts.map (fun t => substt t x u) = ts := by
  intro ts x u
  induction ts with
  | nil => intro _; rfl
  | cons a l ih =>
      intro h
      simp only [List.map_cons]
      rw [h a List.mem_cons_self,
          ih (fun t ht => h t (List.mem_cons_of_mem _ ht))]

theorem substt_self_aux : ∀ n t, tsize t ≤ n → ∀ x, substt t x (.var x) = t := by
  intro n
  induction n with
  | zero =>
      intro t ht
      cases t with
      | var _ => simp [tsize] at ht
      | fsym f ts =>
          have := fr_pos ts
          simp only [tsize] at ht
          omega
  | succ m ih =>
      intro t ht
      cases t with
      | var n0 =>
          intro x
          by_cases e : n0 = x
          · subst e; simp [substt]
          · simp [substt, e]
      | fsym f ts =>
          intro x
          simp only [substt]
          refine congrArg (tm.fsym f) ?_
          exact map_self_gen ts x (.var x) (fun t ht2 =>
            ih t (by
              have hb := tsize_elem ts f t ht2
              simp only [tsize] at hb
              simp only [tsize] at ht
              omega) x)

theorem substt_self (t : tm) (x : Nat) : substt t x (.var x) = t :=
  substt_self_aux (tsize t) t (Nat.le_refl _) x

theorem mem_flat_aux : ∀ (x : Nat) (t : tm) (ts : List tm),
    t ∈ ts → x ∈ fvt t → x ∈ ts.flatMap fvt := by
  intro x t ts
  induction ts with
  | nil => intro ht; cases ht
  | cons a l ih =>
      intro ht hc
      rcases List.mem_cons.mp ht with rfl | ht
      · simp only [List.flatMap_cons, List.mem_append]; exact Or.inl hc
      · simp only [List.flatMap_cons, List.mem_append]
        exact Or.inr (ih ht hc)

theorem substt_fresh_aux : ∀ n t, tsize t ≤ n →
    ∀ x u, x ∉ fvt t → substt t x u = t := by
  intro n
  induction n with
  | zero =>
      intro t ht
      cases t with
      | var _ => simp [tsize] at ht
      | fsym f ts =>
          have := fr_pos ts
          simp only [tsize] at ht
          omega
  | succ m ih =>
      intro t ht x u hfr
      cases t with
      | var n0 =>
          by_cases e : n0 = x
          · subst e
            exact (hfr (by simp [fvt])).elim
          · simp only [substt]
            rw [if_neg e]
      | fsym f ts =>
          simp only [substt]
          refine congrArg (tm.fsym f) ?_
          exact map_self_gen ts x u (fun t ht2 =>
            ih t (by
              have hb := tsize_elem ts f t ht2
              simp only [tsize] at hb
              simp only [tsize] at ht
              omega) x u (fun hc => hfr (by
              simp only [fvt]
              exact mem_flat_aux x t ts ht2 hc)))

theorem substt_fresh (t : tm) (x : Nat) (u : tm) (h : x ∉ fvt t) :
    substt t x u = t :=
  substt_fresh_aux (tsize t) t (Nat.le_refl _) x u h

theorem substf_self (φ : fm) (x : Nat) : substf φ x (.var x) = φ := by
  induction φ with
  | rat r ts =>
      simp only [substf]
      congr 1
      induction ts with
      | nil => rfl
      | cons a l ih => simp only [List.map_cons]; rw [substt_self, ih]
  | eqf t1 t2 => simp [substf, substt_self]
  | neg ψ ih => simp [substf, ih]
  | disj ψ χ ih1 ih2 => simp [substf, ih1, ih2]
  | exq y ψ ih =>
      by_cases h : y = x
      · subst h
        simp only [substf, if_true]
      · simp only [substf, if_neg h]
        rw [ih]

theorem maxl (L : List Nat) : ∃ m, ∀ n ∈ L, n ≤ m := by
  induction L with
  | nil => exact ⟨0, by simp⟩
  | cons a L ih =>
      obtain ⟨m, hm⟩ := ih
      exact ⟨max a m, by
        intro n hn
        rcases List.mem_cons.mp hn with rfl | hn
        · exact Nat.le_max_left _ m
        · exact Nat.le_trans (hm n hn) (Nat.le_max_right a m)⟩

theorem pick_fresh (L : List Nat) : ∃ n, n ∉ L := by
  obtain ⟨m, hm⟩ := maxl L
  exact ⟨m + 1, fun hc => by have := hm (m + 1) hc; omega⟩

-- ---------- 可导规则 ----------

-- 3.1 排中律
theorem d_tnd (Γ : List fm) (φ : fm) : der Γ (.disj φ (.neg φ)) := by
  apply der.PC (ψ := φ)
  · exact der.OrSl _ _ (der.Assm _ List.mem_cons_self)
  · exact der.OrSr _ _ (der.Assm _ List.mem_cons_self)

-- 双重否定消去
theorem d_nne {Γ} {φ} (h : der Γ (.neg (.neg φ))) : der Γ φ := by
  apply der.PC (ψ := φ)
  · exact der.Assm _ List.mem_cons_self
  · apply der.Ctr (ψ := .neg φ)
    · exact der.Assm _ List.mem_cons_self
    · exact der.Ant _
        (fun _ hz => List.mem_cons_of_mem _ (List.mem_cons_of_mem _ hz)) h

-- Ch 链式规则
theorem d_ch {Γ} {χ} {ψ} (hc : der Γ χ) (hs : der (χ :: Γ) ψ) : der Γ ψ := by
  apply der.PC (ψ := χ)
  · exact hs
  · apply der.Ctr (ψ := χ)
    · exact der.Ant _
        (fun _ hz => List.mem_cons_of_mem _ (List.mem_cons_of_mem _ hz)) hc
    · exact der.Assm _ (List.mem_cons_of_mem _ List.mem_cons_self)

-- 5.3(a) 等词对称
theorem d_sym {Γ} {t1 t2} (h : der Γ (.eqf t1 t2)) : der Γ (.eqf t2 t1) := by
  obtain ⟨x, hx⟩ := pick_fresh (fvt t1 ++ (fvt t2 ++ fv_l Γ))
  have hx1 : x ∉ fvt t1 := fun hc => hx (List.mem_append.mpr (Or.inl hc))
  apply d_ch (χ := .eqf t1 t2)
  · exact h
  · have E : substf (.eqf (.var x) t1) x t2 = .eqf t2 t1 := by
      simp only [substf]
      have e0 : substt (.var x) x t2 = t2 := by simp [substt]
      rw [e0, substt_fresh t1 x t2 hx1]
    rw [← E]
    apply der.Sub (x := x) (φ := .eqf (.var x) t1)
    simp only [substf]
    have e0 : substt (.var x) x t1 = t1 := by simp [substt]
    rw [e0, substt_fresh t1 x t1 hx1]
    exact der.Ref _

-- 5.3(b) 等词传递
theorem d_trans {Γ} {t1 t2 t3} (h12 : der Γ (.eqf t1 t2))
    (h23 : der Γ (.eqf t2 t3)) : der Γ (.eqf t1 t3) := by
  obtain ⟨x, hx⟩ := pick_fresh (fvt t1 ++ (fvt t3 ++ fv_l Γ))
  have hx1 : x ∉ fvt t1 := fun hc => hx (List.mem_append.mpr (Or.inl hc))
  apply d_ch (χ := .eqf t2 t3)
  · exact h23
  · have E : substf (.eqf t1 (.var x)) x t3 = .eqf t1 t3 := by
      simp only [substf]
      have e0 : substt (.var x) x t3 = t3 := by simp [substt]
      rw [substt_fresh t1 x t3 hx1, e0]
    rw [← E]
    apply der.Sub (x := x) (φ := .eqf t1 (.var x))
    simp only [substf]
    have e0 : substt (.var x) x t2 = t2 := by simp [substt]
    rw [substt_fresh t1 x t2 hx1, e0]
    exact h12

-- 5.5(a1)：∀-左实例化
theorem d_all_inst {Γ} (x : Nat) (φ : fm) (t : tm)
    (h : der Γ (all x φ)) : der Γ (substf φ x t) := by
  apply der.PC (ψ := substf φ x t)
  · exact der.Assm _ List.mem_cons_self
  · apply der.Ctr (ψ := .exq x (.neg φ))
    · apply der.ExS (x := x) (φ := .neg φ) (t := t)
      exact der.Assm _ List.mem_cons_self
    · exact der.Ant _
        (fun _ hz => List.mem_cons_of_mem _ (List.mem_cons_of_mem _ hz)) h

-- 5.1(a)：Γ ⊢ φ 则 Γ ⊢ ∃xφ
theorem d_exi_self {Γ} (x : Nat) (φ : fm) (h : der Γ φ) : der Γ (.exq x φ) :=
  der.ExS x φ (.var x) (by rw [substf_self]; exact h)

def mul (a b : tm) : tm := .fsym 0 [a, b]
def eg : tm := .fsym 1 []

-- 乘法左右槽同余（书 5.4(b) 特化；新鲜性内部处理）
theorem d_congr_l {Γ} {a b u : tm} (h : der Γ (.eqf a b)) :
    der Γ (.eqf (mul a u) (mul b u)) := by
  obtain ⟨x, hx⟩ := pick_fresh (fvt a ++ (fvt b ++ (fvt u ++ (fv_l Γ))))
  have hxa : x ∉ fvt a := fun hc =>
    hx (List.mem_append.mpr (Or.inl hc))
  have hxb : x ∉ fvt b := fun hc =>
    hx (List.mem_append.mpr (Or.inr (List.mem_append.mpr (Or.inl hc))))
  have hxu : x ∉ fvt u := fun hc =>
    hx (List.mem_append.mpr
      (Or.inr (List.mem_append.mpr (Or.inr (List.mem_append.mpr (Or.inl hc))))))
  apply d_ch (χ := .eqf b a)
  · exact d_sym h
  · have E : substf (.eqf (mul (.var x) u) (mul b u)) x b
                = .eqf (mul b u) (mul b u) := by
      have e0 : substt (.var x) x b = b := by simp [substt]
      have s1 : substt (mul (.var x) u) x b = mul b u := by
        simp only [mul, substt, List.map_cons, List.map_nil]
        rw [if_true, substt_fresh u x b hxu]
      have s2 : substt (mul b u) x b = mul b u := by
        simp only [mul, substt, List.map_cons, List.map_nil]
        rw [substt_fresh b x b hxb, substt_fresh u x b hxu]
      show fm.eqf _ _ = _
      rw [s1, s2]
    have E2 : substf (.eqf (mul (.var x) u) (mul b u)) x a
                = .eqf (mul a u) (mul b u) := by
      have e0 : substt (.var x) x a = a := by simp [substt]
      have s1 : substt (mul (.var x) u) x a = mul a u := by
        simp only [mul, substt, List.map_cons, List.map_nil]
        rw [if_true, substt_fresh u x a hxu]
      have s2 : substt (mul b u) x a = mul b u := by
        simp only [mul, substt, List.map_cons, List.map_nil]
        rw [substt_fresh b x a hxb, substt_fresh u x a hxu]
      show fm.eqf _ _ = _
      rw [s1, s2]
    rw [← E2]
    apply der.Sub (x := x) (φ := .eqf (mul (.var x) u) (mul b u))
    rw [E]
    exact der.Ref _

theorem d_congr_r {Γ} {a b u : tm} (h : der Γ (.eqf a b)) :
    der Γ (.eqf (mul u a) (mul u b)) := by
  obtain ⟨x, hx⟩ := pick_fresh (fvt a ++ (fvt b ++ (fvt u ++ (fv_l Γ))))
  have hxa : x ∉ fvt a := fun hc =>
    hx (List.mem_append.mpr (Or.inl hc))
  have hxb : x ∉ fvt b := fun hc =>
    hx (List.mem_append.mpr (Or.inr (List.mem_append.mpr (Or.inl hc))))
  have hxu : x ∉ fvt u := fun hc =>
    hx (List.mem_append.mpr
      (Or.inr (List.mem_append.mpr (Or.inr (List.mem_append.mpr (Or.inl hc))))))
  apply d_ch (χ := .eqf b a)
  · exact d_sym h
  · have E : substf (.eqf (mul u (.var x)) (mul u b)) x b
                = .eqf (mul u b) (mul u b) := by
      have s1 : substt (mul u (.var x)) x b = mul u b := by
        simp only [mul, substt, List.map_cons, List.map_nil]
        rw [if_true, substt_fresh u x b hxu]
      have s2 : substt (mul u b) x b = mul u b := by
        simp only [mul, substt, List.map_cons, List.map_nil]
        rw [substt_fresh u x b hxu, substt_fresh b x b hxb]
      show fm.eqf _ _ = _
      rw [s1, s2]
    have E2 : substf (.eqf (mul u (.var x)) (mul u b)) x a
                = .eqf (mul u a) (mul u b) := by
      have s1 : substt (mul u (.var x)) x a = mul u a := by
        simp only [mul, substt, List.map_cons, List.map_nil]
        rw [if_true, substt_fresh u x a hxu]
      have s2 : substt (mul u b) x a = mul u b := by
        simp only [mul, substt, List.map_cons, List.map_nil]
        rw [substt_fresh u x a hxu, substt_fresh b x a hxb]
      show fm.eqf _ _ = _
      rw [s1, s2]
    rw [← E2]
    apply der.Sub (x := x) (φ := .eqf (mul u (.var x)) (mul u b))
    rw [E]
    exact der.Ref _

-- ---------- 群论例（书 IV.6） ----------

def phi0 : fm :=
  all 3 (all 4 (all 5 (.eqf (mul (mul (.var 3) (.var 4)) (.var 5))
                            (mul (.var 3) (mul (.var 4) (.var 5))))))
def phi1 : fm := all 3 (.eqf (mul (.var 3) eg) (.var 3))
def phi2 : fm := all 7 (.exq 8 (.eqf (mul (.var 7) (.var 8)) eg))
def Γgr : List fm := [phi0, phi1, phi2]

def A1 : fm := .eqf (mul (.var 0) (.var 10)) eg
def A2 : fm := .eqf (mul (.var 10) (.var 11)) eg
def G0 : fm := .eqf (mul (.var 10) (.var 0)) eg

theorem in_gr0 : phi0 ∈ (A2 :: A1 :: Γgr) :=
  List.mem_cons_of_mem _ (List.mem_cons_of_mem _ List.mem_cons_self)
theorem in_gr1 : phi1 ∈ (A2 :: A1 :: Γgr) :=
  List.mem_cons_of_mem _ (List.mem_cons_of_mem _ (List.mem_cons_of_mem _ List.mem_cons_self))

theorem gr_incl_A1 : Γgr ⊆ (A1 :: Γgr) := by
  intro z hz
  rcases List.mem_cons.mp hz with rfl | hz
  · exact List.mem_cons_of_mem _ List.mem_cons_self
  · exact List.mem_cons_of_mem _ (List.mem_cons_of_mem _ hz)

-- ExA 侧条件的新鲜性（具体公式上 decide）
theorem fresh11 : 11 ∉ fv_l
    (.exq 8 (.eqf (mul (.var 10) (.var 8)) eg) :: G0 :: A1 :: Γgr) := by
  simp [fv_l, fv, fvt, mul, eg, wipe, Γgr, phi0, phi1, phi2, A1, A2, G0, all]
theorem fresh10 : 10 ∉ fv_l
    (.exq 8 (.eqf (mul (.var 0) (.var 8)) eg) :: .exq 10 G0 :: Γgr) := by
  simp [fv_l, fv, fvt, mul, eg, wipe, Γgr, phi0, phi1, phi2, A1, A2, G0, all]

-- 等式链：A2, A1, Γ ⊢ y·x ≡ e（书 IV.6 行 2-23）
theorem chain : der (A2 :: A1 :: Γgr) G0 := by
  have c1 : der (A2::A1::Γgr)
      (.eqf (mul (mul (.var 10) (.var 0)) eg) (mul (.var 10) (.var 0))) := by
    have h := d_all_inst 3 (.eqf (mul (.var 3) eg) (.var 3))
      (mul (.var 10) (.var 0)) (der.Assm phi1 in_gr1)
    simpa [substf, substt, mul, eg, List.map_cons, List.map_nil] using h
  have hA2 : der (A2::A1::Γgr) A2 := der.Assm _ List.mem_cons_self
  have hA2s : der (A2::A1::Γgr) (.eqf eg (mul (.var 10) (.var 11))) := d_sym hA2
  have c2 : der (A2::A1::Γgr)
      (.eqf (mul (mul (.var 10) (.var 0)) eg)
            (mul (mul (.var 10) (.var 0)) (mul (.var 10) (.var 11)))) :=
    d_congr_r (a := eg) (b := mul (.var 10) (.var 11))
      (u := mul (.var 10) (.var 0)) hA2s
  have c1s : der (A2::A1::Γgr) (.eqf (mul (.var 10) (.var 0))
      (mul (mul (.var 10) (.var 0)) eg)) := d_sym c1
  have p1 := d_trans c1s c2
  have h1 : der (A2::A1::Γgr) (all 4 (all 5
      (.eqf (mul (mul (.var 10) (.var 4)) (.var 5))
            (mul (.var 10) (mul (.var 4) (.var 5)))))) := by
    have h := d_all_inst 3 (all 4 (all 5
      (.eqf (mul (mul (.var 3) (.var 4)) (.var 5))
            (mul (.var 3) (mul (.var 4) (.var 5))))))
      (.var 10) (der.Assm phi0 in_gr0)
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have h2 : der (A2::A1::Γgr) (all 5
      (.eqf (mul (mul (.var 10) (.var 0)) (.var 5))
            (mul (.var 10) (mul (.var 0) (.var 5))))) := by
    have h := d_all_inst 4 (all 5
      (.eqf (mul (mul (.var 10) (.var 4)) (.var 5))
            (mul (.var 10) (mul (.var 4) (.var 5))))) (.var 0) h1
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have c3 : der (A2::A1::Γgr)
      (.eqf (mul (mul (.var 10) (.var 0)) (mul (.var 10) (.var 11)))
            (mul (.var 10) (mul (.var 0) (mul (.var 10) (.var 11))))) := by
    have h := d_all_inst 5
      (.eqf (mul (mul (.var 10) (.var 0)) (.var 5))
            (mul (.var 10) (mul (.var 0) (.var 5))))
      (mul (.var 10) (.var 11)) h2
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have p2 := d_trans p1 c3
  have h3 : der (A2::A1::Γgr) (all 4 (all 5
      (.eqf (mul (mul (.var 0) (.var 4)) (.var 5))
            (mul (.var 0) (mul (.var 4) (.var 5)))))) := by
    have h := d_all_inst 3 (all 4 (all 5
      (.eqf (mul (mul (.var 3) (.var 4)) (.var 5))
            (mul (.var 3) (mul (.var 4) (.var 5))))))
      (.var 0) (der.Assm phi0 in_gr0)
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have h4 : der (A2::A1::Γgr) (all 5
      (.eqf (mul (mul (.var 0) (.var 10)) (.var 5))
            (mul (.var 0) (mul (.var 10) (.var 5))))) := by
    have h := d_all_inst 4 (all 5
      (.eqf (mul (mul (.var 0) (.var 4)) (.var 5))
            (mul (.var 0) (mul (.var 4) (.var 5))))) (.var 10) h3
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have c4' : der (A2::A1::Γgr)
      (.eqf (mul (mul (.var 0) (.var 10)) (.var 11))
            (mul (.var 0) (mul (.var 10) (.var 11)))) := by
    have h := d_all_inst 5
      (.eqf (mul (mul (.var 0) (.var 10)) (.var 5))
            (mul (.var 0) (mul (.var 10) (.var 5))))
      (.var 11) h4
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have c4 := d_sym c4'
  have c5 : der (A2::A1::Γgr)
      (.eqf (mul (.var 10) (mul (.var 0) (mul (.var 10) (.var 11))))
            (mul (.var 10) (mul (mul (.var 0) (.var 10)) (.var 11)))) :=
    d_congr_r (a := mul (.var 0) (mul (.var 10) (.var 11)))
      (b := mul (mul (.var 0) (.var 10)) (.var 11)) (u := .var 10) c4
  have p3 := d_trans p2 c5
  have hA1 : der (A2::A1::Γgr) A1 :=
    der.Assm _ (List.mem_cons_of_mem _ List.mem_cons_self)
  have c6a : der (A2::A1::Γgr)
      (.eqf (mul (mul (.var 0) (.var 10)) (.var 11))
            (mul eg (.var 11))) :=
    d_congr_l (a := mul (.var 0) (.var 10)) (b := eg) (u := .var 11) hA1
  have c6 : der (A2::A1::Γgr)
      (.eqf (mul (.var 10) (mul (mul (.var 0) (.var 10)) (.var 11)))
            (mul (.var 10) (mul eg (.var 11)))) :=
    d_congr_r (a := mul (mul (.var 0) (.var 10)) (.var 11))
      (b := mul eg (.var 11)) (u := .var 10) c6a
  have p4 := d_trans p3 c6
  have h6 : der (A2::A1::Γgr) (all 5
      (.eqf (mul (mul (.var 10) eg) (.var 5))
            (mul (.var 10) (mul eg (.var 5))))) := by
    have h := d_all_inst 4 (all 5
      (.eqf (mul (mul (.var 10) (.var 4)) (.var 5))
            (mul (.var 10) (mul (.var 4) (.var 5))))) eg h1
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have c7 : der (A2::A1::Γgr)
      (.eqf (mul (mul (.var 10) eg) (.var 11))
            (mul (.var 10) (mul eg (.var 11)))) := by
    have h := d_all_inst 5
      (.eqf (mul (mul (.var 10) eg) (.var 5))
            (mul (.var 10) (mul eg (.var 5))))
      (.var 11) h6
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have c7s := d_sym c7
  have c8 : der (A2::A1::Γgr) (.eqf (mul (.var 10) eg) (.var 10)) := by
    have h := d_all_inst 3 (.eqf (mul (.var 3) eg) (.var 3)) (.var 10)
      (der.Assm phi1 in_gr1)
    simpa [substf, substt, mul, eg, List.map_cons, List.map_nil] using h
  have c9 : der (A2::A1::Γgr)
      (.eqf (mul (mul (.var 10) eg) (.var 11)) (mul (.var 10) (.var 11))) :=
    d_congr_l (a := mul (.var 10) eg) (b := .var 10) (u := .var 11) c8
  have p5 := d_trans c7s c9
  have p6 := d_trans p4 p5
  exact d_trans p6 hA2

-- 打包：Γ ⊢ ∃y y·x ≡ e（ϕ2 两实例经 ExA 消解、d_ch 剪掉——b3 的机器化身）
theorem grp_left_inv : der Γgr (.exq 10 G0) := by
  have ekey : substf (.eqf (mul (.var 10) (.var 8)) eg) 8 (.var 11) = A2 := by
    simp [substf, substt, mul, eg, A2, List.map_cons, List.map_nil, if_neg]
  have dis2 : der (.exq 8 (.eqf (mul (.var 10) (.var 8)) eg) :: A1 :: Γgr) G0 :=
    der.ExA 8 (.eqf (mul (.var 10) (.var 8)) eg) G0 11 fresh11
      (by rw [ekey]; exact chain)
  have inst2y : der Γgr (.exq 8 (.eqf (mul (.var 10) (.var 8)) eg)) := by
    have h : der Γgr (substf (.exq 8 (.eqf (mul (.var 7) (.var 8)) eg))
                               7 (.var 10)) :=
      d_all_inst 7 (.exq 8 (.eqf (mul (.var 7) (.var 8)) eg)) (.var 10)
      (der.Assm (Γ := Γgr) phi2
        (List.mem_cons_of_mem _ (List.mem_cons_of_mem _ List.mem_cons_self)))
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  have cut2 : der (A1 :: Γgr) G0 :=
    d_ch (der.Ant _ gr_incl_A1 inst2y) dis2
  have gen : der (A1 :: Γgr) (.exq 10 G0) := d_exi_self 10 G0 cut2
  have ekey2 : substf (.eqf (mul (.var 0) (.var 8)) eg) 8 (.var 10) = A1 := by
    simp [substf, substt, mul, eg, A1, List.map_cons, List.map_nil, if_neg]
  have dis1 : der (.exq 8 (.eqf (mul (.var 0) (.var 8)) eg) :: Γgr)
      (.exq 10 G0) :=
    der.ExA 8 (.eqf (mul (.var 0) (.var 8)) eg) (.exq 10 G0) 10 fresh10
      (by rw [ekey2]; exact gen)
  have inst2x : der Γgr (.exq 8 (.eqf (mul (.var 0) (.var 8)) eg)) := by
    have h : der Γgr (substf (.exq 8 (.eqf (mul (.var 7) (.var 8)) eg))
                               7 (.var 0)) :=
      d_all_inst 7 (.exq 8 (.eqf (mul (.var 7) (.var 8)) eg)) (.var 0)
      (der.Assm (Γ := Γgr) phi2
        (List.mem_cons_of_mem _ (List.mem_cons_of_mem _ List.mem_cons_self)))
    simpa [substf, substt, mul, eg, all, List.map_cons, List.map_nil] using h
  exact d_ch inst2x dis1

-- ---------- 协调性（书 IV.7.2） ----------

def ders (Φ : List fm) (φ : fm) : Prop :=
  ∃ Γ, Γ ⊆ Φ ∧ der Γ φ

theorem inc_ders_all {Φ : List fm} {ψ0 : fm}
    (d1 : ders Φ ψ0) (d2 : ders Φ (.neg ψ0)) : ∀ ψ, ders Φ ψ := by
  obtain ⟨Γ1, h1, D1⟩ := d1
  obtain ⟨Γ2, h2, D2⟩ := d2
  intro ψ
  refine ⟨Γ1 ++ Γ2, ?_, ?_⟩
  · intro z hz
    rcases List.mem_append.mp hz with hz | hz
    · exact h1 hz
    · exact h2 hz
  · apply der.Ctr (ψ := ψ0)
    · exact der.Ant _
        (fun z hz => List.mem_cons_of_mem _ (List.mem_append.mpr (Or.inl hz))) D1
    · exact der.Ant _
        (fun z hz => List.mem_cons_of_mem _ (List.mem_append.mpr (Or.inr hz))) D2

-- ---------- 命题片段可靠性 ----------

inductive derp : List fm → fm → Prop
  | pAssm {Γ} φ (h : φ ∈ Γ) : derp Γ φ
  | pAnt {Γ} {Γ'} φ (h : Γ ⊆ Γ') (d : derp Γ φ) : derp Γ' φ
  | pPC {Γ} ψ φ (d1 : derp (ψ :: Γ) φ) (d2 : derp (.neg ψ :: Γ) φ) : derp Γ φ
  | pCtr {Γ} φ ψ (d1 : derp (.neg φ :: Γ) ψ)
      (d2 : derp (.neg φ :: Γ) (.neg ψ)) : derp Γ φ
  | pOrA {Γ} φ ψ χ (d1 : derp (φ :: Γ) χ) (d2 : derp (ψ :: Γ) χ) :
      derp (.disj φ ψ :: Γ) χ
  | pOrSl {Γ} φ ψ (d : derp Γ φ) : derp Γ (.disj φ ψ)
  | pOrSr {Γ} φ ψ (d : derp Γ ψ) : derp Γ (.disj φ ψ)

def comp (α : fm → Bool) : Prop :=
  (∀ φ, α (.neg φ) = !α φ) ∧ (∀ φ ψ, α (.disj φ ψ) = (α φ || α ψ))

theorem derp_sound : ∀ {Γ φ}, derp Γ φ →
    ∀ (α : fm → Bool), (∀ f, α (.neg f) = !α f) →
    (∀ f g, α (.disj f g) = (α f || α g)) →
    (∀ ψ, ψ ∈ Γ → α ψ = true) → α φ = true := by
  intro Γ φ hd
  induction hd with
  | pAssm f h => intro α hn ho hΓ; rw [hΓ f h]
  | pAnt f hin hd ih =>
      intro α hn ho hΓ
      exact ih α hn ho (fun ψ hψ => hΓ ψ (hin hψ))
  | pPC ψ f d1 d2 ih1 ih2 =>
      intro α hn ho hΓ
      cases hψ : α ψ with
      | true =>
          exact ih1 α hn ho (fun ψ2 h2 =>
            match List.mem_cons.mp h2 with
            | Or.inl he => by subst he; exact hψ
            | Or.inr h2 => hΓ ψ2 h2)
      | false =>
          have hnψ : α (.neg ψ) = true := by rw [hn, hψ]; rfl
          exact ih2 α hn ho (fun ψ2 h2 =>
            match List.mem_cons.mp h2 with
            | Or.inl he => by subst he; exact hnψ
            | Or.inr h2 => hΓ ψ2 h2)
  | pCtr f ψ d1 d2 ih1 ih2 =>
      intro α hn ho hΓ
      cases hf : α f with
      | true => rfl
      | false =>
          have Enf : α (.neg f) = true := by rw [hn, hf]; rfl
          have g1 := ih1 α hn ho (fun ψ2 h2 =>
            match List.mem_cons.mp h2 with
            | Or.inl he => by subst he; exact Enf
            | Or.inr h2 => hΓ ψ2 h2)
          have g2 := ih2 α hn ho (fun ψ2 h2 =>
            match List.mem_cons.mp h2 with
            | Or.inl he => by subst he; exact Enf
            | Or.inr h2 => hΓ ψ2 h2)
          rw [hn, g1] at g2
          exact Bool.noConfusion g2
  | pOrA f g χ d1 d2 ih1 ih2 =>
      intro α hn ho hΓ
      have Ed : α (.disj f g) = true := hΓ _ List.mem_cons_self
      rw [ho f g] at Ed
      cases h1 : α f with
      | true =>
          exact ih1 α hn ho (fun ψ2 h2 =>
            match List.mem_cons.mp h2 with
            | Or.inl he => by subst he; exact h1
            | Or.inr h2in => hΓ ψ2 (List.mem_cons_of_mem _ h2in))
      | false =>
          cases h2 : α g with
          | true =>
              exact ih2 α hn ho (fun ψ2 hmem =>
                match List.mem_cons.mp hmem with
                | Or.inl he => by subst he; exact h2
                | Or.inr h2in => hΓ ψ2 (List.mem_cons_of_mem _ h2in))
          | false =>
              rw [h1, h2] at Ed
              exact Bool.noConfusion Ed
  | pOrSl f g d ih =>
      intro α hn ho hΓ
      rw [ho f g, ih α hn ho hΓ]; rfl
  | pOrSr f g d ih =>
      intro α hn ho hΓ
      rw [ho f g, ih α hn ho hΓ]
      cases α f <;> rfl

-- 命题骨架赋值：原子 (rat 0 []) 为假、其余原子为真
def val0 : fm → Bool
  | .rat 0 _ => false
  | .rat _ _ => true
  | .eqf _ _ => true
  | .neg ψ => !val0 ψ
  | .disj ψ χ => val0 ψ || val0 χ
  | .exq _ _ => true

theorem val0_comp : comp val0 :=
  ⟨fun φ => by rfl, fun φ ψ => by rfl⟩

theorem derp_consistent : ¬derp [] (.rat 0 []) := by
  intro hd
  have hv : val0 (.rat 0 []) = true :=
    derp_sound hd val0 (fun _ => rfl) (fun _ _ => rfl)
      (fun ψ h => by cases h)
  exact Bool.noConfusion hv

-- ---------- 冒烟与账本 ----------

#eval fv (.exq 8 (.eqf (mul (.var 10) (.var 8)) eg))   -- [10]
#print axioms grp_left_inv
#print axioms inc_ders_all
#print axioms derp_sound
