/-
文件: 13_mathlib_linear_algebra/matrices.lean
描述: 矩阵，乘法，单位矩阵，转置
编译: lake build Lean4Tutorial.Examples.MathlibLinearAlgebra.Matrices
依赖: Mathlib.Data.Matrix.Basic
-/

import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibLinearAlgebra.Matrices

/-! # 矩阵（Matrices） -/

-- 矩阵是按行和列排列的数表
-- m × n 矩阵有 m 行 n 列
--
-- 在 Mathlib 中，Matrix m n R 表示 m 行 n 列、元素在 R 中的矩阵
-- 其中 m 和 n 是索引类型（通常是 Fin n）

/-! ## 矩阵的定义 -/

-- Matrix m n R 就是 m → n → R
-- 即矩阵可以看作是行索引到列索引到元素的函数

#check Matrix

-- 矩阵的第 i 行第 j 列元素记作 A i j
variable {m n p : Type*} [Fintype m] [Fintype n] [Fintype p]
variable (A B : Matrix m n ℝ) (C : Matrix n p ℝ)

/-! ## 特殊矩阵 -/

-- 零矩阵：所有元素都是 0
def zero_matrix : Matrix m n ℝ := 0

theorem zero_matrix_apply (i : m) (j : n) :
    (0 : Matrix m n ℝ) i j = 0 := by
  simp

-- 单位矩阵：对角线上是 1，其余是 0
-- 只有方阵才有单位矩阵
variable {n' : Type*} [Fintype n']

def identity_matrix : Matrix n' n' ℝ := 1

theorem identity_matrix_apply (i j : n') :
    (1 : Matrix n' n' ℝ) i j = if i = j then 1 else 0 := by
  simp [Matrix.one_apply]
  <;> aesop

/-! ## 矩阵运算 -/

-- 矩阵加法
theorem matrix_add_apply (i : m) (j : n) :
    (A + B) i j = A i j + B i j := by
  simp

-- 矩阵标量乘法
variable (c : ℝ)

theorem matrix_smul_apply (i : m) (j : n) :
    (c • A) i j = c * A i j := by
  simp

-- 矩阵负运算
theorem matrix_neg_apply (i : m) (j : n) :
    (-A) i j = -A i j := by
  simp

-- 矩阵减法
theorem matrix_sub_apply (i : m) (j : n) :
    (A - B) i j = A i j - B i j := by
  simp

/-! ## 矩阵乘法 -/

-- 矩阵乘法：如果 A 是 m × n 矩阵，B 是 n × p 矩阵，
-- 则 AB 是 m × p 矩阵，其中
--   (AB)_{i,j} = Σ_k A_{i,k} * B_{k,j}

-- 矩阵乘法
def matrix_mul : Matrix m p ℝ := A * C

theorem matrix_mul_apply (i : m) (j : p) :
    (A * C) i j = ∑ k : n, A i k * C k j := by
  exact Matrix.mul_apply A C i j

-- 矩阵乘法的性质
variable (D : Matrix p m ℝ)

-- 结合律
-- (AB)C = A(BC)
-- 需要适当的维度

-- 分配律
-- A(B + C) = AB + AC
-- (A + B)C = AC + BC

-- 单位矩阵的性质
variable (E : Matrix n' n' ℝ)

theorem matrix_mul_one_left : (1 : Matrix n' n' ℝ) * E = E := by
  exact Matrix.one_mul E

theorem matrix_mul_one_right : E * (1 : Matrix n' n' ℝ) = E := by
  exact Matrix.mul_one E

-- 注意：矩阵乘法不满足交换律
-- 一般来说 AB ≠ BA

/-! ## 转置 -/

-- 矩阵 A 的转置 Aᵀ 是将 A 的行和列互换得到的矩阵
-- (Aᵀ)_{i,j} = A_{j,i}

def transpose : Matrix n m ℝ := A.transpose

theorem transpose_apply (i : n) (j : m) :
    A.transpose i j = A j i := by
  exact Matrix.transpose_apply A i j

-- 转置的性质
variable (F : Matrix n m ℝ)

-- 转置的转置等于原矩阵
theorem transpose_transpose : A.transpose.transpose = A := by
  exact Matrix.transpose_transpose A

-- 转置保持加法
theorem transpose_add : (A + F).transpose = A.transpose + F.transpose := by
  exact Matrix.transpose_add A F

-- 转置反序乘法：(AB)ᵀ = Bᵀ Aᵀ
theorem transpose_mul :
    (A * C).transpose = C.transpose * A.transpose := by
  exact Matrix.transpose_mul A C

-- 单位矩阵的转置是自身
theorem transpose_one : (1 : Matrix n' n' ℝ).transpose = 1 := by
  exact Matrix.transpose_one

/-! ## 对称矩阵 -/

-- 对称矩阵：Aᵀ = A
-- 即矩阵关于对角线对称

def isSymmetric (A : Matrix n' n' ℝ) : Prop := A.transpose = A

-- 单位矩阵是对称的
theorem one_isSymmetric : isSymmetric (1 : Matrix n' n' ℝ) := by
  simp [isSymmetric, Matrix.transpose_one]

/-! ## 矩阵与线性映射 -/

-- 每个 m × n 矩阵对应一个从 ℝⁿ 到 ℝᵐ 的线性映射
-- 即向量左乘矩阵

-- 反之，在有限维向量空间中，
-- 每个线性映射（在选定基后）都可以表示为矩阵

-- 这就是矩阵表示理论

/-! ## 初等变换 -/

-- 矩阵的初等行变换：
--   1. 交换两行
--   2. 某行乘以非零标量
--   3. 某行加上另一行的倍数

-- 初等变换对应初等矩阵
-- 对矩阵做初等行变换等价于左乘初等矩阵

/-! ## 行最简形 -/

-- 高斯消元法可以将矩阵化为行最简形
-- 用于解线性方程组、求逆矩阵、计算秩等

end Lean4Tutorial.Examples.MathlibLinearAlgebra.Matrices
