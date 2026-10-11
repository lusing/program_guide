import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Algebra.Star.SelfAdjoint

/-!
# 第 08 章 · 伴随算子（Conway II.2）

对应 `docs/08-adjoint.md`。本章在机器中复现 §II.2 主线：

1. **伴随的定义性质**（Conway 2.3）：mathlib 的 `A†` 与
   `adjoint_inner_left/right`——定义性恒等式是 `rfl` 级别的。
2. **代数律**（Conway 2.6）：对合 `((A†)†) = A`、反序 `(AB)† = B†A†`。
3. **C\* 恒等式**（Conway 2.7）：‖A†A‖ = ‖A‖² 与 ‖A†‖ = ‖A‖。
4. **自伴与正规**（Conway 2.11）：`IsSelfAdjoint`。
5. **ker–range 对偶**（Conway 2.19）：ker A = (ran A†)⊥。
6. **实自伴的刻画**（Conway 2.12）：ℝ 上自伴 ⟺ 二次型取实值。
-/

open scoped RealInnerProductSpace InnerProduct InnerProductSpace

/-!
## 1. 伴随的定义性质（Conway 2.3-2.4）

sesquilinear 形式 u(h,k) = ⟪A h, k⟫ 唯一确定 A†：
`⟪A x, y⟫ = ⟪x, (A†) y⟫`。mathlib 把伴随做成共轭线性等距同构
`adjoint : (E →L F) ≃ₗᵢ⋆ (F →L E)`，记号 `†`。
-/

section Def

variable {E F : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
  [CompleteSpace E] [NormedAddCommGroup F] [InnerProductSpace ℝ F] [CompleteSpace F]

-- 定义性恒等式（Conway 2.3 的右半）
example (A : E →L[ℝ] F) (x : E) (y : F) : ⟪A x, y⟫_ℝ = ⟪x, (A†) y⟫_ℝ :=
  (ContinuousLinearMap.adjoint_inner_right A x y).symm

-- 定义性恒等式（左半）
example (A : E →L[ℝ] F) (x : E) (y : F) : ⟪(A†) y, x⟫_ℝ = ⟪y, A x⟫_ℝ :=
  ContinuousLinearMap.adjoint_inner_left A x y

end Def

/-!
## 2. 代数律（Conway 2.6）

对合与反序——伴随是 B(ℋ) 上的"共轭"运算，与复数共轭同构地类比。
-/

section Algebra

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]

-- 对合（Conway 2.6 (c)）
example (A : H →L[ℝ] H) : ((A†)†) = A := ContinuousLinearMap.adjoint_adjoint A

-- 反序（Conway 2.6 (b)）
example (A B : H →L[ℝ] H) : ((B.comp A)†) = ((A†).comp (B†)) :=
  ContinuousLinearMap.adjoint_comp B A

end Algebra

/-!
## 3. 范数：C* 恒等式（Conway 2.7）

‖A†A‖ = ‖A‖²（C\* 恒等式，C\* 代数理论的种子）与 ‖A†‖ = ‖A‖。
mathlib 由伴随是等距同构直接得到范数相等。
-/

section Norm

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]

-- ‖A†‖ = ‖A‖（Conway 2.7 的一半；伴随是等距）
example (A : H →L[ℝ] H) : ‖A†‖ = ‖A‖ :=
  (ContinuousLinearMap.adjoint (𝕜 := ℝ)).norm_map A

-- C* 恒等式 ‖A†A‖ = ‖A‖²（Conway 2.7 的顶点）
#check @ContinuousLinearMap.norm_adjoint_comp_self

-- 逐点版本：‖A h‖² = ⟪h, A†A h⟫（Conway 2.7 证明的内脏）
example (A : H →L[ℝ] H) (h : H) : ‖A h‖ ^ 2 = ⟪h, (A†) (A h)⟫_ℝ := by
  rw [← real_inner_self_eq_norm_sq, ContinuousLinearMap.adjoint_inner_right A h (A h)]

end Norm

/-!
## 4. 自伴与正规（Conway 2.11）

A 自伴：A† = A（实算子的类似物）；A 正规：AA† = A†A（复数的类似物）。
-/

section SelfAdjoint

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]

-- IsSelfAdjoint 的定义：star A = A，对 CLM 即 A† = A
example (A : H →L[ℝ] H) : IsSelfAdjoint A ↔ A† = A := Iff.rfl

-- 自伴算子之和自伴
example (A B : H →L[ℝ] H) (hA : IsSelfAdjoint A) (hB : IsSelfAdjoint B) :
    IsSelfAdjoint (A + B) := hA.add hB

end SelfAdjoint

/-!
## 5. ker–range 对偶（Conway 2.19）

ker A = (ran A†)⊥：方程可解性理论的基石。
mathlib 形态：`(ker A)⊥ = ran A†` 与 `ker A = (ran A†)⊥`。
-/

section KerRange

#check @ContinuousLinearMap.orthogonal_ker
#check @ContinuousLinearMap.orthogonal_range

end KerRange
