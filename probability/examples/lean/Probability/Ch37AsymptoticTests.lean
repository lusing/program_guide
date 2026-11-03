import Mathlib.Tactic

/-!
# 第 37 章：三大统计量的代数关系与检验—置信集对偶
-/

namespace Ch37

/-- 标量约束的 Wald 二次型：`g²/v`。 -/
def scalarQuadratic (g v : ℚ) : ℚ := g ^ 2 / v

/-- Bernoulli 均值约束 `p=p0` 的 Wald 统计量。 -/
def bernoulliWald (n phat p0 : ℚ) : ℚ :=
  scalarQuadratic (phat - p0) (phat * (1 - phat) / n)

/-- Bernoulli 均值约束的 score/LM 统计量。 -/
def bernoulliScore (n phat p0 : ℚ) : ℚ :=
  scalarQuadratic (phat - p0) (p0 * (1 - p0) / n)

/-- 固定 `p0=1/2` 时，Wald 与 LM 只差方差估计的比值。 -/
theorem bernoulli_wald_score_relation (n phat : ℚ)
    (hn : n ≠ 0) (hp : phat ≠ 0) (hp1 : 1 - phat ≠ 0) :
    bernoulliScore n phat (1 / 2) =
      (phat * (1 - phat) / ((1 / 2 : ℚ) * (1 - 1 / 2))) *
        bernoulliWald n phat (1 / 2) := by
  simp only [bernoulliScore, bernoulliWald, scalarQuadratic]
  field_simp

/-- 第 37 章固定数据的 Wald 值。 -/
example : bernoulliWald 20 (3 / 5) (1 / 2) = 5 / 6 := by
  norm_num [bernoulliWald, scalarQuadratic]

/-- 同一数据的 LM 值。 -/
example : bernoulliScore 20 (3 / 5) (1 / 2) = 4 / 5 := by
  norm_num [bernoulliScore, scalarQuadratic]

/-- `K=16` 时 Wald 为 `45/4`。 -/
example : bernoulliWald 20 (4 / 5) (1 / 2) = 45 / 4 := by
  norm_num [bernoulliWald, scalarQuadratic]

/-- 绝对距离不超过临界半宽，表示参数属于置信集。 -/
def insideAbsoluteSet (estimate center halfWidth : ℚ) : Prop :=
  |estimate - center| ≤ halfWidth

/-- 绝对距离超过临界半宽，表示双侧检验拒绝。 -/
def rejectAbsolute (estimate center halfWidth : ℚ) : Prop :=
  halfWidth < |estimate - center|

/-- 检验与置信集是同一判定的两种读法。 -/
theorem confidence_test_duality (estimate center halfWidth : ℚ) :
    insideAbsoluteSet estimate center halfWidth ↔
      ¬ rejectAbsolute estimate center halfWidth := by
  simp only [insideAbsoluteSet, rejectAbsolute, not_lt]

/-- 第 37 章正态例中，`mu0=10` 不被拒绝，`mu0=14` 被拒绝。 -/
example : insideAbsoluteSet (23 / 2) 10 (2 : ℚ) := by
  norm_num [insideAbsoluteSet, abs_of_nonneg]

example : rejectAbsolute (23 / 2) 14 (2 : ℚ) := by
  norm_num [rejectAbsolute, abs_of_nonpos]

end Ch37
