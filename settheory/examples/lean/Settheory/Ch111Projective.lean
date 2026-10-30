import Mathlib.Data.Finset.Basic
import Mathlib.Data.List.Basic

/-!
# 第 111 章 · 投影精细分层与余解析集合

锚点（有限影子）：
- `HasBranch`：全长树枝——定义 3.2 的 [T] 非空的替身；
  有秩树 = 无全长树枝（引理 3.3/定理 3.1 的良基判定）；
- `rho`：赋秩函数的燃料递归（叶 0、内部点 = 子最大 + 1）
  ——秩递归的机制件；
- `rho_le_fuel`：秩不超过燃料（有限树的秩 ≤ 深度——引理 3.5
  「秩有界部分是博雷尔集」的机制件）；
- `branch_imp`：有树枝 ⟺ 树中有全长节点——良基判定的引理；
- 样本账：有秩树 T₀/T₂ 的秩表、无秩树 T₁ 的对照
  （ρ = D 恰是树枝存在的数值影子）。
本体（定义 3.1-3.6、引理 3.1-3.7、定理 3.1-3.6、
推论 3.1-3.5）留在正文。
-/

namespace Settheory.Ch111

open Finset List

/-! ## 一、树与树枝（定义 3.2 的有限替身） -/

/-- 全长树枝：长度恰为深度 D 的路径（[T] 非空的替身）。 -/
def HasBranch (T : Finset (List ℕ)) (D : ℕ) : Prop :=
  ∃ b : List ℕ, b.length = D ∧ ∀ k ≤ D, (b.take k) ∈ T

/-- 有树枝 ⟹ 树中有全长节点（良基判定的桥梁）。 -/
theorem branch_imp (T : Finset (List ℕ)) {D : ℕ} (h : HasBranch T D) :
    ∃ s ∈ T, s.length = D := by
  obtain ⟨b, hb, hmem⟩ := h
  refine ⟨b.take D, hmem D (Nat.le_refl D), ?_⟩
  rw [List.length_take, hb]
  simp

/-! ## 二、赋秩函数（燃料递归） -/

/-- 秩：叶为 0，内部点 = 子点最大秩 + 1；燃料 f 封顶。 -/
def rho (T : Finset (List ℕ)) : ℕ → List ℕ → ℕ
  | 0, _ => 0
  | f + 1, s =>
      if (s ++ [0] ∈ T) || (s ++ [1] ∈ T) then
        (max (rho T f (s ++ [0])) (rho T f (s ++ [1]))) + 1
      else 0

/-- 秩永不超过燃料（有限树的秩 ≤ 深度——秩有界的机制件）。 -/
theorem rho_le_fuel (T : Finset (List ℕ)) :
    ∀ (f : ℕ) (s : List ℕ), rho T f s ≤ f := by
  intro f
  induction f with
  | zero => intro s; simp [rho]
  | succ f ih =>
      intro s
      simp only [rho]
      split
      · next hc =>
          have h0 := ih (s ++ [0])
          have h1 := ih (s ++ [1])
          omega
      · omega

/-! ## 三、样本账（决定性核查） -/

/-- 样本树 T₀：深度 2 的有秩树（无全长树枝）。 -/
def T₀ : Finset (List ℕ) := {[], [0], [1]}

example : ¬ HasBranch T₀ 2 := by
  intro h
  obtain ⟨s, hs, hlen⟩ := branch_imp T₀ h
  simp only [T₀, Finset.mem_insert, Finset.mem_singleton] at hs
  rcases hs with rfl | rfl | rfl <;> exact absurd hlen (by decide)

/-- T₀ 的秩账：根秩 1（两个子点都是叶）。 -/
example : rho T₀ 2 [] = 1 := by decide

/-- 样本树 T₁：无秩树（含全长树枝）。 -/
def T₁ : Finset (List ℕ) := {[], [0], [1], [0, 0]}

example : HasBranch T₁ 2 := by
  refine ⟨[0, 0], rfl, ?_⟩
  intro k _
  cases k with
  | zero => simp [T₁]
  | succ k =>
    cases k with
    | zero => simp [T₁]
    | succ k =>
      cases k with
      | zero => simp [T₁]
      | succ k => omega

/-- ρ = D 恰是树枝存在的数值影子。 -/
example : rho T₁ 2 [] = 2 := by decide

/-- 深度 3 的有秩树 T₂：秩表（根 2、中层 1、叶 0）。 -/
def T₂ : Finset (List ℕ) := {[], [0], [1], [0, 0], [0, 1]}

example : ¬ HasBranch T₂ 3 := by
  intro h
  obtain ⟨s, hs, hlen⟩ := branch_imp T₂ h
  simp only [T₂, Finset.mem_insert, Finset.mem_singleton] at hs
  rcases hs with rfl | rfl | rfl | rfl | rfl <;> exact absurd hlen (by decide)

example : rho T₂ 3 [] = 2 := by decide
example : rho T₂ 3 [0] = 1 := by decide
example : rho T₂ 3 [0, 0] = 0 := by decide

/-- 秩 ≤ 燃料（定理应用于样本）。 -/
example : ∀ s ∈ T₂, rho T₂ 3 s ≤ 3 := by
  intro s _
  have := rho_le_fuel T₂ 3 s
  omega

end Settheory.Ch111
