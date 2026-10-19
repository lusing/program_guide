import Mathlib.MeasureTheory.Measure.Stieltjes

/-!
# 第 05 章 Lebesgue-Stieltjes 测度（Lean）

严书 §1.5。mathlib 的 `StieltjesFunction R`（单调 + 右连续的实函数）
打包结构，其 `measure` 给出 ℝ 上由分布函数诱导的 Lebesgue-Stieltjes
测度，核心公式是 `StieltjesFunction.measure_Ioc`：

  f.measure (Ioc a b) = ENNReal.ofReal (f b - f a)

原子测度（阶梯函数）与 Cantor 型奇异测度的数值实验在 julia/python
通道；`Monotone.stieltjesFunction`（取右极限的万能右连续化）见正文。
-/

open MeasureTheory

noncomputable def idStieltjes : StieltjesFunction ℝ where
  toFun := fun x => x
  mono' := monotone_id
  right_continuous' := fun _ => continuous_id.continuousWithinAt

/-- 恒等分布函数诱导的 LS 测度在 (a, b] 上恰为区间长度：
这就是 Lebesgue 测度的 Stieltjes 诞生地。 -/
example (a b : ℝ) : idStieltjes.measure (Set.Ioc a b) = ENNReal.ofReal (b - a) :=
  idStieltjes.measure_Ioc a b

/-- 具体数值：idStieltjes 诱导的测度给 (0, 1] 赋质量 1。 -/
example : idStieltjes.measure (Set.Ioc 0 1) = 1 := by
  rw [idStieltjes.measure_Ioc]
  simp only [idStieltjes]
  norm_num

/-- (0,1] 与 (2,3] 质量相等（平移不变性在区间层面直接读出）。 -/
example : idStieltjes.measure (Set.Ioc 0 1) = idStieltjes.measure (Set.Ioc 2 3) := by
  rw [idStieltjes.measure_Ioc, idStieltjes.measure_Ioc]
  simp only [idStieltjes]
  norm_num

/-- 质量的可加性：相邻区间拼接（需要 a ≤ b ≤ c——区间无序时 ofReal 负值
截断会让等式失效，这是初稿被机器抓住的陈述漏洞）。 -/
example (a b c : ℝ) (hab : a ≤ b) (hbc : b ≤ c) :
    idStieltjes.measure (Set.Ioc a b) + idStieltjes.measure (Set.Ioc b c)
      = idStieltjes.measure (Set.Ioc a c) := by
  rw [idStieltjes.measure_Ioc, idStieltjes.measure_Ioc, idStieltjes.measure_Ioc]
  simp only [idStieltjes]
  have h1 : ENNReal.ofReal ((b - a) + (c - b))
      = ENNReal.ofReal (b - a) + ENNReal.ofReal (c - b) :=
    ENNReal.ofReal_add (by linarith) (by linarith)
  have hsum : (c - a : ℝ) = (b - a) + (c - b) := by ring
  rw [hsum, ← h1]
