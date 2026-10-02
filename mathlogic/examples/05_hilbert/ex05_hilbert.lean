/- ex05 —— Hilbert 系统 L 与演绎定理（Lean 4 版） -/

namespace Ex05

inductive HForm where
  | hvar (n : Nat) : HForm
  | himp (a b : HForm) : HForm
  | hneg (a : HForm) : HForm

open HForm

/- 公理模式：三个存在量词模式的析取（模式匹配 def 写不了这种「结构等式」） -/

def isAxiom (A : HForm) : Prop :=
  (∃ p q, A = himp p (himp q p))
  ∨ (∃ p q r, A = himp (himp p (himp q r)) (himp (himp p q) (himp p r)))
  ∨ (∃ p q, A = himp (himp (hneg q) (hneg p)) (himp p q))

inductive Derives (Γ : List HForm) : HForm → Prop
  | hyp (A) (h : A ∈ Γ) : Derives Γ A
  | ax (A) (h : isAxiom A) : Derives Γ A
  | mp {P A} (h₁ : Derives Γ (himp P A)) (h₂ : Derives Γ P) : Derives Γ A

open Derives

theorem weakK {Γ : List HForm} {A B : HForm} (h : Derives Γ A) :
    Derives Γ (himp B A) :=
  mp (ax _ (Or.inl ⟨A, B, rfl⟩)) h

theorem identity {Γ : List HForm} (p : HForm) : Derives Γ (himp p p) := by
  have s1 : Derives Γ (himp p (himp (himp p p) p)) :=
    ax _ (Or.inl ⟨p, _, rfl⟩)
  have s2 : Derives Γ (himp (himp p (himp (himp p p) p))
                         (himp (himp p (himp p p)) (himp p p))) :=
    ax _ (Or.inr (Or.inl ⟨p, _, _, rfl⟩))
  have s3 : Derives Γ (himp (himp p (himp p p)) (himp p p)) :=
    mp s2 s1
  have s4 : Derives Γ (himp p (himp p p)) :=
    ax _ (Or.inl ⟨p, p, rfl⟩)
  exact mp s3 s4

/-- 演绎定理：对推导结构归纳 -/
theorem deduction {Γ : List HForm} {p q : HForm}
    (h : Derives (p :: Γ) q) : Derives Γ (himp p q) := by
  induction h with
  | hyp A hIn =>
      cases hIn with
      | head =>
          -- A = p 的情形：p → p
          exact identity p
      | tail _ hIn' => exact weakK (hyp A hIn')
  | ax A hAx => exact weakK (ax A hAx)
  | @mp r A h₁ h₂ ih₁ ih₂ =>
      have s2 : Derives Γ (himp (himp p (himp r A))
                          (himp (himp p r) (himp p A))) :=
        ax _ (Or.inr (Or.inl ⟨p, r, A, rfl⟩))
      exact mp (mp s2 ih₁) ih₂

example (p q r : HForm) : Derives [] (himp (himp p (himp q r)) (himp p (himp q r))) := by
  apply deduction
  exact hyp _ (List.Mem.head _)

#print axioms deduction

/- 坑位速记（Lean 侧）：
   - `induction h with | @mp r A h₁ ih₁ h₂ ih₂` 的 @ 前缀把隐式
     P/A 具名——分支里要引用它们时必须这样写；
   - hyp 分支的 `A ∈ p :: Γ` 用 cases head/tail 拆——head 直接统一 A := p；
   - 模式匹配 def 写不了「三模式析取」——公理模式用 ∃ 显式展开最稳。 -/

end Ex05
