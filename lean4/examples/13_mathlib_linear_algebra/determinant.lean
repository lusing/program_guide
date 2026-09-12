/-
文件: 13_mathlib_linear_algebra/determinant.lean
描述: 行列式性质
编译: lake build Lean4Tutorial.Examples.MathlibLinearAlgebra.Determinant
依赖: Mathlib.LinearAlgebra.Matrix.Determinant
-/

import Mathlib.LinearAlgebra.Matrix.Determinant
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibLinearAlgebra.Determinant

/-! # 行列式（Determinant） -/

-- 行列式是给方阵赋予一个标量值的函数
-- 它反映了矩阵对应的线性变换对体积的缩放因子
--
-- 在 Mathlib 中，方阵 A 的行列式为 Matrix.det A

/-! ## 行列式的定义 -/

variable {n : Type*} [Fintype n] [DecidableEq n]

-- 方阵 A 的行列式
#check Matrix.det

-- 行列式可以通过多种等价方式定义：
-- 1. 按行展开（拉普拉斯展开）
-- 2. 完全展开式（置换和）
-- 3. 公理化定义（多线性交替 + 单位矩阵行列式为 1）

/-! ## 行列式的基本性质 -/

variable (A B : Matrix n n ℝ)

-- 单位矩阵的行列式为 1
theorem det_one : Matrix.det (1 : Matrix n n ℝ) = 1 := by
  exact Matrix.det_one

-- 转置不改变行列式
theorem det_transpose : Matrix.det A.transpose = Matrix.det A := by
  exact Matrix.det_transpose A

-- 乘积的行列式等于行列式的乘积
theorem det_mul : Matrix.det (A * B) = Matrix.det A * Matrix.det B := by
  exact Matrix.det_mul A B

-- 标量乘矩阵的行列式（对于 n × n 矩阵）
-- det(c * A) = c^n * det(A)

/-! ## 行列式与可逆性 -/

-- 方阵 A 可逆当且仅当 det(A) ≠ 0
-- 这是矩阵可逆的重要判据

-- 可逆矩阵的行列式
-- 如果 A 可逆，则 det(A⁻¹) = 1 / det(A)

/-! ## 行变换对行列式的影响 -/

-- 1. 交换两行：行列式变号
-- 2. 某行乘以 c：行列式乘以 c
-- 3. 某行加上另一行的倍数：行列式不变

-- 这些性质是计算行列式的基础

/-! ## 特殊矩阵的行列式 -/

-- 对角矩阵的行列式等于对角元的乘积
-- det(diag(d₁, d₂, ..., dₙ)) = d₁ * d₂ * ... * dₙ

-- 上三角矩阵的行列式等于对角元的乘积
-- 下三角矩阵同理

-- 这使得高斯消元法成为计算行列式的有效方法

/-! ## 2×2 行列式 -/

-- | a b |
-- | c d | = ad - bc

theorem det_fin_two (a b c d : ℝ) :
    Matrix.det ( !![a, b; c, d] ) = a * d - b * c := by
  simp [Matrix.det_fin_two]
  <;> ring

-- 例子
#eval Matrix.det ( !![(1 : ℝ), 2; 3, 4] )  -- 1*4 - 2*3 = -2

/-! ## 3×3 行列式 -/

-- | a b c |
-- | d e f | = a(ei - fh) - b(di - fg) + c(dh - eg)
-- | g h i |

-- 按第一行展开

/-! ## 行列式的几何意义 -/

-- 在 ℝⁿ 中，n 个向量张成的平行六面体的有向体积
-- 等于以这些向量为列（或行）的矩阵的行列式

-- 2D：两个向量张成的平行四边形的有向面积
-- 3D：三个向量张成的平行六面体的有向体积

/-! ## 克莱姆法则（Cramer's Rule） -/

-- 对于线性方程组 Ax = b，如果 det(A) ≠ 0，
-- 则解的第 i 个分量为
--   x_i = det(A_i) / det(A)
-- 其中 A_i 是将 A 的第 i 列替换为 b 得到的矩阵

/-! ## 特征值与行列式 -/

-- 矩阵的特征多项式定义为 p(λ) = det(λI - A)
-- 特征值是特征多项式的根
-- 矩阵的行列式等于所有特征值的乘积（计重数）

-- 矩阵的迹（对角线元素之和）等于所有特征值之和

/-! ## 行列式的计算方法 -/

-- 1. 按定义展开（复杂度高，O(n!)）
-- 2. 高斯消元法（复杂度 O(n³)）
-- 3. 按行/列展开（递归方法）
-- 4. LU 分解

/-! ## 一些重要的行列式 -/

-- 1. 范德蒙德行列式（Vandermonde）
--    |1 x₁ x₁² ... x₁ⁿ⁻¹|
--    |1 x₂ x₂² ... x₂ⁿ⁻¹|
--    ...
--    |1 xₙ xₙ² ... xₙⁿ⁻¹|
--    = Π_{1 ≤ i < j ≤ n} (x_j - x_i)

-- 2. 循环行列式

-- 3. 三对角行列式

end Lean4Tutorial.Examples.MathlibLinearAlgebra.Determinant
