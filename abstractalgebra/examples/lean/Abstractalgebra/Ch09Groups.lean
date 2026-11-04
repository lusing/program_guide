/-
! # 第 09 章 · 群的定义与例子

对应原书 §2.3。机器验证（任意群上复原命题 2.45 / 引理 2.46）：
1. 单位元唯一；
2. (ab)⁻¹ = b⁻¹a⁻¹（袜子鞋子）；(a⁻¹)⁻¹ = a；
3. 消去律；
4. 具体群：ZMod 7 的单位群中元素阶整除 6（引理 2.53 前奏）。
-/

import Mathlib.Algebra.Group.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch09

/-! ## 命题 2.45：单位元唯一（手写标准操作） -/

example {G : Type*} [Group G] {e' : G} (h : ∀ a, e' * a = a) : e' = 1 := by
  have h1 : e' * 1 = 1 := by rw [h 1]
  rw [mul_one] at h1
  exact h1

/-! ## 引理 2.46：(ab)⁻¹ = b⁻¹a⁻¹ 与 (a⁻¹)⁻¹ = a -/

example {G : Type*} [Group G] (a b : G) : (a * b) ⁻¹ = b ⁻¹ * a ⁻¹ :=
  mul_inv_rev a b

example {G : Type*} [Group G] (a : G) : (a ⁻¹) ⁻¹ = a := inv_inv a

/-! ## 消去律 -/

example {G : Type*} [Group G] {a b c : G} (h : a * c = b * c) : a = b :=
  mul_right_cancel h

example {G : Type*} [Group G] {a b c : G} (h : c * a = c * b) : a = b :=
  mul_left_cancel h

/-! ## 指数律（命题 2.51）与阶 -/

example {G : Type*} [Group G] (a : G) (m n : ℕ) : a ^ (m + n) = a ^ m * a ^ n :=
  pow_add a m n

example {G : Type*} [Group G] (a : G) (m n : ℕ) : (a ^ m) ^ n = a ^ (m * n) :=
  (pow_mul a m n).symm

/-! ## 具体群：ℤ₆ 的元素阶（以倍数事实呈现，可 decide 计算） -/

-- 1 的阶恰为 6：6·1 ≡ 0 且更小正倍数 ≠ 0
example : (6 : ℕ) • (1 : ZMod 6) = 0 := by decide

example : (2 : ℕ) • (1 : ZMod 6) ≠ 0 := by decide

example : (3 : ℕ) • (1 : ZMod 6) ≠ 0 := by decide

example : (5 : ℕ) • (1 : ZMod 6) ≠ 0 := by decide

-- 2 的阶为 3：3·2 ≡ 0，2·2 ≢ 0
example : (3 : ℕ) • (2 : ZMod 6) = 0 := by decide

example : (2 : ℕ) • (2 : ZMod 6) ≠ 0 := by decide

-- 每个元素乘以 6 回零（推论 2.84 的 ℤ₆ 版）
example : ∀ a : ZMod 6, (6 : ℕ) • a = 0 := by decide

end Abstractalgebra.Ch09
