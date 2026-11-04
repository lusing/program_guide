import Mathlib.Tactic
import Mathlib.SetTheory.Cardinal.Cofinality.Ordinal

/-!
# 第 141 章 基数幂与连续统（Lean）

连续统函数 2^κ 的约束：单调性 + König 的 cf 界（推论 5.3.8），
幂的恒等式与吸收。
-/

/-! ## 连续统函数的约束 -/

open Cardinal in
/- 单调：α ≤ β ⟹ 2^α ≤ 2^β（注 5.3.9(2)——已知约束之一）；
根命名空间 power_le_power_left 需 open Cardinal。 -/
example (a b : Cardinal) (h : a ≤ b) :
    (2 : Cardinal) ^ a ≤ (2 : Cardinal) ^ b :=
  power_le_power_left two_ne_zero h

/- König 推论 5.3.8：cf(2^κ) > κ——ZFC 对连续统函数的唯一硬约束：
2^{ℵ₀} 不能是 ℵ_ω 等共尾不足的基数。 -/
#check @Cardinal.lt_cof_ord_power

example (κ : Cardinal) (hκ : Cardinal.aleph0 ≤ κ) :
    κ < ((2 : Cardinal) ^ κ).ord.cof :=
  Cardinal.lt_cof_ord_power hκ (by norm_num)

/-! ## 2^κ · 2^κ = 2^κ（幂的吸收） -/

/-- Cantor 给出 κ < 2^κ，故 2^κ 无穷，吸收律开动。 -/
example (κ : Cardinal) (hκ : Cardinal.aleph0 ≤ κ) :
    (2 : Cardinal) ^ κ * (2 : Cardinal) ^ κ = (2 : Cardinal) ^ κ := by
  have h2 : Cardinal.aleph0 ≤ (2 : Cardinal) ^ κ :=
    le_trans hκ (le_of_lt (Cardinal.cantor κ))
  exact Cardinal.mul_eq_self h2

/-! ## 幂恒等式（书 5.2.9） -/

open Cardinal in
example (κ μ ν : Cardinal) :
    ((κ : Cardinal) ^ μ) ^ ν = κ ^ (ν * μ) := by
  rw [← Cardinal.power_mul]
  congr 1
  exact mul_comm μ ν

/- GCH（书 5.2 定义后注）：2^{ℵ_α} = ℵ_{α+1}——ZFC 不可判定，
   第 146 章证其一致性、第 147 章证其否定的一致性。 -/
