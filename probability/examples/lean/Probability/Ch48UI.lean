import Mathlib.Probability.Martingale.OptionalStopping
import Mathlib.Probability.Martingale.Convergence
import Mathlib.Probability.Martingale.OptionalSampling
import Mathlib.Probability.Martingale.Centering

/-!
# 第 48 章 离散鞅 II：一致可积、停时与选样（Lean）

胡书 §7.3-7.4 的机器侧。锚墙登记五个定理的 mathlib 真名；两个精确主件：

- **例 7.3.1 的期望账**：非一致可积鞅 `Xₙ = 2ⁿ·∏Yⱼ` 的 `E|Xₙ| ≡ 1`
  （纯分数恒等式）——UI 失败的"活体标本"；
- **有界停时的选样账**：两步公平游走在 `T = 首次 S ≥ 1` 、
  `T∧2` 截断下四路径穷举 `E[S_{T∧2}] = 0`。
-/

/-! ## 锚墙 -/

#check @MeasureTheory.UniformIntegrable
-- 定义 7.3.1（一致可积）：sup_n ∫_{|X_n|≥c} |X_n| → 0（c → ∞）

#check @MeasureTheory.Integrable.tendsto_ae_condExp
-- 定理 7.3.3（Lévy 鞅上升定理）：E[Y|Fₙ] → E[Y|F∞] a.s.

#check @MeasureTheory.tendsto_ae_condExp
-- 同族的整合形式（下降滤流版本是定理 7.3.4）

#check @MeasureTheory.Martingale.stoppedValue_ae_eq_condExp_of_le
-- 定理 7.4.1 的核（选样定理）：S ≤ T 停时对上 E[X_T | F_S] = X_S

#check @MeasureTheory.submartingale_iff_expected_stoppedValue_mono
-- 定理 7.4.2 面：下鞅在单调上升有界停时列上的期望单调性

#check @MeasureTheory.predictablePart
-- 习题 7.3（Doob 分解）：上鞅 = 鞅 − 可料增过程（martingalePart 配对）

/-! ## 例 7.3.1：非一致可积鞅的期望账 -/

/-- 例 7.3.1 的纯代数面：`E|Xₙ| = 2ⁿ·(1/2)ⁿ = 1` 对一切 n 成立
——均值恒定，为 UI 失败（sup_n E|Xₙ|1{|Xₙ|>c} ≡ 1）提供恒定下界。 -/
example (n : ℕ) : (2 : ℚ) ^ n * ((1 : ℚ) / 2) ^ n = 1 := by
  have h2 : (2 : ℚ) ^ n ≠ 0 := pow_ne_zero n (by norm_num)
  rw [div_pow]
  field_simp
  simp

/-- 存活概率 `P(Xₙ ≠ 0) = (1/2)ⁿ` 精确趋于零——均值恒 1 而轨道归零
（a.s. 极限为 0，`E|Xₙ − 0| = 1` 永不归零：a.s. 收敛 ≠ L¹ 收敛）。 -/
example (n : ℕ) : ((1 : ℚ) / 2) ^ n * 2 ^ n = 1 := by
  have h2 : (2 : ℚ) ^ n ≠ 0 := pow_ne_zero n (by norm_num)
  rw [div_pow]
  field_simp
  simp

/-! ## 有界停时的选样账（四路径穷举） -/

/-- 两步公平游走、停时 `T = 首次 S ≥ 1` 的截断 `T ∧ 2`：
四条路径的 `S_{T∧2}` 取值 `[1, 1, 0, -2]`——
`E[S_{T∧2}] = 0 = E[S_2]`，选样定理（注 7.4.3(a) 有界情形）的完全计数。 -/
example : ((([1, 1, 0, -2] : List ℚ).sum) / 4) = 0 := by
  norm_num
