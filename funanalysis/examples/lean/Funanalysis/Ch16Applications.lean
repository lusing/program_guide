import Mathlib.Analysis.Normed.Module.FiniteDimension

/-!
# 第 16 章 · 应用三讲（Conway III.7-9*）

对应 `docs/16-applications.md`。

Banach 极限与 Runge 定理在 mathlib 中暂无直接形式化。
-/

-- 有限维赋范空间是 Proper（局部紧）
example {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] : ProperSpace E := by infer_instance
