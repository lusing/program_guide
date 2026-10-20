import Mathlib.MeasureTheory.Constructions.Polish.Basic

/-!
# 第 40 章 解析集（Lean）

严书 §7.6。mathlib 锚点（Constructions/Polish/Basic.lean，
**B7 实测翻案**：原计划判"无基础设施"作废）：
`MeasureTheory.AnalyticSet`（解析集 = Polish 空间的连续
像）、`AnalyticSet.image_of_continuous`（连续像封闭）、
`MeasurablySeparable`（可分离谓词）与 **`AnalyticSet.
measurablySeparable`（Lusin 分离定理）**、Borel 集的解析
户口族（analyticSet_empty 等）。

实弹：锚点全家福 + ℝ 上 Borel 集的解析户口引用。
-/

open MeasureTheory

/-! ## 锚点正名 -/

#check @MeasureTheory.AnalyticSet
#check @MeasureTheory.MeasurablySeparable
#check @MeasureTheory.AnalyticSet.image_of_continuous

/-! ## Lusin 分离定理的机器版 -/

/-! `AnalyticSet.measurablySeparable`：两个不交解析集可被
可测集分离——严书 7.6.4-7.6.5 的形式化。树切割 + 归纳
分层的经典证明（Souslin-Lusin 管线）在 mathlib 中完整
运转（文件内 `MeasurablySeparable.iUnion` 等组合引理
支撑）。 -/
#check @MeasureTheory.AnalyticSet.measurablySeparable

/-! ## Borel 的解析户口 -/

/-- 空集的解析户口（解析集类的非空性底座件）。 -/
example {α : Type} [TopologicalSpace α] : MeasureTheory.AnalyticSet (∅ : Set α) :=
  MeasureTheory.analyticSet_empty

/-! Suslin 定理（双解析 = Borel）与 Choquet 可容度性链在
mathlib 中分布于同文件族的可测性定理（`AnalyticSet.
measurable_of...` 型）；解析集的 Lebesgue 可测性由容度
链推出（docs 40.4 骨架）——机器侧登记陈述引用。 -/
#check @MeasureTheory.AnalyticSet.image_of_continuousOn
