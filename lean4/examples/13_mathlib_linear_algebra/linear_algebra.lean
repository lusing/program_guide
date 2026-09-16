/-
文件: 13_mathlib_linear_algebra/linear_algebra.lean
描述: 第16章 线性代数（与教程同步，Mathlib4 master@2026-09 验证）
编译: lake build Lean4Tutorial.Examples.MathlibLinearAlgebra.LinearAlgebra
-/

import Mathlib.Algebra.Module.Defs
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.LinearAlgebra.Matrix.Defs
import Mathlib.LinearAlgebra.Matrix.Notation     -- !![...] 记法（2026 起在 LinearAlgebra 下）
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Vandermonde
import Mathlib.LinearAlgebra.FiniteDimensional.Defs
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas   -- 秩-零度定理
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Real.Sqrt

open Matrix

namespace Lean4Tutorial.Examples.MathlibLinearAlgebra.Ch16

/-! # 16.1 模与向量空间 -/

#check (inferInstance : Module ℝ (Fin 3 → ℝ))

example [Semiring R] [AddCommMonoid M] [Module R M] (r s : R) (x : M) :
    r • s • x = (r * s) • x := smul_smul r s x
example [Semiring R] [AddCommMonoid M] [Module R M] (x : M) : (1 : R) • x = x :=
  one_smul R x
example [Semiring R] [AddCommMonoid M] [Module R M] (r : R) (x y : M) :
    r • (x + y) = r • x + r • y := smul_add r x y

/-! # 16.2 线性映射 -/

#check LinearMap
#check LinearMap.id

example [Semiring R] [AddCommMonoid M] [Module R M] [AddCommMonoid N] [Module R N]
    (f : M →ₗ[R] N) (x y : M) : f (x + y) = f x + f y := f.map_add x y
example [Semiring R] [AddCommMonoid M] [Module R M] [AddCommMonoid N] [Module R N]
    (f : M →ₗ[R] N) (r : R) (x : M) : f (r • x) = r • f x := f.map_smul r x

#check LinearMap.comp
#check LinearMap.ker
#check LinearMap.range

/-! # 16.3 矩阵 -/

example (A : Matrix (Fin 2) (Fin 2) ℝ) : ℝ := A 0 1

def myMat : Matrix (Fin 2) (Fin 2) ℝ := !![1, 2; 3, 4]
#eval myMat 0 1

example (A : Matrix (Fin 2) (Fin 2) ℝ) : Matrix (Fin 2) (Fin 2) ℝ := A * Aᵀ

example (A B : Matrix (Fin 2) (Fin 2) ℝ) (i j : Fin 2) :
    (A * B) i j = ∑ k, A i k * B k j := Matrix.mul_apply

/-! # 16.4 行列式 -/

example : det (1 : Matrix (Fin 3) (Fin 3) ℝ) = 1 := det_one
example (A B : Matrix (Fin n) (Fin n) ℝ) : det (A * B) = det A * det B := det_mul A B
example (A : Matrix (Fin n) (Fin n) ℝ) : det Aᵀ = det A := det_transpose A

example : det (!![2, 0; 0, 3] : Matrix (Fin 2) (Fin 2) ℝ) = 6 := by
  rw [det_fin_two]
  norm_num

/-! # 16.5 Cayley–Hamilton 与 Vandermonde -/

example (M : Matrix (Fin n) (Fin n) ℝ) : Polynomial.aeval M M.charpoly = 0 :=
  Matrix.aeval_self_charpoly M

#check @Matrix.det_vandermonde

/-! # 16.6 有限维与秩-零度 -/

open Module

#check @Module.finrank

example : finrank ℝ (Fin 3 → ℝ) = 3 := by simp [finrank_fintype_fun_eq_card]

example [Field K] [AddCommGroup V] [Module K V] [FiniteDimensional K V]
    [AddCommGroup V₂] [Module K V₂] (f : V →ₗ[K] V₂) :
    finrank K (LinearMap.range f) + finrank K (LinearMap.ker f) = finrank K V :=
  LinearMap.finrank_range_add_finrank_ker f

end Lean4Tutorial.Examples.MathlibLinearAlgebra.Ch16
