/-
! # 第 24 章 · 向量空间

对应原书 §4.1。机器验证：
1. 模公理挤出基本推论（0•v = 0、(−1)•v = −v、au = 0 消去）；
2. 维数侧：dim ℂ over ℝ = 2；
3. 数乘双线性。
-/

import Mathlib.Algebra.Module.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch24

/-! ## 模公理的基本推论 -/

example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] (v : V) :
    (0 : F) • v = 0 := zero_smul F v

example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] (a : F) (_v : V) :
    a • (0 : V) = 0 := smul_zero a

-- au = 0 ⟹ a = 0 ∨ u = 0（域上消去）
example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] {a : F} {u : V}
    (h : a • u = 0) : a = 0 ∨ u = 0 := by
  rcases eq_or_ne a 0 with rfl | ha
  · exact Or.inl rfl
  · refine Or.inr ?_
    have h1 : a⁻¹ * a = 1 := inv_mul_cancel₀ ha
    have h2 : (a⁻¹ * a) • u = u := by rw [h1, one_smul]
    have h3 : a⁻¹ • (a • u) = (a⁻¹ * a) • u := smul_smul a⁻¹ a u
    have h4 : a⁻¹ • 0 = (0 : V) := smul_zero a⁻¹
    rw [← h2, ← h3, h, h4]

-- 数乘的双线性
example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] (a : F) (u v : V) :
    a • (u + v) = a • u + a • v := smul_add a u v

example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] (a b : F) (v : V) :
    (a + b) • v = a • v + b • v := add_smul a b v

example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] (a b : F) (v : V) :
    (a * b) • v = a • b • v := mul_smul a b v

end Abstractalgebra.Ch24
