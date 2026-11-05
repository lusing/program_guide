import Mathlib.Basic.Real.Basic
import Mathlib.Basic.Complex.Basic
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic

/-!
# 第 06 章 复数与欧几里得空间

对应原书第 6 章：复数作为实数有序对的构造、虚数单位 i、共轭与模，
以及欧几里得空间 ℝᵏ 的内积、范数和 Cauchy–Schwarz 不等式。
mathlib 里 ℂ 是 `Complex`（`ℝ × ℝ` 的结构包装），ℝᵏ 是
`EuclideanSpace ℝ (Fin k)`，即带 2-范数的有限函数类型。
-/

namespace Realanalysis.Ch06

open Complex

open scoped ComplexConjugate InnerProductSpace

/-! ## 6.1 复数：实数的有序对 -/

/-- 每个复数都由实部与虚部唯一确定（复数就是有序对）。 -/
example (z : ℂ) : Complex.mk z.re z.im = z := Complex.ext rfl rfl

/-- 虚数单位 i：实部 0、虚部 1 的有序对。 -/
example : I = Complex.mk 0 1 := rfl

/-- i² = -1：复数全部代数的出发点。 -/
example : I * I = -1 := I_mul_I

/-- 乘法公式 (a + bi)(c + di) = (ac - bd) + (ad + bc)i。
    实部与虚部分别用 mul_re / mul_im 展开，剩下的是环恒等式。 -/
example (a b c d : ℝ) :
    (a + b * I) * (c + d * I) = (a * c - b * d) + (a * d + b * c) * I := by
  apply Complex.ext
  · simp [mul_re]
  · simp [mul_im]

/-- ℂ 本身是域：逆元的构造与全部域公理都由实例给出。
    实例依赖实数的非可计算构造，所以声明本身也是 noncomputable。 -/
noncomputable example : Field ℂ := inferInstance

/-- i 不是实数：它的虚部是 1，而实数嵌入的虚部总是 0。 -/
example : I.im = 1 := rfl

/-! ## 6.2 共轭与模 -/

/-- i 的共轭是 -i。 -/
example : conj I = -I := conj_I

/-- z 乘自己的共轭等于模平方（作为复数嵌入实数轴）。
    这正是逆元公式 z⁻¹ = conj z / normSq z 的来源。 -/
example (z : ℂ) : z * conj z = normSq z := mul_conj z

/-- 模平方的坐标公式：a² + b²。 -/
example (a b : ℝ) : normSq (Complex.mk a b) = a ^ 2 + b ^ 2 := by
  rw [normSq_mk]; ring

/-- i 的模平方是 1：i 落在单位圆上。 -/
example : normSq I = 1 := normSq_I

/-- 范数与模平方的关系：‖z‖² = normSq z。 -/
example (z : ℂ) : ‖z‖ ^ 2 = normSq z := (Complex.normSq_eq_norm_sq z).symm

/-- 经典勾股例子：3 + 4i 的模是 5。先算模平方得 25，
    范数非负，所以范数只能是正平方根 5。 -/
example : ‖(3 + 4 * I : ℂ)‖ = 5 := by
  have hz : (3 + 4 * I : ℂ) = Complex.mk (3 : ℝ) 4 := by
    simp [Complex.ext_iff]
  have h2 : ‖(3 + 4 * I : ℂ)‖ ^ 2 = 25 := by
    rw [← Complex.normSq_eq_norm_sq, hz, normSq_mk]
    norm_num
  nlinarith [norm_nonneg (3 + 4 * I : ℂ)]

/-! ## 6.3 欧几里得空间 ℝ²：内积与范数 -/

abbrev R2 := EuclideanSpace ℝ (Fin 2)

/-- 内积的坐标公式：对应分量相乘再求和。 -/
example (x y : R2) : ⟪x, y⟫_ℝ = ∑ i : Fin 2, x i * y i := by
  simp only [PiLp.inner_apply, Real.inner_apply]

/-- 范数平方的坐标公式：各分量平方和。实数的范数是绝对值，
    绝对值的平方等于自身平方。 -/
example (x : R2) : ‖x‖ ^ 2 = ∑ i : Fin 2, (x i) ^ 2 := by
  rw [EuclideanSpace.norm_sq_eq]
  simp [Fin.sum_univ_succ]

/-- 具体向量：x = (1, 2)，y = (3, 4)。EuclideanSpace 是函数类型的
    2-范数包装，用 WithLp.toLp 把普通有限向量装进去。 -/
def x : R2 := WithLp.toLp 2 ![1, 2]
def y : R2 := WithLp.toLp 2 ![3, 4]

/-- 内积 ⟨x, y⟩ = 1·3 + 2·4 = 11。 -/
example : ⟪x, y⟫_ℝ = 11 := by
  rw [PiLp.inner_apply]
  simp [x, y, WithLp.ofLp_toLp, Fin.sum_univ_succ]
  norm_num

/-- 范数平方：‖x‖² = 5，‖y‖² = 25。 -/
example : ‖x‖ ^ 2 = 5 := by
  rw [EuclideanSpace.norm_sq_eq]
  simp [x, WithLp.ofLp_toLp, Fin.sum_univ_succ]
  norm_num

example : ‖y‖ ^ 2 = 25 := by
  rw [EuclideanSpace.norm_sq_eq]
  simp [y, WithLp.ofLp_toLp, Fin.sum_univ_succ]
  norm_num

/-! ## 6.4 Cauchy–Schwarz 不等式 -/

/-- 一般形式（任意有限维实内积空间）：内积平方不超过两个范数平方之积。 -/
example (u v : EuclideanSpace ℝ (Fin 5)) :
    ⟪u, v⟫_ℝ ^ 2 ≤ ‖u‖ ^ 2 * ‖v‖ ^ 2 := by
  simpa [sq, real_inner_self_eq_norm_sq] using real_inner_mul_inner_self_le u v

/-- 绝对值形式：|⟨u, v⟩| ≤ ‖u‖·‖v。 -/
example (u v : R2) : |⟪u, v⟫_ℝ| ≤ ‖u‖ * ‖v‖ := abs_real_inner_le_norm u v

/-- 在 x = (1,2)、y = (3,4) 上核对：11² = 121 ≤ 5·25 = 125。 -/
example : ⟪x, y⟫_ℝ ^ 2 ≤ ‖x‖ ^ 2 * ‖y‖ ^ 2 := by
  have hi : ⟪x, y⟫_ℝ = 11 := by
    rw [PiLp.inner_apply]
    simp [x, y, WithLp.ofLp_toLp, Fin.sum_univ_succ]
    norm_num
  have hx : ‖x‖ ^ 2 = 5 := by
    rw [EuclideanSpace.norm_sq_eq]
    simp [x, WithLp.ofLp_toLp, Fin.sum_univ_succ]
    norm_num
  have hy : ‖y‖ ^ 2 = 25 := by
    rw [EuclideanSpace.norm_sq_eq]
    simp [y, WithLp.ofLp_toLp, Fin.sum_univ_succ]
    norm_num
  rw [hi, hx, hy]
  norm_num

/-- Lagrange 恒等式的二维缺口：(ad - bc)² = ‖x‖²‖y‖² - ⟨x,y⟩²。
    这里 (1·4 - 2·3)² = 4，恰为 125 - 121。C-S 之所以成立，
    是因为左边是一个平方，不可能为负。 -/
example : (1 * 4 - 2 * 3 : ℝ) ^ 2 = ‖x‖ ^ 2 * ‖y‖ ^ 2 - ⟪x, y⟫_ℝ ^ 2 := by
  have hi : ⟪x, y⟫_ℝ = 11 := by
    rw [PiLp.inner_apply]
    simp [x, y, WithLp.ofLp_toLp, Fin.sum_univ_succ]
    norm_num
  have hx : ‖x‖ ^ 2 = 5 := by
    rw [EuclideanSpace.norm_sq_eq]
    simp [x, WithLp.ofLp_toLp, Fin.sum_univ_succ]
    norm_num
  have hy : ‖y‖ ^ 2 = 25 := by
    rw [EuclideanSpace.norm_sq_eq]
    simp [y, WithLp.ofLp_toLp, Fin.sum_univ_succ]
    norm_num
  rw [hi, hx, hy]
  norm_num

/-- 三角不等式（C-S 的直接推论，库中已是一般范数定理）：
    ‖u + v‖ ≤ ‖u‖ + ‖v‖。 -/
example (u v : R2) : ‖u + v‖ ≤ ‖u‖ + ‖v‖ := norm_add_le u v

/-- 欧几里得距离就是差向量的范数。 -/
example (u v : R2) : dist u v = ‖u - v‖ := rfl

end Realanalysis.Ch06
