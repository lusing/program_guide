/-
! # 第 29 章 · 经典公式

对应原书 §5.1-5.2。机器验证：
1. 卡尔达诺换元的内核恒等式；
2. 韦达定理 2 次的具体恒等式与三次的数值案；
3. 三次判别式与根个数的数值案。
-/

import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch29

/-! ## 卡尔达诺换元内核 -/

-- 3uv = −p ⟹ (u+v)³ + p(u+v) = u³ + v³
example (u v p : ℚ) (h : 3 * u * v = -p) :
    (u + v) ^ 3 + p * (u + v) = u ^ 3 + v ^ 3 := by
  have h0 : (3 * u * v + p) = 0 := by linarith [h]
  calc (u + v) ^ 3 + p * (u + v)
      = (u ^ 3 + v ^ 3) + (3 * u * v + p) * (u + v) := by ring
    _ = u ^ 3 + v ^ 3 := by rw [h0, zero_mul, add_zero]

-- 展开内核恒等式（不带假设版，供阅读）
example (u v p : ℚ) :
    (u + v) ^ 3 + p * (u + v) = u ^ 3 + v ^ 3 + (3 * u * v + p) * (u + v) := by
  ring

/-! ## 韦达定理（二次） -/

example (r1 r2 : ℚ) (x : ℚ) :
    x ^ 2 - (r1 + r2) * x + r1 * r2 = (x - r1) * (x - r2) := by ring

/-! ## 具体三次的数值案 -/

-- t³ − 7t + 6 = (t − 1)(t − 2)(t + 3)
example (t : ℚ) : t ^ 3 - 7 * t + 6 = (t - 1) * (t - 2) * (t + 3) := by ring

-- 三个根逐一代入
example : (1 : ℚ) ^ 3 - 7 * 1 + 6 = 0 := by norm_num
example : (2 : ℚ) ^ 3 - 7 * 2 + 6 = 0 := by norm_num
example : (-3 : ℚ) ^ 3 - 7 * (-3) + 6 = 0 := by norm_num

-- 判别式：p = −7、q = 6 → Δ = q²/4 + p³/27 = 9 − 343/27 = −100/27 < 0
example : (6 : ℚ) ^ 2 / 4 + (-7) ^ 3 / 27 < 0 := by norm_num

/-! ## 四次展开核对 -/

example (r1 r2 r3 r4 : ℚ) (x : ℚ) :
    (x - r1) * (x - r2) * (x - r3) * (x - r4) =
    x ^ 4 - (r1 + r2 + r3 + r4) * x ^ 3 +
      (r1 * r2 + r1 * r3 + r1 * r4 + r2 * r3 + r2 * r4 + r3 * r4) * x ^ 2 -
      (r1 * r2 * r3 + r1 * r2 * r4 + r1 * r3 * r4 + r2 * r3 * r4) * x +
      r1 * r2 * r3 * r4 := by ring

end Abstractalgebra.Ch29
