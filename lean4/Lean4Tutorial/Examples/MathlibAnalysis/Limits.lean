/-
文件: 11_mathlib_analysis/limits.lean
描述: 数列极限与函数极限（tendsto）
编译: lake build Lean4Tutorial.Examples.MathlibAnalysis.Limits
依赖: Mathlib.Order.Filter.Basic
-/

import Mathlib.Order.Filter.Basic
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibAnalysis.Limits

/-! # 极限（Limits） -/

-- Mathlib 使用 filter 和 tendsto 来描述极限
-- 这是一种非常通用的方法，可以统一处理
-- 数列极限、函数极限、无穷远极限等各种极限概念

/-! ## 数列极限 -/

-- 数列 a : ℕ → ℝ 收敛到 l，记作 lim_{n→∞} a n = l
-- 在 Mathlib 中表示为：Filter.Tendsto a Filter.atTop (𝓝 l)
-- 读作：当 n 趋向无穷时，a n 趋向 l

-- 直观定义：
-- ∀ ε > 0, ∃ N, ∀ n ≥ N, |a n - l| < ε

-- Mathlib 中的表述
#check @Filter.Tendsto
#check Filter.atTop
#check nhds

-- 记号：a → l 当 n → ∞
-- 在 Lean 中可以写作：Tendsto a atTop (nhds l)

/-! ## 数列极限的基本例子 -/

-- 常数列极限：lim c = c
theorem tendsto_const (c : ℝ) :
    Filter.Tendsto (fun (_ : ℕ) => c) Filter.atTop (nhds c) := by
  exact tendsto_const_nhds

-- lim (1/n) = 0
theorem tendsto_one_div :
    Filter.Tendsto (fun n : ℕ => 1 / (n : ℝ)) Filter.atTop (nhds 0) := by
  exact?

-- 若 |q| < 1，则 lim q^n = 0
-- 需要更多导入

/-! ## 函数极限 -/

-- 函数 f : ℝ → ℝ 在 x → a 时的极限为 l
-- 记作 lim_{x→a} f(x) = l
-- 在 Mathlib 中表示为：Tendsto f (𝓝 a) (𝓝 l)

-- 直观定义：
-- ∀ ε > 0, ∃ δ > 0, ∀ x, 0 < |x - a| < δ → |f x - l| < ε

/-! ## 极限的性质 -/

-- 极限的唯一性
-- 如果 f 在 a 处有极限，则极限唯一

-- 极限的局部有界性
-- 如果 f 在 a 处有极限，则 f 在 a 附近有界

/-! ## 极限的运算 -/

-- 如果 lim f = l，lim g = m，则
--   lim (f + g) = l + m
--   lim (f * g) = l * m
--   lim (f / g) = l / m （当 m ≠ 0 时）
--   lim (c * f) = c * l

-- 这些性质在 Mathlib 中以 tendsto_add, tendsto_mul 等形式存在

#check tendsto_add
#check tendsto_mul
#check tendsto_neg
#check tendsto_sub

/-! ## 夹逼定理（Squeeze Theorem） -/

-- 如果对于 a 附近的所有 x，有 f(x) ≤ g(x) ≤ h(x)，
-- 且 lim_{x→a} f(x) = lim_{x→a} h(x) = l，
-- 则 lim_{x→a} g(x) = l

/-! ## 单调收敛定理 -/

-- 单调有界数列必收敛
-- 递增有上界的数列收敛
-- 递减有下界的数列收敛

/-! ## 柯西准则 -/

-- 数列收敛当且仅当它是柯西列
-- 柯西列：∀ ε > 0, ∃ N, ∀ m n ≥ N, |a_m - a_n| < ε

/-! ## 无穷远极限 -/

-- lim_{x→∞} f(x) = l
-- 表示为：Tendsto f atTop (nhds l)

-- lim_{x→-∞} f(x) = l
-- 表示为：Tendsto f atBot (nhds l)

-- lim_{x→a} f(x) = +∞
-- 表示为：Tendsto f (nhds a) atTop

/-! ## 滤子（Filter）简介 -/

-- Filter 是 Mathlib 中描述极限的基础概念
-- 一个滤子是一个集合族，满足某些性质
-- 直观上，滤子描述了"趋向某个方向"的概念

-- 常见的滤子：
--   atTop：趋向正无穷
--   atBot：趋向负无穷
--   nhds a：趋向点 a（邻域滤子）
--   atBot ⊓ atTop：趋向无穷（绝对值趋向无穷）

/-! ## tendsto 的定义 -/

-- Tendsto f F G 表示：
--   对于 G 中的任何集合 V（"目标附近"），
--   f 的原像 f⁻¹(V) 在 F 中（"足够接近极限时"）

-- 直观地说：当输入按 F 趋向极限时，输出按 G 趋向极限

/-! ## 极限与连续性的关系 -/

-- 函数 f 在 a 处连续当且仅当
--   lim_{x→a} f(x) = f(a)
-- 即 Tendsto f (nhds a) (nhds (f a))

-- 这将在下一节连续性中详细讨论

/-! ## 重要极限 -/

-- lim_{x→0} sin(x) / x = 1
-- lim_{x→∞} (1 + 1/x)^x = e
-- 这些需要导入更多分析模块

end Lean4Tutorial.Examples.MathlibAnalysis.Limits
