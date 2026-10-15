import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.FunctionalSpaces.SobolevInequality
import Mathlib.Analysis.Distribution.Sobolev

/-!
# 第 72 章 · Poincaré 不等式与 Sobolev 嵌入（工科篇 6.1-6.2）

书的两条主线：
- Friedrichs/Poincaré 不等式（6.1.1 + 6.1.6 + 6.2.3）：
  零边界条件补偿"函数本身"的范数——‖u‖_{L²} ≤ C‖∇u‖_{L²}；
- 嵌入定理（6.2.5-6.2.7）：W^{k,p} 连续（甚至紧）地进入更低正则性
  的空间；紧嵌入的钥匙是平移估计（6.1.7，Kolmogorov-Riesz 判据）。

本章 Lean 通道：
1. **一维 Morrey 型嵌入全证**（W^{1,1} → C⁰）：C¹ 函数的振幅被导数
   绝对值的积分控制——嵌入定理在 n=1、p=1 的化身，同时正是 6.1.7
   平移估计 / Arzelà-Ascoli 等度连续性的原型；
2. 官方 Sobolev 不等式锚点（Gagliardo-Nirenberg 路线）巡礼。

Poincaré 本身的初等证明（书的零延拓 + Schwarz 平板论证）在文档
正文中全篇展开；最优常数 1/π²（一维谱）由 Julia/Python 数值承载。
-/

open MeasureTheory intervalIntegral Set

/-! ## 第一层：一维 Morrey 型嵌入（W^{1,1} → C⁰） -/

/-- **一维 Morrey 不等式的 L¹ 形态**（书 6.2.6 在 p=1 的化身）：
f 在 ℝ 上处处有导数 f'（区间 [a,b] 上可积），a ≤ b，则两点振幅被
导数绝对值的积分控制。证明 = 微积分基本定理 + 积分三角不等式。 -/
theorem abs_sub_le_integral_abs_deriv {f f' : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hderiv : ∀ x, HasDerivAt f (f' x) x) (hint : IntervalIntegrable f' volume a b) :
    |f b - f a| ≤ ∫ x in a..b, |f' x| := by
  have hint' : IntervalIntegrable (deriv f) volume a b := by
    refine (intervalIntegrable_congr ?_).2 hint
    exact fun _ _ => (hderiv _).deriv
  have hFTC : ∫ y in a..b, deriv f y = f b - f a :=
    intervalIntegral.integral_deriv_eq_sub (fun x _ => (hderiv x).differentiableAt) hint'
  have hchange : ∫ x in a..b, |deriv f x| = ∫ x in a..b, |f' x| :=
    intervalIntegral.integral_congr (fun _ _ => congrArg abs ((hderiv _).deriv))
  calc |f b - f a|
      = |∫ x in a..b, deriv f x| := by rw [hFTC]
    _ ≤ ∫ x in a..b, |deriv f x| := abs_integral_le_integral_abs hab
    _ = ∫ x in a..b, |f' x| := hchange

/-- **零边界版（一维 Poincaré 的逐点形态）**：f(0) = 0、t ∈ [0,1]
⟹ |f t| ≤ ∫₀¹ |f'|。振幅在整个区间上一致受控——上界与 t 无关。 -/
theorem supnorm_le_l1_deriv {f f' : ℝ → ℝ}
    (hderiv : ∀ x, HasDerivAt f (f' x) x)
    (hint : IntervalIntegrable f' volume 0 1)
    -- |f'| 的区间可积性通常由 f' 的推出；本树（4.33 快照）暂缺
    -- IntervalIntegrable 的 abs 传递引理，故直接作为假设
    (hintabs : IntervalIntegrable (fun x => |f' x|) volume 0 1) (h0 : f 0 = 0)
    {t : ℝ} (ht0 : 0 ≤ t) (ht1 : t ≤ 1) :
    |f t| ≤ ∫ x in 0..1, |f' x| := by
  have hint_t : IntervalIntegrable (fun x => |f' x|) volume 0 t := by
    refine hintabs.mono_set ?_
    rw [uIcc_of_le ht0, uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)]
    exact Icc_subset_Icc (le_refl _) ht1
  have hint_plain : IntervalIntegrable f' volume 0 t := by
    refine hint.mono_set ?_
    rw [uIcc_of_le ht0, uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)]
    exact Icc_subset_Icc (le_refl _) ht1
  have h1 : |f t - f 0| ≤ ∫ x in 0..t, |f' x| :=
    abs_sub_le_integral_abs_deriv ht0 hderiv hint_plain
  rw [h0, sub_zero] at h1
  have hint_t1 : IntervalIntegrable (fun x => |f' x|) volume t 1 := by
    refine hintabs.mono_set ?_
    rw [uIcc_of_le ht1, uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)]
    exact Icc_subset_Icc ht0 (le_refl _)  -- Icc t 1 ⊆ Icc 0 1：左端 0 ≤ t
  have hsplit := intervalIntegral.integral_add_adjacent_intervals
    (f := fun x => |f' x|) (μ := volume) (a := (0 : ℝ)) (b := t) (c := 1) hint_t hint_t1
  have hnn : 0 ≤ ∫ x in t..1, |f' x| :=
    intervalIntegral.integral_nonneg (by linarith) (fun u _ => abs_nonneg _)
  have h2 : ∫ x in 0..t, |f' x| ≤ ∫ x in 0..1, |f' x| := by
    rw [← hsplit]
    exact le_add_of_nonneg_right hnn
  exact le_trans h1 h2

/-! ## 第二层：官方 Sobolev 嵌入锚点 -/

-- Gagliardo-Nirenberg-Sobolev 不等式（一阶导数版）：u 的 L^{n/(n-1)}
-- 范数被 ∇u 的 L¹ 范数控制——书 6.2.6 临界情形 kp > n 的机器对应物
#check @MeasureTheory.eLpNorm_le_eLpNorm_fderiv_one

-- 内积版（带常数）与等式追踪版
#check @MeasureTheory.eLpNorm_le_eLpNorm_fderiv_of_eq_inner

-- Sobolev 成员资格对正则性参数单调（W^{s,2} ⊂ W^{s',2} 型嵌入）
#check @TemperedDistribution.MemSobolev.mono
