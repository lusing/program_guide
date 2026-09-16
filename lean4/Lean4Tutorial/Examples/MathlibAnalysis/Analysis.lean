/-
文件: 11_mathlib_analysis/analysis.lean
描述: 第14章 实分析（与教程同步，Mathlib4 master@2026-09 验证）
编译: lake build Lean4Tutorial.Examples.MathlibAnalysis.Analysis
-/

import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Group.Abs
import Mathlib.Algebra.Order.Archimedean.Real.Basic   -- ℝ 的完备性实例
import Mathlib.Topology.MetricSpace.Pseudo.Defs
import Mathlib.Topology.Continuous
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Tactic.FunProp

open Filter Topology

namespace Lean4Tutorial.Examples.MathlibAnalysis.Ch14

/-! # 14.1 实数 -/

-- 2026 年的 mathlib 把 LinearOrderedField 拆成了可组合的 mixin：
-- Field + LinearOrder + IsStrictOrderedRing/IsOrderedRing 分开携带
#check (inferInstance : Field ℝ)
#check (inferInstance : LinearOrder ℝ)
#check (inferInstance : IsStrictOrderedRing ℝ)
-- 完备性（确界原理）：ConditionallyCompleteLinearOrder
#check (inferInstance : ConditionallyCompleteLinearOrder ℝ)

example (x y z : ℝ) : (x + y) * z = x * z + y * z := by ring
example (x y : ℝ) : x ≤ y ∨ y ≤ x := le_total x y

/-! # 14.2 绝对值 -/

example (x : ℝ) : 0 ≤ |x| := abs_nonneg x
example (x : ℝ) : |x| = max x (-x) := rfl
example (x y : ℝ) : |x + y| ≤ |x| + |y| := abs_add_le x y
example (x y : ℝ) : |x * y| = |x| * |y| := abs_mul x y
example (x : ℝ) : abs (abs x) = abs x := abs_abs x
example (x y : ℝ) : abs (abs x - abs y) ≤ abs (x - y) := abs_abs_sub_abs_le_abs_sub x y
example (x y : ℝ) : dist x y = |x - y| := Real.dist_eq x y

/-! # 14.3 Filter 与极限 -/

example {u : ℕ → ℝ} {a : ℝ} :
    Tendsto u atTop (𝓝 a) ↔ ∀ ε > 0, ∃ N, ∀ n ≥ N, dist (u n) a < ε :=
  Metric.tendsto_atTop

#check (𝓝 0 : Filter ℝ)
#check (atTop : Filter ℕ)
#check (𝓝[>] (0 : ℝ))

example {u v : ℕ → ℝ} {a b : ℝ}
    (hu : Tendsto u atTop (𝓝 a)) (hv : Tendsto v atTop (𝓝 b)) :
    Tendsto (fun n => u n + v n) atTop (𝓝 (a + b)) :=
  hu.add hv

example {u v : ℕ → ℝ} {a b : ℝ}
    (hu : Tendsto u atTop (𝓝 a)) (hv : Tendsto v atTop (𝓝 b)) :
    Tendsto (fun n => u n * v n) atTop (𝓝 (a * b)) :=
  hu.mul hv

example (c : ℝ) : Tendsto (fun _ : ℕ => c) atTop (𝓝 c) := tendsto_const_nhds

/-! # 14.4 连续性 -/

example {f : ℝ → ℝ} : Continuous f ↔ ∀ x, ContinuousAt f x :=
  continuous_iff_continuousAt

example {f : ℝ → ℝ} :
    Continuous f ↔ ∀ s, IsOpen s → IsOpen (f ⁻¹' s) := continuous_def

example {f : ℝ → ℝ} {a : ℝ} :
    ContinuousAt f a ↔ ∀ ε > 0, ∃ δ > 0, ∀ x, dist x a < δ → dist (f x) (f a) < ε :=
  Metric.continuousAt_iff

example {f g : ℝ → ℝ} (hf : Continuous f) (hg : Continuous g) :
    Continuous (f + g) := hf.add hg

example {f g : ℝ → ℝ} (hf : Continuous f) (hg : Continuous g) :
    Continuous (g ∘ f) := hg.comp hf

example : Continuous (fun x : ℝ => x^2 + 2*x + 1) := by fun_prop

/-! # 14.5 导数 -/

example (n : ℕ) (x : ℝ) : HasDerivAt (fun x : ℝ => x ^ n) ((n : ℝ) * x ^ (n - 1)) x :=
  hasDerivAt_pow n x

example {f f' g g' : ℝ → ℝ} {x : ℝ}
    (hf : HasDerivAt f (f' x) x) (hg : HasDerivAt g (g' x) x) :
    HasDerivAt (fun x => f x + g x) (f' x + g' x) x :=
  hf.add hg

example {f f' g g' : ℝ → ℝ} {x : ℝ}
    (hf : HasDerivAt f (f' x) x) (hg : HasDerivAt g (g' x) x) :
    HasDerivAt (fun x => f x * g x) (f' x * g x + f x * g' x) x :=
  hf.mul hg

example : deriv (fun x : ℝ => x^2) 3 = 6 := by
  rw [(hasDerivAt_pow 2 3).deriv]
  norm_num

/-! # 14.6 介值定理 -/

-- intermediate_value_Icc（IntermediateValue.lean:558）：像集包含整个区间
theorem ivt_demo {f : ℝ → ℝ} {a b y : ℝ} (h : a ≤ b)
    (hf : ContinuousOn f (Set.Icc a b)) (hy : f a ≤ y ∧ y ≤ f b) :
    ∃ x ∈ Set.Icc a b, f x = y := by
  have hmem : y ∈ Set.Icc (f a) (f b) := ⟨hy.1, hy.2⟩
  obtain ⟨x, hx, hfx⟩ := intermediate_value_Icc h hf hmem
  exact ⟨x, hx, hfx⟩

-- 用 IVT 证明 √2 存在
theorem sqrt2_exists : ∃ x : ℝ, 1 ≤ x ∧ x ≤ 2 ∧ x^2 = 2 := by
  have hcont : ContinuousOn (fun x : ℝ => x^2) (Set.Icc 1 2) := by fun_prop
  have hmem : (2 : ℝ) ∈ Set.Icc ((1 : ℝ)^2) ((2 : ℝ)^2) := by norm_num
  obtain ⟨x, hx, hfx⟩ :=
    intermediate_value_Icc (show (1 : ℝ) ≤ 2 by norm_num) hcont hmem
  exact ⟨x, hx.1, hx.2, hfx⟩

/-! # 14.7 垃圾值惯例 -/

example {f g : ℝ → ℝ} {x : ℝ} (hf : DifferentiableAt ℝ f x)
    (hg : DifferentiableAt ℝ g x) :
    deriv (f + g) x = deriv f x + deriv g x :=
  deriv_add hf hg

end Lean4Tutorial.Examples.MathlibAnalysis.Ch14
