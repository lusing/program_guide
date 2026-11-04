import Mathlib.Tactic
import Mathlib.SetTheory.Cardinal.Aleph

/-!
# 第 137 章 基数（Lean）

基数的 mathlib 形态、Cantor 定理、ℵ 函数与后继基数。
-/

/-! ## 基数的两种身份 -/

/- 书：|A| = 与 A 等势的最小序数（AC 下由良序定理保证存在）。
mathlib：Cardinal.mk α 是类型 α 的大小（商实现），与初始序数定义
经 Cardinal.aleph 的保序嵌入对应。 -/
#check @Cardinal.mk
#check @Cardinal.aleph

/- ℵ₀ 是第一个无穷基数（书 5.1.5(1)：ω 既当序数又当基数）。 -/
#check @Cardinal.aleph0

example : Cardinal.mk (Set (Fin 3)) = 8 := by simp

/-! ## Cantor 定理（书 5.1.6）：没有最大的基数 -/

#check @Cardinal.cantor

example (a : Cardinal) : a < 2 ^ a := Cardinal.cantor a

/- 对角集 Y = {x | x ∉ f(x)} 藏在 cantor 的证明里——第 01/02/08
章的三次预演在此收束为一条库定理；有限版 #(Set (Fin 3)) = 8 =
2³ 也在上面现场兑现。 -/

/-! ## 后继基数（书 5.1.8/5.1.10） -/

/- ℵ 函数严格增：ℵ_{α+1} 是大于 ℵ_α 的最小基数。 -/
example (α : Ordinal) : Cardinal.aleph α < Cardinal.aleph (α + 1) :=
  Cardinal.aleph_lt_aleph.mpr (by norm_num)

#check @Cardinal.succ_aleph

/- 全体基数没有最大者：Cantor 梯 0 < 1 < 2 < … < ℵ₀ < 2^{ℵ₀} = c
< 2^c < … 没有顶点；ℵ 序列是这条梯子上"初始序数"的里程碑。 -/
