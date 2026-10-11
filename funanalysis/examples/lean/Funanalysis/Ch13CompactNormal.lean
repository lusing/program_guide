import Mathlib.Analysis.InnerProductSpace.Spectrum

/-!
# 第 13 章 · 紧正规算子的谱定理与泛函演算（Conway II.7-8）

对应 `docs/13-compact-normal.md`。

1. **自伴算子**与特征值实。
2. **特征空间正交**。
3. **紧自伴的核心定理**。
4. **正算子**与平方根的背景。

完整的泛函演算在 mathlib 的 C* 代数框架中。
-/

/-!
## 1. 自伴算子（Conway 7.13-7.16 的基础）
-/

section SelfAdjoint

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E]

-- IsSelfAdjoint 的定义
#check @IsSelfAdjoint

end SelfAdjoint

/-!
## 2. 特征值实与特征空间正交（Conway 5.6-5.8）
-/

section EigenvalueFacts

variable {K : Type*} [NormedAddCommGroup K] [InnerProductSpace ℂ K]

example (T : K →ₗ[ℂ] K) (hT : T.IsSymmetric) {μ : ℂ}
    (hμ : Module.End.HasEigenvalue T μ) : starRingEnd ℂ μ = μ :=
  LinearMap.IsSymmetric.conj_eigenvalue_eq_self hT hμ

#check @LinearMap.IsSymmetric.orthogonalFamily_eigenspaces

end EigenvalueFacts

/-!
## 3. 紧自伴的核心定理
-/

section CompactKey

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

#check @ContinuousLinearMap.eq_zero_of_forall_hasEigenvalue_eq_zero

end CompactKey
