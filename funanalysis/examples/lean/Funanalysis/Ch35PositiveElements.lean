import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.InnerProductSpace.Positive

/-!
# 第 35 章 · 正元与 GNS 构造（Conway VIII.3-5）

正元：自伴且 ⟨Tx, x⟩ ≥ 0（等价地 σ(T) ⊆ [0,∞)，或 T = S*S）。
mathlib 的 `ContinuousLinearMap.IsPositive`。
-/

#check @ContinuousLinearMap.IsPositive
