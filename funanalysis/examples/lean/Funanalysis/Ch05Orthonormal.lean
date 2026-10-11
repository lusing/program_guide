import Mathlib.Analysis.InnerProductSpace.Orthonormal
import Mathlib.Analysis.InnerProductSpace.GramSchmidtOrtho
import Mathlib.Analysis.InnerProductSpace.PiL2

/-!
# 第 05 章 · 标准正交集与基（Conway I.4）

对应 `docs/05-orthonormal-bases.md`。本章在机器中复现 §I.4 主线：

1. **Orthonormal** 谓词与 Fourier 系数（Conway 4.1）。
2. **Bessel 不等式**（Conway 4.8）：部分和的能量不超过全空间能量。
3. **Gram-Schmidt 正交化**（Conway 4.6）：mathlib 的 `gramSchmidt`。
4. **基的扩张**（Conway 4.2，Zorn 的用武之地）。
5. **OrthonormalBasis**：表示公式、Parseval 恒等式（Conway 4.13 的
   Fintype 版与 HilbertBasis 无穷版）。
6. **维数**（Conway 4.14-4.16）：任意两基同势。
-/

open scoped RealInnerProductSpace InnerProductSpace

/-!
## 1. 标准正交谓词与 Fourier 系数

`Orthonormal ℝ v`：v 的取值两两正交且都是单位向量。
对标准正交系，向量 h 的 Fourier 系数是 ⟪v i, h⟫。
-/

section Orthonormal

variable {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]

-- 标准正交系的定义形态（实情形）
#check @Orthonormal

-- 对标准正交系中不同指标，内积为零（定义的直接展开）
example (v : ℕ → F) (hv : Orthonormal ℝ v) (i j : ℕ) (hij : i ≠ j) :
    ⟪v i, v j⟫_ℝ = 0 :=
  hv.inner_eq_zero hij

-- 每个基向量是单位向量（Orthonormal 是"单位性 ∧ 两两正交"的合取）
example (v : ℕ → F) (hv : Orthonormal ℝ v) (i : ℕ) : ‖v i‖ = 1 := hv.1 i

end Orthonormal

/-!
## 2. Bessel 不等式（Conway 4.8）

对标准正交系 v 与任意 h：
`∑' i, |⟪v i, h⟫|² ≤ ‖h‖²`（有限部分和版本即 Conway 4.8 原文）。
-/

section Bessel

variable {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]

-- 有限版本的 Bessel（Conway 4.8：部分和 ≤ ‖h‖²；实数域上 ‖⟪v i, h⟫‖² = ⟪v i, h⟫²）
example (v : ℕ → F) (hv : Orthonormal ℝ v) (h : F) (s : Finset ℕ) :
    ∑ i ∈ s, ‖⟪v i, h⟫_ℝ‖ ^ 2 ≤ ‖h‖ ^ 2 :=
  hv.sum_inner_products_le h

-- 无穷版本：级数收敛且不超过 ‖h‖²
example (v : ℕ → F) (hv : Orthonormal ℝ v) (h : F) :
    ∑' i, ‖⟪v i, h⟫_ℝ‖ ^ 2 ≤ ‖h‖ ^ 2 :=
  hv.tsum_inner_products_le h

end Bessel

/-!
## 3. Gram-Schmidt 正交化（Conway 4.6）

线性无关组 (f i) 产生标准正交组 (gramSchmidtNormed f)，
且前 n 项生成的不减子空间链相同。
-/

section GramSchmidt

open Module

variable {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]

-- gramSchmidtNormed 的标准正交性（Conway 4.6 的机器形态；需线性无关假设）
example (f : ℕ → F) (h₀ : LinearIndependent ℝ f) :
    Orthonormal ℝ (InnerProductSpace.gramSchmidtNormed ℝ f) :=
  InnerProductSpace.gramSchmidtNormed_orthonormal h₀

end GramSchmidt

/-!
## 4. 基的扩张与存在（Conway 4.2）

任一标准正交组可扩张为基——Conway 用 Zorn 引理。mathlib 在有限维给出
扩张定理；无穷维的完全对应物由第 06 章的 `HilbertBasis`（经
`mkOfOrthogonalEqBot`）承载，其存在性同样走极大性论证。
-/

section Extension

-- 有限维：标准正交组可扩张为 OrthonormalBasis（Conway 4.2 的有限维形态）
#check @Orthonormal.exists_orthonormalBasis_extension

end Extension

/-!
## 5. OrthonormalBasis：表示与 Parseval（Conway 4.13）

有限指标集上的 OrthonormalBasis 给出完全的坐标化：
表示公式 `∑ i, ⟪b i, x⟫ • b i = x`，内积公式，以及
**Parseval 恒等式** `∑ i, |⟪b i, x⟫|² = ‖x‖²`。
-/

section Parseval

variable {ι : Type*} [Fintype ι] [DecidableEq ι]
  {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]

-- 表示公式（Conway 4.13 (b)：Fourier 级数回到自身）
example (b : OrthonormalBasis ι ℝ F) (x : F) : ∑ i, ⟪b i, x⟫_ℝ • b i = x :=
  b.sum_repr' x

-- 内积的坐标公式（Conway 4.13 (d)：内积 = 系数乘积之和）
example (b : OrthonormalBasis ι ℝ F) (x y : F) :
    ∑ i, ⟪x, b i⟫_ℝ * ⟪b i, y⟫_ℝ = ⟪x, y⟫_ℝ :=
  b.sum_inner_mul_inner x y

-- Parseval 恒等式（Conway 4.13 (e) 的有限版；实数域上 ‖⟪b i, x⟫‖² = ⟪b i, x⟫²）
example (b : OrthonormalBasis ι ℝ F) (x : F) :
    ∑ i, ‖⟪x, b i⟫_ℝ‖ ^ 2 = ‖x‖ ^ 2 :=
  b.sum_sq_norm_inner_left x

end Parseval

/-!
## 6. 具体例子：ℝ³ 的标准基是 OrthonormalBasis（Conway 4.4）

mathlib 直接把 EuclideanSpace 的标准基打包成 OrthonormalBasis。
-/

noncomputable example : OrthonormalBasis (Fin 3) ℝ (EuclideanSpace ℝ (Fin 3)) :=
  EuclideanSpace.basisFun (Fin 3) ℝ

/-!
## 7. 维数良定义（Conway 4.14：任意两基同势）

mathlib 中 Hilbert 空间的"维数"由 HilbertBasis（见第 06 章）承载：
`HilbertBasis.repr` 是到 ℓ²(ι) 的等距同构，两个基给出同势的指标集
（其证明正是 Conway 4.14 的思路：互相嵌入强制等势）。这里确认
EuclideanSpace 的基给出正确的有限维数。
-/

example : Module.finrank ℝ (EuclideanSpace ℝ (Fin 3)) = 3 := by simp
