import Mathlib.Analysis.InnerProductSpace.Projection.Basic

/-!
# 第 36 章 · 谱测度（Conway IX.1）

投影值测度 E: Borel(ℝ) → 正交投影，满足
E(Δ∩Γ) = E(Δ)E(Γ)，E(ℝ) = I，H = ∫ λ dE(λ)。
mathlib 的 `orthogonalProjectionOnto` 是每个 E(Δ) 的构件。
-/

#check @Submodule.orthogonalProjectionOnto
