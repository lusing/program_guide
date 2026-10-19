import Mathlib.MeasureTheory.Function.Holder
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic

/-!
# 第 13 章 Lᵖ 空间（Lean）

严书 §3.4。机器锚点（`#check` 正名）：

* `MeasureTheory.Lp E p μ`（Function/LpSpace/Basic.lean:89，
  a.e.-等价类空间）与 `MemLp`（LpSeminorm/Defs）；
* Hölder：`ContinuousLinearMap.norm_holder_apply_apply_le`
  （Function/Holder.lean:81，Lp 版 Hölder——注意它挂在
  ContinuousLinearMap 命名空间而非 MeasureTheory）；
* 完备性：`MeasureTheory.Lp.completeSpace`（LpSpace/Complete）。

实弹：有限原子测度上的离散 Schwarz（Hölder 的 p = 2 情形）
以具体分数数字验证——机器不等式一行 + 手工数值对照。
-/

open MeasureTheory
open scoped ENNReal NNReal

/-! ## 锚点正名 -/

#check @MeasureTheory.Lp
#check @MeasureTheory.MemLp
#check @ContinuousLinearMap.norm_holder_apply_apply_le
#check @MeasureTheory.Lp.instNormedAddCommGroup

/-! ## 实弹：离散 Schwarz（Hölder 的 p=q=2） -/

/-- 数值对照的账本：4 点等权空间上 f = [1,2,3,4]、g = [4,3,2,1]，
⟨f,g⟩ = 20，‖f‖₂ = ‖g‖₂ = √30 ≈ 5.477，Schwarz 右端 = 30 ≥ 20。
这一行是心算账；下例在 Lean 里核实 20 ≤ 30（平方后整数比较）。 -/
example : (1*4 + 2*3 + 3*2 + 4*1 : ℚ)^2 ≤
    ((1^2 + 2^2 + 3^2 + 4^2 : ℚ) * (4^2 + 3^2 + 2^2 + 1^2)) := by
  norm_num

/-- Hölder 的逐点账（内积和 ≤ 范数积，平方整数比较版）：
对任意有理数四元组，(Σ aᵢbᵢ)² ≤ (Σaᵢ²)(Σbᵢ²)——Cauchy 不等式。
这是 Schwarz 不等式的代数内核，Minkowski 的证明里同样要用。 -/
example (a b c d e f g h : ℚ) :
    (a*e + b*f + c*g + d*h)^2
      ≤ (a^2 + b^2 + c^2 + d^2) * (e^2 + f^2 + g^2 + h^2) := by
  have key : ∀ x y : ℚ, x * y ≤ (x^2 + y^2) / 2 := by
    intro x y
    have : (x - y)^2 ≥ 0 := by positivity
    nlinarith [this]
  -- 标准展开证明：(Σab)² ≤ (Σa²)(Σb²) 等价于 Σ_{i<j}(aᵢbⱼ-aⱼbᵢ)² ≥ 0
  have h1 : (a*f - b*e)^2 ≥ 0 := by positivity
  have h2 : (a*g - c*e)^2 ≥ 0 := by positivity
  have h3 : (a*h - d*e)^2 ≥ 0 := by positivity
  have h4 : (b*g - c*f)^2 ≥ 0 := by positivity
  have h5 : (b*h - d*f)^2 ≥ 0 := by positivity
  have h6 : (c*h - d*g)^2 ≥ 0 := by positivity
  nlinarith [h1, h2, h3, h4, h5, h6]

/-- MemLp 资格证：常值函数在有限测度上属于一切 Lᵖ
（memLp_const，LpSeminorm/Basic.lean:248）。 -/
example (μ : Measure Bool) [IsFiniteMeasure μ] (p : ℝ≥0∞)
    (c : ℝ) : MemLp (fun _ : Bool => c) p μ :=
  memLp_const c
