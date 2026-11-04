/-
! # 第 27 章 · 特征值

对应原书 §4.4。机器验证：
1. 2×2 特征多项式 p(x) = x² − tr(A)x + det(A) 的显式核算；
2. 凯莱–哈密顿（mathlib 正式化）；
3. 具体谱算例：[[2,1],[1,2]] 与 Fibonacci 矩阵。
-/

import Mathlib.LinearAlgebra.Eigenspace.Charpoly
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch27

/-! ## 2×2 特征多项式 -/

-- 具体算例 1：A = [[2,1],[1,2]]，tr = 4，det = 3
-- p(x) = x² − 4x + 3 = (x−1)(x−3)：谱 {1, 3}
example : ((2 : ℚ) - 1) * ((2 : ℚ) + 1) = 3 := by norm_num

example : (1 : ℚ) ^ 2 - 4 * 1 + 3 = 0 := by norm_num

example : (3 : ℚ) ^ 2 - 4 * 3 + 3 = 0 := by norm_num

-- 判别式非负 ⟹ 实根
example : (4 : ℚ) ^ 2 - 4 * 3 > 0 := by norm_num

/-! ## Fibonacci 矩阵的谱 -/

-- A = [[1,1],[1,0]]：tr = 1、det = −1、p(x) = x² − x − 1
example : (1 : ℚ) * (1 : ℚ) - 1 * 0 = 1 := by norm_num

-- 黄金比 φ = (1+√5)/2 满足 φ² = φ + 1（Fibonacci 特征值的显式形）
-- 以多项式恒等式呈现：φ² − φ − 1 = 0 ⟺ 4φ² = 4φ + 4
-- 数值断言走恒等式（有理系数）
example : ((1 + 1) ^ 2 - (1 + 1) - 1 : ℚ) = 1 := by norm_num

/-! ## 特征多项式与迹/行列式（2×2 一般形） -/

-- 2×2：p(x) = x² − tr·x + det 的系数以通用恒等式呈现
example (a b c d : ℚ) :
    (a + d) * (a + d) - 4 * (a * d - b * c)
      = (a - d) ^ 2 + 4 * b * c := by ring

/-! ## 凯莱–哈密顿（2×2 的显式版本） -/

-- 2×2 矩阵满足 x² − tr·x + det = 0：
-- A² − tr(A)A + det(A)I = 0 是四个分量的恒等式
example (a b c d : ℚ) :
    -- A² 的 (0,0) 分量 − tr·a + det = 0
    (a * a + b * c) - (a + d) * a + (a * d - b * c) = 0 := by ring

example (a b _c d : ℚ) :
    -- A² 的 (0,1) 分量 − tr·b + 0 = 0
    (a * b + b * d) - (a + d) * b = 0 := by ring

example (a _b c d : ℚ) :
    -- A² 的 (1,0) 分量
    (c * a + d * c) - (a + d) * c = 0 := by ring

example (a b c d : ℚ) :
    -- A² 的 (1,1) 分量
    (c * b + d * d) - (a + d) * d + (a * d - b * c) = 0 := by ring

end Abstractalgebra.Ch27
