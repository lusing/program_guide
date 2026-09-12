/-
文件: 11_mathlib_analysis/continuity.lean
描述: 连续函数，fun_prop
编译: lake build Lean4Tutorial.Examples.MathlibAnalysis.Continuity
依赖: Mathlib.Topology.Continuity
-/

import Mathlib.Topology.Continuity
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibAnalysis.Continuity

/-! # 连续函数（Continuous Functions） -/

-- 函数 f : X → Y 在点 x 处连续，是指
--   lim_{t→x} f(t) = f(x)
--
-- 函数 f 是连续的，是指 f 在定义域的每一点都连续
--
-- 在 Mathlib 中，Continuous f 表示函数 f 连续

/-! ## 连续性的定义 -/

-- 函数 f 在点 x 处连续：
-- ContinuousAt f x := Tendsto f (𝓝 x) (𝓝 (f x))

-- 函数 f 连续：
-- Continuous f := ∀ x, ContinuousAt f x

#check Continuous
#check ContinuousAt

/-! ## ε-δ 定义 -/

-- 在度量空间中，连续性可以用 ε-δ 语言描述：
-- f 在 x 处连续当且仅当
--   ∀ ε > 0, ∃ δ > 0, ∀ y, dist(y, x) < δ → dist(f(y), f(x)) < ε

/-! ## 连续函数的例子 -/

-- 常值函数连续
theorem continuous_const (c : ℝ) : Continuous (fun (_ : ℝ) => c) := by
  exact continuous_const

-- 恒等函数连续
theorem continuous_id : Continuous (fun x : ℝ => x) := by
  exact continuous_id

-- 投影函数连续

/-! ## 连续函数的运算 -/

-- 连续函数的和、差、积、商（分母非零）仍然连续

variable (f g : ℝ → ℝ)

theorem continuous_add (hf : Continuous f) (hg : Continuous g) :
    Continuous (fun x => f x + g x) := by
  exact hf.add hg

theorem continuous_mul (hf : Continuous f) (hg : Continuous g) :
    Continuous (fun x => f x * g x) := by
  exact hf.mul hg

theorem continuous_neg (hf : Continuous f) :
    Continuous (fun x => -f x) := by
  exact hf.neg

theorem continuous_sub (hf : Continuous f) (hg : Continuous g) :
    Continuous (fun x => f x - g x) := by
  exact hf.sub hg

-- 连续函数的复合仍然连续
theorem continuous_comp (g : ℝ → ℝ) (hf : Continuous f) (hg : Continuous g) :
    Continuous (fun x => g (f x)) := by
  exact hg.comp hf

/-! ## fun_prop 战术 -/

-- fun_prop 战术可以自动证明函数的性质，包括连续性
-- 它通过组合基本的连续函数来证明更复杂的函数连续

section FunPropExamples
  variable (a b c : ℝ)

  -- 多项式函数连续
  example : Continuous (fun x : ℝ => a * x ^ 2 + b * x + c) := by
    fun_prop

  -- 有理函数连续（在分母不为零的区域）
  example : Continuous (fun x : ℝ => (x + 1) / (x ^ 2 + 1)) := by
    fun_prop

  -- 复合函数连续
  example : Continuous (fun x : ℝ => (x + 1) ^ 2) := by
    fun_prop

  -- 更复杂的例子
  example : Continuous (fun x : ℝ => (x ^ 2 + 1) * (x - 2) + 3 / (x ^ 2 + 2)) := by
    fun_prop

end FunPropExamples

/-! ## 连续函数的性质 -/

-- 介值定理（Intermediate Value Theorem）
-- 如果 f 在 [a, b] 上连续，且 f(a) ≤ y ≤ f(b)，
-- 则存在 c ∈ [a, b] 使得 f(c) = y

-- 极值定理（Extreme Value Theorem）
-- 如果 f 在有界闭区间 [a, b] 上连续，
-- 则 f 在 [a, b] 上取得最大值和最小值

-- 一致连续性
-- 如果 f 在有界闭区间上连续，则 f 在该区间上一致连续

/-! ## 连续函数与极限的交换 -/

-- 如果 f 连续且 lim x_n = a，则 lim f(x_n) = f(a)
-- 即连续函数与极限可交换

/-! ## 局部性质 -/

-- 连续性是局部性质
-- f 在 x 处连续只取决于 f 在 x 附近的行为

/-! ## 间断点 -/

-- 不连续的点称为间断点
-- 常见类型：可去间断点、跳跃间断点、无穷间断点

/-! ## 半连续 -/

-- 上半连续和下半连续是比连续更弱的概念
-- 在优化理论中有重要应用

end Lean4Tutorial.Examples.MathlibAnalysis.Continuity
