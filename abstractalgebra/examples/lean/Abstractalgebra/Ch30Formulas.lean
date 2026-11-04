/-
! # 第 30 章 · 经典公式

对应原书 §5.1-5.2。机器验证：
1. 卡尔达诺换元的内核恒等式；
2. 韦达定理 2 次的具体恒等式与三次的数值案；
3. 三次判别式与根个数的数值案。
-/

import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

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


/-! ## 韦达的三解（定理 5.12）：三角公式替代开立方

casus irreducibilis（三实根）时卡尔达诺公式要穿过复数；韦达用
cos(3θ) = 4cos³θ − 3cosθ 把根直接写成 t·cos(θ + 120°k)。
机器面是替换的多项式证书 + 整数展示例 x³ − 3x − 2 = (x−2)(x+1)²。 -/

/-- 定理 5.12 的代数核心：三条件 ⟹ (tu)³ + q(tu) + r = 0。
h1 : t² = −4q/3（伸缩），h2 : t³·c = −4r（c = cos3θ 的定义式），
h3 : 4u³ − 3u = c（三倍角恒等式）。 -/
example (q r t u c : ℚ) (h1 : 3 * t ^ 2 = -4 * q) (h2 : t ^ 3 * c = -4 * r)
    (h3 : 4 * u ^ 3 - 3 * u = c) : (t * u) ^ 3 + q * (t * u) + r = 0 := by
  linear_combination (t ^ 3 / 4) * h3 + (1 / 4) * h2 + (u * t / 4) * h1

/-- 整数展示例：x³ − 3x − 2 = (x−2)(x+1)²，韦达参数 t = 2、
cos3θ = 1（θ = 0°, 120°, 240°），根 = 2·{1, −1/2, −1/2} = {2, −1, −1}。 -/
example (x : ℚ) : (x - 2) * (x + 1) ^ 2 = x ^ 3 - 3 * x - 2 := by
  ring

example : (2 : ℚ) ^ 3 - 3 * 2 - 2 = 0 ∧ ((-1 : ℚ)) ^ 3 - 3 * (-1) - 2 = 0 := by
  norm_num

end Abstractalgebra.Ch29
