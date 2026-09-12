/-
文件: 13_mathlib_linear_algebra/linear_maps.lean
描述: 线性映射，恒等，复合
编译: lake build Lean4Tutorial.Examples.MathlibLinearAlgebra.LinearMaps
依赖: Mathlib.LinearAlgebra.LinearMap.Basic
-/

import Mathlib.LinearAlgebra.LinearMap.Basic
import Mathlib.Data.Real.Basic

namespace Lean4Tutorial.Examples.MathlibLinearAlgebra.LinearMaps

/-! # 线性映射（Linear Maps） -/

-- 线性映射是保持模/向量空间结构的函数
-- f : M → N 是线性映射，如果：
--   1. f(x + y) = f(x) + f(y)  （保持加法）
--   2. f(r • x) = r • f(x)    （保持标量乘法）
--
-- 在 Mathlib 中，线性映射类型为 M →ₗ[R] N

/-! ## 线性映射的定义 -/

-- LinearMap R M N 或 M →ₗ[R] N
-- 表示从 M 到 N 的 R-线性映射

#check LinearMap

variable (R : Type*) [Ring R]
variable (M N P : Type*) [AddCommGroup M] [AddCommGroup N] [AddCommGroup P]
variable [Module R M] [Module R N] [Module R P]

/-! ## 线性映射的性质 -/

variable (f : M →ₗ[R] N) (x y : M) (r : R)

-- 保持加法
theorem map_add : f (x + y) = f x + f y := by
  exact map_add f x y

-- 保持标量乘法
theorem map_smul : f (r • x) = r • f x := by
  exact map_smul f r x

-- 保持零向量
theorem map_zero : f 0 = 0 := by
  exact map_zero f

-- 保持负向量
theorem map_neg : f (-x) = -f x := by
  exact map_neg f x

-- 保持减法
theorem map_sub : f (x - y) = f x - f y := by
  exact map_sub f x y

-- 保持线性组合
theorem map_linear_comb (a b : R) (x y : M) :
    f (a • x + b • y) = a • f x + b • f y := by
  simp [map_add, map_smul]

/-! ## 恒等映射 -/

-- 恒等映射 id : M → M
-- id(x) = x

def id_map : M →ₗ[R] M := LinearMap.id

theorem id_apply (x : M) : (id_map R M) x = x := by
  rfl

-- 恒等映射是线性的
#check (LinearMap.id : M →ₗ[R] M)

/-! ## 线性映射的复合 -/

-- 如果 f : M → N 和 g : N → P 都是线性映射，
-- 则它们的复合 g ∘ f : M → P 也是线性映射

def comp (g : N →ₗ[R] P) (f : M →ₗ[R] N) : M →ₗ[R] P :=
  LinearMap.comp g f

theorem comp_apply (g : N →ₗ[R] P) (f : M →ₗ[R] N) (x : M) :
    (comp R M N P g f) x = g (f x) := by
  rfl

-- 复合的结合律
theorem comp_assoc (f : M →ₗ[R] N) (g : N →ₗ[R] P) (Q : Type*) [AddCommGroup Q] [Module R Q]
    (h : P →ₗ[R] Q) :
    LinearMap.comp h (LinearMap.comp g f) = LinearMap.comp (LinearMap.comp h g) f := by
  ext x
  simp

-- 恒等映射是复合的单位元
theorem comp_id_left (f : M →ₗ[R] N) :
    LinearMap.comp f (LinearMap.id : M →ₗ[R] M) = f := by
  ext x
  simp

theorem comp_id_right (f : M →ₗ[R] N) :
    LinearMap.comp (LinearMap.id : N →ₗ[R] N) f = f := by
  ext x
  simp

/-! ## 线性映射的运算 -/

-- 线性映射的加法
def add_maps (f g : M →ₗ[R] N) : M →ₗ[R] N := f + g

theorem add_maps_apply (f g : M →ₗ[R] N) (x : M) :
    (add_maps R M N f g) x = f x + g x := by
  rfl

-- 线性映射的标量乘法
def smul_map (r : R) (f : M →ₗ[R] N) : M →ₗ[R] N := r • f

theorem smul_map_apply (r : R) (f : M →ₗ[R] N) (x : M) :
    (smul_map R M N r f) x = r • f x := by
  rfl

-- 所有从 M 到 N 的线性映射构成一个 R-模
-- 即 (M →ₗ[R] N) 本身是 R-模

/-! ## 核与像 -/

-- 线性映射 f 的核（kernel）：被 f 映到 0 的向量集合
-- ker(f) = {x ∈ M | f(x) = 0}

#check LinearMap.ker

-- 核是定义域的子模
theorem ker_isSubmodule : (LinearMap.ker f : Set M) = {x | f x = 0} := by
  ext x
  simp [LinearMap.mem_ker]

-- 线性映射 f 的像（image/range）：f 所能取到的值的集合
-- im(f) = {f(x) | x ∈ M}

#check LinearMap.range

-- 像是陪域的子模
theorem range_isSubmodule : LinearMap.range f = f '' Set.univ := by
  ext y
  simp [LinearMap.mem_range]

/-! ## 单射、满射、双射 -/

-- 线性映射是单射当且仅当它的核是零子空间
theorem inj_iff_ker_eq_bot :
    Function.Injective f ↔ LinearMap.ker f = ⊥ := by
  exact LinearMap.ker_eq_bot'

-- 线性映射是满射当且仅当它的像是整个空间
theorem surj_iff_range_eq_top :
    Function.Surjective f ↔ LinearMap.range f = ⊤ := by
  exact?

-- 秩-零度定理（Rank-Nullity Theorem）
-- 对于有限维向量空间之间的线性映射 f : V → W，
--   dim(ker f) + dim(im f) = dim V

/-! ## 可逆线性映射 -/

-- 线性映射 f : M → N 是可逆的，如果存在线性映射 g : N → M 使得
--   g ∘ f = id  且  f ∘ g = id

-- 可逆线性映射也称为线性同构
-- 双射线性映射是可逆的（在向量空间中）

/-! ## 线性映射的例子 -/

-- 1. 零映射：将所有向量映到 0
def zero_map : M →ₗ[R] N := 0

theorem zero_map_apply (x : M) : (zero_map R M N) x = 0 := by
  simp [zero_map]

-- 2. 标量乘法映射（当 M = N = R 时）
-- f(x) = c * x

-- 3. 坐标投影
-- 例如：ℝ² → ℝ, (x, y) ↦ x

-- 4. 微分算子
-- 在函数空间上，求导是线性映射

-- 5. 积分算子
-- 在函数空间上，积分是线性映射

/-! ## 对偶空间 -/

-- 线性泛函：从向量空间 V 到标量域 K 的线性映射
-- V* = Hom(V, K) 称为 V 的对偶空间

-- 对偶空间的元素是线性函数 f : V → K

end Lean4Tutorial.Examples.MathlibLinearAlgebra.LinearMaps
