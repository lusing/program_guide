/-
文件: 15_mathlib_measure_probability/probability.lean
描述: 概率测度
编译: lake build Lean4Tutorial.Examples.MathlibMeasureProbability.Probability
依赖: Mathlib.Probability.Basic
-/

import Mathlib.Probability.Basic
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibMeasureProbability.Probability

/-! # 概率测度（Probability Measures） -/

-- 概率空间是测度空间的特例，其中总测度为 1
-- 即 P(Ω) = 1，其中 Ω 是样本空间
--
-- 在概率论中：
--   Ω  样本空间（所有可能结果的集合）
--   𝓕  事件空间（σ-代数）
--   ℙ  概率测度（P : 𝓕 → [0, 1]）
--
-- (Ω, 𝓕, ℙ) 称为概率空间

/-! ## 概率的公理 -/

-- 概率测度 ℙ 满足：
--   1. 非负性：对任意事件 A，ℙ(A) ≥ 0
--   2. 规范性：ℙ(Ω) = 1
--   3. 可数可加性：如果 Aₙ 两两不交，则 ℙ(⋃ Aₙ) = Σ ℙ(Aₙ)

-- 这些就是柯尔莫哥洛夫公理

/-! ## 概率的基本性质 -/

-- P(∅) = 0
-- 空事件的概率为 0

-- P(Aᶜ) = 1 - P(A)
-- 对立事件的概率

-- 单调性：如果 A ⊆ B，则 P(A) ≤ P(B)

-- 次可加性：P(A ∪ B) ≤ P(A) + P(B)

-- 容斥原理：
-- P(A ∪ B) = P(A) + P(B) - P(A ∩ B)
--
-- 三个集合：
-- P(A ∪ B ∪ C) = P(A) + P(B) + P(C)
--              - P(A∩B) - P(A∩C) - P(B∩C)
--              + P(A∩B∩C)

/-! ## 条件概率 -/

-- 在事件 B 发生的条件下，事件 A 的条件概率：
-- P(A | B) = P(A ∩ B) / P(B)
-- （其中 P(B) > 0）

-- 乘法公式：
-- P(A ∩ B) = P(A | B) * P(B)

-- 全概率公式：
-- 如果 B₁, B₂, ..., Bₙ 是样本空间的划分，则
-- P(A) = Σ P(A | Bᵢ) * P(Bᵢ)

-- 贝叶斯公式：
-- P(Bᵢ | A) = P(A | Bᵢ) * P(Bᵢ) / Σⱼ P(A | Bⱼ) * P(Bⱼ)

/-! ## 独立性 -/

-- 两个事件 A 和 B 独立，如果
-- P(A ∩ B) = P(A) * P(B)

-- 等价地，P(A | B) = P(A)（当 P(B) > 0 时）

-- 多个事件的独立性：
-- 事件族 {A_i} 独立，如果对任意有限子族，交的概率等于概率的乘积

-- 注意：两两独立不蕴含相互独立

/-! ## 随机变量 -/

-- 随机变量是概率空间上的可测函数
-- X : Ω → ℝ 是随机变量，如果 X 是可测函数

-- 随机变量的分布（概率分布）：
-- μ_X(A) = P(X ∈ A) = P({ω ∈ Ω | X(ω) ∈ A})

-- 分布函数：
-- F_X(x) = P(X ≤ x)

-- 离散型随机变量：
--   概率质量函数（PMF）：p(x) = P(X = x)

-- 连续型随机变量：
--   概率密度函数（PDF）：f(x) = F'(x)（几乎处处）
--   P(a ≤ X ≤ b) = ∫_a^b f(x) dx

/-! ## 常见的概率分布 -/

-- 离散分布：
--   1. 伯努利分布 Bernoulli(p)
--   2. 二项分布 Binomial(n, p)
--   3. 几何分布 Geometric(p)
--   4. 泊松分布 Poisson(λ)
--   5. 均匀分布（离散）

-- 连续分布：
--   1. 均匀分布 Uniform(a, b)
--   2. 正态分布 Normal(μ, σ²)
--   3. 指数分布 Exponential(λ)
--   4. 伽马分布 Gamma(α, β)
--   5. 卡方分布 χ²(n)
--   6. t 分布 t(n)
--   7. F 分布 F(m, n)

/-! ## 期望 -/

-- 随机变量 X 的期望（均值）：
-- E[X] = ∫ X dP

-- 离散型：E[X] = Σ x * P(X = x)
-- 连续型：E[X] = ∫ x * f(x) dx

-- 期望的性质：
--   1. 线性：E[aX + bY] = a E[X] + b E[Y]
--   2. 单调性：如果 X ≤ Y a.s.，则 E[X] ≤ E[Y]
--   3. 非负性：如果 X ≥ 0 a.s.，则 E[X] ≥ 0

/-! ## 方差 -/

-- 方差：Var(X) = E[(X - E[X])²] = E[X²] - (E[X])²

-- 标准差：σ(X) = √Var(X)

-- 方差的性质：
--   1. Var(X) ≥ 0
--   2. Var(aX + b) = a² Var(X)
--   3. 如果 X, Y 独立，则 Var(X + Y) = Var(X) + Var(Y)

/-! ## 协方差与相关系数 -/

-- 协方差：Cov(X, Y) = E[(X - E[X])(Y - E[Y])] = E[XY] - E[X]E[Y]

-- 相关系数：ρ(X, Y) = Cov(X, Y) / (σ(X) * σ(Y))
-- 取值范围：[-1, 1]

-- 如果 X, Y 独立，则 Cov(X, Y) = 0
-- 但反之不一定成立（不相关不一定独立）

/-! ## 大数定律 -/

-- 弱大数定律（WLLN）：
-- 如果 X₁, X₂, ... 独立同分布，且 E[X₁] = μ，
-- 则 (X₁ + ... + X_n) / n → μ（依概率收敛）

-- 强大数定律（SLLN）：
-- 在相同条件下，
-- (X₁ + ... + X_n) / n → μ a.s.（几乎必然收敛）

/-! ## 中心极限定理 -/

-- 中心极限定理（CLT）：
-- 如果 X₁, X₂, ... 独立同分布，E[X₁] = μ，Var(X₁) = σ² > 0，
-- 则
-- (X₁ + ... + X_n - nμ) / (σ√n) → N(0, 1)（依分布收敛）
--
-- 即标准化后的样本均值依分布收敛于标准正态分布

-- 这是统计学的理论基础

end Lean4Tutorial.Examples.MathlibMeasureProbability.Probability
