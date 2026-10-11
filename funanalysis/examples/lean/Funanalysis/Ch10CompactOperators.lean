import Mathlib.Analysis.Normed.Operator.Compact.Basic
import Mathlib.Analysis.InnerProductSpace.Spectrum

/-!
# 第 10 章 · 紧算子（Conway II.4）

对应 `docs/10-compact-operators.md`。本章在机器中复现 §II.4 主线：

1. **IsCompactOperator** 谓词（Conway 4.1）。
2. **有限维 ⟹ 全紧**（Heine-Borel）。
3. **紧性的刻画**（闭球像含于紧集）。
4. **紧自伴算子的关键定理**：全部特征值为零 ⟹ 算子为零——
   这是谱定理（第 11 章）证明的最后一步。
5. **自伴算子的特征值实、特征空间正交**（5.6-5.8 前奏）。
-/

open scoped RealInnerProductSpace InnerProductSpace

section Compact

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H]

/-!
## 1. 紧算子的定义（Conway 4.1）
-/

#check @IsCompactOperator

-- 零算子紧
example : IsCompactOperator (0 : H →L[ℝ] H) :=
  isCompactOperator_zero

/-!
## 2. 有限维空间上所有算子都紧（Heine-Borel）
-/

example [FiniteDimensional ℝ H] (T : H →L[ℝ] H) : IsCompactOperator T :=
  IsCompactOperator.image_closedBall_subset_compact T isCompact_closedBall

/-!
## 3. 紧性的等价刻画
-/

#check @IsCompactOperator.isCompact_closure_image_closedBall
#check @isCompactOperator_iff_image_closedBall_subset_compact

end Compact

/-!
## 4. 紧自伴算子的核心定理（谱定理之钥）

如果紧自伴算子的所有特征值都是零，则算子本身为零。
这是 Conway 5.1 证明的最后一步：谱分解的余项范数趋于零。
-/

section Key

variable {K : Type*} [NormedAddCommGroup K] [InnerProductSpace ℂ K] [CompleteSpace K]

#check @ContinuousLinearMap.eq_zero_of_forall_hasEigenvalue_eq_zero

end Key

/-!
## 5. 自伴算子的特征值理论（Conway 5.6-5.8 前奏）

自伴算子的特征值全实；不同特征值的特征空间正交。
-/

section Symmetric

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]

-- 特征值实
example (T : E →ₗ[ℝ] E) (hT : T.IsSymmetric) {μ : ℝ}
    (hμ : Module.End.HasEigenvalue T μ) : conj μ = μ :=
  LinearMap.IsSymmetric.conj_eigenvalue_eq_self hT hμ

-- 不同特征值的特征空间正交
#check @LinearMap.IsSymmetric.orthogonalFamily_eigenspaces

end Symmetric
