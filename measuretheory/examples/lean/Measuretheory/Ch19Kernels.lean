import Mathlib.Probability.Kernel.Composition.CompMap
import Mathlib.Probability.Kernel.Composition.Prod

/-!
# 第 19 章 转移核（Lean）

严书 §4.3。mathlib 锚点（Probability/Kernel/ 文件族）：`Kernel`
（α 上的测度值函数 + 内置可测性）、复合 `Kernel.comp`（记号
`∘ₖ`，Composition/Comp.lean）、单位元 `Kernel.id` 与单位律
`id_comp`/`comp_id`（Comp.lean:79-84）、dirac 型核
`Kernel.deterministic`（Basic.lean:59，逐点账 `deterministic_apply`
:63 参数序=可测性在前）、复合捷径 `deterministic_comp_
deterministic`（CompMap.lean:50——确定性核的复合 = 映射的
复合）、并排 `Kernel.prod`。

实弹：单位律两件、布尔翻转核两次复合 = 恒等（两步转移的
矩阵乘方原文）。
-/

open MeasureTheory ProbabilityTheory

/-! ## 锚点正名 -/

#check @Kernel.comp
#check @Kernel.id
#check @Kernel.id_comp
#check @Kernel.comp_id
#check @Kernel.comp_apply
#check @Kernel.deterministic
#check @ProbabilityTheory.Kernel.deterministic_comp_deterministic
#check @Kernel.prod

/-! ## 单位元与单位律 -/

/-- dirac 型核：deterministic f hf 把每个 x 送到 δ_{f(x)}——
"确定性映射"的核化（谱系表的"完全确定"端点）。 -/
example (f : ℝ → ℝ) (hf : Measurable f) (x : ℝ) :
    Kernel.deterministic f hf x = Measure.dirac (f x) :=
  Kernel.deterministic_apply hf x

/-- 单位律左：id ∘ₖ κ = κ（"先恒等再走"= 原地踏步）。 -/
example (κ : Kernel ℝ ℝ) : Kernel.id ∘ₖ κ = κ := Kernel.id_comp κ

/-- 单位律右：κ ∘ₖ id = κ。 -/
example (κ : Kernel ℝ ℝ) : κ ∘ₖ Kernel.id = κ := Kernel.comp_id κ

/-! ## 两步转移的显式账 -/

/-- 布尔翻转核：κnot = deterministic not。 -/
noncomputable def κnot : Kernel Bool Bool :=
  Kernel.deterministic (fun b => !b) (by fun_prop)

/-- **确定性核的复合 = 映射的复合**（CompMap.lean:50）：两步
确定性转移就是走两次函数——核复合在"完全确定"端退化为
函数复合，谱系表的端点行为。 -/
example : (κnot : Kernel Bool Bool) ∘ₖ κnot
    = Kernel.deterministic (fun b => !(!b)) (by fun_prop) :=
  Kernel.deterministic_comp_deterministic (by fun_prop) (by fun_prop)

/-- 两次翻转 = 恒等核：复合账 + not_not + 逐集账，ext 收口。 -/
example : (κnot : Kernel Bool Bool) ∘ₖ κnot = Kernel.id := by
  have h : (κnot : Kernel Bool Bool) ∘ₖ κnot
      = Kernel.deterministic (fun b => !(!b)) (by fun_prop) :=
    Kernel.deterministic_comp_deterministic (by fun_prop) (by fun_prop)
  rw [h]
  ext a s
  simp [Kernel.deterministic_apply, Kernel.id_apply, Bool.not_not]
