import Realanalysis.Ch16Cauchy
import Realanalysis.Ch18Special
import Realanalysis.Ch19Series
import Mathlib.Algebra.Order.Group.Unbundled.Abs
import Mathlib.Tactic

/-!
# 第 20 章 总结

对应原书第 20 章：从要证明的结论往回推，每一章留一条反复用的技巧。
不新增连续性、导数或积分。
-/

namespace Realanalysis.Ch20

open Filter

/-- 证明两个集合相等，就是证明互相包含。 -/
theorem set_eq_iff {α : Type*} (A B : Set α) : A = B ↔ A ⊆ B ∧ B ⊆ A :=
  Set.Subset.antisymm_iff

/-- 并集的补集是补集的交集。 -/
theorem de_morgan {α : Type*} (A B : Set α) : (A ∪ B)ᶜ = Aᶜ ∩ Bᶜ := by
  ext x
  simp

/-- 阿基米德性质的最简形式：5 后面还有自然数。 -/
theorem past_five : ∃ n : ℕ, (5 : ℝ) < n :=
  exists_nat_gt 5

/-- 三角不等式。 -/
theorem triangle (x y : ℝ) : |x + y| ≤ |x| + |y| :=
  abs_add_le x y

/-- 误差预算可以拆成两半。任何正数都能当 ε，包括 ε/2。 -/
theorem eps_split (ε : ℝ) : ε / 2 + ε / 2 = ε := by
  ring

/-- 实数上，柯西序列已经足够推出收敛。 -/
theorem cauchy_is_enough {s : ℕ → ℝ} (h : CauchySeq s) :
    ∃ p, Tendsto s atTop (nhds p) :=
  Realanalysis.Ch16.cauchy_converges h

/-- 二项式展开丢掉正项之后，仍留下 1 + n x。 -/
theorem binomial_drop : (1 : ℝ) + 2 * (1 / 2) < (3 / 2) ^ 2 :=
  Realanalysis.Ch18.binomial_step

/-- 几何级数是一条部分和序列，公比 1/2 时和是 2。 -/
theorem geometric_is_sequence : ∑' n : ℕ, ((1 : ℝ) / 2) ^ n = 2 :=
  Realanalysis.Ch19.half_series

end Realanalysis.Ch20
