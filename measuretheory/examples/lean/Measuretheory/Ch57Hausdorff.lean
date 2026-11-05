import Mathlib.Topology.MetricSpace.HausdorffDimension
import Mathlib.MeasureTheory.Measure.Hausdorff
import Mathlib.Topology.Instances.CantorSet

/-!
# 第 57 章 Hausdorff 测度、填充测度与分形维数（Lean）

胡书 §1.5 的机器侧锚点：mathlib 的 `μH[d]`（`hausdorffMeasure`，
双层 sup-inf 构造即正文 57.4 的直译）与 `dimH`（临界指数）。本章
完整证明：可数集维数为零（"不可数才可能有正维数"）、有内点集
维数为全维；零或顶二分法（正文 57.5 的相变）作为定理锚点登记。
Cantor 集维数等式 mathlib 未收录——按通道分工纪律交给
Julia/Python/Prolog 的精确证书，不硬造形式化。
-/

open MetricSpace MeasureTheory

/-! ## 定理锚点正名 -/

#check @MeasureTheory.Measure.hausdorffMeasure
-- 正文 57.4：μH[s] = sup_δ inf{Σ d(Cᵢ)^s : 覆盖, diam ≤ δ}

#check @MeasureTheory.Measure.hausdorffMeasure_zero_or_top
-- 正文 57.5 相变：s < t ⟹ μH[s] E = ∞ 或 μH[t] E = 0

#check @dimH_union
-- 维数对有限并取最大（可数版 dimH_iUnion）

#check @dimH_countable
-- 可数集维数为零

/-! ## 单点与空集：维数的起点 -/

example (x : ℝ) : dimH ({x} : Set ℝ) = 0 :=
  dimH_singleton x

example : dimH (∅ : Set ℝ) = 0 :=
  dimH_empty

/-! ## 可数集维数零：覆盖账看见可数的贫瘠 -/

/-- 自然数集（作为 ℝ 的子集）维数为零——可数并的单点账。
这正是正文 57.6 质量分布原理的"反面"：没有不可数的质量，
任何幂次 s > 0 的覆盖账都能用"逐点覆盖、直径为零"清零。 -/
example : dimH (Set.range (fun n : ℕ => (n : ℝ))) = 0 :=
  dimH_countable (Set.countable_range _)

/-- 有理数集维数为零：Q 可数（Q = ⋃ n, {p/q : |p| ≤ n} 的计数版账
也可以走 Set.Countable 实例）。 -/
example : dimH (Set.range (fun q : ℚ => (q : ℝ))) = 0 :=
  dimH_countable (Set.countable_range _)

/-! ## 有内点的集合：回到欧氏维数 -/

/-- 区间 [0,1] 的 Hausdorff 维数为 1：有内点 ⟹ 全维
（Real.dimH_of_nonempty_interior）。 -/
example : dimH (Set.Icc (0 : ℝ) 1) = 1 := by
  have h : (interior (Set.Icc (0 : ℝ) 1)).Nonempty := by
    rw [interior_Icc]
    exact ⟨1 / 2, by constructor <;> norm_num⟩
  rw [Real.dimH_of_nonempty_interior h]
  simp

/-! ## 单调性与 Cantor 集的名字登记 -/

/-- 维数单调：C ⊆ [0,1] ⟹ dimH C ≤ 1。上界的机器版；
下界 log2/log3 的账见 Python 证书（27 < 32）。 -/
example : dimH (cantorSet) ≤ dimH (Set.Icc (0 : ℝ) 1) :=
  dimH_mono cantorSet_subset_unitInterval

/-- 计数尺度换算锚点：μH[1] 在 ℝ 上即直径账（与 Lebesgue 测度
只差常数——正文 57.4 的 c_n 换算，此处只登记 API）。 -/
example (s : Set ℝ) (h₁ h₂ : ℝ) (h : h₁ < h₂) :
    μH[h₂] s = 0 ∨ μH[h₁] s = ⊤ :=
  MeasureTheory.Measure.hausdorffMeasure_zero_or_top h s
