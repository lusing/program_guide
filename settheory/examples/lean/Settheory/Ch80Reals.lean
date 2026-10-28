import Mathlib

/-!
# 第 80 章 · 实数轴、连续统与拓扑

mathlib 的 `ℝ` 已经配备条件完备有序域结构。这里只登记本章正文
从 Dedekind 截断证明出的两个关键接口：非空有界集的上/下确界，
以及阿基米德性。没有把任何有限二分实验当成完备性的证明。
-/

namespace Settheory.Ch80

open Set

/-- 非空有上界的实数集，其 `sSup` 确为最小上界。 -/
theorem real_sup (s : Set ℝ) (hne : s.Nonempty) (hbdd : BddAbove s) :
    IsLUB s (sSup s) :=
  isLUB_csSup hne hbdd

/-- 非空有下界的实数集，其 `sInf` 确为最大下界。 -/
theorem real_inf (s : Set ℝ) (hne : s.Nonempty) (hbdd : BddBelow s) :
    IsGLB s (sInf s) :=
  isGLB_csInf hne hbdd

/-- 阿基米德性：任意实数都被某个自然数超过。 -/
theorem real_archimedean (x : ℝ) : ∃ n : ℕ, x < n :=
  exists_nat_gt x

/-- 上确界落在每个上界之下；这是区间套证明反复使用的方向。 -/
example (s : Set ℝ) (hne : s.Nonempty) (hbdd : BddAbove s)
    {b : ℝ} (hb : b ∈ upperBounds s) : sSup s ≤ b :=
  (real_sup s hne hbdd).2 hb

end Settheory.Ch80
