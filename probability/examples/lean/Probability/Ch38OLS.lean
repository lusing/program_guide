import Mathlib.Tactic

/-!
# 第 38 章：OLS 的投影代数——正规方程、残差正交与幂等矩阵

固定三点设计上的全部代数断言由 `native_decide` 编译执行精确判定：
有理数矩阵运算经编译器以 GMP 实现，无浮点参与。
（kernel `decide` 对 Rat 链式求和的归约会停滞，故走编译执行通道。）
-/

open Matrix

namespace Ch38

/-- 固定三点设计的回归矩阵（常数列 + x = 0,1,2）。 -/
def X : Matrix (Fin 3) (Fin 2) ℚ := !![(1 : ℚ), 0; 1, 1; 1, 2]

/-- 观测向量 y = (1, 2, 4)。 -/
def yVec : Fin 3 → ℚ := ![(1 : ℚ), 2, 4]

/-- OLS 解 β̂ = (5/6, 3/2)。 -/
def betaHat : Fin 2 → ℚ := ![(5 : ℚ) / 6, 3 / 2]

/-- 残差 e = y - Xβ̂ = (1/6, -1/3, 1/6)。 -/
def resid : Fin 3 → ℚ := ![(1 : ℚ) / 6, -1 / 3, 1 / 6]

/-- 帽子矩阵 P = X(X'X)⁻¹X'。 -/
def P : Matrix (Fin 3) (Fin 3) ℚ :=
  !![(5 : ℚ) / 6, 2 / 6, -1 / 6; 2 / 6, 2 / 6, 2 / 6; -1 / 6, 2 / 6, 5 / 6]

/-- 残差制造矩阵 M = I - P。 -/
def M : Matrix (Fin 3) (Fin 3) ℚ :=
  !![(1 : ℚ) / 6, -2 / 6, 1 / 6; -2 / 6, 4 / 6, -2 / 6; 1 / 6, -2 / 6, 1 / 6]

-- 正规方程 X'Xβ̂ = X'y。
example : (Xᵀ * X) *ᵥ betaHat = Xᵀ *ᵥ yVec := by native_decide

-- 残差正交 X'e = 0：纯代数事实，不需要任何随机假设。
example : Xᵀ *ᵥ resid = ![(0 : ℚ), 0] := by native_decide

-- e'e = RSS = 1/6。
example : resid ⬝ᵥ resid = 1 / 6 := by native_decide

-- P 对称、幂等；M 幂等；P 与 M 互补且正交。
example : Pᵀ = P := by native_decide
example : P * P = P := by native_decide
example : M * M = M := by native_decide
example : P * M = 0 := by native_decide
example : P + M = 1 := by native_decide

-- 幂等矩阵的秩等于迹：tr P = k = 2，tr M = n - k = 1。
example : Matrix.trace P = 2 := by native_decide
example : Matrix.trace M = 1 := by native_decide

-- 投影与残差把 y 分解为拟合值与残差。
example : P *ᵥ yVec = ![(5 : ℚ) / 6, 7 / 3, 23 / 6] := by native_decide
example : M *ᵥ yVec = resid := by native_decide

-- Pythagoras：‖y‖² = ‖Py‖² + ‖My‖²（ŷ ⊥ e）。
example : yVec ⬝ᵥ yVec =
    (P *ᵥ yVec) ⬝ᵥ (P *ᵥ yVec) + (M *ᵥ yVec) ⬝ᵥ (M *ᵥ yVec) := by
  native_decide

/-- 该设计下斜率恰为 (y₃ - y₁)/2 —— 与矩阵公式 (X'X)⁻¹X'y 一致。 -/
example : betaHat 1 = (yVec 2 - yVec 0) / 2 := by native_decide

end Ch38
