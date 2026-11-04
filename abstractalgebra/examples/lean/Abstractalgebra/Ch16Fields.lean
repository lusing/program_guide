/-
! # 第 16 章 · 域与分式域

对应原书 §3.2。机器验证：
1. 域上的消去律与方程唯一解；
2. 域 ⟹ 无零因子；
3. ℚ(√2) 序对模型的算术（乘法封闭核对）。
-/

import Mathlib.Algebra.Field.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Data.Rat.Defs

namespace Abstractalgebra.Ch16

/-! ## 域上消去与方程求解 -/

example {F : Type*} [Field F] {a b c : F} (ha : a ≠ 0) (h : a * b = a * c) :
    b = c :=
  mul_left_cancel₀ ha h

-- 域上 ax = b（a ≠ 0）有唯一解
example {F : Type*} [Field F] (a b : F) (ha : a ≠ 0) :
    ∃! x : F, a * x = b :=
  ⟨a ⁻¹ * b, by field_simp, fun y hy => by
    exact mul_left_cancel₀ ha (hy.trans (by field_simp))⟩

-- 域 ⟹ 无零因子（命题 3.14 的域版）
example {F : Type*} [Field F] {a b : F} (h : a * b = 0) : a = 0 ∨ b = 0 := by
  rcases eq_or_ne a 0 with rfl | ha
  · exact Or.inl rfl
  · refine Or.inr ?_
    have h1 : a⁻¹ * a = 1 := inv_mul_cancel₀ ha
    calc b = (a⁻¹ * a) * b := by rw [h1]; ring
      _ = a⁻¹ * (a * b) := by ring
      _ = a⁻¹ * 0 := by rw [h]
      _ = 0 := by ring

/-! ## ℚ(√2) 序对模型：Frac(ℤ[√2]) 的预演 -/

-- (a,b) 表示 a + b√2：乘法 (a,b)(c,d) = (ac+2bd, ad+bc)
def q2 (a b c d : ℚ) : ℚ × ℚ := (a * c + 2 * b * d, a * d + b * c)

-- √2 · √2 = 2
example : q2 0 1 0 1 = (2, 0) := by norm_num [q2]

-- (√2 + 1) · √2 = 2 + √2（分配律在模型中的投影）
example : q2 1 1 0 1 = (2, 1) := by norm_num [q2]

-- 范数恒等式的模型版：(a,b)(a,−b) = (a²−2b², 0)
example (a b : ℚ) : q2 a b a (-b) = (a * a - 2 * b * b, 0) := by
  simp only [q2]
  ring

end Abstractalgebra.Ch16
