import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.LinearAlgebra.Matrix.DotProduct

/-!
# 第 29 章（Lean 通道）：三角形线性元的单元刚度

三角形 P1 元：单元刚度 k_ab = (b_a b_b + c_a c_b)/(4A)。对**单位直角
三角形**（顶点 (0,0),(1,0),(0,1)，A = 1/2）：

    b = (−1, 1, 0)，c = (−1, 0, 1)，
    k = (bb^T + cc^T)/2 = [[1, −1/2, −1/2], [−1/2, 1/2, 0], [−1/2, 0, 1/2]]。

核心性质：**行和为零**——k 乘常数向量为零（零模式），是"划去边界
行后矩阵可逆"的代数前提；以及**对称性**。
-/

open Real

namespace Pdenum.Ch29

/-- 单位直角三角形单元刚度（b = (−1,1,0)、c = (−1,0,1)、4A = 2）。 -/
def keUnit : Matrix (Fin 3) (Fin 3) ℚ :=
  Matrix.of fun i j =>
    match i, j with
    | 0, 0 => 1
    | 0, 1 => -1 / 2
    | 0, 2 => -1 / 2
    | 1, 0 => -1 / 2
    | 1, 1 => 1 / 2
    | 1, 2 => 0
    | 2, 0 => -1 / 2
    | 2, 1 => 0
    | 2, 2 => 1 / 2

/-- **行 0 的和为零**：1 − 1/2 − 1/2 = 0。 -/
theorem row0 : keUnit 0 0 + keUnit 0 1 + keUnit 0 2 = 0 := by
  simp [keUnit]; norm_num

/-- **行 1 的和为零**：−1/2 + 1/2 + 0 = 0。 -/
theorem row1 : keUnit 1 0 + keUnit 1 1 + keUnit 1 2 = 0 := by
  simp [keUnit]; norm_num

/-- **行 2 的和为零**：−1/2 + 0 + 1/2 = 0。 -/
theorem row2 : keUnit 2 0 + keUnit 2 1 + keUnit 2 2 = 0 := by
  simp [keUnit]; norm_num

/-- **对称性**：k i j = k j i——D(u,v) = D(v,u) 的单元体现。 -/
theorem keUnit_symmetric (i j : Fin 3) : keUnit i j = keUnit j i := by
  fin_cases i <;> fin_cases j <;> simp [keUnit]

end Pdenum.Ch29
