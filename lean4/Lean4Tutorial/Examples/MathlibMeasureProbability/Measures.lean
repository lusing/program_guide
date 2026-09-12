/-
文件: 15_mathlib_measure_probability/measures.lean
描述: 测度，勒贝格测度
编译: lake build Lean4Tutorial.Examples.MathlibMeasureProbability.Measures
依赖: Mathlib.MeasureTheory.Measure.MeasureSpace
-/

import Mathlib.MeasureTheory.Measure.MeasureSpace
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibMeasureProbability.Measures

/-! # 测度（Measures） -/

-- 测度是给可测集赋予"大小"的函数
-- 测度 μ 满足：
--   1. μ(∅) = 0
--   2. μ(A) ≥ 0（非负性）
--   3. 可数可加性：如果 Aₙ 两两不交，则 μ(⋃ Aₙ) = Σ μ(Aₙ)
--
-- 在 Mathlib 中，MeasureSpace α 表示 α 上的测度空间
-- 测度函数为 volume 或 μ

/-! ## 测度的定义 -/

-- 测度空间 = 可测空间 + 测度
-- MeasureSpace α 是 MeasurableSpace α 加上一个测度

#check MeasureSpace

variable {α : Type*} [MeasureSpace α]

/-! ## 测度的基本性质 -/

-- 空集的测度为 0
theorem measure_empty : measure (∅ : Set α) = 0 := by
  exact measure_empty

-- 测度非负
theorem measure_nonneg (s : Set α) : 0 ≤ measure s := by
  exact measure_nonneg s

-- 单调性：如果 A ⊆ B，则 μ(A) ≤ μ(B)
theorem measure_mono {s t : Set α} (h : s ⊆ t) : measure s ≤ measure t := by
  exact measure_mono h

-- 可数可加性（σ-可加性）
-- 如果 {Aₙ} 是两两不交的可测集序列，则
-- μ(⋃ₙ Aₙ) = Σₙ μ(Aₙ)

/-! ## 测度的更多性质 -/

-- 次可加性：μ(⋃ₙ Aₙ) ≤ Σₙ μ(Aₙ)
-- （不要求不交）

-- 连续下增：如果 A₁ ⊆ A₂ ⊆ A₃ ⊆ ...，则
-- μ(⋃ₙ Aₙ) = lim_{n→∞} μ(Aₙ)

-- 连续上减：如果 A₁ ⊇ A₂ ⊇ A₃ ⊇ ...，且 μ(A₁) < ∞，则
-- μ(⋂ₙ Aₙ) = lim_{n→∞} μ(Aₙ)

/-! ## 零测集 -/

-- 测度为 0 的集合称为零测集
-- NullSet s := measure s = 0

-- 零测集的子集是零测集
-- 可数个零测集的并是零测集

-- "几乎处处"（almost everywhere, a.e.）
-- 性质 P 几乎处处成立，如果不满足 P 的集合是零测集

/-! ## 勒贝格测度（Lebesgue Measure） -/

-- 实数集 ℝ 上的勒贝格测度是长度概念的推广
-- 区间 [a, b] 的勒贝格测度是 b - a

-- 勒贝格测度的性质：
--   1. 平移不变性：μ(A + x) = μ(A)
--   2. 正则性：可以用开集从外逼近，用紧集从内逼近
--   3. σ-有限性：ℝ 可以表示为可数个有限测度集的并

-- 高维欧氏空间 ℝⁿ 上也有勒贝格测度
-- 推广了体积的概念

/-! ## 勒贝格积分 -/

-- 有了测度，就可以定义勒贝格积分
-- ∫ f dμ 表示函数 f 关于测度 μ 的积分

-- 勒贝格积分比黎曼积分更强大：
--   1. 更多函数可积
--   2. 更好的极限定理（单调收敛、控制收敛）
--   3. 可以在更一般的空间上积分

/-! ## 重要的收敛定理 -/

-- 1. 单调收敛定理（Levi 定理）
--    如果 0 ≤ f₁ ≤ f₂ ≤ f₃ ≤ ... 且 fₙ → f a.e.，则
--    ∫ f dμ = lim ∫ fₙ dμ

-- 2. Fatou 引理
--    如果 fₙ ≥ 0，则
--    ∫ lim inf fₙ dμ ≤ lim inf ∫ fₙ dμ

-- 3. 控制收敛定理（Lebesgue 定理）
--    如果 fₙ → f a.e.，且存在可积函数 g 使得 |fₙ| ≤ g a.e.，则
--    ∫ f dμ = lim ∫ fₙ dμ

/-! ## 乘积测度 -/

-- 两个测度空间 (X, μ) 和 (Y, ν) 的乘积测度 μ × ν
-- 满足：(μ × ν)(A × B) = μ(A) * ν(B)

-- 富比尼定理：
-- 如果 f 可积，则
-- ∫_{X×Y} f(x,y) d(μ×ν) = ∫_X (∫_Y f(x,y) dν(y)) dμ(x)
--                        = ∫_Y (∫_X f(x,y) dμ(x)) dν(y)

-- 托内利定理（非负函数版本）：
-- 如果 f ≥ 0 可测，则可以交换积分顺序

/-! ## 其他重要的测度 -/

-- 1. 计数测度：每个点的测度为 1
--    积分就是求和

-- 2. 狄拉克测度 δ_a：集中在点 a 的测度
--    δ_a(A) = 1 如果 a ∈ A，否则 0

-- 3. 概率测度：总测度为 1 的测度
--    下一节详细讨论

-- 4. 豪斯多夫测度：推广了维数的概念
--    可以测量分数维集合的"大小"

-- 5. 哈尔测度：局部紧群上的平移不变测度

/-! ## 测度的分解 -/

-- 勒贝格分解定理：
-- 任意 σ-有限测度可以唯一分解为
-- 绝对连续部分 + 奇异部分
-- μ = μ_ac + μ_sing

-- 拉东-尼科迪姆定理：
-- 如果 μ 关于 ν 绝对连续，则存在密度函数 f 使得
-- μ(A) = ∫_A f dν
-- f 称为 μ 关于 ν 的拉东-尼科迪姆导数，记作 dμ/dν

end Lean4Tutorial.Examples.MathlibMeasureProbability.Measures
