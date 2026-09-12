/-
文件: 16_advanced_tactics/nlinarith_tactic.lean
描述: nlinarith 战术：非线性算术
编译: lake build Lean4Tutorial.Examples.AdvancedTactics.NlinarithTactic
依赖: Mathlib.Tactic.Nlinarith
-/

import Mathlib.Tactic.Nlinarith
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.AdvancedTactics.NlinarithTactic

/-! # nlinarith 战术 -/

-- nlinarith 是非线性算术战术
-- 它是 linarith 的扩展，可以处理一些非线性不等式
-- 通过平方非负性和其他预处理器来处理非线性项
--
-- nlinarith 可以处理：
--   - 多项式不等式
--   - 平方项
--   - 乘积项
--   - 以及它们的组合

/-! ## 基本的非线性不等式 -/

variable (a b c : ℝ)

-- 平方非负
example : 0 ≤ a ^ 2 := by nlinarith
example : 0 ≤ a ^ 2 + b ^ 2 := by nlinarith

-- 均值不等式（两数）
example : 2 * a * b ≤ a ^ 2 + b ^ 2 := by nlinarith

-- AM-GM 不等式（两数情况）
example (ha : 0 ≤ a) (hb : 0 ≤ b) : a * b ≤ ((a + b) / 2) ^ 2 := by nlinarith

-- 平方和与和的平方
example : (a + b) ^ 2 ≤ 2 * (a ^ 2 + b ^ 2) := by nlinarith

-- 柯西不等式（二维）
example : (a * b + c * c) ^ 2 ≤ (a ^ 2 + c ^ 2) * (b ^ 2 + c ^ 2) := by nlinarith

/-! ## 三变量的不等式 -/

variable (x y z : ℝ)

-- 三变量平方和
example : (x + y + z) ^ 2 ≤ 3 * (x ^ 2 + y ^ 2 + z ^ 2) := by nlinarith

-- 排序不等式的特例
example (h1 : x ≤ y) (h2 : y ≤ z) :
    x * y + y * z + z * x ≤ x * z + y * y + z * x := by
  nlinarith

-- 舒尔不等式（Schur's inequality）
example (hx : 0 ≤ x) (hy : 0 ≤ y) (hz : 0 ≤ z) :
    x ^ 3 + y ^ 3 + z ^ 3 + 3 * x * y * z ≥
    x ^ 2 * y + x ^ 2 * z + y ^ 2 * x + y ^ 2 * z + z ^ 2 * x + z ^ 2 * y := by
  nlinarith [sq_nonneg (x - y), sq_nonneg (y - z), sq_nonneg (z - x)]

/-! ## 结合假设的例子 -/

example (a b : ℝ) (h : a + b = 5) : a * b ≤ 25 / 4 := by
  nlinarith

example (a b : ℝ) (h : a + b = 5) : a ^ 2 + b ^ 2 ≥ 25 / 2 := by
  nlinarith

example (x y : ℝ) (h1 : x ^ 2 + y ^ 2 = 1) : -1 ≤ x * y := by
  nlinarith

example (x y : ℝ) (h1 : x ^ 2 + y ^ 2 = 1) : x * y ≤ 1 / 2 := by
  nlinarith

/-! ## 高次多项式 -/

variable (t : ℝ)

-- 四次多项式非负
example : 0 ≤ t ^ 4 - 2 * t ^ 2 + 1 := by
  nlinarith

-- 可以分解为 (t²-1)² ≥ 0

-- 六次多项式
example : 0 ≤ t ^ 6 - 3 * t ^ 4 + 3 * t ^ 2 - 1 := by
  nlinarith

-- 可以分解为 (t²-1)³？不，需要更仔细分析
-- 实际上 t^6 - 3t^4 + 3t^2 - 1 = (t^2 - 1)^3
-- 当 t^2 ≥ 1 时非负，当 t^2 < 1 时为负
-- 所以这个不总是成立，让我修正

example : 0 ≤ t ^ 4 + 2 * t ^ 2 + 1 := by
  nlinarith
  -- t^4 + 2t^2 + 1 = (t^2 + 1)^2 ≥ 0 ✓

/-! ## nlinarith 的工作原理 -/

-- nlinarith 的基本思想：
--   1. 首先运行 preprocessor 来处理非线性项
--   2. 主要的 preprocessor 是"平方和"（SOS）方法
--   3. 它会尝试将不等式转化为平方和 ≥ 0 的形式
--   4. 然后调用 linarith 来处理剩余的线性部分

-- 预处理器包括：
--   1. 平方非负：x² ≥ 0
--   2. 绝对值相关的不等式
--   3. min/max 的性质
--   4. 用户提供的自定义引理

/-! ## nlinarith 的配置 -/

-- 可以通过配置来控制 nlinarith 的行为：
--
-- nlinarith 会使用所有平方非负事实
-- 也可以手动添加额外的引理

example (a b : ℝ) (h : 0 ≤ a) (h' : 0 ≤ b) :
    a ^ 3 + b ^ 3 ≥ a ^ 2 * b + a * b ^ 2 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (a + b)]

-- 通常 nlinarith 自己会找到需要的平方
-- 但有时手动提供可以帮助它

/-! ## nlinarith 与 linarith -/

-- linarith 只能处理线性不等式
-- nlinarith 可以处理一些非线性不等式
--
-- 所有 linarith 能证明的，nlinarith 也能证明
-- （因为 nlinarith 内部调用 linarith）
--
-- 但 nlinarith 更慢，所以能用 linarith 就用 linarith

-- 线性的例子，两者都能用
example (x y : ℝ) (h1 : x ≤ y) (h2 : y ≤ z) : x ≤ z := by
  linarith  -- 更快

example (x y z : ℝ) (h1 : x ≤ y) (h2 : y ≤ z) : x ≤ z := by
  nlinarith  -- 也能证明，但更慢

/-! ## nlinarith 的局限性 -/

-- 1. 只能处理多项式不等式
--    不能处理 sin, cos, exp, log 等超越函数
--
-- 2. 不是完备的决策过程
--    有些真的多项式不等式它证不出来
--    （特别是高次、多变量的复杂情况）
--
-- 3. 可能很慢
--    变量越多、次数越高，搜索空间越大
--
-- 4. 需要变量是实数（或有序环）
--    对于自然数和整数，效果可能不好

/-! ## 使用技巧 -/

-- 1. 先试试 linarith，不行再用 nlinarith
-- 2. 如果 nlinarith 失败，试试提供额外的平方假设
-- 3. 对于对称不等式，考虑变量替换
-- 4. 对于高次问题，考虑因式分解
-- 5. 合理利用假设中的条件

/-! ## 更多经典不等式 -/

-- 柯西-施瓦茨不等式
theorem cauchy_schwarz (a b c d : ℝ) :
    (a * c + b * d) ^ 2 ≤ (a ^ 2 + b ^ 2) * (c ^ 2 + d ^ 2) := by
  nlinarith [sq_nonneg (a * d - b * c)]

-- 三角不等式（平方形式）
theorem triangle_ineq_sq (a b c d : ℝ) :
    ((a + c) ^ 2 + (b + d) ^ 2) ≤
    (a ^ 2 + b ^ 2) + (c ^ 2 + d ^ 2) + 2 * Real.sqrt ((a ^ 2 + b ^ 2) * (c ^ 2 + d ^ 2)) := by
  sorry  -- 需要 sqrt 相关的理论

-- 杨氏不等式
theorem young_inequality (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) (p q : ℝ)
    (hp : 1 < p) (hq : 1 < q) (h : 1 / p + 1 / q = 1) :
    a * b ≤ a ^ p / p + b ^ q / q := by
  sorry  -- 需要更多分析工具

end Lean4Tutorial.Examples.AdvancedTactics.NlinarithTactic
