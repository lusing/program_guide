import Mathlib.Analysis.InnerProductSpace.Spectrum
import Mathlib.Analysis.CStarAlgebra.Basic

/-!
# 第 13 章 · 紧正规算子的谱定理与泛函演算（Conway II.7-8）

对应 `docs/13-compact-normal.md`。

1. **正规算子的特征空间约化性**（Conway 5.6/7.5）。
2. **紧正规算子的谱定理**（Conway 7.6）：T = Σ αₙPₙ，αₙ ∈ ℂ。
3. **泛函演算**（Conway 7.11）：Φ ↦ Φ(T) 是乘法线性映射。
4. **正算子**（Conway 7.13-7.16）：T ≥ 0 与平方根。

mathlib 对应物：C* 代数的连续泛函演算 + 谱理论的有限维原型。
-/

open scoped RealInnerProductSpace InnerProductSpace

/-!
## 1. 正规算子与对角化
-/

section Normal

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E]

-- 正规算子：与自己的伴随交换
#check @IsSelfAdjoint

-- IsNormal 在 Module.End 上
#check @Module.End.IsNormal

end Normal

/-!
## 2. 正算子与平方根（Conway 7.13-7.16）
-/

section Positive

variable {K : Type*} [NormedAddCommGroup K] [InnerProductSpace ℂ K] [CompleteSpace K]

-- C* 代数中的正性
#check @CStarAlgebra

-- 正算子的平方根存在唯一
#check @IsSelfAdjoint.sqrt

end Positive

/-!
## 3. 泛函演算

mathlib 的 C* 代数框架下有完整的连续泛函演算。
对紧正规算子，这化为对特征值的逐点演算。
-/
