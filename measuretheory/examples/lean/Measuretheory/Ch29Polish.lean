import Mathlib.Topology.MetricSpace.Polish
import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic

/-!
# 第 29 章 Polish 空间（Lean）

严书 §5.7 / 袁上册 §2.4 + 第 11 章。mathlib 锚点：
`PolishSpace`（class：∃ 完备距离 + 可分）、实例族（ℝ、
可数乘积封闭）、`Constructions/Polish/` 文件族（嵌入定理
`EmbeddingReal`、可测分离——后者属第 40 章素材）。

实弹：家谱表首行的机器登记（ℝ 的 PolishSpace）、可数乘积
封闭（ℕ → ℝ 的户口——第三幕默认舞台）、BorelSpace 联合登记。
"Polish 有限 Borel 测度正则"（严书 5.7.6）的打包定理以 docs
29.3 骨架 + 数值承载（分工如实）。
-/

open MeasureTheory

/-! ## 锚点正名 -/

#check @PolishSpace
#check @TopologicalSpace.SeparableSpace
#check @SecondCountableTopology

/-! ## 家谱的机器登记 -/

/-- ℝ 是 Polish（可分 + 完备）：家谱表首行。 -/
example : PolishSpace ℝ := inferInstance

/-- 可数乘积封闭：ℕ → ℝ 是 Polish——序列空间的典范户口
（第 20 章无穷乘积的舞台 + 第 29.2 嵌入定理的目标）。 -/
example : PolishSpace (ℕ → ℝ) := inferInstance

/-- Polish ⟹ BorelSpace 联合登记：测度论在标准 Borel 上的
一切 API 即时可用（第 29.4 牌照条例的机器面）。 -/
example : BorelSpace (ℕ → ℝ) := inferInstance

/-- Polish 的可分半与第二可数半（MetricSpace 情形的合流：
可分 ⟹ 第二可数——袁书关系链的 instance 化）。 -/
example (X : Type) [MetricSpace X] [PolishSpace X] :
    TopologicalSpace.SeparableSpace X := inferInstance
