/- ex34_symbolicmc —— 符号模型检查与关系 μ 演算（Lean 4 版，H&R §6.3-6.4）

   与 Coq 版同构：preE 前像 + iterF 泛函迭代 + μ/ν 两种起跑
   + EG/EU 编码与 24 章迭代的同构引理。 -/
namespace Ex34

structure FModel where
  fstates : List Nat
  ftrans : Nat → List Nat

def memL (S : List Nat) (s : Nat) : Bool := S.any (· == s)

theorem memL_mem {S : List Nat} {s : Nat} : memL S s = true ↔ s ∈ S := by
  unfold memL; rw [List.any_eq_true]
  constructor
  · rintro ⟨x, hx, hxn⟩
    rw [beq_iff_eq] at hxn; rw [← hxn]; exact hx
  · intro h; exact ⟨s, h, beq_iff_eq.mpr rfl⟩

def interL (S T : List Nat) : List Nat := S.filter (memL T)
def unionL (S T : List Nat) : List Nat := S ++ T

theorem interL_mem {S T : List Nat} {s : Nat} :
    s ∈ interL S T ↔ s ∈ S ∧ s ∈ T := by
  simp only [interL, List.mem_filter]
  constructor
  · rintro ⟨h1, h2⟩; exact ⟨h1, memL_mem.mp h2⟩
  · rintro ⟨h1, h2⟩; exact ⟨h1, memL_mem.mpr h2⟩

theorem unionL_mem {S T : List Nat} {s : Nat} :
    s ∈ unionL S T ↔ s ∈ S ∨ s ∈ T := by
  simp only [unionL, List.mem_append]

/-- preE：前像（一步倒带） -/
def preE (m : FModel) (S : List Nat) : List Nat :=
  m.fstates.filter (fun s => (m.ftrans s).any (fun s' => memL S s'))

theorem preE_mem {m : FModel} {S : List Nat} {s : Nat}
    (hs : s ∈ m.fstates) :
    s ∈ preE m S ↔ ∃ s', s' ∈ m.ftrans s ∧ s' ∈ S := by
  simp only [preE, List.mem_filter]
  constructor
  · rintro ⟨_, hy⟩
    rw [List.any_eq_true] at hy
    obtain ⟨s', htr, hmem⟩ := hy
    exact ⟨s', htr, memL_mem.mp hmem⟩
  · rintro ⟨s', htr, hmem⟩
    refine ⟨hs, ?_⟩
    rw [List.any_eq_true]
    exact ⟨s', htr, memL_mem.mpr hmem⟩

/-- preE 单调 -/
theorem preE_mono (m : FModel) {S T : List Nat}
    (hsub : ∀ x, x ∈ S → x ∈ T) :
    ∀ x, x ∈ preE m S → x ∈ preE m T := by
  intro x hx
  have hst : x ∈ m.fstates := (List.mem_filter.mp hx).1
  rw [preE_mem hst] at hx ⊢
  obtain ⟨s', htr, hmem⟩ := hx
  exact ⟨s', htr, hsub s' hmem⟩

/-- 泛函迭代 -/
def iterF : Nat → (List Nat → List Nat) → List Nat → List Nat
  | 0, _, seed => seed
  | k + 1, F, seed => F (iterF k F seed)

def muFix (m : FModel) (F : List Nat → List Nat) : List Nat :=
  iterF (m.fstates.length + 1) F []          -- μ：⊥ 起涨

def nuFix (m : FModel) (F : List Nat → List Nat) : List Nat :=
  iterF (m.fstates.length + 1) F m.fstates   -- ν：⊤ 起压

/-- 24 章的直接迭代 -/
def iterEG (m : FModel) : Nat → List Nat → List Nat
  | 0, _ => m.fstates
  | k + 1, A => interL A (preE m (iterEG m k A))

def iterEU (m : FModel) : Nat → List Nat → List Nat → List Nat
  | 0, _, B => B
  | k + 1, A, B => unionL B (interL A (preE m (iterEU m k A B)))

def egFun (m : FModel) (A : List Nat) (Z : List Nat) : List Nat :=
  interL A (preE m Z)

def euFun (m : FModel) (A B : List Nat) (Z : List Nat) : List Nat :=
  unionL B (interL A (preE m Z))

/-- 旗舰二：ν 编码 = 直接迭代（同一条迭代链） -/
theorem iterF_is_iterEG (m : FModel) (fuel : Nat) (A : List Nat) :
    iterF fuel (fun Z => interL A (preE m Z)) m.fstates
    = iterEG m fuel A := by
  induction fuel with
  | zero => rfl
  | succ k ih => simp only [iterF, iterEG, ← ih]

/-- ν 编码定理 -/
theorem nu_eg_is_iterEG (m : FModel) (A : List Nat) :
    nuFix m (fun Z => egFun m A Z)
    = iterEG m (m.fstates.length + 1) A :=
  iterF_is_iterEG m _ A

/-- μ 的 ⊥-起跑与 EU 的 B-起跑差一轮 -/
theorem preE_empty (m : FModel) : preE m [] = [] := by
  apply List.eq_nil_iff_forall_not_mem.mpr
  intro x hx
  obtain ⟨_, hy⟩ := List.mem_filter.mp hx
  rw [List.any_eq_true] at hy
  obtain ⟨s', _, hmem⟩ := hy
  exact absurd (memL_mem.mp hmem) (by simp)

theorem interL_empty (S : List Nat) : interL S [] = [] := by
  apply List.eq_nil_iff_forall_not_mem.mpr
  intro x hx
  obtain ⟨_, hy⟩ := List.mem_filter.mp hx
  exact absurd (memL_mem.mp hy) (by simp)

theorem mu_seed_step (m : FModel) (A B : List Nat) :
    euFun m A B [] = B := by
  simp only [euFun, preE_empty m, interL_empty, unionL, List.append_nil]

/-- 旗舰三：μ 编码 = 直接迭代（轮次对齐后） -/
theorem iterF_is_iterEU (m : FModel) (fuel : Nat) (A B : List Nat) :
    iterF (fuel + 1) (fun Z => unionL B (interL A (preE m Z))) []
    = iterEU m fuel A B := by
  induction fuel with
  | zero => simp only [iterF, iterEU]; exact mu_seed_step m A B
  | succ k ih => simp only [iterF, iterEU, ← ih]

theorem mu_eu_is_iterEU (m : FModel) (A B : List Nat) :
    muFix m (fun Z => euFun m A B Z)
    = iterEU m m.fstates.length A B := by
  simp only [muFix, euFun]
  exact iterF_is_iterEU m _ A B

/-- 现场：两状态模型 0→1→1 -/
def m2 : FModel where
  fstates := [0, 1]
  ftrans := fun _ => [1]

example : memL (nuFix m2 (fun Z => egFun m2 [1] Z)) 1 = true := by rfl

example : memL (nuFix m2 (fun Z => egFun m2 [1] Z)) 0 = false := by rfl

example : memL (muFix m2 (fun Z => euFun m2 [1] [1] Z)) 1 = true := by rfl

example : memL (muFix m2 (fun Z => euFun m2 [1] [1] Z)) 0 = false := by rfl

end Ex34
