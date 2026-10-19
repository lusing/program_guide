import Mathlib.MeasureTheory.Function.SimpleFuncDenseLp
import Mathlib.MeasureTheory.Integral.CompactlySupported
import Mathlib.Topology.ContinuousMap.CompactlySupported

/-!
# 第 27 章 Lusin 定理（Lean）

严书 §5.5 / 袁上册 §11.3。**分工如实**：近似型 Lusin 主定理
（C_c 在 Lᵖ 稠密 / 紧限制连续）mathlib 无直接锚——
`Constructions/Polish` 的 "Lusin" 是解析集分离定理（第 40 章
素材，不冒领）。本章机器侧的零件：简单函数 Lᵖ 逼近
（`SimpleFunc.memLp_approxOn` 族——Lusin 证明第二步的现成件）
与 C_c 函数的可积性（`CompactlySupportedContinuousMap.
integrable`——第 24 章泛函论的积分前提）。
-/

open MeasureTheory
open scoped CompactlySupported

/-! ## 零件正名 -/

#check @MeasureTheory.SimpleFunc.memLp_approxOn
#check @MeasureTheory.SimpleFunc.tendsto_approxOn_range_Lp_eLpNorm
#check @CompactlySupportedContinuousMap.integrable
#check @CompactlySupportedContinuousMap.integralPositiveLinearMap

/-! ## 零件实弹：简单函数逼近的存在性 -/

/-! 可测函数的 Lᵖ 逼近零件（`memLp_approxOn`）：逼近对象落在
简单函数的值域网中——Lusin 证明第二步（简单稠密）的机器
登记（陈述见上方 #check）。 -/

/-- C_c 的可积性：紧支撑连续函数在 σ-有限测度下可积——
第 24 章泛函论 I(f) = ∫f dμ 良定义的前提，Lusin C_c 稠密
的"函数存在性"半边。 -/
example (X : Type) [TopologicalSpace X] [MeasurableSpace X] [OpensMeasurableSpace X]
    (E : Type) [NormedAddCommGroup E]
    (f : X →C_c E) (μ : Measure X) [IsFiniteMeasureOnCompacts μ] :
    Integrable f μ :=
  CompactlySupportedContinuousMap.integrable f
