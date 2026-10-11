import Mathlib.Analysis.InnerProductSpace.Spectrum

/-!
# 第 11 章 · 紧自伴算子的对角化（Conway II.5）

对应 `docs/11-diagonalization.md`。
-/

/-!
## 1. 自伴算子的特征值实（Conway 5.8）
-/

section Symmetric

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E]

example (T : E →ₗ[ℂ] E) (hT : T.IsSymmetric) {μ : ℂ}
    (hμ : Module.End.HasEigenvalue T μ) : starRingEnd ℂ μ = μ :=
  LinearMap.IsSymmetric.conj_eigenvalue_eq_self hT hμ

end Symmetric

/-!
## 2. 特征空间正交（Conway 5.7）
-/

#check @LinearMap.IsSymmetric.orthogonalFamily_eigenspaces

/-!
## 3. 紧自伴的核心定理

全部特征值为零 ⟹ 算子为零。
-/

#check @ContinuousLinearMap.eq_zero_of_forall_hasEigenvalue_eq_zero
