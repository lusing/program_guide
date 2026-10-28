import Mathlib.Logic.Function.Iterate
import Mathlib.Order.Directed

/-!
# 第 97 章 · 线性迭代超幂

锚点：函数迭代的合成律（iterate_add_apply：f^[m+n] x = f^[m] (f^[n] x)，
即引理 1.37 分解引理的有限骨架）与定向集合（IsDirected，定向极限
的索引结构）。迭代超幂本体与 Gaifman 良基性定理留在正文。
-/

namespace Settheory.Ch97

/-- 分解引理的有限骨架：先迭代 n 步再迭代 m 步等于迭代 m+n 步。
引理 1.37（ult^(α+ε) ≅ ult^(ε)(ult^(α))）在「取 α, ε 为有限数、
嵌入取函数迭代」时的影子。 -/
theorem decompose_iterate {α : Type*} (f : α → α) (m n : ℕ) (x : α) :
    f^[m + n] x = f^[m] (f^[n] x) :=
  Function.iterate_add_apply f m n x

/-- 临界点轨迹的骨架：若 f 严格上升，则迭代轨迹严格递增——
推论 1.10 的临界点序列严格单调性的影子。 -/
theorem iterate_traj_strict {f : ℕ → ℕ} (h : ∀ k, k < f k)
    (n : ℕ) : f^[n] 0 < f^[n + 1] 0 := by
  rw [Function.iterate_succ_apply']
  exact h (f^[n] 0)

/-- 连续性骨架：轨迹 n ↦ f^[n] 0 单调（f 单调时）——极限阶段
「取上确界」的前奏。 -/
theorem iterate_traj_mono {f : ℕ → ℕ} (h : ∀ k, k ≤ f k)
    (m n : ℕ) (hmn : m ≤ n) : f^[m] 0 ≤ f^[n] 0 := by
  induction n with
  | zero =>
      have : m = 0 := Nat.le_zero.mp hmn
      subst this
      exact Nat.le_refl _
  | succ n ih =>
      rcases Nat.eq_or_lt_of_le hmn with hEq | hEq
      · subst hEq
        exact le_of_eq rfl
      · rw [Function.iterate_succ_apply']
        exact Nat.le_trans (ih (by omega)) (h (f^[n] 0))

/-- 定向索引结构：迭代超幂的定向系统 (M_β, j_{β,δ}) 的索引集
  （任意两个阶段有共同延伸）。 -/
example : IsDirected ℕ (· ≤ ·) :=
  ⟨fun a b => ⟨max a b, Nat.le_max_left a b, Nat.le_max_right a b⟩⟩

/-- 定向系统的相容性骨架：j_{β,δ} = j_{γ,δ} ∘ j_{β,γ}（推论 1.10
  的交换图）在函数迭代下的形态：从 β 到 δ 的迭代 = 从 γ 到 δ 的
  迭代复合从 β 到 γ 的迭代。 -/
theorem commute_iterate {α : Type*} (f : α → α) (β γ δ : ℕ)
    (hβγ : β ≤ γ) (hγδ : γ ≤ δ) (x : α) :
    f^[δ - β] x = f^[δ - γ] (f^[γ - β] x) := by
  have h1 : (δ - γ) + (γ - β) = δ - β := by omega
  calc f^[δ - β] x = f^[(δ - γ) + (γ - β)] x := by rw [h1]
    _ = f^[δ - γ] (f^[γ - β] x) := Function.iterate_add_apply f (δ - γ) (γ - β) x

end Settheory.Ch97
