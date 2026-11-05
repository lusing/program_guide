import Mathlib.MeasureTheory.Covering.DensityTheorem
import Mathlib.MeasureTheory.Covering.Differentiation
import Mathlib.MeasureTheory.Measure.Stieltjes

/-!
# 第 58 章 测度的导数：Lebesgue 微分定理、有界变差与绝对连续（Lean）

胡书 §2.3 的机器侧：mathlib 在 `MeasureTheory.Covering` 里完整实现了
Vitali 族机器，三个主定理直接锚定——密度定理、微分定理、奇异测度
密度为零（书引理 2.3.1 的一般形式）。另配两条精确侧影：Lebesgue 测度
无原子（μ({a}) = F(a) − F(a−) 公式的全证）与单跳分布函数在跳点两侧
的区间账（左恒 1、右恒 0——上导数发散的有限影子）。
-/

open MeasureTheory
open scoped ENNReal Topology

/-! ## 三个定理锚点 -/

#check @IsUnifLocDoublingMeasure.ae_tendsto_measure_inter_div
-- 正文 58.7 密度定理：m(S ∩ B(x,r)) / m(B(x,r)) → 1_S(x)（S 内 a.e.）

#check @IsUnifLocDoublingMeasure.ae_tendsto_average_norm_sub
-- 正文 58.7 微分定理：‖f 的球平均 − f(x)‖₁ → 0（a.e.）

#check @VitaliFamily.ae_eventually_measure_zero_of_singular
-- 正文 58.4.1 引理 2.3.1 一般形式：ρ ⟂ μ ⟹ ρ(B(x,r))/μ(B(x,r)) → 0

#check @VitaliFamily.ae_tendsto_rnDeriv
-- 正文 58.1 的主角：测度比趋于 rnDeriv（Dμ = dμ_ac/dm）

/-! ## 原子公式全证：Lebesgue 测度无原子 -/

-- 原子公式（书注 1.4.3 的机器名）：μ({a}) = F(a) − F(a−)。
#check @StieltjesFunction.measure_singleton

/-- F = id（恒等分布函数）对应 Lebesgue 测度：每个单点原子质量为零
—— F 处处连续 ⟺ 无原子（正文 58.4：连续点判据的完全体）。 -/
example (a : ℝ) : StieltjesFunction.id.measure ({a} : Set ℝ) = 0 := by
  rw [StieltjesFunction.measure_singleton, StieltjesFunction.id_leftLim]
  simp

-- 区间公式 μ(a,b] = F(b) − F(a) 的机器名（书定理 1.4.2）：本章一切"区间账"的源头。
#check @StieltjesFunction.measure_Ioc

/-! ## 单跳分布：跳点两侧的精确判决 -/

/-- 单跳函数 f = 1_{x ≥ 1}（在 1 处跳 1），单调。 -/
private noncomputable def step1 (x : ℝ) : ℝ := if x < 1 then 0 else 1

private lemma step1_mono : Monotone step1 := by
  intro x y hxy
  by_cases hx : x < 1 <;> by_cases hy : y < 1 <;>
    simp [step1, hx, hy]; linarith

/-- 单跳分布函数（Stieltjes 函数化）：x ↦ rightLim step1 x。 -/
noncomputable def jump1 : StieltjesFunction ℝ := step1_mono.stieltjesFunction

/-- 求值引理：x < 1 处 jump1 = 0（(x,1) 上 step1 恒 0）。 -/
private lemma jump1_eval_lt (x : ℝ) (hx : x < 1) : jump1 x = 0 := by
  rw [jump1, Monotone.stieltjesFunction_eq]
  have hIoo : (Set.Ioo x 1 : Set ℝ) ∈ (𝓝[>] x) := Ioo_mem_nhdsGT hx
  refine rightLim_eq_of_tendsto (Filter.Tendsto.congr' ?_ tendsto_const_nhds)
  filter_upwards [hIoo] with y hy
  simp [step1, hy.2]

/-- 求值引理：x ≥ 1 处 jump1 = 1（(x,∞) ⊆ [1,∞) 上 step1 恒 1）。 -/
private lemma jump1_eval_ge (x : ℝ) (hx : ¬ x < 1) : jump1 x = 1 := by
  rw [jump1, Monotone.stieltjesFunction_eq]
  have hge : ∀ᶠ y in (𝓝[>] x), 1 ≤ y := by
    filter_upwards [self_mem_nhdsWithin] with y hy
    exact le_trans (not_lt.mp hx) hy.le
  refine rightLim_eq_of_tendsto (Filter.Tendsto.congr' ?_ tendsto_const_nhds)
  filter_upwards [hge] with y hy
  have hy' : ¬ (y < 1) := not_lt.mpr hy
  simp [step1, hy']

/-- **跳点左侧**：μ(1−h, 1] = 1 对一切 0 < h ——含原子的区间质量
恒为 1，区间长度 → 0 时比值 → ∞（上导数发散的精确影子）。 -/
example (h : ℝ) (h0 : 0 < h) :
    jump1.measure (Set.Ioc (1 - h) 1) = 1 := by
  rw [StieltjesFunction.measure_Ioc, jump1_eval_ge 1 (by linarith),
    jump1_eval_lt (1 - h) (by linarith)]
  simp

/-- **跳点右侧**：μ(1, 1+h] = 0 ——越过原子后再无质量（右连续性把
质量记在左端点上）。一侧恒 1、一侧恒 0：区间比值在原子点不收敛，
这正是"分布函数在跳点不可微"的测度语言。 -/
example (h : ℝ) (h0 : 0 < h) :
    jump1.measure (Set.Ioc 1 (1 + h)) = 0 := by
  rw [StieltjesFunction.measure_Ioc, jump1_eval_ge (1 + h) (by linarith),
    jump1_eval_ge 1 (by linarith)]
  simp
