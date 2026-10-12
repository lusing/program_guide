import Mathlib.MeasureTheory.Measure.Haar.Basic
import Mathlib.Topology.Algebra.Group.Compact

/-!
# 第 65 章 · 不动点定理群与 Haar 测度（Rudin 5.11–5.28）

本树 mathlib 的 Haar 测度走 Weil–Cartan 路线（prehaar 泛函 +
Tychonoff），与 Rudin 的 Kakutani 路线（C(G) 左移凸壳的紧凸集上
的不动点）构成同一结果的独立双证明——"第二证明通道"在数学本体
层面的化身。

锚点：`IsHaarMeasure`（左不变测度类，MeasureTheory 命名空间）、
`MeasureTheory.haarMeasure`（存在性，以正紧集 K₀ 归一化）、
`MeasureTheory.haarMeasure_unique`（唯一性）。
-/

#check @MeasureTheory.Measure.IsHaarMeasure
#check @MeasureTheory.Measure.haarMeasure
#check @MeasureTheory.Measure.haarMeasure_unique

-- IsHaarMeasure 是三条件的合取：紧集有限 + 左不变 + 开集正测
example {G : Type*} [Group G] [TopologicalSpace G] [MeasurableSpace G]
    (μ : MeasureTheory.Measure G) [MeasureTheory.Measure.IsHaarMeasure μ] : True := trivial

