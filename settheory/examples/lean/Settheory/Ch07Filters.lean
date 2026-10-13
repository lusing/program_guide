import Mathlib.Order.Filter.Ultrafilter.Defs
import Mathlib.Order.Filter.Cofinite
import Mathlib.Order.Filter.Basic

/-!
# 第 07 章 · 滤子与理想、club 与静止集

mathlib 的 `Filter` 理论是全库最大的基础设施之一（拓扑/收敛
理论的底座）。本章对齐 Jech §7 的集合论侧：主滤子、Fréchet
滤子、Tarski 超滤存在定理。
-/

open Filter

/-! ## 一、滤子的基本例 -/

/-- **主滤子**（Jech 例 2）：包含 X₀ 的全体子集。
    mathlib 的 𝓟 s 即 principal filter。 -/
example {α : Type} (s : Set α) : s ∈ 𝓟 s :=
  mem_principal_self s

/-- 主滤子对任意交封闭（Jech："every principal filter is closed
    under arbitrary intersections"）。 -/
example {α : Type} (s : Set α) (S : Set (Set α))
    (hS : ∀ t ∈ S, s ⊆ t) : s ⊆ ⋂₀ S :=
  fun _ hx t ht => hS t ht hx

/-- **Fréchet 滤子**（Jech 例 3）：余有限集。
    membership 刻画：s ∈ cofinite ⟺ sᶜ 有限。 -/
example {s : Set ℕ} : s ∈ (cofinite : Filter ℕ) ↔ sᶜ.Finite :=
  mem_cofinite

/-! ## 二、Tarski 超滤定理（定理 21）-/

/-- 每个非退化滤子可扩成超滤——Zorn 引理的滤子版。
    mathlib 形态：∃ u : Ultrafilter α, ↑u ≤ f（≤ 即更细）。 -/
example {α : Type} (f : Filter α) [f.NeBot] :
    ∃ u : Ultrafilter α, (u : Filter α) ≤ f :=
  f.exists_ultrafilter_le

/-- 超滤的两分性：X 或 Xᶜ 恰一在 U 中（Jech (7.9)）。 -/
example {α : Type} (u : Ultrafilter α) (X : Set α) :
    X ∈ (u : Filter α) ∨ Xᶜ ∈ (u : Filter α) :=
  u.mem_or_compl_mem X
