import Mathlib.Tactic

/-!
# 第 26 章 证明十一式（Lean）

附录 A 的机器侧：归纳的锚点正名与实例判决、抽屉原理的
Finset 形态、加零配方的 ring 判决、反例的 decide 账。
-/

/-! ## 归纳法的锚点 -/

#check @Nat.rec              -- 归纳原理的原语
#check @Nat.le_succ          -- 归纳步的骨架件
#check @Nat.succ_le_succ

/-- **实例判决**：Σk = n(n+1)/2 的 n = 5 形态。 -/
example : ∑ k ∈ Finset.range 5, (k + 1) = 5 * 6 / 2 := by
  norm_num [Finset.sum_range_succ]

/-- **平方和**：Σk² = n(n+1)(2n+1)/6 的 n = 4 形态。 -/
example : ∑ k ∈ Finset.range 4, (k + 1) ^ 2 = 4 * 5 * 9 / 6 := by
  norm_num [Finset.sum_range_succ]

/-- **Nicomachus**：Σk³ = (Σk)² 的 n = 3 形态。 -/
example : ∑ k ∈ Finset.range 3, (k + 1) ^ 3 = (3 * 4 / 2) ^ 2 := by
  norm_num [Finset.sum_range_succ]

/-! ## 抽屉原理 -/

#check @Finset.card_lt_card
#check @Finset.card_le_card

/-- **生日直觉**：23 人 365 天 ⟹ 至少两人同天（严格版是容斥；
鸽笼版需要 366 人才直接）。C(23,2) = 253 对的朴素账：直和
已过半——真实碰撞概率 ~50.7% 的粗界来历。 -/
example : (253 : ℚ) / 365 > 1 / 2 := by norm_num

/-! ## 加零与乘一：恒等式的 ring 判决 -/

/-- **配方**：2t² − 6t + 9 = 2(t − 3/2)² + 9/2（加零 z²/4 − z²/4
的代数残迹——ring 一行收割）。 -/
example (t : ℚ) : 2 * t ^ 2 - 6 * t + 9 = 2 * (t - 3 / 2) ^ 2 + 9 / 2 := by ring

/-- **方差分解**（加零 X − μ = (X − x̄) + (x̄ − μ) 的平方展开；
交叉项 Σ(x−x̄) = 0 的结构账）。 -/
example (x m c : ℚ) (h : x - m = (x - c) + (c - m)) :
    (x - m) ^ 2 = (x - c) ^ 2 + 2 * (x - c) * (c - m) + (c - m) ^ 2 := by
  rw [h]; ring

/-- **乘一**（German Tank 的 k/(N+1)·(N+1)/(k+1) 拆项形态）。 -/
example (k N : ℚ) (h : N + 1 ≠ 0) : k = k / (N + 1) * ((N + 1) / 1) := by
  field_simp

/-! ## 反例的 decide 账 -/

/-- **零协方差不独立**：X 均匀 {−2,−1,1,2}、Y = X²。
E[X] = 0、E[X³] = 0（对称相消）——Cov = 0。 -/
example : ((-2 : ℚ) + (-1) + 1 + 2) / 4 = 0 := by norm_num

example : (((-8 : ℚ) + (-1) + 1 + 8)) / 4 = 0 := by norm_num

/-- E[Y] = 5/2、E[Y²] = 17/2 → Var(Y) = 9/4（但 Y 完全由 X
决定——函数关系与零协方差共存）。 -/
example : ((4 + 1 + 1 + 4 : ℚ)) / 4 = 5 / 2 := by norm_num

example : ((16 + 1 + 1 + 16 : ℚ)) / 4 - (5 / 2) ^ 2 = 9 / 4 := by norm_num

/-! ## 故事法的组合账 -/

/-- **Vandermonde** 的玩具例（m=3、n=2、k=2 的两路会师）。 -/
example : 1 * 1 + 3 * 2 + 3 * 1 = 10 := by norm_num

example : Nat.choose 5 2 = 10 := by decide

/-- **子集总大小**：Σk·C(4,k) = 4·2³ = 32。 -/
example : 0 * Nat.choose 4 0 + 1 * Nat.choose 4 1 + 2 * Nat.choose 4 2
    + 3 * Nat.choose 4 3 + 4 * Nat.choose 4 4 = 32 := by decide

/-- **对偶故事**（"选主席"计数）：k·C(n,k) = n·C(n−1,k−1) 的
n=4、k=2 形态。 -/
example : 2 * Nat.choose 4 2 = 4 * Nat.choose 3 1 := by decide
