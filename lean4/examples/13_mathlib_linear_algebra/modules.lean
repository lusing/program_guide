/-
文件: 13_mathlib_linear_algebra/modules.lean
描述: 模与向量空间，标量乘法
编译: lake build Lean4Tutorial.Examples.MathlibLinearAlgebra.Modules
依赖: Mathlib.LinearAlgebra.Basic
-/

import Mathlib.LinearAlgebra.Basic
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibLinearAlgebra.Modules

/-! # 模与向量空间（Modules and Vector Spaces） -/

-- 模是环上的代数结构，类似于向量空间，但标量来自环而不是域
-- 向量空间是域上的模
--
-- 在 Mathlib 中：
--   Module R M 表示 M 是环 R 上的模
--   当 R 是域时，这就是向量空间

/-! ## 模的定义 -/

-- 左 R-模 M 具有：
--   1. 加法：M × M → M
--   2. 标量乘法：R × M → M
-- 满足：
--   1. M 关于加法构成交换群
--   2. 标量乘法对加法分配：r • (x + y) = r • x + r • y
--   3. 标量乘法对标量加法分配：(r + s) • x = r • x + s • x
--   4. 标量乘法结合律：(r * s) • x = r • (s • x)
--   5. 单位元：1 • x = x

#check Module

variable (R : Type*) [Ring R] (M : Type*) [AddCommGroup M] [Module R M]

/-! ## 标量乘法的性质 -/

variable (r s : R) (x y : M)

-- 标量乘法对向量加法的分配律
theorem smul_add : r • (x + y) = r • x + r • y := by
  exact smul_add r x y

-- 标量乘法对标量加法的分配律
theorem add_smul : (r + s) • x = r • x + s • x := by
  exact add_smul r s x

-- 标量乘法的结合律
theorem mul_smul : (r * s) • x = r • (s • x) := by
  exact mul_smul r s x

-- 单位标量
theorem one_smul : (1 : R) • x = x := by
  exact one_smul R x

-- 零标量
theorem zero_smul : (0 : R) • x = 0 := by
  exact zero_smul R x

-- 标量乘零向量
theorem smul_zero : r • (0 : M) = 0 := by
  exact smul_zero r

-- 负标量
theorem neg_smul : (-r) • x = - (r • x) := by
  exact neg_smul r x

-- 标量乘负向量
theorem smul_neg : r • (-x) = - (r • x) := by
  exact smul_neg r x

/-! ## 向量空间 -/

-- 当标量集 K 是域时，模 K V 称为 K 上的向量空间
-- 向量空间中的元素称为向量

-- 实数向量空间
-- variable (V : Type*) [AddCommGroup V] [Module ℝ V]

-- 常见的向量空间：
--   1. ℝⁿ：n 维实向量空间
--   2. 函数空间：{f : X → ℝ}
--   3. 多项式空间
--   4. 矩阵空间

/-! ## 子模 -/

-- 子模是模的子集，对加法和标量乘法封闭
-- 在 Mathlib 中，Submodule R M 表示 M 的 R-子模

#check Submodule

-- 子模的性质：
--   1. 包含零向量
--   2. 对加法封闭
--   3. 对标量乘法封闭

-- 向量空间的子模称为子空间

-- 例子：
--   1. {0} 是子模（零子模）
--   2. M 本身是子模
--   3. 线性映射的核和像都是子模

/-! ## 生成子模 -/

-- 由集合 S 生成的子模是包含 S 的最小子模
-- 记作 Submodule.span R S

#check Submodule.span

-- 生成子模由 S 中元素的所有有限线性组合组成

/-! ## 线性无关 -/

-- 向量族 v_i 是线性无关的，如果
-- Σ c_i * v_i = 0 蕴含所有 c_i = 0

-- 线性无关 + 生成 = 基

/-! ## 基与维数 -/

-- 向量空间的基是一个线性无关且生成整个空间的向量组
-- 基的大小称为向量空间的维数

-- 在有限维向量空间中，所有基的大小相同
-- 这是维数的良定义性

/-! ## 模与向量空间的区别 -/

-- 模比向量空间更一般
-- 主要区别：
--   1. 模的标量来自环，向量空间的标量来自域
--   2. 模不一定有基（自由模才有基）
--   3. 模中线性无关的集合不一定能扩充为基
--   4. 模的维数概念更复杂

-- 例如：
--   ℤ-模就是交换群
--   有限生成交换群的结构定理是模论的经典结果

/-! ## 直和 -/

-- 两个模的直和 M ⊕ N 是由有序对 (m, n) 组成的模
-- 运算按分量进行

/-! ## 商模 -/

-- 给定子模 N ⊆ M，商模 M/N 是等价类的集合
-- 等价关系：m₁ ~ m₂ 当且仅当 m₁ - m₂ ∈ N

end Lean4Tutorial.Examples.MathlibLinearAlgebra.Modules
