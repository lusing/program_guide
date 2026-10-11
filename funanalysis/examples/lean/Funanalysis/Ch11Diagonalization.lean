import Mathlib.Analysis.InnerProductSpace.Spectrum
import Mathlib.Analysis.InnerProductSpace.SingularValues

/-!
# 第 11 章 · 紧自伴算子的对角化（Conway II.5）

对应 `docs/11-diagonalization.md`。本章承载 Conway §II.5 的主线：
**紧自伴算子的谱定理**（Conway 5.1）——任何紧自伴算子 T 可写为
T = Σ αₙPₙ（特征值 × 特征空间投影的正交分解）。

mathlib 中的对应物：
- **有限维版**：`InnerProductSpace.Spectrum` 的对角化定理。
- **紧自伴版**：`eq_zero_of_forall_hasEigenvalue_eq_zero`（核心步骤）。
- **奇异值分解**：`SingularValues.lean`——紧算子的 |T| 分解。
-/

open scoped RealInnerProductSpace InnerProductSpace

/-!
## 1. 谱定理的有限维原型

有限维自伴算子有实特征值的标准正交特征基。
-/

section FiniteDim

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
  [FiniteDimensional ℝ E]

-- 自伴算子的特征族正交
#check @LinearMap.IsSymmetric.orthogonalFamily_eigenspaces

-- 自伴算子的特征值实
example (T : E →ₗ[ℝ] E) (hT : T.IsSymmetric) {μ : ℝ}
    (hμ : Module.End.HasEigenvalue T μ) : conj μ = μ :=
  LinearMap.IsSymmetric.conj_eigenvalue_eq_self hT hμ

end FiniteDim

/-!
## 2. 紧自伴的核心：所有特征值为零 ⟹ 算子为零

这是 Conway 5.1 证明的最后一步。mathlib 以
`spectralRadius` 路线实现。
-/

section CompactKey

variable {K : Type*} [NormedAddCommGroup K] [InnerProductSpace ℂ K] [CompleteSpace K]

-- 核心定理：紧自伴的全部特征值为零 → 算子为零
#check @ContinuousLinearMap.eq_zero_of_forall_hasEigenvalue_eq_zero

end CompactKey

/-!
## 3. 奇异值（|T| 的特征值）

紧算子 T 的奇异值 = |T| = (T*T)^{1/2} 的特征值。
对自伴 T，奇异值 = |特征值|。
-/

section Singular

#check @singularValues

end Singular

/-!
## 4. 谱定理的陈述（Conway 5.1 的数学内容）

紧自伴 T 的非零特征值至多可数、实数、趋于零。
特征空间两两正交且有限维。
T = Σ αₙ Pₙ 按算子范数收敛。

mathlib 的完整无穷维谱定理在 C* 代数框架（第 37 章）中；
此处以核心步骤与有限维原型承载。
-/
