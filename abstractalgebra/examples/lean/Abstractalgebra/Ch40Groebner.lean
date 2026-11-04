/-
! # 第 40 章 · 格罗布纳基

对应原书 §7.6。机器验证：S-多项式的消首恒等式、Buchberger 判据的
数值面、理想成员/相等/消元三应用的恒等式证书。
-/

import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

namespace Abstractalgebra.Ch39

/-! ## S-多项式：首单项式相消 -/

-- S(x²+1, xy−1) = y·(x²+1) − x·(xy−1) = x + y（mod 原基余式非零 ⟹ 非基）
example : ∀ x y : ℚ, y * (x * x + 1) - x * (x * y - 1) = x + y := by
  intro x y; ring

/-! ## Buchberger 补基 -/

-- 新对的 S-多项式：S(xy−1, x+y) = (xy−1) − y(x+y) = −(y²+1)（补入 y²+1）
example : ∀ x y : ℚ, (x * y - 1) - y * (x + y) = -(y * y + 1) := by
  intro x y; ring

/-! ## 应用一：理想成员（推论 7.63）的证书 -/

-- xy² − x ∈ (xy+1, y²−1)：换序除法余式为零的显式组合
example : ∀ x y : ℚ,
    x * y * y - x = 0 * (x * y + 1) + x * (y * y - 1) + 0 := by
  intro x y; ring

/-! ## 应用二：理想相等 -/

-- (x+y, x−y) = (x, y)：x、y 表成生成元的组合（½ 系数出场）
example : ∀ x y : ℚ,
    x = (1 / 2) * (x + y) + (1 / 2) * (x - y) ∧
    y = (1 / 2) * (x + y) - (1 / 2) * (x - y) := by
  intro x y; constructor <;> ring

/-! ## 应用三：消元（lex 基含纯 y 多项式） -/

-- 2y² − 1 = (x²+y²−1) − (x+y)(x−y)：圆与直线联立的三角形化
--（lex 序 Grobner 基含纯 y 元素 ⟹ y = ±1/√2、x = y）
example : ∀ x y : ℚ,
    2 * y * y - 1 = (x * x + y * y - 1) - (x + y) * (x - y) := by
  intro x y; ring

end Abstractalgebra.Ch39
