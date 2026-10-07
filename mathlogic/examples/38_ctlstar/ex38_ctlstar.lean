/- ex38_ctlstar —— CTL* 与 LTL/CTL 表达能力对照（Lean 4 版，H&R §3.5）

   与 Coq 版同构：互嵌两层语法 + 三组分离现场（AG EF p、E[G F p]、
   F G p vs AF AG p）+ 路径分类引理。 -/

namespace Ex38

mutual
inductive SForm where
  | sAtom (p : Nat) : SForm
  | sNeg (a : SForm) : SForm
  | sAnd (a b : SForm) : SForm
  | sA (pf : PForm) : SForm
  | sE (pf : PForm) : SForm

inductive PForm where
  | pState (sf : SForm) : PForm
  | pNeg (a : PForm) : PForm
  | pAnd (a b : PForm) : PForm
  | pX (a : PForm) : PForm
  | pG (a : PForm) : PForm
  | pF (a : PForm) : PForm
  | pU (a b : PForm) : PForm
end

open SForm PForm

structure Model where
  mlab : Nat → Bool
  mstep : Nat → List Nat

abbrev Pth := Nat → Nat

def IsPath (m : Model) (s : Nat) (π : Pth) : Prop :=
  π 0 = s ∧ ∀ i, (π (i + 1)) ∈ m.mstep (π i)

mutual
def sem (m : Model) (π : Pth) (i : Nat) : SForm → Prop
  | sAtom _ => m.mlab (π i) = true
  | sNeg a => ¬ sem m π i a
  | sAnd a b => sem m π i a ∧ sem m π i b
  | sA pf => ∀ π', IsPath m (π i) π' → psem m π' 0 pf
  | sE pf => ∃ π', IsPath m (π i) π' ∧ psem m π' 0 pf

def psem (m : Model) (π : Pth) (i : Nat) : PForm → Prop
  | pState sf => sem m π i sf
  | pNeg a => ¬ psem m π i a
  | pAnd a b => psem m π i a ∧ psem m π i b
  | pX a => psem m π (i + 1) a
  | pG a => ∀ j, i ≤ j → psem m π j a
  | pF a => ∃ j, i ≤ j ∧ psem m π j a
  | pU a b => ∃ j, i ≤ j ∧ psem m π j b ∧
              (∀ k, i ≤ k ∧ k < j → psem m π k a)
end

abbrev EFP : SForm := sE (pF (pState (sAtom 0)))
abbrev AGEFP : SForm := sA (pG (pState EFP))
abbrev EGFP : SForm := sE (pG (pF (pState (sAtom 0))))
abbrev AGP : SForm := sA (pG (pState (sAtom 0)))
abbrev AFAGP : SForm := sA (pF (pState AGP))
abbrev FGP : PForm := pF (pG (pState (sAtom 0)))

/- ---------- 分离模型 ---------- -/

def M : Model where
  mlab := fun s => match s with | 1 => true | _ => false
  mstep := fun s => match s with
    | 0 => [1, 2] | 1 => [1] | _ => [2, 1]

def M' : Model where
  mlab := fun s => match s with | 1 => true | _ => false
  mstep := fun s => match s with | 0 => [2] | _ => [2]

def N : Model where
  mlab := fun s => match s with | 0 => true | 1 => false | _ => true
  mstep := fun s => match s with | 0 => [0, 1] | 1 => [2] | _ => [2]

/- ---------- 见证路径 ---------- -/

def path01 : Pth := fun i => match i with | 0 => 0 | _ => 1
def path11 : Pth := fun _ => 1
def path21 : Pth := fun i => match i with | 0 => 2 | _ => 1
def path02 : Pth := fun i => match i with | 0 => 0 | _ => 2
def path012 : Pth := fun i => match i with | 0 => 0 | 1 => 1 | _ => 2
def path00 : Pth := fun _ => 0

theorem ipM01 : IsPath M 0 path01 := by
  refine ⟨rfl, ?_⟩
  intro i
  cases i with
  | zero => simp [path01, M]
  | succ i' => simp [path01, M]

theorem ipM11 : IsPath M 1 path11 := by
  refine ⟨rfl, ?_⟩; intro i
  simp [path11, M]

theorem ipM21 : IsPath M 2 path21 := by
  refine ⟨rfl, ?_⟩
  intro i
  cases i with
  | zero => simp [path21, M]
  | succ i' => simp [path21, M]

theorem ipM'02 : IsPath M' 0 path02 := by
  refine ⟨rfl, ?_⟩
  intro i
  cases i with
  | zero => simp [path02, M']
  | succ i' => simp [path02, M']

theorem ipN00 : IsPath N 0 path00 := by
  refine ⟨rfl, ?_⟩; intro i
  simp only [path00, N]; exact .head _

theorem ipN012 : IsPath N 0 path012 := by
  refine ⟨rfl, ?_⟩
  intro i
  cases i with
  | zero => simp [path012, N]
  | succ i' =>
    cases i' with
    | zero => simp only [path012, N]; exact .head _
    | succ _ => simp only [path012, N]; exact .head _

/- ---------- 路径分类 ---------- -/

theorem M_inv (π : Pth) (h : IsPath M 0 π) :
    ∀ i, π i = 0 ∨ π i = 1 ∨ π i = 2 := by
  obtain ⟨h0, hs⟩ := h
  intro i
  induction i with
  | zero => rw [h0]; exact Or.inl rfl
  | succ i ih =>
    specialize hs i
    rcases ih with E | E | E
    · rw [E] at hs; simp [M] at hs
      rcases hs with E2 | E2 <;>
        first | (simp only [E2]; decide) | (simp only [← E2]; decide)
    · rw [E] at hs; simp [M] at hs
      first | (simp only [hs]; decide) | (simp only [← hs]; decide)
    · rw [E] at hs; simp [M] at hs
      rcases hs with E2 | E2 <;>
        first | (simp only [E2]; decide) | (simp only [← E2]; decide)

theorem M'_stay2 (π : Pth) (h : IsPath M' 2 π) : ∀ i, π i = 2 := by
  obtain ⟨h0, hs⟩ := h
  intro i
  induction i with
  | zero => exact h0
  | succ i ih =>
    specialize hs i
    rw [ih] at hs
    simp [M'] at hs
    first | exact hs | exact hs.symm

theorem M'_paths (π : Pth) (h : IsPath M' 0 π) : ∀ i, π (i + 1) = 2 := by
  obtain ⟨h0, hs⟩ := h
  have h1 : π 1 = 2 := by
    specialize hs 0
    rw [h0] at hs
    simp [M'] at hs
    first | exact hs | exact hs.symm
  intro i
  induction i with
  | zero => exact h1
  | succ i ih =>
    specialize hs (i + 1)
    rw [ih] at hs
    simp [M'] at hs
    first | exact hs | exact hs.symm

theorem N_paths (π : Pth) (h : IsPath N 0 π) :
    (∀ i, π i = 0) ∨ ∃ n, π n = 1 ∧ ∀ k, n < k → π k = 2 := by
  obtain ⟨h0, hs⟩ := h
  have hfirst : ∀ i, π i ≠ 0 → ∃ n, n ≤ i ∧ π n = 1 := by
    intro i
    induction i with
    | zero =>
      intro hne
      exact absurd h0 hne
    | succ i ih =>
      intro hne
      by_cases hz : π i = 0
      · have h1 : π (i + 1) = 1 := by
          specialize hs i
          rw [hz] at hs
          simp [N] at hs
          rcases hs with E | E
          · first | exact absurd E hne | exact absurd E.symm hne
          · first | exact E | exact E.symm
        exact ⟨i + 1, by omega, h1⟩
      · obtain ⟨n, hn, h1⟩ := ih hz
        exact ⟨n, Nat.le_trans hn (Nat.le_succ i), h1⟩
  by_cases hex : ∃ n, π n = 1
  · obtain ⟨n, h1⟩ := hex
    refine Or.inr ⟨n, h1, ?_⟩
    have hk2 : π (n + 1) = 2 := by
      specialize hs n
      rw [h1] at hs
      simp [N] at hs
      first | exact hs | exact hs.symm
    intro k hk
    have hgen : ∀ j, π (n + 1 + j) = 2 := by
      intro j
      induction j with
      | zero => simpa using hk2
      | succ j ihj =>
        specialize hs (n + 1 + j)
        rw [ihj] at hs
        simp [N] at hs
        first | exact hs | exact hs.symm
    have : n + 1 + (k - n - 1) = k := by omega
    rw [← this]
    exact hgen _
  · refine Or.inl ?_
    intro i
    by_cases hz : π i = 0
    · exact hz
    · obtain ⟨n, _, h1⟩ := hfirst i hz
      exact absurd ⟨n, h1⟩ hex

/- ---------- (a) AG EF p：M ⊨ ---------- -/

theorem M_AGEFP (π : Pth) (h : IsPath M 0 π) : sem M π 0 AGEFP := by
  obtain ⟨h0, _⟩ := h
  simp only [sem, psem]
  rw [h0]
  intro π' hπ' j _
  rcases M_inv π' ⟨hπ'.1, hπ'.2⟩ j with E | E | E
  · rw [E]; exact ⟨path01, ipM01, 1, by omega, rfl⟩
  · rw [E]; exact ⟨path11, ipM11, 0, by omega, rfl⟩
  · rw [E]; exact ⟨path21, ipM21, 1, by omega, rfl⟩

/- ---------- (a) M' ⊭ ---------- -/

theorem M'_not_AGEFP : ¬ sem M' path02 0 AGEFP := by
  intro hall
  simp only [sem, psem] at hall
  obtain ⟨q, hq, hf⟩ := hall path02 ipM'02 1 (by omega)
  have hq2 := M'_stay2 q hq
  obtain ⟨j, _, hj⟩ := hf
  rw [hq2 j] at hj
  simp [M'] at hj

/- ---------- (b) E[G F p] ---------- -/

theorem M_EGFP : sem M path01 0 EGFP := by
  simp only [sem, psem]
  refine ⟨path01, ipM01, ?_⟩
  intro j _
  refine ⟨j + 1, by omega, ?_⟩
  cases j with
  | zero => rfl
  | succ j' => rfl

theorem M'_not_EGFP : ¬ sem M' path02 0 EGFP := by
  intro hall
  simp only [sem, psem] at hall
  obtain ⟨q, hq, hg⟩ := hall
  have hq2 := M'_paths q hq
  obtain ⟨j, hj1, hj⟩ := hg 1 (by omega)
  have eq2 : q j = 2 := by
    cases j with
    | zero => omega
    | succ j' => exact hq2 j'
  rw [eq2] at hj
  simp [M'] at hj

/- ---------- (c) F G p ⊨ 而 AF AG p ⊭ ---------- -/

theorem N_AFGP (π : Pth) (h : IsPath N 0 π) : psem N π 0 FGP := by
  simp only [psem]
  rcases N_paths π h with h0 | ⟨n, h1, h2⟩
  · refine ⟨0, by omega, ?_⟩
    intro j _
    show N.mlab (π j) = true
    rw [h0 j]; rfl
  · refine ⟨n + 1, by omega, ?_⟩
    intro k _
    have hk : π k = 2 := h2 k (by omega)
    show N.mlab (π k) = true
    rw [hk]; rfl

theorem N_not_AFAGP : ¬ sem N path00 0 AFAGP := by
  intro hall
  simp only [sem, psem] at hall
  obtain ⟨j, _, hj⟩ := hall path00 ipN00
  have hk := hj path012 ipN012 1 (by omega)
  simp [N, path012] at hk

end Ex38
