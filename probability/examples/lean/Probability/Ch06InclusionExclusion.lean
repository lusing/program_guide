import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Nat.Choose.Vandermonde
import Mathlib.Tactic

/-!
# 第 06 章 容斥与组合恒等式（Lean）

本章承载三类机器锚点：

1. 三事件容斥在有限骰子空间上的精确分数账；
2. 错排闭式
   \[D_n=\sum_{k=0}^n(-1)^k\frac{n!}{k!}\]
   的 `native_decide` 检查；
3. Vandermonde、hockey-stick 与子集总大小等组合恒等式的数值实弹。
-/

/-! ## 容斥的骰子账 -/

/-- 事件 \(A\)=首骰为 6，\(B\)=次骰为 6，\(C\)=两骰同点。
在 36 个等可能结果上，三事件容斥给出 \(16/36\)。 -/
example : (6 + 6 + 6 - 1 - 1 - 1 + 1 : ℚ) / 36 = 16 / 36 := by norm_num

/-! ## 错排：闭式、递推和小宇宙枚举 -/

/-- 错排闭式的整数版：每一项 \(n!/k!\) 都是整数。 -/
def derZ (n : ℕ) : ℤ :=
  ∑ k ∈ Finset.range (n + 1),
    (-1 : ℤ)^k * ((Nat.factorial n : ℤ) / Nat.factorial k)

example : derZ 0 = 1 := by native_decide
example : derZ 4 = 9 := by native_decide
example : derZ 5 = 44 ∧ derZ 6 = 265 ∧ derZ 7 = 1854 := by native_decide

example : derZ 4 = 4 * derZ 3 + 1 := by native_decide
example : derZ 5 = 5 * derZ 4 - 1 := by native_decide
example : derZ 8 = 8 * derZ 7 + 1 := by native_decide

/-! ## Vandermonde 恒等式 -/

#check @Nat.add_choose_eq

/-- \(m=3,n=2,k=2\)：
\(\binom30\binom22+\binom31\binom21+\binom32\binom20=10=\binom52\)。 -/
example : Nat.choose 3 0 * Nat.choose 2 2
    + Nat.choose 3 1 * Nat.choose 2 1
    + Nat.choose 3 2 * Nat.choose 2 0
    = Nat.choose 5 2 := by decide

/-! ## Hockey-stick 与子集总大小 -/

/-- \(\sum_{i=2}^{6}\binom i2=\binom73\)。 -/
example : Nat.choose 2 2 + Nat.choose 3 2 + Nat.choose 4 2
    + Nat.choose 5 2 + Nat.choose 6 2 = Nat.choose 7 3 := by decide

/-- 4 元素集合的所有子集总大小为 \(4\cdot2^3=32\)。 -/
example : 0 * 1 + 1 * 4 + 2 * 6 + 3 * 4 + 4 * 1 = 32 := by decide

/-- 交换记账顺序：\(\binom85\binom53=\binom83\binom52\)。 -/
example : Nat.choose 8 5 * Nat.choose 5 3
    = Nat.choose 8 3 * Nat.choose 5 2 := by decide
