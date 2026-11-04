/-
! # 第 28 章 · 行列式

对应原书 §4.4 前半（英文 3 版 pp. 385-389）。机器验证：
1. 2×2 显式式 det[[a,b;c,d]] = ad − bc（Laplace 展开引理推得）；
2. 书例 A₃ = [[2,1,0],[1,3,1],[0,1,2]] 的 det = 8（decide 精确计算）；
3. 式 (1)/(2)：det(AB) = det(A)·det(B)、det(Aᵀ) = det(A)（mathlib 正式化）；
4. 命题 4.86：A·adj(A) = det(A)·I（正式化 + 3×3 具体例）；
5. 推论 4.87：可逆 ⟺ det 为单位（正式化；ℤ 上 det = ±1 的两侧实例）；
6. 命题 4.88：det(PMP⁻¹) = det(M)（域上，由 det 乘法性与 det(P⁻¹) 导出）。
-/

import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Adjugate
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

namespace Abstractalgebra.Ch27Determinants

/-- 2×2 完全展开 = ad − bc：按 Laplace 第 0 行展开（公式 (3) 的最小实例）。 -/
example (a b c d : ℤ) :
    (Matrix.of ![![a, b], ![c, d]] : Matrix (Fin 2) (Fin 2) ℤ).det = a * d - b * c := by
  rw [Matrix.det_succ_row_zero]
  simp [Fin.sum_univ_two]
  ring

/-- 书例：det A₃ = 8（decide 走完全展开的机器计算）。 -/
example : Matrix.det (Matrix.of !![2, 1, 0; 1, 3, 1; 0, 1, 2] : Matrix (Fin 3) (Fin 3) ℤ) = 8 := by
  decide

/-- 完全展开的定义形态（mathlib：det_apply'，与原书 Σ sgn(σ)∏a_{σ(i),i} 逐字对应）。 -/
example (M : Matrix (Fin 3) (Fin 3) ℤ) :
    M.det = ∑ σ : Equiv.Perm (Fin 3), Equiv.Perm.sign σ * ∏ i, M (σ i) i :=
  Matrix.det_apply' M

/-- 式 (1)：det(AB) = det(A)·det(B)。 -/
example (A B : Matrix (Fin 2) (Fin 2) ℤ) : (A * B).det = A.det * B.det :=
  Matrix.det_mul A B

/-- 式 (2)：det(Aᵀ) = det(A)（记法 ᵀ 须另开 scope，这里用全名）。 -/
example (A : Matrix (Fin 2) (Fin 2) ℤ) : (Matrix.transpose A).det = A.det :=
  Matrix.det_transpose A

/-- 命题 4.86（mathlib 正式化，任意交换环）：A·adj(A) = det(A)·I。 -/
example {R : Type*} [CommRing R] {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n R) : A * A.adjugate = A.det • 1 :=
  Matrix.mul_adjugate A

/-- 命题 4.86 的具体算例：A₃·adj(A₃) = 8·I（native_decide 精确算出伴随）。 -/
example :
    (Matrix.of !![2, 1, 0; 1, 3, 1; 0, 1, 2] : Matrix (Fin 3) (Fin 3) ℤ)
      * ((Matrix.of !![2, 1, 0; 1, 3, 1; 0, 1, 2] : Matrix (Fin 3) (Fin 3) ℤ)).adjugate
    = (8 : Matrix (Fin 3) (Fin 3) ℤ) • 1 := by
  native_decide

/-- 推论 4.87（mathlib 正式化）：方阵可逆 ⟺ 行列式是单位。 -/
example {R : Type*} [CommRing R] {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n R) : IsUnit A ↔ IsUnit A.det :=
  Matrix.isUnit_iff_isUnit_det A

/-- 推论 4.87 的整数侧（det = 1）：[[2,1],[1,1]] 的逆是整数阵。 -/
example : IsUnit (Matrix.of !![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ).det := by
  have h : (Matrix.of !![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ).det = 1 := by decide
  rw [h]
  exact isUnit_one

/-- 推论 4.87 的整数侧（det = 2）：ℤ 上不可逆（ℤ 的单位只有 ±1）。 -/
example : ¬ IsUnit (Matrix.of !![2, 0; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).det := by
  have h : (Matrix.of !![2, 0; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).det = 2 := by decide
  rw [h, Int.isUnit_iff_abs_eq]
  decide

/-- 命题 4.88：相似不变性 det(PMP⁻¹) = det(M)。
由 det 乘法性与 (P⁻¹P) = 1 导出，不引用「逆的行列式」现成引理。 -/
example (P M : Matrix (Fin 2) (Fin 2) ℚ) (hP : IsUnit P.det) :
    (P * M * P⁻¹).det = M.det := by
  have hinv : P⁻¹ * P = 1 := Matrix.nonsing_inv_mul P hP
  have hdetinv : P⁻¹.det * P.det = 1 := by
    have h := Matrix.det_mul P⁻¹ P
    rw [hinv, Matrix.det_one] at h
    exact h.symm
  have hne : P.det ≠ 0 := by
    intro hc
    rw [hc, mul_zero] at hdetinv
    exact zero_ne_one hdetinv
  have hinv' : P⁻¹.det = (P.det)⁻¹ := eq_inv_of_mul_eq_one_left hdetinv
  rw [Matrix.det_mul, Matrix.det_mul, hinv']
  field_simp

end Abstractalgebra.Ch27Determinants
