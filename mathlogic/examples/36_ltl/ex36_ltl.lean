/- ex36_ltl —— LTL 线性时态逻辑（Lean 4 版，H&R §3.2）

   与 Coq 版同构：路径=位置→原子赋值；lsat 为公式结构上的递归
   （Lean 的 `def … : Prop` 对 Prop 递归合法——G/U 处是全称/存在
   命题，不做 Fixpoint 停机检查）；等价族六件，经典成分显式记账。 -/

namespace Ex36

inductive Ltl where
  | lAtom (a : Nat) : Ltl
  | lTrue : Ltl
  | lNeg  (a : Ltl) : Ltl
  | lAnd  (a b : Ltl) : Ltl
  | lOr   (a b : Ltl) : Ltl
  | lX    (a : Ltl) : Ltl
  | lF    (a : Ltl) : Ltl
  | lG    (a : Ltl) : Ltl
  | lU    (a b : Ltl) : Ltl

open Ltl

/-- 路径：位置 → 原子赋值 -/
abbrev Path := Nat → Nat → Bool

/-- 满足关系：公式结构上递归（U 的位置见证无界不妨碍公式递归） -/
def lsat (p : Path) (i : Nat) : Ltl → Prop
  | lAtom a => p i a = true
  | lTrue => True
  | lNeg a => ¬ lsat p i a
  | lAnd a b => lsat p i a ∧ lsat p i b
  | lOr a b => lsat p i a ∨ lsat p i b
  | lX a => lsat p (i + 1) a
  | lF a => ∃ j, i ≤ j ∧ lsat p j a
  | lG a => ∀ j, i ≤ j → lsat p j a
  | lU a b => ∃ j, i ≤ j ∧ lsat p j b ∧ (∀ k, i ≤ k ∧ k < j → lsat p k a)

/- ---------- 等价族（H&R 式 3.3-3.6 一带） ---------- -/

/-- F φ ≡ ⊤ U φ（无公理） -/
theorem F_unfold (p : Path) (i : Nat) (f : Ltl) :
    lsat p i (lF f) ↔ lsat p i (lU lTrue f) := by
  simp only [lsat]
  constructor
  · intro h
    obtain ⟨j, hij, hf⟩ := h
    exact ⟨j, hij, hf, fun _ _ => trivial⟩
  · intro h
    obtain ⟨j, hij, hf, _⟩ := h
    exact ⟨j, hij, hf⟩

/-- G φ → ¬F ¬φ（对偶正向，无公理） -/
theorem G_dual_fwd (p : Path) (i : Nat) (f : Ltl)
    (hg : lsat p i (lG f)) : lsat p i (lNeg (lF (lNeg f))) := by
  simp only [lsat] at *
  intro h
  obtain ⟨j, hij, hnf⟩ := h
  exact hnf (hg j hij)

/-- ¬F ¬φ → G φ：反向是经典步骤（每位置的排中），Classical.em 入账公示 -/
theorem G_dual_bwd (p : Path) (i : Nat) (f : Ltl)
    (hn : lsat p i (lNeg (lF (lNeg f)))) : lsat p i (lG f) := by
  simp only [lsat] at *
  intro j hj
  cases Classical.em (lsat p j f) with
  | inl hf => exact hf
  | inr hnf => exact absurd (⟨j, hj, hnf⟩ : ∃ j, i ≤ j ∧ ¬ lsat p j f) hn

/-- F 的析取分配：F(f ∨ g) ≡ F f ∨ F g（无公理） -/
theorem F_or (p : Path) (i : Nat) (f g : Ltl) :
    lsat p i (lF (lOr f g)) ↔ lsat p i (lF f) ∨ lsat p i (lF g) := by
  simp only [lsat]
  constructor
  · intro h
    obtain ⟨j, hij, hor⟩ := h
    cases hor with
    | inl hf => exact Or.inl ⟨j, hij, hf⟩
    | inr hg => exact Or.inr ⟨j, hij, hg⟩
  · intro h
    cases h with
    | inl hf =>
      obtain ⟨j, hij, hf⟩ := hf
      exact ⟨j, hij, Or.inl hf⟩
    | inr hg =>
      obtain ⟨j, hij, hg⟩ := hg
      exact ⟨j, hij, Or.inr hg⟩

/-- G 的合取分配：G(f ∧ g) ≡ G f ∧ G g（无公理） -/
theorem G_and (p : Path) (i : Nat) (f g : Ltl) :
    lsat p i (lG (lAnd f g)) ↔ lsat p i (lG f) ∧ lsat p i (lG g) := by
  simp only [lsat]
  constructor
  · intro h
    exact ⟨fun j hj => (h j hj).1, fun j hj => (h j hj).2⟩
  · intro h j hj
    exact ⟨h.1 j hj, h.2 j hj⟩

/-- F 的幂等：F F φ ≡ F φ（无公理） -/
theorem F_idem (p : Path) (i : Nat) (f : Ltl) :
    lsat p i (lF (lF f)) ↔ lsat p i (lF f) := by
  simp only [lsat]
  constructor
  · intro h
    obtain ⟨j, hij, k, hjk, hk⟩ := h
    exact ⟨k, by omega, hk⟩
  · intro h
    obtain ⟨j, hij, hj⟩ := h
    exact ⟨j, hij, j, Nat.le_refl j, hj⟩

/-- X 的否定交换：X ¬φ ≡ ¬ X φ（无公理） -/
theorem X_neg (p : Path) (i : Nat) (f : Ltl) :
    lsat p i (lX (lNeg f)) ↔ lsat p i (lNeg (lX f)) := by
  simp only [lsat]

/- ---------- 现场：路径上的模式求值 ---------- -/

def ptrue : Path := fun _ _ => true

example : ∀ i, lsat ptrue i (lG (lAtom 0)) := by
  intro i j _; rfl

example : ∀ i, lsat ptrue i (lU (lAtom 0) (lAtom 1)) := by
  intro i; exact ⟨i, Nat.le_refl i, rfl, fun _ _ => rfl⟩

/-- 脉冲路径：原子 5 只在位置 3 为真 -/
def ppulse : Path := fun i a =>
  if Nat.beq i 3 then Nat.beq a 5 else false

example : ∀ i ≤ 3, lsat ppulse i (lF (lAtom 5)) := by
  intro i hi; exact ⟨3, hi, rfl⟩

example : lsat ppulse 0 (lX (lX (lX (lAtom 5)))) := rfl

#print axioms F_unfold     -- 无公理
#print axioms G_dual_fwd   -- 无公理
#print axioms G_dual_bwd   -- Classical.choice 系（排中入账）
#print axioms F_or
#print axioms G_and
#print axioms F_idem
#print axioms X_neg

end Ex36
