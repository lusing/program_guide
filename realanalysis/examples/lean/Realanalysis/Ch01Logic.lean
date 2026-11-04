import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic

/-!
# 第 01 章 数学语言与证明技巧

对应原书第 2 章《基础数学与逻辑》：量词、蕴涵的三种亲属命题、
德摩根律，以及五种证明技巧（反例、逆否、反证、归纳、直接证明）
在 Lean 中的对应写法。
-/

namespace Realanalysis.Ch01

variable (A B C : Prop)

/-- 逆否命题与原命题等价：A → B 当且仅当 ¬B → ¬A。 -/
example : (A → B) ↔ (¬ B → ¬ A) := by
  constructor
  · -- 正向：假设 h : A → B，要证 ¬B → ¬A
    intro h hnB hA
    exact hnB (h hA)
  · -- 反向：假设 h : ¬B → ¬A，要证 A → B（用 by_contra 反证）
    intro h hA
    by_contra hnB
    exact h hnB hA

/-- 原书的警示：逆命题 B → A 不被 A → B 保证。
    “n = 5 → n 是自然数”为真，但反过来有反例 246734。 -/
example : ∃ n : ℕ, n ≠ 5 := ⟨246734, by norm_num⟩

/-- 否命题同样不被保证：n ≠ 5 推不出 n 不是自然数。 -/
example : ∃ n : ℕ, n ≠ 5 ∧ True := ⟨246734, by norm_num, trivial⟩

section QuantifierOrder

/-- 量词顺序之一（真）：对每个实数 x，都能找到 y > x——取 y = x+1。 -/
example : ∀ x : ℝ, ∃ y : ℝ, y > x := fun x => ⟨x + 1, by linarith⟩

/-- 量词顺序之二（假）：不存在一个压过所有实数的 y。
    若 y 压过一切 x，令 x = y+1 立刻矛盾。 -/
example : ¬ (∃ y : ℝ, ∀ x : ℝ, y > x) := by
  rintro ⟨y, hy⟩
  have := hy (y + 1)
  linarith

/-- 量词的德摩根律之一：¬(∀x, P x) ↔ ∃x, ¬P x。 -/
example (P : α → Prop) : (¬ ∀ x, P x) ↔ ∃ x, ¬ P x := not_forall

/-- 量词的德摩根律之二：¬(∃x, P x) ↔ ∀x, ¬P x。 -/
example (P : α → Prop) : (¬ ∃ x, P x) ↔ ∀ x, ¬ P x := not_exists

end QuantifierOrder

section Induction

/-- 原书例 2.4：前 n 个自然数之和。先证无除法版本
    `2 * S = n(n+1)`，归纳步骤干净地交给 ring。 -/
theorem sum_formula_double :
    ∀ n : ℕ, 2 * (∑ i ∈ Finset.range n, (i + 1)) = n * (n + 1) := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [Finset.sum_range_succ, mul_add, ih]
    ring

/-- 由无除法版本取一半，得到原书公式 ∑i = n(n+1)/2。 -/
theorem sum_formula :
    ∀ n : ℕ, ∑ i ∈ Finset.range n, (i + 1) = n * (n + 1) / 2 := by
  intro n
  let S := ∑ i ∈ Finset.range n, (i + 1)
  have h := sum_formula_double n
  exact (calc n * (n + 1) / 2
      = (2 * S) / 2 := by rw [h.symm]
    _ = S := Nat.mul_div_cancel_left S (by norm_num : 0 < 2)).symm

end Induction

section EpsilonDelta

/-- 原书例 2.5 的直接证明：lim_{x→2} (3x+1) = 7。
    把极限定义写成 ∀ε>0, ∃δ>0 的纯逻辑命题，关键步骤是
    观察到 |(3x+1)-7| = 3|x-2|，于是取 δ = ε/3。 -/
example : ∀ ε : ℝ, 0 < ε →
    ∃ δ : ℝ, 0 < δ ∧ ∀ x : ℝ, |x - 2| < δ → |(3 * x + 1) - 7| < ε := by
  intro ε hε
  refine ⟨ε / 3, by linarith, fun x hx => ?_⟩
  have h3 : (3 * x + 1) - 7 = 3 * (x - 2) := by ring
  rw [h3]
  have h4 : |3 * (x - 2)| = 3 * |x - 2| := by
    rw [abs_mul, abs_of_pos (by norm_num : (0 : ℝ) < 3)]
  rw [h4]
  linarith

/-- 原书例 2.2：x = y 当且仅当 ∀ε>0, |x-y| < ε。
    反向用逆否：x ≠ y 时取 ε = |x-y| 本身即反例。 -/
example (x y : ℝ) : x = y ↔ ∀ ε : ℝ, 0 < ε → |x - y| < ε := by
  constructor
  · intro h ε hε
    rw [h]
    simpa using hε
  · intro h
    by_cases hxy : x = y
    · exact hxy
    · -- x ≠ y：令 ε = |x-y| > 0，假设给出 |x-y| < |x-y|，矛盾
      have hpos : 0 < |x - y| := abs_pos.mpr (sub_ne_zero.mpr hxy)
      have hcont := h (|x - y|) hpos
      exact False.elim (lt_irrefl _ hcont)

end EpsilonDelta

end Realanalysis.Ch01
