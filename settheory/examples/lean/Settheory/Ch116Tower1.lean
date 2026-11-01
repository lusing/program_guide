import Mathlib.Data.List.Basic
import Mathlib.Tactic.IntervalCases

/-!
# 第 116 章 · 荟萃塔 I：定义、力迫与泛型超幂

锚点（有限影子：载体 U = {0,1,2}，子集 = 点到 Bool 的函数）：
- `imageN`/`clubf`：无界闭集的一元影子 C_f = {A | f[A] ⊆ A}
  （定义 3.10 的机制核——「对分裂函数封闭」的有限替身）；
- `clubf_empty`/`clubf_univ`/`gcyc_orbit`/`clubf_gcyc_char`：
  ∅ 与 U 属于每个 club；轮换的 club 最小——荟萃性的完全刻画
  （引理 3.26 的影子）；
- `smn_iff`/`smn_trivial`/`smn_X2_fail`：荟萃 ⟺ 含 ∅ 或含 U；
  平凡荟萃集（∪X ∈ X 的影子）；三点余单点族被轮换打败——
  非平凡反例；
- `eqset`/`feq`：泛型超幂的等价类机制——f ~_G g ⟺ 相等集
  属于滤子（引理 3.36 前置的 ~ 关系：自反/对称/传递与常值刻画）。

本体（定义 3.10 的序列函数 (∪X)^<ω、引理 3.24 的编码、P_δ、
≤/≤_w、Łoś 3.30、良基性 3.33）留在正文 docs/116-tower1.md。
-/

namespace Settheory.Ch116Tower1

open Classical in
/-- 子集 = 点到 Bool 的函数（载体 U = {0,1,2}）。 -/
abbrev Subset := Nat → Bool

def emp : Subset := fun _ => false

def univ : Subset := fun b => decide (b < 3)

/-- 余单点族成员：U − {i}。 -/
def co (i : Nat) : Subset := fun b => decide (b < 3 ∧ b ≠ i)

/-- 轮换 g = (012)：无不动点。 -/
def gcyc (i : Nat) : Nat := if i = 0 then 1 else if i = 1 then 2 else 0

lemma gcyc_0 : gcyc 0 = 1 := by simp [gcyc]
lemma gcyc_1 : gcyc 1 = 2 := by simp [gcyc]
lemma gcyc_2 : gcyc 2 = 0 := by simp [gcyc]

lemma gcyc_lt {i : Nat} (h : i < 3) : gcyc i < 3 := by
  interval_cases i <;> simp [gcyc]

lemma gcyc_orbit3 (i : Nat) (h : i < 3) : gcyc (gcyc (gcyc i)) = i := by
  interval_cases i <;> simp [gcyc]

lemma gcyc_ne_self (i : Nat) (h : i < 3) : gcyc (gcyc i) ≠ i := by
  interval_cases i <;> simp [gcyc]

open Classical in
/-- 像（只在载体上取）：imageN f A 的成员是某个 a ∈ A 的 f 像。 -/
noncomputable def imageN (f : Nat → Nat) (A : Subset) : Subset :=
  fun b => decide (b < 3 ∧ ∃ a, a < 3 ∧ A a = true ∧ f a = b)

open Classical in
lemma imageN_intro (f : Nat → Nat) (A : Subset) (a : Nat) (hb3 : f a < 3)
    (ha3 : a < 3) (haA : A a = true) : imageN f A (f a) = true := by
  simp only [imageN, decide_eq_true_eq]
  exact ⟨hb3, a, ha3, haA, rfl⟩

open Classical in
lemma imageN_elim (f : Nat → Nat) (A : Subset) (b : Nat)
    (h : imageN f A b = true) :
    b < 3 ∧ ∃ a, a < 3 ∧ A a = true ∧ f a = b := by
  simp only [imageN, decide_eq_true_eq] at h
  exact h

/-- 无界闭集（一元影子）：C_f = {A | f[A] ⊆ A}。 -/
def clubf (f : Nat → Nat) (A : Subset) : Prop :=
  ∀ b, imageN f A b = true → A b = true

/-! ## 件 A：club 的基本事实 -/

/-- ∅ 属于每个 club：f[∅] = ∅ ⊆ ∅。 -/
theorem clubf_empty (f : Nat → Nat) : clubf f emp := by
  intro b hb
  obtain ⟨-, ⟨a, -, ha, -⟩⟩ := imageN_elim f emp b hb
  exact absurd ha (by simp [emp])

/-- U 属于每个 club：像只在载体上取。 -/
theorem clubf_univ (f : Nat → Nat) : clubf f univ := by
  intro b hb
  obtain ⟨hb3, -⟩ := imageN_elim f univ b hb
  simp only [univ]
  exact decide_eq_true hb3

/-- 轮换轨道：a ∈ A ∧ A 对轮换封闭 ⟹ 整条轨道在 A 中。 -/
theorem gcyc_orbit (A : Subset) (h : clubf gcyc A) {a : Nat}
    (ha3 : a < 3) (haA : A a = true) :
    A (gcyc a) = true ∧ A (gcyc (gcyc a)) = true := by
  have h1 : A (gcyc a) = true :=
    h _ (imageN_intro gcyc A a (gcyc_lt ha3) ha3 haA)
  exact ⟨h1, h _ (imageN_intro gcyc A (gcyc a)
    (gcyc_lt (gcyc_lt ha3)) (gcyc_lt ha3) h1)⟩

/-- 轮换的 club 最小：对轮换封闭的载体子集只有 ∅ 与 U。 -/
theorem clubf_gcyc_char (A : Subset) (hA : ∀ b, A b = true → b < 3) :
    clubf gcyc A ↔ (A = emp ∨ A = univ) := by
  constructor
  · intro h
    by_cases hw : ∃ a, a < 3 ∧ A a = true
    · right
      obtain ⟨a, ha3, haA⟩ := hw
      obtain ⟨h1, h2⟩ := gcyc_orbit A h ha3 haA
      funext b
      by_cases hb : b < 3
      · have hbA : A b = true := by
          interval_cases a <;> interval_cases b <;>
            first | exact haA | exact h1 | exact h2
        simp [univ, hbA, hb]
      · have hb' : A b = false := by
          cases hbv : A b with
          | false => rfl
          | true => exact absurd (hA b hbv) hb
        simp [univ, hb', hb]
    · left
      funext b
      cases hbv : A b with
      | false => rfl
      | true => exact absurd ⟨b, hA b hbv, hbv⟩ hw
  · intro h
    rcases h with rfl | rfl
    · exact clubf_empty gcyc
    · exact clubf_univ gcyc

/-! ## 荟萃性的完全刻画（引理 3.26 的影子） -/

/-- 荟萃（一元影子）：与每个 club 相交。 -/
def smn (X : List Subset) : Prop :=
  ∀ f, ∃ A ∈ X, clubf f A

theorem smn_iff (X : List Subset) (hX : ∀ A ∈ X, ∀ b, A b = true → b < 3) :
    smn X ↔ (emp ∈ X ∨ univ ∈ X) := by
  constructor
  · intro h
    obtain ⟨A, hA, hc⟩ := h gcyc
    rcases (clubf_gcyc_char A (hX A hA)).mp hc with rfl | rfl
    · exact Or.inl hA
    · exact Or.inr hA
  · intro h f
    rcases h with h | h
    · exact ⟨emp, h, clubf_empty f⟩
    · exact ⟨univ, h, clubf_univ f⟩

/-- 平凡荟萃集：∪X ∈ X 的影子（U ∈ X ⟹ 荟萃）。 -/
theorem smn_trivial (X : List Subset) (hX : ∀ A ∈ X, ∀ b, A b = true → b < 3)
    (h : univ ∈ X) : smn X := by
  rw [smn_iff X hX]
  exact Or.inr h

/-- 非平凡反例：三点余单点族被轮换打败（非荟萃）。 -/
theorem not_clubf_gcyc_co (i : Nat) (hi : i < 3) : ¬ clubf gcyc (co i) := by
  intro h
  have h1 : co i (gcyc (gcyc i)) = true := by
    simp only [co, decide_eq_true_eq]
    exact ⟨gcyc_lt (gcyc_lt hi), gcyc_ne_self i hi⟩
  have hb3 : gcyc (gcyc (gcyc i)) < 3 := by
    rw [gcyc_orbit3 i hi]
    exact hi
  have hw : imageN gcyc (co i) i = true := by
    have h2 := imageN_intro gcyc (co i) (gcyc (gcyc i)) hb3
      (gcyc_lt (gcyc_lt hi)) h1
    rw [gcyc_orbit3 i hi] at h2
    exact h2
  have hbad : co i i = true := h i hw
  simp only [co, decide_eq_true_eq] at hbad
  exact absurd rfl hbad.2

theorem smn_X2_fail : ¬ smn [co 0, co 1, co 2] := by
  intro hs
  obtain ⟨A, hA, hc⟩ := hs gcyc
  rcases List.mem_cons.1 hA with rfl | hA
  · exact not_clubf_gcyc_co 0 (by norm_num) hc
  rcases List.mem_cons.1 hA with rfl | hA
  · exact not_clubf_gcyc_co 1 (by norm_num) hc
  rcases List.mem_cons.1 hA with rfl | hA
  · exact not_clubf_gcyc_co 2 (by norm_num) hc
  cases hA

/-! ## 件 D/E：泛型超幂的等价类机制（引理 3.36 前置的 ~_G） -/

/-- 相等集：eqset f g = {b ∈ U | f b = g b}。 -/
def eqset (f g : Nat → Nat) : Subset :=
  fun b => decide (b < 3 ∧ f b = g b)

/-- f ~_G g ⟺ 相等集属于 G。 -/
def feq (G : Subset → Prop) (f g : Nat → Nat) : Prop := G (eqset f g)

/-- 自反：univ ∈ G + 向上封闭。 -/
theorem feq_refl (G : Subset → Prop) (f : Nat → Nat) (hfull : G univ)
    (hup : ∀ B C, (∀ b, B b = true → C b = true) → G B → G C) :
    feq G f f := by
  refine hup univ (eqset f f) ?_ hfull
  intro b hb
  simp only [univ, eqset, decide_eq_true_eq] at hb ⊢
  exact ⟨hb, trivial⟩

/-- 对称：相等集的可交换性。 -/
theorem feq_sym (G : Subset → Prop) (f g : Nat → Nat) (h : feq G f g) :
    feq G g f := by
  have he : eqset f g = eqset g f := by
    funext b
    by_cases h3 : b < 3
    · by_cases heg : f b = g b
      · simp [eqset, h3, heg]
      · simp [eqset, h3, heg, Ne.symm heg]
    · simp [eqset, h3]
  unfold feq at h ⊢
  rw [← he]
  exact h

/-- 传递：滤子的交封闭（eqset f k ⊇ eqset f g ∩ eqset g k）。 -/
theorem feq_trans (G : Subset → Prop) (f g k : Nat → Nat)
    (hup : ∀ B C, (∀ b, B b = true → C b = true) → G B → G C)
    (hand : ∀ B C, G B → G C → G (fun b => B b && C b))
    (h1 : feq G f g) (h2 : feq G g k) : feq G f k := by
  refine hup _ (eqset f k) ?_ (hand (eqset f g) (eqset g k) h1 h2)
  intro b hb
  simp only [eqset, decide_eq_true_eq, Bool.and_eq_true] at hb ⊢
  exact ⟨hb.1.1, hb.1.2.trans hb.2.2⟩

/-- 常值刻画：[f] = [常值 c] ⟺ {b ∈ U | f b = c} ∈ G
（引理 3.36 的影子——等价于常值当且仅当相等集进滤子）。 -/
theorem feq_const (G : Subset → Prop) (f : Nat → Nat) (c : Nat) :
    feq G f (fun _ => c) ↔
      G (fun b => decide (b < 3 ∧ f b = c)) :=
  Iff.rfl

end Settheory.Ch116Tower1
