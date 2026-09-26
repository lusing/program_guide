# 16 · 线性代数

> 对应示例：`examples/13_mathlib_linear_algebra/linear_algebra.lean`

源码坐标：`Mathlib/Algebra/Module/Defs.lean`（Module 类）、`Mathlib/Algebra/Module/LinearMap/Defs.lean`（LinearMap 结构）、`Mathlib/LinearAlgebra/Matrix/Defs.lean`（Matrix）、`Mathlib/LinearAlgebra/Matrix/Determinant/Basic.lean`（行列式）、`Mathlib/LinearAlgebra/FiniteDimensional/`（有限维）。

## 16.1 模与向量空间

**Module 是 mathlib 的向量空间**（域上模就是向量空间，没有单独的 VectorSpace 类）：

```lean
import Mathlib.Algebra.Module.Defs

-- Module（Defs.lean:54）：R-模 = 加法交换幺半群 + 标量乘 • 满足四条公理
-- class Module (R M) [Semiring R] [AddCommMonoid M] extends DistribMulAction R M where
--   add_smul : ∀ (r s : R) (x : M), (r + s) • x = r • x + s • x
--   zero_smul : ∀ x : M, (0 : R) • x = 0

-- 向量空间 = 域上的模
#check (inferInstance : Module ℝ (Fin 3 → ℝ))   -- ℝ³ 的 mathlib 写法

-- 标量乘法公理（命名规律：smul_op / op_smul；结合律名字是 smul_smul）
example [Semiring R] [AddCommMonoid M] [Module R M] (r s : R) (x : M) :
    r • s • x = (r * s) • x := smul_smul r s x
example [Semiring R] [AddCommMonoid M] [Module R M] (x : M) : (1 : R) • x = x :=
  one_smul R x
example [Semiring R] [AddCommMonoid M] [Module R M] (r : R) (x y : M) :
    r • (x + y) = r • x + r • y := smul_add r x y
```

**为什么 ℝ³ 写成 `Fin 3 → ℝ`**：mathlib 的向量/矩阵都以**有限类型索引的函数**实现，而非列表。好处：`x + y`、`r • x` 直接由函数空间的逐点实例给出；索引集合本身是可枚举的 `Fintype`。

## 16.2 线性映射

```lean
import Mathlib.Algebra.Module.LinearMap.Defs

-- LinearMap（Defs.lean:85）：带标量兼容 σ 的加性映射；记法 M →ₗ[R] N
#check LinearMap        -- structure，字段 toFun + map_add' + map_smul'
#check LinearMap.id     -- M →ₗ[R] M

-- 性质即字段（点号记法）
example [Semiring R] [AddCommMonoid M] [Module R M] [AddCommMonoid N] [Module R N]
    (f : M →ₗ[R] N) (x y : M) : f (x + y) = f x + f y := f.map_add x y
example [Semiring R] [AddCommMonoid M] [Module R M] [AddCommMonoid N] [Module R N]
    (f : M →ₗ[R] N) (r : R) (x : M) : f (r • x) = r • f x := f.map_smul r x

-- 复合与核/值域
#check LinearMap.comp     -- (N →ₗ[R] P) → (M →ₗ[R] N) → M →ₗ[R] P
#check LinearMap.ker      -- (M →ₗ[R] N) → Submodule R M
#check LinearMap.range    -- (M →ₗ[R] N) → Submodule R N
```

## 16.3 矩阵

```lean
import Mathlib.LinearAlgebra.Matrix.Defs

-- Matrix（LinearAlgebra/Matrix/Defs.lean:57）：
-- def Matrix (m n : Type u) (α : Type v) := m → n → α
-- 矩阵就是"索引对 → 元素"的函数！

open Matrix

-- 元素访问：A i j
example (A : Matrix (Fin 2) (Fin 2) ℝ) : ℝ := A 0 1

-- 字面量构造（!![...] 记法，2026 起在 Mathlib/LinearAlgebra/Matrix/Notation.lean）
def myMat : Matrix (Fin 2) (Fin 2) ℝ := !![1, 2; 3, 4]
#eval myMat 0 1     -- 2

-- 转置 ᵀ 与乘法 *
example (A : Matrix (Fin 2) (Fin 2) ℝ) : Matrix (Fin 2) (Fin 2) ℝ := A * Aᵀ

-- 乘法按"行列内积"展开（Matrix.mul_apply 参数全是隐式的）
example (A B : Matrix (Fin 2) (Fin 2) ℝ) (i j : Fin 2) :
    (A * B) i j = ∑ k, A i k * B k j := Matrix.mul_apply
```

## 16.4 行列式

`Matrix.det`（`Mathlib/LinearAlgebra/Matrix/Determinant/Basic.lean:60`）定义是交错和 `∑ σ : Perm n, sign σ * ∏ i, M i (σ i)`：

```lean
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic

open Matrix

example : det (1 : Matrix (Fin 3) (Fin 3) ℝ) = 1 := det_one
example (A B : Matrix (Fin n) (Fin n) ℝ) : det (A * B) = det A * det B := det_mul A B
example (A : Matrix (Fin n) (Fin n) ℝ) : det Aᵀ = det A := det_transpose A

-- 2×2 手算验证（!! 字面量要标注矩阵类型，否则数字默认成 ℕ 而没有 CommRing 实例）
example : det (!![2, 0; 0, 3] : Matrix (Fin 2) (Fin 2) ℝ) = 6 := by
  rw [det_fin_two]    -- det !![a,b;c,d] = a*d - b*c
  norm_num
```

## 16.5 经典证明案例四：Cayley–Hamilton 与 Vandermonde

```lean
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Vandermonde

-- Cayley-Hamilton（Charpoly/Basic.lean:216）：
-- 矩阵代入自己的特征多项式得零矩阵
example (M : Matrix (Fin n) (Fin n) ℝ) : Polynomial.aeval M M.charpoly = 0 :=
  Matrix.aeval_self_charpoly M

-- Vandermonde 行列式（LinearAlgebra/Vandermonde.lean:219）：
-- det (vandermonde v) = ∏ i < j, (v j - v i)
#check @Matrix.det_vandermonde
-- {n : ℕ} → {R : Type} → [CommRing R] → (v : Fin n → R) →
--   (vandermonde v).det = ∏ i : Fin n, ∏ j ∈ Finset.Ioi i, (v j - v i)
```

## 16.6 有限维与秩-零度定理

```lean
import Mathlib.LinearAlgebra.FiniteDimensional.Defs
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
-- 2026 起 FiniteDimensional 是目录：Defs.lean（类与 finrank）、Lemmas.lean（秩-零度）

open Module

-- finrank：有限维空间的维数（Dimension/Finrank.lean:62）
#check @Module.finrank    -- (R M : Type*) → ... → ℕ

-- ℝ³ 的维数是 3
example : finrank ℝ (Fin 3 → ℝ) = 3 := by simp [finrank_fintype_fun_eq_card]

-- 秩-零度定理（FiniteDimensional/Lemmas.lean:173）
example [FiniteDimensional K V] [AddCommGroup V₂] [Module K V₂]
    (f : V →ₗ[K] V₂) :
    finrank K (LinearMap.range f) + finrank K (LinearMap.ker f) = finrank K V :=
  LinearMap.finrank_range_add_finrank_ker f
```

---

> 上一章：[15 · 拓扑学](15-topology.md) ｜ 下一章：[17 · 组合数学](17-combinatorics.md) ｜ 返回：[README](../README.md)
