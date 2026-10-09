/- ex10_adequate.lean —— 完备连接词集与公理独立性（Mendelson §1.3/1.5/1.6）Lean 镜像
   shannon 表示定理 / tAND·toDown 翻译器 / Prop 1.7 骨架 / 三值矩阵独立性（Fin 3 decide 枚举）/ super 擦负号 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ============ 0. 公式与二值语义 ============

inductive Fm : Type where
  | v (n : Nat)
  | neg (a : Fm)
  | imp (a b : Fm)
  | conj (a b : Fm)
  | disj (a b : Fm)

abbrev Asn := Nat → Bool

def bimp (x y : Bool) : Bool := !x || y

def beval (f : Fm) (s : Asn) : Bool :=
  match f with
  | .v n => s n
  | .neg a => !beval a s
  | .imp a b => bimp (beval a s) (beval b s)
  | .conj a b => beval a s && beval b s
  | .disj a b => beval a s || beval b s

def upd (s : Asn) (n : Nat) (b : Bool) : Asn :=
  fun i => if i = n then b else s i

-- ============ 一、Shannon 表示定理 ============

def fTrue : Fm := .imp (.v 0) (.v 0)
def fFalse : Fm := .neg fTrue

def shannon : (n : Nat) → (Asn → Bool) → Fm
  | 0, f => if f (fun _ => false) then fTrue else fFalse
  | n + 1, f =>
      .disj (.conj (.v n) (shannon n (fun s => f (upd s n true))))
            (.conj (.neg (.v n)) (shannon n (fun s => f (upd s n false))))

def AgreeUpto (n : Nat) (s1 s2 : Asn) : Prop := ∀ i, i < n → s1 i = s2 i

theorem beval_fTrue (s : Asn) : beval fTrue s = true := by
  simp only [fTrue, beval, bimp]; cases s 0 <;> rfl

theorem beval_fFalse (s : Asn) : beval fFalse s = false := by
  simp only [fFalse, fTrue, beval, bimp]; cases s 0 <;> rfl

theorem shannon_ok : ∀ (n : Nat) (f : Asn → Bool) (s : Asn),
    (∀ s1 s2, AgreeUpto n s1 s2 → f s1 = f s2) →
    beval (shannon n f) s = f s := by
  intro n
  induction n with
  | zero =>
    intro f s hdep
    simp only [shannon]
    split
    next h =>
      rw [beval_fTrue, ← h]
      exact hdep _ _ fun _ habs => by omega
    next h =>
      have hb : f (fun _ => false) = false := by
        cases hf : f (fun _ => false) with
        | true => exact absurd hf h
        | false => rfl
      rw [beval_fFalse, ← hb]
      exact hdep _ _ fun _ habs => by omega
  | succ n ih =>
    intro f s hdep
    simp only [shannon, beval]
    have hdep' : ∀ s1 s2, AgreeUpto n s1 s2 → f (upd s1 n true) = f (upd s2 n true) := by
      intro s1 s2 hag
      apply hdep
      intro i hi
      by_cases h : i = n
      · subst h; simp [upd]
      · simp [upd, h, hag i (by omega)]
    have hdep'' : ∀ s1 s2, AgreeUpto n s1 s2 → f (upd s1 n false) = f (upd s2 n false) := by
      intro s1 s2 hag
      apply hdep
      intro i hi
      by_cases h : i = n
      · subst h; simp [upd]
      · simp [upd, h, hag i (by omega)]
    cases hsn : s n with
    | true =>
      have hA : beval (shannon n (fun s0 => f (upd s0 n true))) s = f (upd s n true) :=
        ih (fun s0 => f (upd s0 n true)) s hdep'
      have hT : f (upd s n true) = f s := by
        apply hdep
        intro i hi
        by_cases h : i = n
        · subst h; simp [upd, hsn]
        · simp [upd, h]
      rw [Bool.true_and, Bool.not_true, Bool.false_and, Bool.or_false, hA, hT]
    | false =>
      have hB : beval (shannon n (fun s0 => f (upd s0 n false))) s = f (upd s n false) :=
        ih (fun s0 => f (upd s0 n false)) s hdep''
      have hF : f (upd s n false) = f s := by
        apply hdep
        intro i hi
        by_cases h : i = n
        · subst h; simp [upd, hsn]
        · simp [upd, h]
      rw [Bool.not_false, Bool.false_and, Bool.true_and, Bool.false_or, hB, hF]

-- ============ 二、翻译器：{¬,∧} 与单连接词 ↓ ============

def tAND : Fm → Fm
  | .v n => .v n
  | .neg a => .neg (tAND a)
  | .imp a b => .neg (.conj (tAND a) (.neg (tAND b)))
  | .conj a b => .conj (tAND a) (tAND b)
  | .disj a b => .neg (.conj (.neg (tAND a)) (.neg (tAND b)))

theorem tAND_ok : ∀ (f : Fm) (s : Asn), beval (tAND f) s = beval f s := by
  intro f
  induction f with
  | v n => intro s; rfl
  | neg a iha => intro s; simp only [tAND, beval, iha]
  | imp a b iha ihb =>
    intro s; simp only [tAND, beval, iha, ihb]
    cases beval a s <;> cases beval b s <;> rfl
  | conj a b iha ihb => intro s; simp only [tAND, beval, iha, ihb]
  | disj a b iha ihb =>
    intro s; simp only [tAND, beval, iha, ihb]
    cases beval a s <;> cases beval b s <;> rfl

-- 单连接词 ↓（joint denial/NOR）：A↓B := ¬(A∨B)
inductive Upfm : Type where
  | uv (n : Nat)
  | up (a b : Upfm)

def upeval (f : Upfm) (s : Asn) : Bool :=
  match f with
  | .uv n => s n
  | .up a b => !(upeval a s || upeval b s)

def toDown : Fm → Upfm
  | .v n => .uv n
  | .neg a => .up (toDown a) (toDown a)
  | .imp a b =>
      .up (.up (.up (toDown a) (toDown a)) (toDown b))
          (.up (.up (toDown a) (toDown a)) (toDown b))
  | .conj a b => .up (.up (toDown a) (toDown a)) (.up (toDown b) (toDown b))
  | .disj a b => .up (.up (toDown a) (toDown b)) (.up (toDown a) (toDown b))

theorem toDown_ok : ∀ (f : Fm) (s : Asn), upeval (toDown f) s = beval f s := by
  intro f
  induction f with
  | v n => intro s; rfl
  | neg a iha =>
    intro s; simp only [toDown, upeval, beval, iha]
    cases beval a s <;> rfl
  | imp a b iha ihb =>
    intro s; simp only [toDown, upeval, beval, iha, ihb]
    cases beval a s <;> cases beval b s <;> rfl
  | conj a b iha ihb =>
    intro s; simp only [toDown, upeval, beval, iha, ihb]
    cases beval a s <;> cases beval b s <;> rfl
  | disj a b iha ihb =>
    intro s; simp only [toDown, upeval, beval, iha, ihb]
    cases beval a s <;> cases beval b s <;> rfl

-- ============ 三、Prop 1.7 骨架：唯 ↓ 与 | 可作单连接词 ============

inductive Hfm : Type where
  | hv (n : Nat)
  | hap (a b : Hfm)

def heval (h : Bool → Bool → Bool) (f : Hfm) (s : Asn) : Bool :=
  match f with
  | .hv n => s n
  | .hap a b => h (heval h a s) (heval h b s)

def AllTrue (s : Asn) : Prop := ∀ n, s n = true

theorem h_TT_propagates (h : Bool → Bool → Bool) (hTT : h true true = true) :
    ∀ (f : Hfm) (s : Asn), AllTrue s → heval h f s = true := by
  intro f s hall
  induction f with
  | hv n => exact hall n
  | hap a b iha ihb =>
    simp only [heval, iha, ihb, hTT]

theorem undef_neg (h : Bool → Bool → Bool) (hTT : h true true = true) :
    ∀ f, ¬ (∀ s, heval h f s = !s 0) := by
  intro f hexp
  have h1 := hexp (fun _ => true)
  have h2 : heval h f (fun _ => true) = true :=
    h_TT_propagates h hTT _ _ (fun _ => rfl)
  rw [h2] at h1
  simp at h1

inductive Nfm : Type where
  | nv
  | nneg (a : Nfm)

def neval (f : Nfm) (b : Bool) : Bool :=
  match f with
  | .nv => b
  | .nneg a => !neval a b

theorem neg_only_two : ∀ f, (∀ b, neval f b = b) ∨ (∀ b, neval f b = !b) := by
  intro f
  induction f with
  | nv => exact Or.inl fun _ => rfl
  | nneg a iha =>
    rcases iha with h | h
    · exact Or.inr fun b => by simp only [neval, h]
    · exact Or.inl fun b => by simp only [neval, h]; cases b <;> rfl

theorem undef_constT : ¬ ∃ f, ∀ b, neval f b = true := by
  intro ⟨f, hf⟩
  rcases neg_only_two f with h | h
  · have h0 := hf false
    rw [h false] at h0
    simp at h0
  · have h0 := hf true
    rw [h true] at h0
    simp at h0

-- ============ 四、L 三公理独立性 ============

inductive Pfm : Type where
  | pv (n : Nat)
  | pneg (a : Pfm)
  | pimp (a b : Pfm)

def ev3 (ng : Nat → Nat) (im : Nat → Nat → Nat) (f : Pfm) (s : Nat → Nat) : Nat :=
  match f with
  | .pv n => s n
  | .pneg a => ng (ev3 ng im a s)
  | .pimp a b => im (ev3 ng im a s) (ev3 ng im b s)

def peval (f : Pfm) (s : Asn) : Bool :=
  match f with
  | .pv n => s n
  | .pneg a => !peval a s
  | .pimp a b => bimp (peval a s) (peval b s)

-- 矩阵一：select = 恒取 0（书 §1.5 原表）
def neg1 : Nat → Nat
  | 0 => 1 | 1 => 1 | _ => 0

def imp1 : Nat → Nat → Nat
  | 0, 0 => 0 | 0, 1 => 2 | 0, _ => 2
  | 1, 0 => 2 | 1, 1 => 2 | 1, _ => 0
  | _, _ => 0

def ev1 (f : Pfm) (s : Nat → Nat) : Nat := ev3 neg1 imp1 f s
def Sel (f : Pfm) : Prop := ∀ s, ev1 f s = 0

-- 值级查表（0/1/≥2 三案）：矩阵一上的独立性骨架
theorem imp1_mp (b c : Nat) (h1 : b = 0) (h2 : imp1 b c = 0) : c = 0 := by
  cases b with
  | zero => cases c with
    | zero => rfl
    | succ c => cases c with
      | zero => simp only [imp1] at h2; omega
      | succ c => simp only [imp1] at h2; omega
  | succ b => cases b with
    | zero => omega
    | succ b => omega

theorem imp1_a2 (b c d : Nat) :
    imp1 (imp1 b (imp1 c d)) (imp1 (imp1 b c) (imp1 b d)) = 0 := by
  match b, c, d with
  | 0, 0, 0 => rfl
  | 0, 0, 1 => rfl
  | 0, 0, d+2 => rfl
  | 0, 1, 0 => rfl
  | 0, 1, 1 => rfl
  | 0, 1, d+2 => rfl
  | 0, c+2, 0 => rfl
  | 0, c+2, 1 => rfl
  | 0, c+2, d+2 => rfl
  | 1, 0, 0 => rfl
  | 1, 0, 1 => rfl
  | 1, 0, d+2 => rfl
  | 1, 1, 0 => rfl
  | 1, 1, 1 => rfl
  | 1, 1, d+2 => rfl
  | 1, c+2, 0 => rfl
  | 1, c+2, 1 => rfl
  | 1, c+2, d+2 => rfl
  | b+2, 0, 0 => rfl
  | b+2, 0, 1 => rfl
  | b+2, 0, d+2 => rfl
  | b+2, 1, 0 => rfl
  | b+2, 1, 1 => rfl
  | b+2, 1, d+2 => rfl
  | b+2, c+2, 0 => rfl
  | b+2, c+2, 1 => rfl
  | b+2, c+2, d+2 => rfl

theorem imp1_a3 (b c : Nat) :
    imp1 (imp1 (neg1 b) (neg1 c)) (imp1 (imp1 (neg1 b) c) b) = 0 := by
  match b, c with
  | 0, 0 => rfl
  | 0, 1 => rfl
  | 0, c+2 => rfl
  | 1, 0 => rfl
  | 1, 1 => rfl
  | 1, c+2 => rfl
  | b+2, 0 => rfl
  | b+2, 1 => rfl
  | b+2, c+2 => rfl

theorem mp_sel : ∀ B C, Sel B → Sel (Pfm.pimp B C) → Sel C := by
  intro B C h1 h2 s
  have hb := h1 s
  have h2' := h2 s
  simp only [ev1, ev3] at h2'
  simp only [Sel, ev1, ev3] at *
  exact imp1_mp _ _ hb h2'

theorem A2_sel : ∀ B C D,
    Sel (Pfm.pimp (Pfm.pimp B (Pfm.pimp C D))
                  (Pfm.pimp (Pfm.pimp B C) (Pfm.pimp B D))) := by
  intro B C D s
  simp only [Sel, ev1, ev3]
  exact imp1_a2 _ _ _

theorem A3_sel : ∀ B C,
    Sel (Pfm.pimp (Pfm.pimp (Pfm.pneg B) (Pfm.pneg C))
                  (Pfm.pimp (Pfm.pimp (Pfm.pneg B) C) B)) := by
  intro B C s
  simp only [Sel, ev1, ev3]
  exact imp1_a3 _ _

example : ev1 (Pfm.pimp (.pv 0) (Pfm.pimp (.pv 1) (.pv 0)))
              (fun n => match n with | 0 => 1 | 1 => 2 | _ => 0) = 2 := rfl

-- 矩阵二：grotesque = 恒取 0（书 §1.5 原表）
def neg2 : Nat → Nat
  | 0 => 1 | 1 => 0 | _ => 1

def imp2 : Nat → Nat → Nat
  | 0, 0 => 0 | 0, 1 => 2 | 0, _ => 1
  | 1, 0 => 0 | 1, 1 => 2 | 1, _ => 0
  | _, _ => 0

def ev2 (f : Pfm) (s : Nat → Nat) : Nat := ev3 neg2 imp2 f s
def Grot (f : Pfm) : Prop := ∀ s, ev2 f s = 0

theorem imp2_mp (b c : Nat) (h1 : b = 0) (h2 : imp2 b c = 0) : c = 0 := by
  cases b with
  | zero => cases c with
    | zero => rfl
    | succ c => cases c with
      | zero => simp only [imp2] at h2; omega
      | succ c => simp only [imp2] at h2; omega
  | succ b => cases b with
    | zero => omega
    | succ b => omega

theorem imp2_a1 (b c : Nat) : imp2 b (imp2 c b) = 0 := by
  match b, c with
  | 0, 0 => rfl
  | 0, 1 => rfl
  | 0, c+2 => rfl
  | 1, 0 => rfl
  | 1, 1 => rfl
  | 1, c+2 => rfl
  | b+2, 0 => rfl
  | b+2, 1 => rfl
  | b+2, c+2 => rfl

theorem imp2_a3 (b c : Nat) :
    imp2 (imp2 (neg2 b) (neg2 c)) (imp2 (imp2 (neg2 b) c) b) = 0 := by
  match b, c with
  | 0, 0 => rfl
  | 0, 1 => rfl
  | 0, c+2 => rfl
  | 1, 0 => rfl
  | 1, 1 => rfl
  | 1, c+2 => rfl
  | b+2, 0 => rfl
  | b+2, 1 => rfl
  | b+2, c+2 => rfl

theorem mp_grot : ∀ B C, Grot B → Grot (Pfm.pimp B C) → Grot C := by
  intro B C h1 h2 s
  have hb := h1 s
  have h2' := h2 s
  simp only [ev2, ev3] at h2'
  simp only [Grot, ev2, ev3] at *
  exact imp2_mp _ _ hb h2'

theorem A1_grot : ∀ B C, Grot (Pfm.pimp B (Pfm.pimp C B)) := by
  intro B C s
  simp only [Grot, ev2, ev3]
  exact imp2_a1 _ _

theorem A3_grot : ∀ B C,
    Grot (Pfm.pimp (Pfm.pimp (Pfm.pneg B) (Pfm.pneg C))
                   (Pfm.pimp (Pfm.pimp (Pfm.pneg B) C) B)) := by
  intro B C s
  simp only [Grot, ev2, ev3]
  exact imp2_a3 _ _

example : ev2 (Pfm.pimp (Pfm.pimp (.pv 0) (Pfm.pimp (.pv 1) (.pv 2)))
                   (Pfm.pimp (Pfm.pimp (.pv 0) (.pv 1)) (Pfm.pimp (.pv 0) (.pv 2))))
              (fun n => match n with | 0 => 0 | 1 => 0 | 2 => 1 | _ => 0) = 2 := rfl

-- A3 独立：super 擦负号技巧
def erase : Pfm → Pfm
  | .pv n => .pv n
  | .pneg a => erase a
  | .pimp a b => .pimp (erase a) (erase b)

theorem taut_A1 : ∀ X Y s, peval (Pfm.pimp X (Pfm.pimp Y X)) s = true := by
  intro X Y s
  simp only [peval, bimp]
  cases peval X s <;> cases peval Y s <;> rfl

theorem taut_A2 : ∀ X Y Z s,
    peval (Pfm.pimp (Pfm.pimp X (Pfm.pimp Y Z))
                    (Pfm.pimp (Pfm.pimp X Y) (Pfm.pimp X Z))) s = true := by
  intro X Y Z s
  simp only [peval, bimp]
  cases peval X s <;> cases peval Y s <;> cases peval Z s <;> rfl

theorem super_MP : ∀ B C,
    (∀ s, peval (erase (Pfm.pimp B C)) s = true) →
    (∀ s, peval (erase B) s = true) →
    (∀ s, peval (erase C) s = true) := by
  intro B C h1 h2 s
  have h1' := h1 s
  have h2' := h2 s
  simp only [erase, peval, bimp] at h1' h2' ⊢
  cases hb : peval (erase B) s with
  | true =>
    cases hc : peval (erase C) s with
    | true => rfl
    | false =>
      rw [hb, hc] at h1'
      simp at h1'
  | false =>
    rw [hb] at h2'
    simp at h2'

theorem A1_super : ∀ B C s, peval (erase (Pfm.pimp B (Pfm.pimp C B))) s = true := by
  intro B C s
  show peval (Pfm.pimp (erase B) (Pfm.pimp (erase C) (erase B))) s = true
  exact taut_A1 _ _ _

theorem A2_super : ∀ B C D s,
    peval (erase (Pfm.pimp (Pfm.pimp B (Pfm.pimp C D))
                           (Pfm.pimp (Pfm.pimp B C) (Pfm.pimp B D)))) s = true := by
  intro B C D s
  show peval (Pfm.pimp (Pfm.pimp (erase B) (Pfm.pimp (erase C) (erase D)))
                       (Pfm.pimp (Pfm.pimp (erase B) (erase C))
                                 (Pfm.pimp (erase B) (erase D)))) s = true
  exact taut_A2 _ _ _ _

example : peval (erase (Pfm.pimp (Pfm.pimp (Pfm.pneg (.pv 0)) (Pfm.pneg (.pv 0)))
                                 (Pfm.pimp (Pfm.pimp (Pfm.pneg (.pv 0)) (.pv 0)) (.pv 0))))
                 (fun _ => false) = false := rfl

-- ============ 五、L1（Hilbert–Ackermann ∨¬ 系统）四公理重言验证 ============

theorem L1_ax1 : ∀ (B : Fm) (s : Asn), beval (.imp (.disj B B) B) s = true := by
  intro B s; simp only [beval, bimp]; cases beval B s <;> rfl

theorem L1_ax2 : ∀ (B C : Fm) (s : Asn), beval (.imp B (.disj B C)) s = true := by
  intro B C s; simp only [beval, bimp]
  cases beval B s <;> cases beval C s <;> rfl

theorem L1_ax3 : ∀ (B C : Fm) (s : Asn), beval (.imp (.disj B C) (.disj C B)) s = true := by
  intro B C s; simp only [beval, bimp]
  cases beval B s <;> cases beval C s <;> rfl

theorem L1_ax4 : ∀ (B C D : Fm) (s : Asn),
    beval (.imp (.imp C D) (.imp (.disj B C) (.disj B D))) s = true := by
  intro B C D s; simp only [beval, bimp]
  cases beval B s <;> cases beval C s <;> cases beval D s <;> rfl

-- ============ 账本 ============

#print axioms shannon_ok
#print axioms tAND_ok
#print axioms toDown_ok
#print axioms undef_neg
#print axioms A2_sel
#print axioms A1_super
