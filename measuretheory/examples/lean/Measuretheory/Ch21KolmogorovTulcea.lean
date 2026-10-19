import Mathlib.Probability.Kernel.IonescuTulcea.Traj
import Mathlib.MeasureTheory.Constructions.Projective

/-!
# 第 21 章 Kolmogorov 相容性与 Tulcea 定理（Lean）

严书 §4.5。mathlib 4.33 的两件基础设施（B4 实测修订——原计划
判"mathlib 无"，实测推翻）：

1. **Ionescu-Tulcea 定理全形式化**（Probability/Kernel/
   IonescuTulcea/ 三件套）：核列 κ : (n) → Kernel (前 n 步轨迹)
   (X (n+1)) 的无穷复合——`Kernel.traj κ a`（无穷轨迹核）、
   `Kernel.trajMeasure μ₀ κ`（初始分布 + 核列装配）、
   `Kernel.eq_traj`（唯一性判据）、`Kernel.map_traj_succ_self`
   （一步边际 = κ a）。**Tulcea 引擎**：存在性不要拓扑。
2. **投影极限谓词族**（Constructions/Projective.lean）：
   `IsProjectiveMeasureFamily`（相容族）、`IsProjectiveLimit`
   （投影极限谓词）+ `measure_cylinder`（柱集账）+ `unique`
   （唯一性——ext_of_generate_finite + 柱集 π-系收口）。
   **Kolmogorov 一般相容族的存在性 mathlib 仍无**（乘积型
   由第 20 章 `Measure.infinitePi` 承担）——Isabelle 侧分工。

实弹：唯一性定理的实例化（两个投影极限必相等——数学陈述
"唯一性"的机器版）与 traj 锚点正名。
-/

open MeasureTheory ProbabilityTheory

/-! ## 锚点正名 -/

#check @ProbabilityTheory.Kernel.traj
#check @ProbabilityTheory.Kernel.trajMeasure
#check @ProbabilityTheory.Kernel.eq_traj
#check @ProbabilityTheory.Kernel.map_traj_succ_self
#check @MeasureTheory.IsProjectiveMeasureFamily
#check @MeasureTheory.IsProjectiveLimit
#check @MeasureTheory.IsProjectiveLimit.measure_cylinder
#check @MeasureTheory.IsProjectiveLimit.unique
#check @MeasureTheory.cylinder

/-! ## 唯一性：柱集 π-系收口 -/

/-- **投影极限的唯一性**（Projective.lean）：有限测度族的两个
投影极限必相等。证明骨架：`ext_of_generate_finite`（第 06 章
唯一性机器）+ 可测柱集族是 π-系 + 柱集账一致 + 总质量一致。
本章 21.3 步骤 4 的机器版。 -/
example {ι : Type} {α : ι → Type} [∀ i, MeasurableSpace (α i)]
    (P : ∀ J : Finset ι, Measure ((j : J) → α j)) [∀ J, IsFiniteMeasure (P J)]
    (μ ν : Measure ((i : ι) → α i))
    (hμ : IsProjectiveLimit μ P) (hν : IsProjectiveLimit ν P) : μ = ν :=
  hμ.unique hν

/-- 柱集账：投影极限测度在每个柱集上的账 = 对应有限维账
（`measure_cylinder`——"账本 P(柱) := 有限维账"的定义性一致）。 -/
example {ι : Type} {α : ι → Type} [∀ i, MeasurableSpace (α i)]
    (P : ∀ J : Finset ι, Measure ((j : J) → α j))
    (μ : Measure ((i : ι) → α i)) (hμ : IsProjectiveLimit μ P)
    (I : Finset ι) (s : Set ((j : I) → α j)) (hs : MeasurableSet s) :
    μ (cylinder I s) = P I s :=
  hμ.measure_cylinder I hs

/-! ## Tulcea 侧：traj 锚点的数学内容

`map_traj_succ_self`：无穷轨迹核 traj 在"a+1 时刻坐标"上的
像测度 = 一步核 κ a——**Chapman-Kolmogorov 的无穷尾版**：
装配出的无穷维分布的一步边际恰是装机时的核。Tulcea 构造
"逐坐标装配"的逐字机器保证。

`eq_traj`：要证某测度 η = traj κ a，只需对每个有限窗口 b
验证 η 的 b-截段 = 有限复合 partialTraj κ a b——**唯一性的
usable 形态**（21.5 的"装配一致性检验"机器版）。-/

#check @ProbabilityTheory.Kernel.map_traj_succ_self

#check @ProbabilityTheory.Kernel.eq_traj
