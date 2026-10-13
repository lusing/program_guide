import Mathlib.SetTheory.Cardinal.Continuum
import Mathlib.Topology.Instances.CantorSet

/-!
# 第 04 章 · 实数的集合论构造

连续统 𝔠 = 2^ℵ₀ 的官方记号、三分康托集的完整理论、
以及实数不可数性的库内锚点。
-/

open scoped Cardinal

/-! ## 一、连续统记号 -/

/-- 𝔠 = 2^ℵ₀：连续统假设（CH）即 𝔠 = ℵ₁——不可判定性的主角。 -/
example : 2 ^ ℵ₀ = 𝔠 := rfl

/-- Cantor 定理对 ℵ₀ 的特写：ℵ₀ < 𝔠。 -/
example : ℵ₀ < 𝔠 := by
  simpa using Cardinal.cantor ℵ₀

/-! ## 二、三分康托集：mathlib 的完整理论 -/

open Set

/-- 0 与 1/4 都是康托集的成员——1/4 是"非端点成员"的著名例子
    （其三进制地址 0.020202... 只用 0 与 2）。 -/
example : (0 : ℝ) ∈ cantorSet := zero_mem_cantorSet

example : (1 / 4 : ℝ) ∈ cantorSet := quarter_mem_cantorSet

/-- 康托集落在单位区间内。 -/
example : cantorSet ⊆ Icc (0 : ℝ) 1 := cantorSet_subset_unitInterval

/-- 自相似方程：C = (C/3) ∪ ((2+C)/3)——两个 1/3 缩放的拷贝。 -/
example : cantorSet = (· / 3) '' cantorSet ∪ (fun x ↦ (2 + x) / 3) '' cantorSet :=
  cantorSet_eq_union_halves
