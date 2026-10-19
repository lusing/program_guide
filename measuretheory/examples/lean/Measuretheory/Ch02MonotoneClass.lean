import Mathlib.MeasureTheory.PiSystem

/-!
# 第 02 章 单调类定理·集合形式（Lean）

严书 §1.2。手工定义单调类 / λ 类（Dynkin 类）/ σ 类，并证明单调类定理
的两个核心引擎：

1. 代数 + 单调类 ⟹ σ 类（部分和列的单调极限技巧）；
2. λ 类 + π-系 ⟹ σ 类（不交化技巧）。

这两条正是"在生成系上验证性质即可"这一测度论基本策略的形式化内核。
mathlib 侧的对应物是 `ext_of_generateFrom_of_iUnion`（第 06 章锚点）。
-/

section Defs

variable {α : Type*}

/-- σ 类：含全集，对补与可列并封闭（= 一个 σ-代数的载体）。 -/
def IsSigmaClass (C : Set (Set α)) : Prop :=
  Set.univ ∈ C ∧ (∀ A ∈ C, Aᶜ ∈ C) ∧
    (∀ f : ℕ → Set α, (∀ n, f n ∈ C) → (⋃ n, f n) ∈ C)

/-- 单调类：对单调递增列的并与单调递减列的交封闭。 -/
def IsMonotoneClass (C : Set (Set α)) : Prop :=
  (∀ f : ℕ → Set α, (∀ n, f n ∈ C) → Monotone f → (⋃ n, f n) ∈ C) ∧
  (∀ f : ℕ → Set α, (∀ n, f n ∈ C) → Antitone f → (⋂ n, f n) ∈ C)

/-- λ 类（Dynkin 类）：含全集，对真差封闭，对可列不交并封闭。 -/
def IsLambdaClass (C : Set (Set α)) : Prop :=
  Set.univ ∈ C ∧ (∀ A ∈ C, ∀ B ∈ C, B ⊆ A → A \ B ∈ C) ∧
    (∀ f : ℕ → Set α, (∀ n, f n ∈ C) → (∀ i j, i ≠ j → Disjoint (f i) (f j)) → (⋃ n, f n) ∈ C)

/-- 集代数：含全集，对补与二元并封闭。 -/
def IsAlgebraClass (C : Set (Set α)) : Prop :=
  Set.univ ∈ C ∧ (∀ A ∈ C, Aᶜ ∈ C) ∧ (∀ A ∈ C, ∀ B ∈ C, A ∪ B ∈ C)

end Defs

section Engine1

variable {α : Type*} {C : Set (Set α)}

/-- 单调类定理引擎一：代数若又是单调类，则已是 σ 类。

关键技巧：任意可列并 ∪ₙ fₙ 化为部分和列 Bₙ = f₀ ∪ … ∪ fₙ（递归定义）
的单调递增极限——代数给有限并，单调类接管极限。 -/
theorem algebraClass_monotone_isSigma (hAlg : IsAlgebraClass C)
    (hMono : IsMonotoneClass C) : IsSigmaClass C := by
  obtain ⟨huniv, hcomp, hunion⟩ := hAlg
  obtain ⟨hup, _hdown⟩ := hMono
  refine ⟨huniv, hcomp, ?_⟩
  intro f hf
  -- 部分和列：B 0 = f 0；B (n+1) = B n ∪ f (n+1)
  have hstep : ∀ n : ℕ, (⋃ k ≤ n + 1, f k) = (⋃ k ≤ n, f k) ∪ f (n + 1) := by
    intro n
    ext x
    simp only [Set.mem_iUnion, exists_prop, Set.mem_union]
    constructor
    · rintro ⟨k, hk, hx⟩
      rcases Nat.lt_or_ge k (n + 1) with h | h
      · exact Or.inl ⟨k, Nat.lt_succ_iff.mp h, hx⟩
      · exact Or.inr (Nat.le_antisymm hk h ▸ hx)
    · rintro (⟨k, hk, hx⟩ | hx)
      · exact ⟨k, hk.trans (Nat.le_succ n), hx⟩
      · exact ⟨n + 1, le_refl _, hx⟩
  obtain ⟨B, hB0, hBstep⟩ :
      ∃ B : ℕ → Set α, B 0 = f 0 ∧ ∀ n, B (n + 1) = B n ∪ f (n + 1) :=
    ⟨fun n => ⋃ k ≤ n, f k, by ext x; simp, hstep⟩
  have hBin : ∀ n, B n ∈ C := by
    intro n
    induction n with
    | zero => rw [hB0]; exact hf 0
    | succ n ih => rw [hBstep]; exact hunion _ ih _ (hf (n + 1))
  have hBmono : Monotone B := by
    have key : ∀ b a, a ≤ b → ∀ {x}, x ∈ B a → x ∈ B b := by
      intro b
      induction b with
      | zero =>
        intro a ha x hx
        rw [Nat.le_zero.mp ha] at hx; exact hx
      | succ b ih =>
        intro a ha x hx
        rcases Nat.lt_or_ge a (b + 1) with h | h
        · rw [hBstep]; exact Or.inl (ih a (Nat.lt_succ_iff.mp h) hx)
        · rw [Nat.le_antisymm ha h] at hx; exact hx
    intro a b hab x hx
    exact key b a hab hx
  have hcover : (⋃ n, f n) = (⋃ n, B n) := by
    ext x
    simp only [Set.mem_iUnion]
    constructor
    · rintro ⟨n, hx⟩
      have fsub : ∀ n, x ∈ f n → x ∈ B n := by
        intro n
        induction n with
        | zero => intro hx; rw [hB0]; exact hx
        | succ n ih => intro hx; rw [hBstep]; exact Or.inr hx
      exact ⟨n, fsub n hx⟩
    · rintro ⟨n, hn⟩
      have bsub : ∀ n, x ∈ B n → ∃ m, x ∈ f m := by
        intro n
        induction n with
        | zero => intro hn; rw [hB0] at hn; exact ⟨0, hn⟩
        | succ n ih =>
          intro hn
          rw [hBstep] at hn
          rcases hn with h | h
          · exact ih h
          · exact ⟨n + 1, h⟩
      exact bsub n hn
  rw [hcover]
  exact hup B hBin hBmono

end Engine1

section Engine2

variable {α : Type*} {C : Set (Set α)}

/-- λ 类若对交封闭（即同时是 π-系），则已是 σ 类——Dynkin π-λ 定理的
"读出"方向；极小性论证（λ(π系) = σ(π系)）见正文文字证明。

关键技巧：先由交封闭导出补封闭与二元并封闭（De Morgan），再把任意
可列并不交化为 Dₙ = fₙ \ ∪_{k<n} fₖ。 -/
theorem lambdaClass_pi_isSigma (hL : IsLambdaClass C)
    (hPi : ∀ A ∈ C, ∀ B ∈ C, A ∩ B ∈ C) : IsSigmaClass C := by
  obtain ⟨huniv, hdiff, hdisj⟩ := hL
  -- 补封闭：Aᶜ = univ \ A（真差）
  have hcomp : ∀ A ∈ C, Aᶜ ∈ C := by
    intro A hA
    rw [Set.compl_eq_univ_sdiff]
    exact hdiff _ huniv _ hA (Set.subset_univ _)
  -- 空集属于 C
  have hempty : (∅ : Set α) ∈ C := by
    have hzz : (∅ : Set α) = Set.univ \ Set.univ := (Set.sdiff_self).symm
    rw [hzz]
    exact hdiff _ huniv _ huniv (subset_refl _)
  -- 一般差：A \ B = A ∩ Bᶜ
  have hdiff2 : ∀ A ∈ C, ∀ B ∈ C, A \ B ∈ C := by
    intro A hA B hB
    rw [Set.sdiff_eq]
    exact hPi A hA _ (hcomp B hB)
  -- 二元并：A ∪ B = (Aᶜ ∩ Bᶜ)ᶜ（De Morgan，无需不交化）
  have hunion2 : ∀ A ∈ C, ∀ B ∈ C, A ∪ B ∈ C := by
    intro A hA B hB
    have h1 : Aᶜ ∩ Bᶜ ∈ C := hPi _ (hcomp A hA) _ (hcomp B hB)
    have h2 : A ∪ B = (Aᶜ ∩ Bᶜ)ᶜ := Set.union_eq_compl_compl_inter_compl A B
    rw [h2]
    exact hcomp _ h1
  -- 任意可列并：不交化 Dₙ = fₙ \ ∪_{k<n} fₖ
  refine ⟨huniv, hcomp, ?_⟩
  intro f hf
  have hSn : ∀ n, (⋃ k < n, f k) ∈ C := by
    intro n
    induction n with
    | zero => simpa using hempty
    | succ n ih =>
      have hsplit : (⋃ k < n + 1, f k) = (⋃ k < n, f k) ∪ f n := by
        ext x
        simp only [Set.mem_iUnion, Set.mem_union, exists_prop]
        constructor
        · rintro ⟨k, hk, hx⟩
          rcases Nat.lt_succ_iff_lt_or_eq.mp hk with h | h
          · exact Or.inl ⟨k, h, hx⟩
          · exact Or.inr (h ▸ hx)
        · rintro (⟨k, hk, hx⟩ | hx)
          · exact ⟨k, Nat.lt_succ_of_lt hk, hx⟩
          · exact ⟨n, Nat.lt_succ_self n, hx⟩
      rw [hsplit]
      exact hunion2 _ ih _ (hf n)
  obtain ⟨D, hDdef⟩ : ∃ D : ℕ → Set α, ∀ n, D n = f n \ ⋃ k < n, f k :=
    ⟨fun n => f n \ ⋃ k < n, f k, fun _ => rfl⟩
  have hDin : ∀ n, D n ∈ C := by
    intro n
    rw [hDdef]
    exact hdiff2 _ (hf n) _ (hSn n)
  have hDpair : ∀ i j, i ≠ j → Disjoint (D i) (D j) := by
    intro i j hij
    refine Set.disjoint_left.mpr ?_
    intro x hxi hxj
    rw [hDdef] at hxi hxj
    rcases Nat.lt_or_ge i j with h | h
    · exact absurd (Set.mem_iUnion₂.2 ⟨i, h, hxi.1⟩) hxj.2
    · have hjlt : j < i := Nat.lt_of_le_of_ne h hij.symm
      exact absurd (Set.mem_iUnion₂.2 ⟨j, hjlt, hxj.1⟩) hxi.2
  have hDcover : (⋃ n, f n) = (⋃ n, D n) := by
    ext x
    simp only [Set.mem_iUnion]
    constructor
    · -- 取最早出现指标：强归纳
      have key : ∀ n, x ∈ f n → ∃ m, x ∈ D m := by
        intro n
        induction n using Nat.strong_induction_on with
        | h n ih =>
          intro hx
          by_cases h : x ∈ ⋃ k < n, f k
          · obtain ⟨k, hk, hxk⟩ := Set.mem_iUnion₂.mp h
            exact ih k hk hxk
          · exact ⟨n, by rw [hDdef]; exact ⟨hx, h⟩⟩
      rintro ⟨n, hx⟩
      exact key n hx
    · rintro ⟨n, hn⟩
      rw [hDdef] at hn
      exact ⟨n, hn.1⟩
  rw [hDcover]
  exact hdisj _ hDin hDpair

end Engine2
