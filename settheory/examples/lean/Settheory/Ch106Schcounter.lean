import Mathlib.Data.List.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card

/-!
# 第 106 章 · 力迫 SCH 最小反例

锚点（有限影子）：
- `Book`：有限 SCH 账簿——各点的指数位移（0 = GCH 点 2^μ=μ⁺；
  1 = 跳档点 2^μ=μ⁺⁺）；
- `gmwShape`：GMW 账簿形态——非空、末位跳档、其余全 GCH；
- `minimalFailure`：最小失败归约（Task 21 Step 2 指定件）；
- `shiftsAbove`：引理 2.20 交织引理的有限影子
  （终段位移支配 + 自反/传递）。
本体（定义 2.12–2.19、引理 2.13–2.21、定理 2.12）留在正文。
-/

namespace Settheory.Ch106

/-- 账簿：位置 i 的指数账（0 = GCH 点；1 = 跳档点）。 -/
abbrev Book := List ℕ

/-- GCH 点：指数位移 0（2^μ = μ⁺）。 -/
def gchPoint (b : ℕ) : Prop := b = 0

/-- 跳档点：指数位移 1（2^μ = μ⁺⁺）。 -/
def jumpPoint (b : ℕ) : Prop := b = 1

/-- GMW 账簿形态：非空、末位跳档、其余全 GCH。 -/
def gmwShape (B : Book) : Prop :=
  B ≠ [] ∧ jumpPoint B.getLast! ∧ ∀ i < B.length - 1, gchPoint (B[i]!)

/-- 最小失败归约：GMW 形态 ⟹ 一切非末位点是 GCH 点且非跳档点。 -/
theorem gch_jump_disjoint (b : ℕ) : gchPoint b → ¬ jumpPoint b := by
  intro h1 h2
  simp only [gchPoint, jumpPoint] at h1 h2
  omega

theorem minimalFailure (B : Book) (i : ℕ)
    (h : gmwShape B) (hi : i + 1 < B.length) :
    gchPoint (B[i]!) ∧ ¬ jumpPoint (B[i]!) := by
  obtain ⟨_, _, hall⟩ := h
  exact ⟨hall i (by omega), gch_jump_disjoint _ (hall i (by omega))⟩

/-- GMW 账簿样本：[0,0,0,1]（三点 GCH + 顶跳）。 -/
example : gmwShape [0, 0, 0, 1] := by
  refine ⟨by simp, by simp [jumpPoint], fun i hi => by
    match i with
    | 0 => rfl
    | 1 => rfl
    | 2 => rfl
    | (i + 3) => exact absurd hi (by simp)⟩

/-- 非 GMW 样本：[0,1,0,1]（中间跳档——失败不孤悬于顶）。 -/
example : ¬ gmwShape [0, 1, 0, 1] := by
  intro h
  obtain ⟨_, _, hall⟩ := h
  have h2 := hall 1 (by simp)
  simp only [gchPoint] at h2
  exact absurd h2 (by decide)

/-- 交织引理（引理 2.20）的有限影子：
b 被 a 终段位移支配（∃k ∀n≥k，b n ≤ a (n+k)）。 -/
def shiftsAbove (a b : ℕ → ℕ) : Prop :=
  ∃ k, ∀ n, k ≤ n → b n ≤ a (n + k)

theorem shifts_refl (a : ℕ → ℕ) : shiftsAbove a a :=
  ⟨0, fun _ _ => Nat.le_refl _⟩

theorem shifts_trans {a b c : ℕ → ℕ}
    (h₁ : shiftsAbove a b) (h₂ : shiftsAbove b c) : shiftsAbove a c := by
  obtain ⟨k₁, e₁⟩ := h₁
  obtain ⟨k₂, e₂⟩ := h₂
  refine ⟨k₁ + k₂, fun n hn => ?_⟩
  have h3 : c n ≤ b (n + k₂) := e₂ n (by omega)
  have h4 : b (n + k₂) ≤ a (n + k₂ + k₁) := e₁ (n + k₂) (by omega)
  have h5 : n + k₂ + k₁ = n + (k₁ + k₂) := by omega
  rw [h5] at h4
  exact le_trans h3 h4

/-- 样本：快序列位移支配慢序列。 -/
example : shiftsAbove (fun n => n + 2) (fun n => n) :=
  ⟨0, fun n _ => by show n ≤ n + 2 + 0; omega⟩

example : shiftsAbove (fun n => 2 * n) (fun n => n + 3) :=
  ⟨3, fun n _ => by show n + 3 ≤ 2 * (n + 3); omega⟩

/-- 交织的样本：a 单调时 shiftsAbove a b 给出逐点有限支配
（引理 2.20 的逐点读法）。 -/
theorem shifts_pointwise (a b : ℕ → ℕ) (ha : Monotone a)
    (h : shiftsAbove a b) : ∃ m, ∀ j ≥ m, b j ≤ a (j + m) := by
  obtain ⟨k, e⟩ := h
  exact ⟨k, fun j hj => le_trans (e j hj) (ha (by omega))⟩

end Settheory.Ch106
