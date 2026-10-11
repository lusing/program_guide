import Mathlib.Analysis.InnerProductSpace.Adjoint

/-!
# 第 31 章 · Riesz 泛函演算（Conway VII.4）
-/

example {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H]
    [CompleteSpace H] : CompleteSpace (H →L[ℂ] H) := by infer_instance
