import Mathlib.Analysis.Distribution.Sobolev
import Mathlib.Analysis.Distribution.TemperedDistribution
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Topology.Defs.Filter
import Mathlib.Topology.Basic
import Mathlib.Order.Filter.Defs
import Mathlib.Order.Filter.AtTopBot.Defs
import Mathlib.Order.Filter.AtTopBot.Tendsto

/-!
# 第 71 章 · 弱导数：从 δ 到 W^{k,p}（工科篇 3.7 + 6.1-6.3）

《工科泛函分析基础》的两条导数推广路线：
- 3.7 节：δ 函数与 Heaviside 的"算子演算"危机 ⟹ 广义函数 = D 上的
  连续线性泛函 ⟹ 分部积分定义广义导数；
- 6.1/6.3 节：完备化定义广义导数（W^{1,2} 为 C¹ 的完备化），检验函数
  定义弱导数，两定义等价（书 6.3.5）。

本章 Lean 通道：
1. **分部积分恒等式**（弱导数定义的动机，书 3.7.9 的启发式）：
   紧支撑光滑函数对的边界项消失 ⟹ ∫ u v' = −∫ u' v；
2. mathlib 的 Sobolev 空间 API 巡礼（`TemperedDistribution.MemSobolev`，Fourier/Bessel 位势
   定义——与书的完备化定义 6.1.2-6.1.4 属于同一对象的不同实现路线）。

|x| 的弱导数 = sgn、ln|x| ∈ W^{1,2}(B₁)、磨光函数逼近（书 6.3.3/6.3.4/
3.7.4/3.7.5）由 Julia/Python 数值通道承载——mathlib 的分布层尚无
"逐点不可微函数的分布导数等于经典函数"的直接 API，这是诚实的通道分工。
-/

open MeasureTheory
open Set
open Filter
open scoped Topology

/-! ## 第一层：分部积分——弱导数定义的动机 -/

/-- **分部积分恒等式（全直线，边界项为零）**：u、v 连续可微（在对方
支撑上），u·v 在 ±∞ 处趋于零，则 ∫ u v' = −∫ u' v。
这正是书 3.7.9 启发式的形式：把求导从 u 转移到检验函数 v 上，
多出一个负号——弱导数定义 ⟨g, φ⟩ = −⟨f, φ'⟩ 的来源。 -/
theorem ibp_zero_boundary (u v u' v' : ℝ → ℝ)
    (hu : ∀ x ∈ tsupport v, HasDerivAt u (u' x) x)
    (hv : ∀ x ∈ tsupport u, HasDerivAt v (v' x) x)
    (huv' : Integrable (u * v')) (hu'v : Integrable (u' * v))
    (hbot : Tendsto (u * v) atBot (𝓝 0)) (htop : Tendsto (u * v) atTop (𝓝 0)) :
    ∫ x, u x * v' x = -∫ x, u' x * v x := by
  rw [integral_mul_deriv_eq_deriv_mul hu hv huv' hu'v hbot htop]
  ring

/-- 紧支撑情形：u、v 的支撑有界 ⟹ 边界项自动消失。
这正是书 3.7.9 中检验函数 φ ∈ C₀^∞ 的角色：紧支撑换掉了
"边界值为零"的人为假设。 -/
theorem ibp_compact_support (u v u' v' : ℝ → ℝ)
    (hu : ∀ x ∈ tsupport v, HasDerivAt u (u' x) x)
    (hv : ∀ x ∈ tsupport u, HasDerivAt v (v' x) x)
    (huv' : Integrable (u * v')) (hu'v : Integrable (u' * v))
    (hsu : ∃ R : ℝ, tsupport u ⊆ Icc (-R) R) (hsv : ∃ R : ℝ, tsupport v ⊆ Icc (-R) R) :
    ∫ x, u x * v' x = -∫ x, u' x * v x := by
  obtain ⟨Ru, hRu⟩ := hsu
  obtain ⟨Rv, hRv⟩ := hsv
  have hbot : Tendsto (u * v) atBot (𝓝 0) := by
    have heq : ∀ᶠ x in atBot, (u * v) x = (0 : ℝ) := by
      filter_upwards [eventually_lt_atBot (-Ru)] with x hx
      by_contra hne
      have hu0 : u x ≠ 0 := fun h => hne (by simp [h])
      have hmem := (hRu (subset_closure (Function.mem_support.mpr hu0))).1
      linarith
    rw [tendsto_congr' heq]
    exact tendsto_const_nhds
  have htop : Tendsto (u * v) atTop (𝓝 0) := by
    have heq : ∀ᶠ x in atTop, (u * v) x = (0 : ℝ) := by
      filter_upwards [eventually_gt_atTop Rv] with x hx
      by_contra hne
      have hv0 : v x ≠ 0 := fun h => hne (by simp [h])
      have hmem := (hRv (subset_closure (Function.mem_support.mpr hv0))).2
      linarith
    rw [tendsto_congr' heq]
    exact tendsto_const_nhds
  exact ibp_zero_boundary u v u' v' hu hv huv' hu'v hbot htop

/-! ## 第二层：mathlib 的 Sobolev 空间 API 巡礼 -/

-- mathlib 走 Fourier/Bessel 位势路线：MemSobolev s p f 定义为
-- f = (1+|ξ|²)^{-s/2} ĝ（某个 L^p 的 Fourier 侧光滑化）
#check @TemperedDistribution.MemSobolev

-- s = 0 时 MemSobolev 就是 L^p 成员资格——与书的 W^{0,p} = L^p 一致
#check @TemperedDistribution.memSobolev_zero_iff

-- 光滑速降函数都属于 Sobolev 空间（对应书中 C^∞(Ω̄) ⊂ W^{k,p}）
#check @SchwartzMap.memSobolev

-- Sobolev 成员资格是线性子空间：加法封闭
#check @TemperedDistribution.MemSobolev.add

-- 单调性：正则性 s 大 ⟹ 成员资格传递到 s' 小（对应嵌入 W^{s,2} ⊂ W^{s',2}）
#check @TemperedDistribution.MemSobolev.mono
