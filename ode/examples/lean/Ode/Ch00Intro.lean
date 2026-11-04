import Mathlib.Analysis.SpecialFunctions.ExpDeriv

/-!
# 第 00 章 导言：什么是常微分方程（Lean）

冒烟章：验证"解就是代入后使方程恒成立的函数"这件最基本的事。
y = 2eˣ - x - 1 是初值问题 y' = x + y、y(0) = 1 的解——
机器用导数定义逐字核对。
-/

open Real

/-- 最小二乘式的开场：y = 2eˣ - x - 1 处处可导，导数为 2eˣ - 1。 -/
example (x : ℝ) : HasDerivAt (fun x => 2 * exp x - x - 1) (2 * exp x - 1) x := by
  have h1 : HasDerivAt (fun x => 2 * exp x) (2 * exp x) x := by
    simpa using (hasDerivAt_exp x).const_mul 2
  exact h1.sub (hasDerivAt_id x) |>.sub_const 1

/-- 代入右端：x + y(x) = x + (2eˣ - x - 1) = 2eˣ - 1，与 y' 吻合，
故 y 满足微分方程 y' = x + y。 -/
example (x : ℝ) :
    HasDerivAt (fun x => 2 * exp x - x - 1) (x + (2 * exp x - x - 1)) x := by
  rw [show x + (2 * exp x - x - 1) = 2 * exp x - 1 by ring]
  exact (hasDerivAt_exp x).const_mul 2 |>.sub (hasDerivAt_id x) |>.sub_const 1

/-- 初值条件：y(0) = 2 - 0 - 1 = 1。 -/
example : (fun x => 2 * exp x - x - 1) 0 = 1 := by norm_num
