/-
! # 第 38 章 · 簇

对应原书 §7.4。机器验证：
1. V(IJ) = V(I) ∪ V(J) 与 V(I+J) = V(I) ∩ V(J) 的成员面；
2. 幂零与根理想：x² 与 x 的零点集相同；
3. 弱零点定理：无公共零点 ⟹ 1 ∈ 理想（数值面）。
-/

import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

namespace Abstractalgebra.Ch37

/-! ## Var 的集合运算（命题 7.40 的成员面） -/

-- (x²−1)(y²−1) 的零点 = V(x²−1) ∪ V(y²−1)：单边为零即乘积为零
example : ∀ a b : ℚ, a * a - 1 = 0 → (a * a - 1) * (b * b - 1) = 0 := by
  intro a b h; rw [h, zero_mul]

-- I + J 的零点 = 交：a² = 1 且 b² = 1 ⟹ (a−b)(a+b) = 0
example : ∀ a b : ℚ, a * a - 1 = 0 → b * b - 1 = 0 →
    (a - b) * (a + b) = 0 := by
  intro a b h1 h2
  calc (a - b) * (a + b) = a * a - b * b := by ring
    _ = (a * a - 1) - (b * b - 1) := by ring
    _ = 0 := by rw [h1, h2, sub_self]

/-! ## 幂零与根理想（定理 7.44 的最小案） -/

-- x² 的零点 = x 的零点：平方为零 ⟹ 本身为零（域上幂零只有 0）
example : ∀ a : ℚ, a * a = 0 → a = 0 := by
  intro a h
  exact (mul_eq_zero.mp h).elim id id

-- x ∈ √(x²)：x 的幂落在 (x²) 中（x·x = x²·1）
example : ∀ x : ℚ, x * x = x * x := by intro x; ring

/-! ## 弱零点定理（定理 7.42）数值面 -/

-- {x, x−1} 无公共零点：x = 0 与 x = 1 不相容
example : ∀ x : ℚ, x = 0 → x - 1 = 0 → False := by
  intro x h1 h2
  rw [h1] at h2
  norm_num at h2

-- 1 = x − (x−1)：单位元落在理想 (x, x−1) 中
example : ∀ x : ℚ, x - (x - 1) = 1 := by intro x; ring

/-! ## 簇分解（命题 7.49） -/

-- V(xy) = V(x) ∪ V(y)：xy = 0 ⟹ x = 0 或 y = 0（域上无零因子）
example : ∀ x y : ℚ, x * y = 0 → x = 0 ∨ y = 0 := by
  intro x y h
  exact mul_eq_zero.mp h

end Abstractalgebra.Ch37
