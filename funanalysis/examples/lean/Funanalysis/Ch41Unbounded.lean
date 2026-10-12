import Mathlib.Analysis.InnerProductSpace.LinearPMap
import Mathlib.Analysis.InnerProductSpace.Symmetric

/-!
# 第 41 章 · 无界算子基础（Conway X.1）

稠定算子 T: Dom(T) ⊆ H → H。闭算子/闭图像定理：
处处定义的闭算子自动有界。mathlib 的 `LinearPMap`
（部分定义线性映射）承载无界算子：
`LinearPMap.adjoint` 是稠定算子的伴随，
`LinearMap.IsSymmetric` 对不连续的线性映射也适用。
-/

#check @LinearPMap.adjoint
#check @LinearMap.IsSymmetric
