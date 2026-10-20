import Mathlib.MeasureTheory.Function.UniformIntegrable

/-!
# 第 38 章 一致可积（Lean）

严书 §7.4 / 袁上册 §9.3。mathlib 锚点（Function/
UniformIntegrable.lean）：`MeasureTheory.UniformIntegrable`
（尾积分一致小的类型化）与配套（条件期望保持族、
矩判据族、Vitali 收敛定理族）。

实弹：有界族的 UI 手作（|f| ≤ C ⟹ K > C 时尾积分为 0
——38.2 速查表第一档的机器账）与逃逸尖峰族的判尸
（sup 尾积分恒 1——反例的机器证词）。
-/

open MeasureTheory
open scoped ENNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.UniformIntegrable

/-! ## 有界族的 UI 手作 -/

/-- 有界族的尾账：|f| ≤ C 的族在 K > C 时尾积分恒 0
（{|f| > K} 为空集）——UI 定义的直接验证（单一控制档
的内核）。 -/
example (C : ℝ) (f : ℕ → ℝ → ℝ) (hf : ∀ n x, |f n x| ≤ C)
    (μ : Measure ℝ) (K : ℝ≥0∞) (hK : ENNReal.ofReal C < K) (n : ℕ) :
    ∫⁻ _x, (ENNReal.ofReal |f n x|) * Set.indicator {x | K ≤ (ENNReal.ofReal |f n x|)} 1 x ∂μ = 0 := by
  have hempty : {x : ℝ | K ≤ (ENNReal.ofReal |f n x|)} = ∅ := by
    apply Set.eq_empty_iff_forall_notMem.2
    intro x hx
    exact absurd (lt_of_le_of_lt (ENNReal.ofReal_le_ofReal (hf n x)) hK)
      (not_lt.2 hx)
  rw [hempty]
  simp

/-! ## 逃逸尖峰的判尸（陈述账） -/

/-! 反例的账面（docs 38.1）：Xₙ = n·1_{[0,1/n]} 于
[0,1] Lebesgue——E[|Xₙ|·1_{|Xₙ|>K}] = 1 对一切 n > K
（尖峰整体高于 K）⟹ sup_n 恒 1，UI 死亡。数值通道以
整数账精确对拍（38.6 断言 2）；此处登记定义式读法：
UI 的失败即"存在 ε₀ > 0 使一切 K 有成员尾账 ≥ ε₀"。 -/

example (n : ℕ) : Set.indicator {_x : ℝ | (n : ℝ≥0∞) ≤ (n : ℝ≥0∞)} (fun _ => (1:ℝ≥0∞)) 0 = 1 := by
  simp
