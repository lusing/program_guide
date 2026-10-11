import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.Dual
import Mathlib.MeasureTheory.Function.L2Space

/-!
# 第 04 章 · Riesz 表示定理（Conway I.3）

对应 `docs/04-riesz.md`。本章在机器中复现 Conway §I.3 的主线：

1. **‖L(x)‖ ≤ ‖L‖·‖x‖ 的三重等价刻画**（Conway 3.1/3.3 的机器形态）。
2. **"取内积即得泛函"的观察**：`toDualMap` 是等距嵌入，‖⟪x, ·⟫‖ = ‖x‖。
3. **Riesz 表示定理**（Conway 3.4）：完备时 `toDualMap` 升级为满同构 `toDual`；
   我们把满射性展开成书上的陈述（存在唯一表示向量，且范数相等）。
4. **唯一性的正交论证**（按 Conway 3.4 末段手工做）。
-/

open scoped RealInnerProductSpace ComplexInnerProductSpace InnerProductSpace

/-!
## 1. 连续线性泛函的范数刻画（Conway 3.1、3.3）

mathlib 中"有界线性泛函"就是 `E →L[𝕜] 𝕜`（`L` 代表 bounded/continuous），
`ContinuousLinearMap.norm_le`、`ContinuousLinearMap.norm_apply_le` 等给出
Conway 3.3 的三重等式。这里验证最常用的一条：|L x| ≤ ‖L‖·‖x‖。
-/

section Bound

variable {𝕜 : Type*} [RCLike 𝕜] {E : Type*} [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]

example (L : E →L[𝕜] 𝕜) (x : E) : ‖L x‖ ≤ ‖L‖ * ‖x‖ :=
  L.le_opNorm x

-- 算子范数的"下确界刻画"（Conway 3.3 的第三重等式：一切界之最小）
#check @ContinuousLinearMap.isLeast_opNorm

end Bound

/-!
## 2. 内积泛函的范数（Conway 3.4 之前的观察）

固定 x，映射 `y ↦ ⟪x, y⟫` 是连续线性泛函（注意 mathlib 约定：
第一变元共轭线性，故这是"对 y 线性"的合法 CLM），
且其范数恰为 ‖x‖。mathlib 的 `toDualMap` 把它做成等距。
-/

section ToDualMap

variable {𝕜 : Type*} [RCLike 𝕜] {E : Type*} [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]

#check @InnerProductSpace.toDualMap
#check @InnerProductSpace.toDual_apply_apply

example (x : E) : ‖(InnerProductSpace.toDualMap 𝕜 E x : E →L[𝕜] 𝕜)‖ = ‖x‖ :=
  (InnerProductSpace.toDualMap 𝕜 E).norm_map x

end ToDualMap

/-!
## 3. Riesz 表示定理（Conway 3.4）

完备性把等距嵌入升级为等距同构：`toDual : E ≃ₗᵢ⋆[𝕜] StrongDual 𝕜 E`。
用满射性写出书上的陈述：每个连续线性泛函 L 都有唯一的表示向量 x₀，
L y = ⟪x₀, y⟫ 对一切 y 成立。
-/

section Riesz

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E]

theorem fa_riesz_repr [CompleteSpace E] (L : E →L[ℂ] ℂ) :
    ∃ x₀ : E, ∀ y, L y = ⟪x₀, y⟫ := by
  obtain ⟨x₀, hx₀⟩ := (InnerProductSpace.toDual ℂ E).surjective L
  refine ⟨x₀, fun y => ?_⟩
  have h1 : (InnerProductSpace.toDual ℂ E) x₀ y = L y := by rw [hx₀]
  rw [← InnerProductSpace.toDual_apply_apply]
  exact h1.symm

/-!
唯一性按 Conway 3.4 的末段论证：若 ⟪h₀, y⟫ = ⟪h₀', y⟫ 对一切 y，
则 ⟪h₀ - h₀', h₀ - h₀'⟫ = 0，正定性给出 h₀ = h₀'。
-/

theorem fa_riesz_unique {x₀ x₁ : E}
    (h : ∀ y, ⟪x₀, y⟫ = ⟪x₁, y⟫) : x₀ = x₁ := by
  have hdiff : ∀ y, ⟪x₀ - x₁, y⟫ = 0 := by
    intro y
    rw [inner_sub_left, h y, sub_self]
  have hself := hdiff (x₀ - x₁)
  rw [inner_self_eq_zero] at hself
  exact sub_eq_zero.mp hself

/-!
范数相等：`toDual` 是等距，故 ‖L‖ = ‖x₀‖（Conway 3.4 的最后一句）。
-/

theorem fa_riesz_norm [CompleteSpace E] (L : E →L[ℂ] ℂ) :
    ∃ x₀ : E, (∀ y, L y = ⟪x₀, y⟫) ∧ ‖L‖ = ‖x₀‖ := by
  obtain ⟨x₀, hx₀⟩ := (InnerProductSpace.toDual ℂ E).surjective L
  refine ⟨x₀, ?_, ?_⟩
  · intro y
    have h1 : (InnerProductSpace.toDual ℂ E) x₀ y = L y := by rw [hx₀]
    rw [← InnerProductSpace.toDual_apply_apply]
    exact h1.symm
  · rw [← hx₀]
    exact (InnerProductSpace.toDual ℂ E).norm_map x₀

end Riesz

/-!
## 4. L²(μ) 的特例（Conway 3.5）

Riesz 定理 + "L²(μ) 是 Hilbert 空间" ⟹ L²(μ) 上的连续线性泛函
都是与某个 L² 函数做内积。mathlib 中 L² 的内积空间结构在
`Mathlib.MeasureTheory.Function.L2Space`；这里只展示它存在：
-/

#check @MeasureTheory.L2.innerProductSpace
