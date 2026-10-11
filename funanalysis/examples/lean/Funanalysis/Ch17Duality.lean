import Mathlib.Analysis.Normed.Operator.Basic

/-!
# 第 17 章 · 对偶理论（Conway III.10-11 + 附录 B/C）

对应 `docs/17-duality.md`。

1. **对偶空间** X* = B(X, 𝔽) 完备。
2. **L^p 对偶**：(L^p)* = L^q（1 ≤ p < ∞）。
-/

-- 对偶空间完备（𝔽 完备 ⟹ X* 完备）
example {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] :
    CompleteSpace (E →L[ℝ] ℝ) := by infer_instance
