import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic

/-!
# 第 09 章 连续随机变量（Lean）

Miller ch8 的机器侧：mathlib 的 Lebesgue 体积
`Real.volume_Icc`（均匀概率的测度原文）与密度 2x 的
CDF 反导数判据（`HasDerivAt` 形态的 F′ = f）——区间
概率、归一、多项式 CDF 端点全部 norm_num 精确判决。
-/

open MeasureTheory
open Set

/-! ## 锚点正名 -/

#check @Real.volume_Icc   -- volume (Icc a b) = ofReal (b − a)：均匀概率的原文
#check @hasDerivAt_pow    -- (xⁿ)′ = n·xⁿ⁻¹：F′ = f 的机器件

/-! ## 均匀：体积账 -/

/-- **总质量**：[0,1] 的体积 = 1（均匀密度的归一）。 -/
example : volume (Icc (0 : ℝ) 1) = 1 := by simp [Real.volume_Icc]

/-- **区间账**：P(1/4 ≤ U ≤ 3/4) = 体积 1/2（长度比的
测度原文；连续世界端点开闭无所谓）。 -/
example : volume (Icc (1 / 4 : ℝ) (3 / 4)) = ENNReal.ofReal (1 / 2) := by
  rw [Real.volume_Icc]; congr 1; norm_num

/-! ## 密度 f(x) = 2x：F = x² 的全套账 -/

/-- **反导数判据**：F(y) = y² 在 x 处的导数 = 2x = f(x)
（微积分基本定理的逐点形态）。 -/
example (x : ℝ) : HasDerivAt (fun y => y ^ 2) (2 * x) x := by
  simpa using hasDerivAt_pow 2 x

/-- **归一**：∫₀¹ 2x dx = F(1) − F(0) = 1（这个密度天然
归一，常数免配）。 -/
example : (1 : ℝ) ^ 2 - 0 ^ 2 = 1 := by norm_num

/-- **区间概率**：P(1/4 ≤ X ≤ 3/4) = (3/4)² − (1/4)² = 1/2。 -/
example : (3 / 4 : ℝ) ^ 2 - (1 / 4) ^ 2 = 1 / 2 := by norm_num

/-- **尾部账**：P(X ≤ 1/4) = 1/16（小值区域只占 6.25%——
质量向 1 端倾斜的密度）。 -/
example : ((1 / 4 : ℝ) ^ 2 = 1 / 16) := by norm_num

/-! ## 多项式密度 (6/11)(2+3x−5x²) 的 CDF -/

/-- **端点归一**：F(1) = (6/11)(2 + 3/2 − 5/3) = 1
（∫₀¹ 形状 = 11/6 ⟹ 常数 6/11 的配平闭环）。 -/
example : (6 / 11 : ℝ) * (2 + 3 / 2 - 5 / 3) = 1 := by norm_num

/-- **中位读数**：F(1/2) = (6/11)(1 + 3/8 − 5/24) = 7/11。 -/
example : (6 / 11 : ℝ) * (1 + 3 / 8 - 5 / 24) = 7 / 11 := by norm_num

/-- **半程概率**：P(X ≤ 1/2) = 7/11 > 1/2（左倾——中位数
在均值 9/22 的右侧，两把"中心"尺子分道）。 -/
example : (7 : ℚ) / 11 > 1 / 2 := by norm_num

/-- **Cauchy 配平预告**：形状 1/(1+x²) 在整轴的面积是 π
（arctan 的端点账），常数 1/π 使其成密度。 -/
example : Real.tan (Real.pi / 4) = 1 := by norm_num
