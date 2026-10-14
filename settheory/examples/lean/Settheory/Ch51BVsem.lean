import Mathlib.Order.BooleanAlgebra.Basic
import Mathlib.Data.Set.Basic

/-!
# 第 51 章 · 布尔值语义：B-值模型与可靠性

自建 `BValued` 结构（等词 + 单关系 + 相容律，Viale Def 6.1.1），
验证：
- 等词三律在 Bool 实例上的形态；
- 关系相容律的原子代换（可靠性证明的核心一步）。
-/

namespace Settheory.Ch51

/-- B-值模型骨架：域 + 等词 + 一个二元关系（Viale Def 6.1.1） -/
structure BValued (B : Type*) [BooleanAlgebra B] where
  /-- 域 -/
  carrier : Type
  /-- 等词的解释 -/
  eqv : carrier → carrier → B
  /-- 二元关系的解释 -/
  rel : carrier → carrier → B
  /-- 等词三律 -/
  eq_refl : ∀ σ, eqv σ σ = ⊤
  eq_sym : ∀ σ τ, eqv σ τ = eqv τ σ
  eq_trans : ∀ σ τ ρ, eqv σ τ ⊓ eqv τ ρ ≤ eqv σ ρ
  /-- 关系相容律（二元版） -/
  rel_congr : ∀ σ₁ τ₁ σ₂ τ₂,
    eqv σ₁ τ₁ ⊓ eqv σ₂ τ₂ ⊓ rel σ₁ σ₂ ≤ rel τ₁ τ₂

/-! ## 一、Bool 上的最小实例检查（三律自动成立） -/

-- 等词 = 同布尔值；关系 = 恒等
def boolModel : BValued Bool where
  carrier := Bool
  eqv := fun a b => (a == b)
  rel := fun a b => (a && b)
  eq_refl := by intro σ; cases σ <;> rfl
  eq_sym := by intro σ τ; cases σ <;> cases τ <;> rfl
  eq_trans := by
    intro σ τ ρ
    cases σ <;> cases τ <;> cases ρ <;> simp
  rel_congr := by
    intro σ₁ τ₁ σ₂ τ₂
    cases σ₁ <;> cases τ₁ <;> cases σ₂ <;> cases τ₂ <;> simp

/-! ## 二、原子代换（可靠性证明的核心步） -/

/-- 相容律给出：σ = τ ∧ R(σ,σ') ≤ R(τ,σ')（代换第一个位置） -/
theorem subst_left {B : Type*} [BooleanAlgebra B] (M : BValued B)
    (σ τ : M.carrier) :
    M.eqv σ τ ⊓ M.rel σ σ ≤ M.rel τ σ := by
  have h := M.rel_congr σ τ σ σ
  simp only [M.eq_refl σ, inf_top_eq] at h
  exact h

/-- 代换第二个位置 -/
theorem subst_right {B : Type*} [BooleanAlgebra B] (M : BValued B)
    (σ τ : M.carrier) :
    M.eqv σ τ ⊓ M.rel σ σ ≤ M.rel σ τ := by
  have h := M.rel_congr σ σ σ τ
  simp only [M.eq_refl σ, top_inf_eq] at h
  exact h

end Settheory.Ch51
