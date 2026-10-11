import Mathlib.Analysis.Normed.Module.FiniteDimension

/-!
# 第 14 章 · 赋范空间与 Banach 空间（Conway III.1-4）

对应 `docs/14-banach-spaces.md`。

1. **有限维赋范空间**自动完备。
2. **有限维 = 局部紧**（Riesz 引理的推论背景）。
-/

-- 有限维赋范空间自动完备
example {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] : CompleteSpace E := by infer_instance
