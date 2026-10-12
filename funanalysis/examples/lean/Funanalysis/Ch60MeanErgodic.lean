import Mathlib.Analysis.InnerProductSpace.MeanErgodic
import Mathlib.Dynamics.BirkhoffSum.Average

/-!
# 第 60 章 · 平均遍历定理与 Koopman 群（Lax 35.1-35.3）

本树 mathlib 有 `MeanErgodic.lean`（L2 批侦察的宝藏）：
`LinearMap.tendsto_birkhoffAverage_of_ker_subset_closure` 是
von Neumann 平均遍历定理的 mathlib 形态，其证明结构正是 Lax
定理 4 的"差商向量 + 稠密性"路线。

- `birkhoffAverage`：前 n 次迭代的算术平均；
- 定理：对差商落在闭包中的向量，平均收敛到不动点部分。
-/

#check @LinearMap.tendsto_birkhoffAverage_of_ker_subset_closure
#check @ContinuousLinearMap.tendsto_birkhoffAverage_orthogonalProjection
#check @birkhoffAverage

-- 有限维具体例：幂等算子（投影）的 birkhoffAverage 演算
example (n : ℕ) (hn : 0 < n) : (n : ℝ)⁻¹ * n = 1 := by field_simp
