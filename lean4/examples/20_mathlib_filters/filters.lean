/-
文件: 20_mathlib_filters/filters.lean
描述: 第33章 滤子（与教程同步，Mathlib4 v4.35.0-rc3 验证）
编译: lake build Lean4Tutorial.Examples.MathlibFilters.Filters
-/

import Mathlib.Order.Filter.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Basic
import Mathlib.Topology.Order.OrderClosed
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Tactic

namespace Lean4Tutorial.Examples.MathlibFilters.Ch33

open Filter Topology

variable {α β : Type}

/-! # 33.1 Filter：刻画"足够大"的集合族 -/

#check (Filter ℕ)                 -- Filter ℕ : Type
#check (atTop : Filter ℕ)         -- 趋于无穷的滤子
#check (atBot : Filter ℤ)
example : Filter ℕ := ⊤           -- 含一切集合
example : Filter ℕ := ⊥           -- 序是"反向包含"，⊥ 是最细的滤子
#check (pure : α → Filter α)      -- pure a = principal {a}（a 处的"点滤子"）
#check (Filter.principal : Set α → Filter α)

/-! # 33.2 最终性 ∀ᶠ：eventually -/

-- ∀ᶠ x in l, p x 读作"对 l-几乎所有 x，p x 成立"
#check (∀ᶠ (n : ℕ) in atTop, 0 < n)
example : ∀ᶠ n : ℕ in atTop, 0 < n := eventually_gt_atTop 0
example : ∀ᶠ n : ℕ in atTop, n ≥ 100 := eventually_ge_atTop 100

-- filter_upwards：把已知的 eventually 事实"向上"组合
example : ∀ᶠ n : ℕ in atTop, n ≠ 0 := by
  filter_upwards [eventually_gt_atTop 0] with n hn
  omega

/-! # 33.3 Tendsto：滤子意义的极限 -/

-- Tendsto f l₁ l₂ 的定义就是 map f l₁ ≤ l₂
example (f : α → β) (l₁ : Filter α) (l₂ : Filter β) :
    Tendsto f l₁ l₂ ↔ map f l₁ ≤ l₂ := Iff.rfl

#check @Filter.map
#check @Filter.comap
#check @tendsto_atTop_atTop   -- Tendsto f atTop atTop ↔ ∀ b, ∃ i, ∀ a, i ≤ a → b ≤ f a

-- fun n => n + 1 把 atTop 映到 atTop
example : Tendsto (fun n : ℕ => n + 1) atTop atTop := by
  rw [tendsto_atTop_atTop]
  intro b
  use b
  intro a ha
  show b ≤ a + 1
  omega

-- 常值序列收敛到该常数（𝓝 b 是 b 的邻域滤子）
example : Tendsto (fun _ : ℕ => (0 : ℝ)) atTop (𝓝 0) := tendsto_const_nhds

/-! # 33.4 𝓝：邻域滤子与序列收敛 -/

#check (𝓝 : ℝ → Filter ℝ)
-- s ∈ 𝓝 x 当且仅当 s 是 x 的邻域；开区间 (0,∞) 是 1 的邻域
example : Set.Ioi (0 : ℝ) ∈ 𝓝 (1 : ℝ) := Ioi_mem_nhds (by norm_num : (0 : ℝ) < 1)

-- 序列 u 收敛到 x，定义即 Tendsto u atTop (𝓝 x)；ℝ 上的 ε-N 刻画：
example (u : ℕ → ℝ) (x : ℝ) :
    Tendsto u atTop (𝓝 x) ↔ ∀ ε > 0, ∃ N, ∀ n ≥ N, dist (u n) x < ε :=
  Metric.tendsto_atTop

end Lean4Tutorial.Examples.MathlibFilters.Ch33
