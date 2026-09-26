# 18 · 测度论与概率论

> 对应示例：`examples/15_mathlib_measure_probability/measure_probability.lean`

源码坐标：`Mathlib/MeasureTheory/MeasurableSpace/Defs.lean`（可测空间）、`Mathlib/MeasureTheory/Measure/MeasureSpaceDef.lean`（Measure 结构、volume）、`Mathlib/MeasureTheory/Integral/Bochner/`（博赫纳积分）、`Mathlib/Probability/`（概率论专题）。

## 18.1 可测空间

```lean
import Mathlib.MeasureTheory.MeasurableSpace.Basic

-- MeasurableSpace：σ-代数作为 class（Defs.lean，可测集谓词 + 三条公理）
-- MeasurableSet s 是"可测"谓词（Defs.lean:64）

-- 基本公理（命名规律：measurableSet_op）
example [MeasurableSpace α] : MeasurableSet (∅ : Set α) := MeasurableSet.empty
example [MeasurableSpace α] : MeasurableSet (Set.univ : Set α) := MeasurableSet.univ
example [MeasurableSpace α] {s : Set α} (hs : MeasurableSet s) :
    MeasurableSet sᶜ := hs.compl
example [MeasurableSpace α] {s : ℕ → Set α} (hs : ∀ i, MeasurableSet (s i)) :
    MeasurableSet (⋃ i, s i) := MeasurableSet.iUnion hs

-- Borel σ-代数：拓扑空间上由开集生成
#check BorelSpace    -- class：measurable = borel 的一致性断言
example : MeasurableSpace ℝ := inferInstance   -- ℝ 自带 Borel 结构
```

## 18.2 测度与 volume

```lean
import Mathlib.MeasureTheory.Measure.MeasureSpaceDef

-- Measure（MeasureSpaceDef.lean:77）：structure，extends OuterMeasure
-- 字段：measureOf（集合函数）、empty、mono、iUnion_nat（可数可加）

-- MeasureSpace class（同文件:356）：给类型挂上标准测度 volume
-- ℝ 的 volume 就是勒贝格测度
example : volume (Set.Icc (0 : ℝ) 1) = 1 := by simp

-- 测度的基本性质（Measure 命名空间）
example [MeasurableSpace α] (μ : Measure α) : μ ∅ = 0 := μ.empty
example [MeasurableSpace α] (μ : Measure α) {s t : Set α} (h : s ⊆ t) :
    μ s ≤ μ t := μ.mono h

-- 概率测度作为谓词类（Typeclasses/Probability.lean:64）
-- class IsProbabilityMeasure (μ : Measure α) : Prop where measure_univ : μ univ = 1
example [MeasurableSpace α] (μ : Measure α) [IsProbabilityMeasure μ] :
    μ Set.univ = 1 := IsProbabilityMeasure.measure_univ
```

## 18.3 可测函数

```lean
import Mathlib.MeasureTheory.Function.StronglyMeasurable.Basic

-- Measurable f：可测集的原像可测（与拓扑的 Continuous 对偶）
example {f : ℝ → ℝ} (hf : Measurable f) (s : Set ℝ) (hs : MeasurableSet s) :
    MeasurableSet (f ⁻¹' s) := hf hs

-- 连续 ⇒ 可测（Borel 结构下）
example {f : ℝ → ℝ} (hf : Continuous f) : Measurable f := hf.measurable

-- measurable 战术：自动组装可测性证明
example : Measurable (fun x : ℝ => x^2 + x) := by fun_prop
```

## 18.4 博赫纳积分

```lean
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Real          -- μ.real（= (μ s).toReal）
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

-- 记法：∫ x, f x ∂μ 与 ∫ x in s, f x ∂μ
-- 可积性谓词 Integrable f μ
-- 注意 2026 API 细节：测度论定理的 MeasurableSpace 是隐式数据参数
-- {m : MeasurableSpace α}（不是实例隐式），需要从实例手动喂入

-- 常值函数积分
example [MeasurableSpace α] (μ : Measure α) (c : ℝ) :
    ∫ _ : α, c ∂μ = μ.real Set.univ • c := integral_const (m := ‹MeasurableSpace α›) c

-- 线性性
example [MeasurableSpace α] {f g : α → ℝ} {μ : Measure α}
    (hf : Integrable f μ) (hg : Integrable g μ) :
    ∫ x, f x + g x ∂μ = ∫ x, f x ∂μ + ∫ x, g x ∂μ :=
  integral_add (m := ‹MeasurableSpace α›) hf hg

-- 区间积分的计算实例（integral_id 在根命名空间，:201）
example : ∫ x in (0 : ℝ)..1, x = 1 / 2 := by
  rw [integral_id]
  norm_num
```

## 18.5 概率论专题（mathlib 的真实覆盖）

mathlib 的概率论在 2026 年已相当完整——**中心极限定理、Borel–Cantelli、条件期望、鞅**全部形式化：

```lean
import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Probability.BorelCantelli
import Mathlib.Probability.Independence.Basic

-- 中心极限定理（ProbabilityTheory 命名空间，CentralLimitTheorem.lean:79）：
-- 独立同分布、均值 0、方差 1 ⟹ 标准化和依分布收敛到标准高斯
#check @ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum
-- (hY : HasLaw Y (gaussianReal 0 1) P') (h0 : P[X 0] = 0) (h1 : P[X 0 ^ 2] = 1)
-- (hindep : iIndepFun X P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P) :
--   TendstoInDistribution (fun n ω ↦ (√n)⁻¹ * ∑ k ∈ Finset.range n, X k ω) atTop Y

-- 独立性谓词族（Independence/Basic.lean:96/111/124）：
-- iIndepSets / iIndep / iIndepSet / iIndepFun——从 σ-代数到随机变量四个层级

-- Borel-Cantelli 第二引理（BorelCantelli.lean:69）：
-- 独立事件序列的测度和发散 ⟹ 上极限概率为 1
#check @ProbabilityTheory.measure_limsup_eq_one
```

**设计观察**：概率论不引入"概率空间"新类型——`[MeasureSpace Ω] [IsProbabilityMeasure (volume : Measure Ω)]` 就够了。这种"复用一般结构 + 谓词类约束"的做法是 mathlib 降低 API 重复的核心手法。

---

> 上一章：[17 · 组合数学](17-combinatorics.md) ｜ 下一章：[19 · 常用高级战术](19-advanced-tactics.md) ｜ 返回：[README](../README.md)
