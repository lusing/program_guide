import Mathlib.Analysis.Normed.Operator.Compact.Basic
import Mathlib.Analysis.InnerProductSpace.Spectrum

/-!
# 第 10 章 · 紧算子（Conway II.4）

对应 `docs/10-compact-operators.md`。
-/

/-!
## 1. 紧算子的定义（Conway 4.1）
-/

#check @IsCompactOperator

-- 零算子紧
example {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] :
    IsCompactOperator (0 : H →L[ℝ] H) :=
  isCompactOperator_zero

/-!
## 2. 紧性的等价刻画
-/

#check @IsCompactOperator.isCompact_closure_image_closedBall
#check @isCompactOperator_iff_image_closedBall_subset_compact

/-!
## 3. 紧自伴算子的核心定理

全部特征值为零 ⟹ 算子为零。
-/

#check @ContinuousLinearMap.eq_zero_of_forall_hasEigenvalue_eq_zero

/-!
## 4. 自伴算子的特征值理论（5.6-5.8 前奏）
-/

section Symmetric

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E]

example (T : E →ₗ[ℂ] E) (hT : T.IsSymmetric) {μ : ℂ}
    (hμ : Module.End.HasEigenvalue T μ) : starRingEnd ℂ μ = μ :=
  LinearMap.IsSymmetric.conj_eigenvalue_eq_self hT hμ

#check @LinearMap.IsSymmetric.orthogonalFamily_eigenspaces

end Symmetric
