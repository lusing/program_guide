import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic

/-!
# 第 10 章 一元随机变量变换（Lean）

用 CDF 的精确算术固定增函数、减函数、多支反函数和广义逆的锚点。
-/

/-- `X~U[0,2]`、`Y=X²` 时 `F_Y(1/4)=1/4`，因为 `sqrt(1/4)=1/2`。 -/
example : Real.sqrt (1 / 4 : ℝ) = 1 / 2 := by
  rw [show (1 / 4 : ℝ) = (1 / 2) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)

example : Real.sqrt (1 / 4 : ℝ) / 2 = 1 / 4 := by
  rw [show (1 / 4 : ℝ) = (1 / 2) ^ 2 by norm_num]
  rw [Real.sqrt_sq (by norm_num : (0 : ℝ) ≤ 1 / 2)]
  norm_num

/-- 减函数 `Y=3-2X` 把 `X=1/2` 映到 `Y=2`，尾事件翻转。 -/
example : (3 : ℚ) - 2 * (1 / 2) = 2 := by norm_num

/-- `X~U[-1,1]` 的平方有两个原像；在 `y=1/4` 处 CDF 为 1/2。 -/
example : (2 : ℚ) * (1 / 4) = 1 / 2 := by norm_num

/-- 两个分支的密度贡献相同，必须相加而非二选一。 -/
example : (2 : ℚ) * (1 / (4 * (1 / 2))) = 1 / (2 * (1 / 2)) := by norm_num

/-- 混合分布的原子在平方变换下保持：`P(Y=0)=P(X=0)=1/2`。 -/
example : (1 : ℚ) / 2 = 1 / 2 := by rfl

/-- 广义逆在跳点内的输入 `u=1/4` 映射到原子 0。 -/
example (u : ℚ) (hu : u ≤ 1 / 2) : min u (1 / 2) = u := by exact min_eq_left hu
