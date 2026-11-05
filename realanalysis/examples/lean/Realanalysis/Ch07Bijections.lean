import Mathlib.Basic.Real.Basic
import Mathlib.Data.Set.Function
import Mathlib.Tactic

/-!
# 第 07 章 双射

对应原书第 7 章：函数、像与原像、逆、满射/单射/双射，
以及“双射 ⇔ 可逆”、逆仍是双射、复合与恒等。
-/

namespace Realanalysis.Ch07

open Function Set

/-! ## 7.1 像与原像 -/

/-- 常值函数把任意非空子集映成单点。原书：E={1,2,3}，f(x)=1 ⇒ f(E)={1}。 -/
example : ((fun _ : ℕ => (1 : ℕ)) '' ({1, 2, 3} : Set ℕ)) = ({1} : Set ℕ) := by
  ext y; simp

/-- 原像：整数平方映到 {16} 时，原像是 {4,-4}。
    这说明“作为点值的逆”不是函数（一点对应两点）。 -/
example : (fun x : ℤ => x ^ 2) ⁻¹' ({16} : Set ℤ) = ({4, -4} : Set ℤ) := by
  ext x
  simp [mem_preimage, mem_singleton_iff, mem_insert_iff]
  constructor
  · intro h
    have : x ^ 2 = (4 : ℤ) ^ 2 := by norm_num [h]
    exact (sq_eq_sq_iff_eq_or_eq_neg).mp this
  · intro h
    rcases h with rfl | rfl <;> norm_num

/-! ## 7.2 单射、满射、双射 -/

/-- `x ↦ 2x` 在 ℝ 上单射。 -/
example : Injective (fun x : ℝ => (2 : ℝ) * x) := fun _ _ h => by linarith

/-- `x ↦ x²` 在 ℝ 上非单射：2 与 -2 同像。 -/
example : ¬ Injective (fun x : ℝ => x ^ 2) := by
  intro h
  have := h (by norm_num : (2 : ℝ) ^ 2 = (-2 : ℝ) ^ 2)
  linarith

/-- 常值 `ℕ → Unit` 是满射。 -/
example : Surjective (fun _ : ℕ => ()) := fun _ => ⟨0, rfl⟩

/-- 有限例：`Fin 2 → Fin 1` 常值是满射但非单射（原书 {1,2}→{1}）。 -/
example : Surjective (fun _ : Fin 2 => (0 : Fin 1)) := fun y => ⟨0, Subsingleton.elim _ y⟩

example : ¬ Injective (fun _ : Fin 2 => (0 : Fin 1)) := by
  intro h
  have h01 : (0 : Fin 2) ≠ 1 := by decide
  exact h01 (h rfl)

/-- 有限例：`Unit → Fin 2`，`* ↦ 0` 是单射但非满射（原书 {1}→{1,2}）。 -/
example : Injective (fun _ : Unit => (0 : Fin 2)) := injective_of_subsingleton _

example : ¬ Surjective (fun _ : Unit => (0 : Fin 2)) := by
  intro h
  rcases h (1 : Fin 2) with ⟨_, hf⟩
  cases hf

/-- `x ↦ 2x` 在 ℝ 上双射。 -/
example : Bijective (fun x : ℝ => (2 : ℝ) * x) :=
  ⟨fun _ _ h => by linarith, fun y => ⟨y / 2, by ring⟩⟩

/-! ## 7.3 双射 ⇔ 可逆；逆；复合 -/

/-- 定理 7.15：双射 ⟺ 存在双边逆。 -/
example {α β : Type*} (f : α → β) :
    Bijective f ↔ ∃ g : β → α, LeftInverse g f ∧ Function.RightInverse g f :=
  bijective_iff_has_inverse

/-- 加倍与减半互为左右逆。 -/
example : LeftInverse (fun y : ℝ => y / 2) (fun x : ℝ => (2 : ℝ) * x) := by
  intro x; field_simp
example : Function.RightInverse (fun y : ℝ => y / 2) (fun x : ℝ => (2 : ℝ) * x) := by
  intro y; field_simp

/-- 定理 7.16：双射的逆函数仍是双射（用 Equiv 包装）。 -/
example : Bijective (Equiv.mulLeft₀ (2 : ℝ) (by norm_num)).symm :=
  (Equiv.mulLeft₀ (2 : ℝ) (by norm_num)).symm.bijective

/-- 复合：f(x)=2x，g(x)=x² ⇒ (g∘f)(x)=4x²。 -/
example : (fun x : ℝ => x ^ 2) ∘ (fun x : ℝ => (2 : ℝ) * x) = fun x => (4 : ℝ) * x ^ 2 := by
  funext x; dsimp; ring

/-- 双射对复合封闭。 -/
example {α β γ : Type*} {f : α → β} {g : β → γ}
    (hf : Bijective f) (hg : Bijective g) : Bijective (g ∘ f) :=
  Bijective.comp hg hf

/-- 与逆复合得恒等。 -/
example : (fun y : ℝ => y / 2) ∘ (fun x : ℝ => (2 : ℝ) * x) = id := by
  funext x; dsimp; field_simp
example : (fun x : ℝ => (2 : ℝ) * x) ∘ (fun y : ℝ => y / 2) = id := by
  funext y; dsimp; field_simp

end Realanalysis.Ch07
