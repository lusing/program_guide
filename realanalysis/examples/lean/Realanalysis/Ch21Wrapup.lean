import Realanalysis.Ch19Series
import Mathlib.Algebra.Order.Archimedean.Defs
import Mathlib.Tactic

/-!
# 第 21 章 收官

教程自己的收官，不对应原书的一章。
沿阅读路线抽四个标记再证一遍：三分之一加三次、超过 5 的自然数、
两半误差拼回 ε、公比 1/2 的几何级数。
不新增连续性、导数或积分。
-/

namespace Realanalysis.Ch21

open Filter

/-- 三个三分之一加回 1。有理数运算不舍入。 -/
theorem thirds : (1 : ℝ) / 3 + 1 / 3 + 1 / 3 = 1 := by
  norm_num

/-- 阿基米德性质的一个见证：5 后面还有自然数。 -/
theorem past_five : ∃ n : ℕ, (5 : ℝ) < n :=
  exists_nat_gt 5

/-- 误差预算拆成两半之后可以拼回去。 -/
theorem eps_split (ε : ℝ) : ε / 2 + ε / 2 = ε := by
  ring

/-- 公比 1/2 的几何级数是一条部分和序列，和是 2。 -/
theorem geometric_sum : ∑' n : ℕ, ((1 : ℝ) / 2) ^ n = 2 :=
  Realanalysis.Ch19.half_series

end Realanalysis.Ch21
