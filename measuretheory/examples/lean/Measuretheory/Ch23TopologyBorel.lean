import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic
import Mathlib.Topology.Bases
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

/-!
# 第 23 章 拓扑空间与 Borel σ-代数（Lean）

严书 §5.1 / 袁上册第 2 章 + §3.4。mathlib 锚点：`borel`
（拓扑 → σ-代数的 canonical 装配）、`Continuous.measurable`
（连续 ⟹ Borel 可测——"B(X) 是使连续函数可测的最小 σ-代数"
的机器版）、乘积对齐 `prod_le_borel_prod`（+ 第二可数下
`BorelSpace` instance 取等）、`SeparableSpace`/`
SecondCountableTopology`（可数性两档）。

Baire σ-代数：mathlib 无基础设施（`BaireSpace` 是纲定理概念，
同名不同物）——docs 分工注记。实弹：连续组合的可测性、
三处 BorelSpace instance（ℝ、ℝ×ℝ、序列空间 ℕ→ℝ——
第三幕默认舞台的机器登记）。
-/

open MeasureTheory

/-! ## 锚点正名 -/

#check @borel
#check @Continuous.measurable
#check @prod_le_borel_prod
#check @BorelSpace
#check @TopologicalSpace.SeparableSpace
#check @SecondCountableTopology

/-! ## 连续 ⟹ Borel 可测 -/

/-- 连续组合的免费可测性：abs 与三角函数由连续性过桥
（第 07 章 Borel 机器的一般化现场）。 -/
example : Measurable fun x : ℝ => |Real.sin x + 1| :=
  ((Real.continuous_sin.add continuous_const).abs).measurable

/-- 分段连续样例：x ↦ max x 0 的可测性。 -/
example : Measurable fun x : ℝ => max x 0 :=
  (continuous_id.max continuous_const).measurable

/-! ## BorelSpace 的 instance 层 -/

/-- ℝ 的 Borel 户口：borel 与标准 MeasurableSpace instance 一致
（`BorelSpace` class 即"borel = 默认 σ-代数"的登记证）。 -/
example : BorelSpace ℝ := inferInstance

/-- 乘积对齐（23.4）：ℝ×ℝ 的 BorelSpace——第二可数下
B(ℝ×ℝ) = B(ℝ) ⊗ B(ℝ) 的 instance 形态（`prod_le_borel_prod`
给 ≤ 方向，instance 给反向，合龙取等）。 -/
example : BorelSpace (ℝ × ℝ) := inferInstance

/-- 序列空间 ℕ → ℝ 的 BorelSpace（可数指标乘积的 Borel 对齐，
第 20/29 章的默认舞台）。 -/
example : BorelSpace (ℕ → ℝ) := inferInstance

/-! ## 可数性两档 -/

/-- ℝ 可分（第 29 章 Polish 的入场券之可分半）。 -/
example : TopologicalSpace.SeparableSpace ℝ := inferInstance

/-- ℝ 第二可数（乘积对齐取等的关键档）。 -/
example : SecondCountableTopology ℝ := inferInstance

/-- 可分性与第二可数在度量空间合流：有可数稠密集的度量空间
自动第二可数（袁书 §2.4 关系链的机器登记）。 -/
example (X : Type) [MetricSpace X] [TopologicalSpace.SeparableSpace X] :
    SecondCountableTopology X := inferInstance
