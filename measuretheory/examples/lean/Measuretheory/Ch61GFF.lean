import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Probability.Distributions.Gaussian.IsGaussianProcess.Basic

/-!
# 第 61 章 高斯自由场（Lean）

胡书 §8.3 的机器侧。主件是纯线性代数（不带概率库）：路径图 pinned
拉普拉斯 L 与闭式格林矩阵 G(i,j) = min(i,j)(n+1−max(i,j))/(n+1) 的
恒等式 L·G = I 在 n = 3、n = 4 上于 ℚ 完全证明——"离散 GFF 的协方差
= 格林函数"的代数核心。等距层锚点 IsGaussianProcess 登记。
-/

open MeasureTheory

#check @ProbabilityTheory.IsGaussianProcess
-- 正文 61.2：零均值高斯过程（Gauss–Hilbert 空间的化身）

#check @ProbabilityTheory.IsGaussianProcess.hasGaussianLaw
-- 有限维联合高斯（等距 T 的化身：任意有限指标联合正态，
--   协方差由内积 ⟨f,g⟩ 折叠——正文 61.2 的核心句）

/-! ## 路径图 n=3：L·G = I 的精确全证 -/

/-- 路径图 {1,2,3}（端点 0 与 4 接地）的 pinned 拉普拉斯。 -/
def pathL3 : Matrix (Fin 3) (Fin 3) ℚ :=
  !![(2 : ℚ), -1, 0; -1, 2, -1; 0, -1, 2]

/-- 闭式格林矩阵：G(i,j) = min(i,j)(4−max(i,j))/4。
G = (1/4)·[[3,2,1],[2,4,2],[1,2,3]]。 -/
def pathG3 : Matrix (Fin 3) (Fin 3) ℚ :=
  !![(3 : ℚ)/4, 2/4, 1/4; 2/4, 4/4, 2/4; 1/4, 2/4, 3/4]

/-- **格林恒等式（n=3）**：L·G = I——"离散 GFF 协方差 = 格林函数"
的代数核心（正文 61.5 性质 1）。 -/
example : pathL3 * pathG3 = 1 := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, pathL3, pathG3, Fin.sum_univ_three] <;> norm_num

/-- 对称性：G = Gᵀ（协方差矩阵对称）。 -/
example : Matrix.transpose pathG3 = pathG3 := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [pathG3, Matrix.transpose_apply]

/-! ## 路径图 n=4：同一恒等式 -/

/-- 路径图 {1,2,3,4}（端点 0 与 5 接地）。 -/
def pathL4 : Matrix (Fin 4) (Fin 4) ℚ :=
  !![(2 : ℚ), -1, 0, 0; -1, 2, -1, 0; 0, -1, 2, -1; 0, 0, -1, 2]

/-- G(i,j) = min(i,j)(5−max(i,j))/5 = (1/5)·[[4,3,2,1],[3,6,4,2],[2,4,6,3],[1,2,3,4]]。 -/
def pathG4 : Matrix (Fin 4) (Fin 4) ℚ :=
  !![(4 : ℚ)/5, 3/5, 2/5, 1/5;
     3/5, 6/5, 4/5, 2/5;
     2/5, 4/5, 6/5, 3/5;
     1/5, 2/5, 3/5, 4/5]

/-- **格林恒等式（n=4）**：L·G = I。 -/
example : pathL4 * pathG4 = 1 := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, pathL4, pathG4, Fin.sum_univ_succ] <;> norm_num

/-- 对角线读数：G(i,i) = i(n+1−i)/(n+1)——内部点的"方差"（离边界越远
越大，中点取最大 n/4·... 的二次型）。 -/
example : pathG3 0 0 = (3 : ℚ)/4 ∧ pathG4 0 0 = (4 : ℚ)/5 := by
  constructor <;> simp [pathG3, pathG4]
