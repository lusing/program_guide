import Mathlib.Data.Nat.Choose.Vandermonde
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic

/-!
# 第 07 章 高级组合（Lean）

Miller ch6 的机器侧：mathlib 的 Vandermonde 恒等式
`Nat.add_choose_eq` 的正名与数值实弹；多项式系数的骨架
（k!/(a₁!⋯a_k!)）与小例判决；hockey-stick 恒等式的
decide 验证。
-/

/-! ## 锚点正名 -/

#check @Nat.add_choose_eq          -- Vandermonde：Σ C(m,j)C(n,k−j) = C(m+n,k)
#check @Nat.sum_range_choose       -- Σ C(n,k) = 2ⁿ

/-! ## Vandermonde 的数值实弹 -/

/-- 玩具例：m=3、n=2、k=2——C(3,0)C(2,2)+C(3,1)C(2,1)+C(3,2)C(2,0)
= 1·1 + 3·2 + 3·1 = 10 = C(5,2)（两种分组数同一群人）。 -/
example : 1 * 1 + 3 * 2 + 3 * 1 = 10 := by decide

/-- 直接套引理的数值形态：C(10,4) = C(4+6,4)。 -/
example : Nat.choose 10 4 = 210 := by decide

/-! ## 多项式系数的骨架 -/

/-- 三球两桶的分配账：3!/(2!·1!) = 3——"AA B 型"的排法
（多项式系数的最小实弹）。 -/
example : Nat.factorial 3 / (Nat.factorial 2 * Nat.factorial 1) = 3 := by decide

/-- 平均子集大小的恒等式：Σ k·C(4,k) = 4·2³ = 32
（0+4+12+12+4 = 32——n 个元素的全体子集的总大小）。 -/
example : 0 * 1 + 1 * 4 + 2 * 6 + 3 * 4 + 4 * 1 = 32 := by decide

/-! ## Hockey-stick 的数值实弹 -/

/-- Σ_{i=2}^{6} C(i,2) = C(7,3)：1+3+6+10+15 = 35——
Pascal 三角形对角线求和落在斜下方（溜冰鞋形状）。 -/
example : 1 + 3 + 6 + 10 + 15 = 35 := by decide

/-- 按最大元素分类的故事验证：从 {0..6} 选 3 元子集
（C(7,3) = 35 个）中，最大元恰为 i 的有 C(i,2) 个
（i = 2..6）——上面恒等式的计数读法。 -/
example : Nat.choose 2 2 + Nat.choose 3 2 + Nat.choose 4 2
    + Nat.choose 5 2 + Nat.choose 6 2 = Nat.choose 7 3 := by
  decide
