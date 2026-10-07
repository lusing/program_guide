/- ex35_label —— CTL 标记算法（Lean 4 版，H&R §3.6.1）

   与 Coq 版同构：satEX 前像 + iterEU 最小不动点迭代 + eufin_to_iter
   单方向正确性 + iterEG 减法迭代的子集性。
   设计注记：iterEU 每轮 = 旧集 ∪ (A 中有后继落入旧集者)——
   直接 filter A，避免 fstates 域条件的携带。 -/

namespace Ex35Label

structure FModel where
  fstates : List Nat
  ftrans : Nat → List Nat
  flab : Nat → Nat → Bool

def memList (S : List Nat) (s : Nat) : Bool := S.any (· == s)

theorem memList_mem {S : List Nat} {s : Nat} : memList S s = true ↔ s ∈ S := by
  unfold memList; rw [List.any_eq_true]
  constructor
  · rintro ⟨x, hx, hxn⟩
    rw [beq_iff_eq] at hxn; rw [← hxn]; exact hx
  · intro h; exact ⟨s, h, beq_iff_eq.mpr rfl⟩

def satEX (m : FModel) (S : List Nat) : List Nat :=
  m.fstates.filter (fun s => (m.ftrans s).any (fun s' => memList S s'))

theorem satEX_mem {m : FModel} {S : List Nat} {s : Nat}
    (hs : s ∈ m.fstates) :
    s ∈ satEX m S ↔ (∃ s', s' ∈ m.ftrans s ∧ s' ∈ S) := by
  simp only [satEX, List.mem_filter]
  constructor
  · intro h
    obtain ⟨_, hany⟩ := h
    rw [List.any_eq_true] at hany
    obtain ⟨s', htr', hmem⟩ := hany
    exact ⟨s', htr', memList_mem.mp hmem⟩
  · rintro ⟨s', htr', hmem⟩
    refine ⟨hs, ?_⟩
    rw [List.any_eq_true]
    exact ⟨s', htr', memList_mem.mpr hmem⟩

def iterEU (m : FModel) : Nat → List Nat → List Nat → List Nat
  | 0, _, B => B
  | k + 1, A, B =>
      iterEU m k A B ++
      A.filter (fun x => (m.ftrans x).any (fun s' => memList (iterEU m k A B) s'))

theorem iterEU_mem_step {m : FModel} {k : Nat} {A B : List Nat} {s : Nat} :
    s ∈ iterEU m (k + 1) A B ↔
    s ∈ iterEU m k A B ∨ (s ∈ A ∧ ∃ s', s' ∈ m.ftrans s ∧ s' ∈ iterEU m k A B) := by
  simp only [iterEU, List.mem_append, List.mem_filter, List.any_eq_true]
  constructor
  · rintro (h | ⟨h1, s', htr', hmem⟩)
    · exact Or.inl h
    · refine Or.inr ⟨h1, s', htr', ?_⟩; exact memList_mem.mp hmem
  · rintro (h | ⟨h1, s', htr', hin⟩)
    · exact Or.inl h
    · exact Or.inr ⟨h1, s', htr', memList_mem.mpr hin⟩

theorem iterEU_mono {m : FModel} {k : Nat} {A B : List Nat} :
    ∀ s ∈ iterEU m k A B, s ∈ iterEU m (k + 1) A B := by
  intro s hin
  rw [iterEU_mem_step]
  exact Or.inl hin

theorem iterEU_mono_le {m : FModel} {d1 d2 : Nat} {A B : List Nat}
    (hle : d1 ≤ d2) : ∀ s ∈ iterEU m d1 A B, s ∈ iterEU m d2 A B := by
  intro s hin
  induction hle with
  | refl => exact hin
  | @step d2' _ ih => exact iterEU_mono s ih

/-- 有限深度 EU 语义 -/
def eufin (m : FModel) (d : Nat) (s : Nat) (ap bp : Nat → Bool) : Prop :=
  match d with
  | 0 => bp s = true
  | d' + 1 => bp s = true ∨
      (ap s = true ∧ ∃ s', s' ∈ m.ftrans s ∧ eufin m d' s' ap bp)

/-- EU 标记的正确性（语义 ⟹ 迭代成员；反向登记边界） -/
theorem eufin_to_iter {m : FModel} {ap bp : Nat → Bool} {A B : List Nat}
    (HA : ∀ x, x ∈ A ↔ ap x = true)
    (HB : ∀ x, x ∈ B ↔ bp x = true) :
    ∀ d s, eufin m d s ap bp → s ∈ iterEU m d A B := by
  intro d
  induction d with
  | zero =>
    intro s h
    simp only [eufin] at h
    exact (HB s).mpr h
  | succ d' ih =>
    intro s h
    simp only [eufin] at h
    rw [iterEU_mem_step]
    cases h with
    | inl hb =>
      left
      exact iterEU_mono_le (Nat.zero_le d') s ((HB s).mpr hb)
    | inr hand =>
      obtain ⟨ha, s', htr', hd⟩ := hand
      right
      exact ⟨(HA s).mpr ha, s', htr', ih s' hd⟩

/-- EG 减法迭代：子集性（最大不动点的结构构件） -/
def iterEG (m : FModel) : Nat → List Nat → List Nat
  | 0, _ => m.fstates
  | k + 1, A => A.filter (fun x => (m.ftrans x).any (fun s' => memList (iterEG m k A) s'))

theorem iterEG_sub {m : FModel} {k : Nat} {A : List Nat} :
    ∀ s ∈ iterEG m (k + 1) A, s ∈ A := by
  intro s hin
  simp only [iterEG, List.mem_filter] at hin
  exact hin.1

/- 现场演示：两状态模型 0→1→1（自环） -/

def m2 : FModel where
  fstates := [0, 1]
  ftrans := fun _ => [1]
  flab := fun s p => match s, p with
    | 1, 0 => true
    | _, _ => false

example : satEX m2 [1] = [0, 1] := by rfl

example : iterEU m2 2 [1] [] = [] := by rfl

example : (iterEU m2 3 [1] [1]).any (· == 1) = true := by rfl

example : iterEG m2 1 [1] = [1] := by rfl

end Ex35Label
