/-
文件: 12_mathlib_topology/metric_spaces.lean
描述: 度量空间，距离公理
编译: lake build Lean4Tutorial.Examples.MathlibTopology.MetricSpaces
依赖: Mathlib.Topology.MetricSpace.Basic
-/

import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibTopology.MetricSpaces

/-! # 度量空间（Metric Spaces） -/

-- 度量空间是具有距离函数的集合
-- 距离函数 d : X × X → ℝ 满足：
--   1. d(x, y) ≥ 0            （非负性）
--   2. d(x, y) = 0 ↔ x = y    （同一性）
--   3. d(x, y) = d(y, x)      （对称性）
--   4. d(x, z) ≤ d(x, y) + d(y, z)  （三角不等式）
--
-- 在 Mathlib 中，MetricSpace X 表示 X 是度量空间
-- 距离函数为 dist x y

/-! ## 距离公理 -/

#check MetricSpace

variable {X : Type*} [MetricSpace X] (x y z : X)

-- 非负性
theorem dist_nonneg : 0 ≤ dist x y := by
  exact dist_nonneg

-- 同一性
theorem dist_eq_zero : dist x y = 0 ↔ x = y := by
  exact dist_eq_zero

-- 对称性
theorem dist_comm : dist x y = dist y x := by
  exact dist_comm x y

-- 三角不等式
theorem dist_triangle : dist x z ≤ dist x y + dist y z := by
  exact dist_triangle x y z

-- 三角不等式的另一种形式
theorem dist_triangle_left : dist x y ≤ dist z x + dist z y := by
  exact dist_triangle_left x y z

-- 反向三角不等式
theorem dist_dist_le : dist (dist x z) (dist y z) ≤ dist x y := by
  exact?

/-! ## 开球与闭球 -/

-- 以 x 为中心、r 为半径的开球：
--   ball x r = {y | dist y x < r}

-- 以 x 为中心、r 为半径的闭球：
--   closedBall x r = {y | dist y x ≤ r}

#check Metric.ball
#check Metric.closedBall

-- 开球的性质
theorem mem_ball : y ∈ Metric.ball x r ↔ dist y x < r := by
  exact Metric.mem_ball

theorem mem_closedBall : y ∈ Metric.closedBall x r ↔ dist y x ≤ r := by
  exact Metric.mem_closedBall

-- 开球是开集
theorem isOpen_ball (x : X) (r : ℝ) : IsOpen (Metric.ball x r) := by
  exact Metric.isOpen_ball

-- 闭球是闭集
theorem isClosed_closedBall (x : X) (r : ℝ) : IsClosed (Metric.closedBall x r) := by
  exact Metric.isClosed_closedBall

-- 开球包含于同名闭球
theorem ball_subset_closedBall (x : X) (r : ℝ) :
    Metric.ball x r ⊆ Metric.closedBall x r := by
  exact Metric.ball_subset_closedBall

-- 小球包含于大球
theorem ball_subset_ball (x : X) {r₁ r₂ : ℝ} (h : r₁ ≤ r₂) :
    Metric.ball x r₁ ⊆ Metric.ball x r₂ := by
  exact Metric.ball_subset_ball h

/-! ## 度量空间中的拓扑 -/

-- 度量空间自然地诱导一个拓扑：
-- 集合 U 是开集当且仅当
--   对每个 x ∈ U，存在 ε > 0 使得 ball x ε ⊆ U

-- 这就是说，开集是"每一点都有一个开球包含在其中"的集合

-- 度量空间都是 Hausdorff 空间

/-! ## 度量空间中的连续性 -/

-- 在度量空间中，函数 f 在点 x 处连续的 ε-δ 定义：
--   ∀ ε > 0, ∃ δ > 0, ∀ y, dist y x < δ → dist (f y) (f x) < ε

-- 这与拓扑意义下的连续是等价的

/-! ## 度量空间中的极限 -/

-- 数列极限：lim_{n→∞} x_n = a
--   ∀ ε > 0, ∃ N, ∀ n ≥ N, dist (x_n) a < ε

-- 函数极限：lim_{t→x} f(t) = l
--   ∀ ε > 0, ∃ δ > 0, ∀ y, 0 < dist y x < δ → dist (f y) l < ε

/-! ## 常见的度量空间 -/

/-! ### 实数空间 ℝ -/

-- 实数上的标准度量是绝对值距离：d(x, y) = |x - y|

theorem real_dist_eq_abs (x y : ℝ) : dist x y = |x - y| := by
  exact?

-- 在实数中，开球就是开区间
-- ball x r = (x - r, x + r)

/-! ### 欧氏空间 ℝⁿ -/

-- n 维欧氏空间上的欧氏距离：
-- d(x, y) = √(Σ (x_i - y_i)²)

/-! ### 离散度量 -/

-- 离散度量：
-- d(x, y) = 0, 如果 x = y
-- d(x, y) = 1, 如果 x ≠ y

-- 在离散度量下，每个单点集都是开集
-- 这诱导了离散拓扑

/-! ## 完备度量空间 -/

-- 柯西列：∀ ε > 0, ∃ N, ∀ m n ≥ N, dist(x_m, x_n) < ε

-- 完备度量空间：所有柯西列都收敛
-- 即每个柯西列都有极限

-- 实数空间 ℝ 是完备的
-- 这是实数的基本性质之一

/-! ## 有界集与完全有界集 -/

-- 集合 S 是有界的，如果存在 M 使得
--   ∀ x y ∈ S, dist(x, y) ≤ M

-- 集合 S 是完全有界的，如果对任意 ε > 0，
-- S 可以被有限个半径为 ε 的开球覆盖

-- 完全有界蕴含着有界
-- 在有限维欧氏空间中，有界等价于完全有界

/-! ##  Lipschitz 连续与一致连续 -/

-- 一致连续：∀ ε > 0, ∃ δ > 0, ∀ x y, dist(x, y) < δ → dist(f(x), f(y)) < ε
-- 注意：δ 只依赖于 ε，不依赖于 x 和 y

-- Lipschitz 连续：存在 K ≥ 0，使得
--   ∀ x y, dist(f(x), f(y)) ≤ K * dist(x, y)
--
-- Lipschitz 连续蕴含一致连续

end Lean4Tutorial.Examples.MathlibTopology.MetricSpaces
