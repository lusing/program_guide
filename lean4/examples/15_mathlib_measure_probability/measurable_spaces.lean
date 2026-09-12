/-
文件: 15_mathlib_measure_probability/measurable_spaces.lean
描述: 可测空间，可测集
编译: lake build Lean4Tutorial.Examples.MathlibMeasureProbability.MeasurableSpaces
依赖: Mathlib.MeasureTheory.MeasurableSpace.Basic
-/

import Mathlib.MeasureTheory.MeasurableSpace.Basic

namespace Lean4Tutorial.Examples.MathlibMeasureProbability.MeasurableSpaces

/-! # 可测空间（Measurable Spaces） -/

-- 可测空间是具有 σ-代数结构的集合
-- σ-代数是一族子集，满足：
--   1. 全集在其中
--   2. 对补集封闭
--   3. 对可数并封闭
--
-- 在 Mathlib 中，MeasurableSpace α 表示 α 上的可测空间结构
-- 可测集族记为 MeasurableSet

/-! ## σ-代数的定义 -/

-- 一个集合 X 上的 σ-代数 𝓕 是 X 的一族子集，满足：
--   1. X ∈ 𝓕
--   2. 如果 A ∈ 𝓕，则 Aᶜ ∈ 𝓕
--   3. 如果 Aₙ ∈ 𝓕 对所有 n，则 ⋃ₙ Aₙ ∈ 𝓕

#check MeasurableSpace
#check MeasurableSet

/-! ## 可测集的性质 -/

variable {α : Type*} [MeasurableSpace α]

-- 全集是可测的
theorem univ_measurable : MeasurableSet (Set.univ : Set α) := by
  exact MeasurableSet.univ

-- 空集是可测的
theorem empty_measurable : MeasurableSet (∅ : Set α) := by
  exact MeasurableSet.empty

-- 可测集的补集是可测的
theorem compl_measurable {s : Set α} (hs : MeasurableSet s) :
    MeasurableSet sᶜ := by
  exact MeasurableSet.compl hs

-- 两个可测集的并是可测的
theorem union_measurable {s t : Set α} (hs : MeasurableSet s) (ht : MeasurableSet t) :
    MeasurableSet (s ∪ t) := by
  exact MeasurableSet.union hs ht

-- 两个可测集的交是可测的
theorem inter_measurable {s t : Set α} (hs : MeasurableSet s) (ht : MeasurableSet t) :
    MeasurableSet (s ∩ t) := by
  exact MeasurableSet.inter hs ht

-- 可测集的差是可测的
theorem diff_measurable {s t : Set α} (hs : MeasurableSet s) (ht : MeasurableSet t) :
    MeasurableSet (s \ t) := by
  exact MeasurableSet.diff hs ht

-- 可数个可测集的并是可测的
-- (i.e., σ-代数对可数并封闭)

-- 可数个可测集的交是可测的
-- 由 De Morgan 定律可得

/-! ## 可测函数 -/

-- 函数 f : α → β 是可测的，如果
-- 每个可测集的原像都是可测的
--
-- 即：对任意可测集 S ⊆ β，f⁻¹(S) ⊆ α 是可测的

#check Measurable

-- 可测函数的性质
variable {β : Type*} [MeasurableSpace β]

-- 常值函数可测
theorem measurable_const (b : β) : Measurable (fun (_ : α) => b) := by
  exact measurable_const

-- 恒等函数可测
theorem measurable_id : Measurable (fun x : α => x) := by
  exact measurable_id

-- 可测函数的复合可测
variable {γ : Type*} [MeasurableSpace γ]

theorem measurable_comp {f : α → β} {g : β → γ}
    (hf : Measurable f) (hg : Measurable g) : Measurable (g ∘ f) := by
  exact Measurable.comp hg hf

/-! ## Borel σ-代数 -/

-- 对于拓扑空间，有一个标准的 σ-代数：Borel σ-代数
-- 它是由所有开集生成的 σ-代数
-- 即包含所有开集的最小 σ-代数

-- 实数上的 Borel σ-代数由所有开区间生成

-- 在 Borel 空间中，连续函数都是可测的

/-! ## 生成的 σ-代数 -/

-- 给定任意一族集合，可以生成一个 σ-代数
-- 即包含这族集合的最小 σ-代数

-- 这类似于拓扑中由开集基生成拓扑的概念

/-! ## 乘积可测空间 -/

-- 两个可测空间的笛卡尔积上有乘积 σ-代数
-- 它是由所有"可测矩形"生成的 σ-代数
-- 可测矩形 = A × B，其中 A、B 可测

/-! ## 可测空间的重要性 -/

-- 可测空间是测度论和概率论的基础
--
-- 测度论的结构：
--   可测空间（MeasurableSpace） + 测度（Measure） = 测度空间
--
-- 概率论的结构：
--   概率空间 = 测度空间 + 总测度为 1

-- 为什么需要 σ-代数？
--   1. 不是所有集合都是"可测的"（Banach-Tarski 悖论）
--   2. 需要足够多的可测集来支持常用运算
--   3. σ-代数恰好是可数运算封闭的集合族

end Lean4Tutorial.Examples.MathlibMeasureProbability.MeasurableSpaces
