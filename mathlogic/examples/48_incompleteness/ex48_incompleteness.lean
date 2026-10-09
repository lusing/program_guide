/- ex48_incompleteness.lean —— 哥德尔不完备性：机器件升级（Mendelson §3.5-3.6）
   mini-S 语言标准求值 / 表示性样板（加法图、≤、偶性、乘法图）真定理 /
   有限域可判定现场（qf_agree + 论域相对性对照）。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ============ 一、mini-S 语言与标准模型 ============

inductive Tm : Type where
  | var (n : Nat)
  | num (n : Nat)
  | pls (t1 t2 : Tm)
  | mul (t1 t2 : Tm)

inductive Fm : Type where
  | eqt (t1 t2 : Tm)
  | neg (a : Fm)
  | imp (a b : Fm)
  | exq (x : Nat) (a : Fm)

abbrev Asn := Nat → Nat

def upd (s : Asn) (x v : Nat) : Asn := fun n => if n == x then v else s n

def teval (t : Tm) (s : Asn) : Nat :=
  match t with
  | .var n => s n
  | .num n => n
  | .pls a b => teval a s + teval b s
  | .mul a b => teval a s * teval b s

def feval (φ : Fm) (s : Asn) : Prop :=
  match φ with
  | .eqt a b => teval a s = teval b s
  | .neg a => ¬ feval a s
  | .imp a b => feval a s → feval b s
  | .exq x a => ∃ v, feval a (upd s x v)

-- ============ 二、表示性样板：标准正确性真定理 ============

def s2 (x y : Nat) : Asn := upd (upd (fun _ => 0) 0 x) 1 y
def s3 (x y z : Nat) : Asn := upd (s2 x y) 2 z

def repAdd : Fm := .eqt (.pls (.var 0) (.var 1)) (.var 2)

theorem repAdd_ok (x y z : Nat) : feval repAdd (s3 x y z) ↔ x + y = z := by
  simp [repAdd, feval, teval, s3, s2, upd]

def repMul : Fm := .eqt (.mul (.var 0) (.var 1)) (.var 2)

theorem repMul_ok (x y z : Nat) : feval repMul (s3 x y z) ↔ x * y = z := by
  simp [repMul, feval, teval, s3, s2, upd]

def repLe : Fm := .exq 2 (.eqt (.pls (.var 0) (.var 2)) (.var 1))

theorem repLe_ok (x y : Nat) : feval repLe (s2 x y) ↔ x ≤ y := by
  constructor
  · rintro ⟨d, hd⟩
    simp only [repLe, feval, teval] at hd
    change x + d = y at hd
    omega
  · intro hle
    refine ⟨y - x, ?_⟩
    simp only [repLe, feval, teval]
    change x + (y - x) = y
    omega

def repEven : Fm := .exq 1 (.eqt (.pls (.var 1) (.var 1)) (.var 0))

theorem repEven_ok (x : Nat) :
    feval repEven (upd (fun _ => 0) 0 x) ↔ ∃ y, y + y = x := by
  constructor
  · rintro ⟨y, hy⟩
    simp only [repEven, feval, teval] at hy
    change y + y = x at hy
    exact ⟨y, hy⟩
  · rintro ⟨y, hy⟩
    refine ⟨y, ?_⟩
    simp only [repEven, feval, teval]
    change y + y = x
    exact hy

-- ============ 三、有限域可判定现场 ============

def fevalb (φ : Fm) (K : Nat) (s : Asn) : Bool :=
  match φ with
  | .eqt a b => teval a s == teval b s
  | .neg a => !fevalb a K s
  | .imp a b => (!fevalb a K s || fevalb b K s)
  | .exq x a => (List.range K).any (fun v => fevalb a K (upd s x v))

def qf : Fm → Bool
  | .eqt _ _ => true
  | .neg a => qf a
  | .imp a b => qf a && qf b
  | .exq _ _ => false

-- 无量词式：布尔求值与命题语义逐点一致（量词是有限/无穷的分水岭）
theorem qf_agree (φ : Fm) (h : qf φ = true) :
    ∀ (s : Asn) (K : Nat), fevalb φ K s = true ↔ feval φ s := by
  induction φ with
  | eqt a b =>
    intro s K
    simp [fevalb, feval]
  | neg a iha =>
    intro s K
    have ha : qf a = true := h
    specialize iha ha s K
    simp only [fevalb, feval]
    rw [Bool.not_eq_true']
    constructor
    · intro Hn Hfa
      have Hn' : ¬(fevalb a K s = true) := by
        intro hc; rw [Hn] at hc; exact Bool.noConfusion hc
      exact absurd (iha.mpr Hfa) Hn'
    · intro Hn
      cases hb : fevalb a K s with
      | false => rfl
      | true => exact absurd (iha.mp hb) Hn
  | imp a b iha ihb =>
    intro s K
    obtain ⟨ha, hb2⟩ : qf a = true ∧ qf b = true := by simpa [qf] using h
    specialize iha ha s K
    specialize ihb hb2 s K
    simp only [fevalb, feval]
    constructor
    · intro Hor Hfa
      have hA : fevalb a K s = true := iha.mpr Hfa
      rw [hA] at Hor
      simp only [Bool.not_true, Bool.true_or] at Hor
      exact ihb.mp Hor
    · intro Himp
      cases hA : fevalb a K s with
      | false => simp [hA]
      | true =>
        have hB : fevalb b K s = true := ihb.mpr (Himp (iha.mp hA))
        simp [hA, hB]
  | exq x a => simp [qf] at h

-- 现场一：同一句子的真值随论域变化——有限域真是相对的，N 真是绝对的。
-- senEven2 = ∃x (x+x ≡ 2)：论域 {0..4} 上真（x=1），论域 {0} 上假
def senEven2 : Fm := .exq 0 (.eqt (.pls (.var 0) (.var 0)) (.num 2))

example : fevalb senEven2 5 (fun _ => 0) = true := by native_decide
example : fevalb senEven2 1 (fun _ => 0) = false := by native_decide

-- 现场二：N 标准模型上它是真句子（定理而非计算——量词跑遍全体自然数）
theorem even2_true : ∃ v, v + v = 2 := ⟨1, rfl⟩

-- ============ 账本 ============

#print axioms repLe_ok
#print axioms repEven_ok
#print axioms qf_agree
