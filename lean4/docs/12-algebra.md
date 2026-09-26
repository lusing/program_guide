# 12 · 代数结构

> 对应示例：`examples/09_mathlib_algebra/algebra.lean`

Mathlib 代数层次的类定义源码：`Mathlib/Algebra/Group/Semigroup.lean`、`Mathlib/Algebra/Group/Monoid.lean`、`Mathlib/Algebra/Group/Defs.lean`、`Mathlib/Algebra/Ring/Defs.lean`、`Mathlib/Algebra/Field/Defs.lean`。**学这一章建议对照源码读**——class 的字段列表就是结构的公理。

## 12.1 代数层次的真实样子

```
Semigroup (mul_assoc)          AddSemigroup (add_assoc)
    │ extends Mul                  │ extends Add
Monoid (npow, 单位元公理)      AddMonoid
    │ extends Semigroup+One        │
DivInvMonoid (a⁻¹, a/b)        SubNegMonoid (-a, a-b)
    │                              │
Group (inv_mul_cancel)         AddGroup (neg_add_cancel)
    │                              │
CommGroup                      AddCommGroup

Semiring = AddCommMonoid + MonoidWithZero + NonUnitalSemiring + ...
Ring     = Semiring + AddCommGroup + AddGroupWithOne
CommRing = Ring + CommMonoid
Field    = CommRing + DivisionRing（含 inv、除法、nnqpow 等）
```

关键认知：**extends 链上的字段会被扁平化合并**（第 6.5 节的钻石问题）。`Ring R` 实例同时提供 `+`、`0`、`-`、`+` 结合交换律、`*`、`1`、分配律——一个实例承载全部公理。

```lean
import Mathlib.Algebra.Group.Semigroup   -- Semigroup/AddSemigroup 类定义
import Mathlib.Algebra.Group.Basic       -- 群常用引理集

-- 用 #print 看公理真面目（Infoview 中查看）
-- #print Semigroup
-- class Semigroup (G : Type*) extends Mul G where
--   protected mul_assoc : ∀ a b c : G, a * b * c = a * (b * c)

-- 标准类型的实例（实例本身分散在各 Data 文件里）
#check (inferInstance : Semigroup Nat)       -- Nat.mul_assoc 驱动
#check (inferInstance : AddSemigroup Int)
#check (inferInstance : Monoid Nat)          -- 乘幺半群
#check (inferInstance : AddMonoid Nat)       -- 加幺半群
```

## 12.2 群（Group）

```lean
import Mathlib.Algebra.Group.Basic

-- Group 类定义（Mathlib/Algebra/Group/Defs.lean:33）：
-- class Group (G : Type*) extends DivInvMonoid G where
--   protected inv_mul_cancel : ∀ a : G, a⁻¹ * a = 1

-- 整数加法群、非零实数乘法群
#check (inferInstance : AddGroup Int)
#check (inferInstance : Group ℝˣ)   -- ℝˣ 是单位群（Units）

-- 核心引理（名字即内容）
example (a : G) [Group G] : a⁻¹ * a = 1 := inv_mul_cancel a
example (a : G) [Group G] : a * a⁻¹ = 1 := mul_inv_cancel a
example (a : G) [Group G] : (a⁻¹)⁻¹ = a := inv_inv a
example (a b : G) [Group G] : (a * b)⁻¹ = b⁻¹ * a⁻¹ := mul_inv_rev a b

-- 减法定义（加群版）：sub_eq_add_neg 是定理而非定义
example (a b : Int) : a - b = a + (-b) := sub_eq_add_neg a b

-- 消去律：mathlib 命名为 mul_left_cancel / add_left_cancel 等
example (a b c : Int) (h : a + b = a + c) : b = c := add_left_cancel h
```

**注意**：旧名字 `add_left_neg`、`add_right_neg` 已在 2026-09 的废弃清理中删除，现名是 `neg_add_cancel`、`add_neg_cancel`。这正是"跟最新 mathlib 对齐"的实战案例。

## 12.3 交换群与 abel 战术

```lean
import Mathlib.Algebra.Group.Basic
import Mathlib.Tactic.Abel

#check (inferInstance : AddCommGroup Int)

-- abel：交换（加）群中的等式自动化（实现：Mathlib/Tactic/Abel.lean）
example (a b c d : Int) : (a + b) + (c + d) = (a + c) + (b + d) := by abel

-- abel 操作的对象是加法结构：整数系数要写成 • (nsmul)，不是 Int 乘法 *
example (G : Type) [AddCommGroup G] (a b : G) : 2 • (a + b) - (b + a) = a + b := by abel
```

## 12.4 半环与环

```lean
import Mathlib.Algebra.Ring.Basic

-- Semiring（Mathlib/Algebra/Ring/Defs.lean:142）：
-- 加法是交换幺半群、乘法是含零幺半群、乘法对加法分配
#check (inferInstance : Semiring Nat)

-- 分配律（Semigroup 版命名规律：left/right_distrib）
example (a b c : Nat) : a * (b + c) = a * b + a * c := left_distrib a b c
example (a b c : Nat) : (a + b) * c = a * c + b * c := right_distrib a b c

-- Ring = Semiring + 加法交换群
#check (inferInstance : Ring Int)

-- ring 战术（Mathlib/Tactic/Ring/ 实现）：交换半环/环的恒等式
example (a b : Int) : (a + b) * (a - b) = a^2 - b^2 := by ring
example (x y : Int) : (x + y)^2 = x^2 + 2*x*y + y^2 := by ring

-- ring 在"任意 CommSemiring"上可用，不必是 Int
example (R : Type) [CommSemiring R] (a b : R) :
    (a + b)^2 = a^2 + 2*a*b + b^2 := by ring
```

## 12.5 域（Field）

```lean
import Mathlib.Algebra.Field.Basic
import Mathlib.Basic.Real.Basic        -- ℝ 记法与 Field ℝ（2026-08 起新位置，见 11.2）

-- Field（Mathlib/Algebra/Field/Defs.lean:180）：
-- CommRing + 每个非零元有乘法逆元
#check (inferInstance : Field ℚ)
#check (inferInstance : Field ℝ)

example (a : ℝ) (h : a ≠ 0) : a * a⁻¹ = 1 := mul_inv_cancel₀ h
example (a b : ℝ) : a / b = a * b⁻¹ := div_eq_mul_inv a b

-- field_simp（Mathlib/Tactic/FieldSimp.lean）：把分式等式通分成多项式等式
example (a b c : ℝ) (hb : b ≠ 0) (hc : c ≠ 0) :
    (a / b) / c = a / (b * c) := by
  field_simp
  <;> ring
```

**命名观察**：`mul_inv_cancel₀` 的下标 ₀ 表示"带非零假设的版本"（GroupWithZero 语境）。看到下标 ₀ 要想到零/非零条件。

## 12.6 子结构：Submonoid / Subgroup / Subring / Ideal

子结构是"载体谓词 + 封闭性证明"的打包，源码：`Mathlib/Algebra/Group/Subgroup/Defs.lean`、`Mathlib/Algebra/Ring/Subring/Defs.lean`、`Mathlib/RingTheory/Ideal/Defs.lean`。

```lean
import Mathlib.Algebra.Group.Subgroup.Basic
import Mathlib.RingTheory.Ideal.Basic

-- Subgroup G 是 structure（Defs.lean:296）：
-- 字段 carrier : Set G，公理 mul_mem、one_mem、inv_mem
example [Group G] (H : Subgroup G) : (1 : G) ∈ H := H.one_mem'
example [Group G] (H : Subgroup G) {x y : G} (hx : x ∈ H) (hy : y ∈ H) :
    x * y ∈ H := H.mul_mem' hx hy
example [Group G] (H : Subgroup G) {x : G} (hx : x ∈ H) : x⁻¹ ∈ H := H.inv_mem' hx

-- 子结构构成完全格：⊓ 交、⊔ 并（闭包）、⊥ 最小、⊤ 最大
example [Group G] (H K : Subgroup G) : Subgroup G := H ⊓ K

-- Ideal R 是 Submodule R R 的缩写（RingTheory/Ideal/Defs.lean:40）
-- 吸收性：r ∈ R, x ∈ I ⟹ r * x ∈ I
example [CommRing R] (I : Ideal R) (r : R) {x : R} (hx : x ∈ I) : r * x ∈ I :=
  I.mul_mem_left r hx
```

## 12.7 同态与等价：→*、→+、→+*、≃*

```lean
import Mathlib.Algebra.Group.Hom.Defs      -- MonoidHom（Defs.lean:366）
import Mathlib.Algebra.Ring.Hom.Defs       -- RingHom（Defs.lean:297）

-- 记号速查
#check MonoidHom        -- 记法 M →* N：保持 * 与 1
#check AddMonoidHom     -- 记法 M →+ N：保持 + 与 0
#check RingHom          -- 记法 R →+* S：保持 +、*、0、1
#check MulEquiv         -- 记法 M ≃* N：双射同态（同构）

-- 同态的通用 API（FunLike 驱动，f x 直接应用）
example [MulOneClass M] [MulOneClass N] (f : M →* N) (x y : M) :
    f (x * y) = f x * f y := f.map_mul x y

example [MulOneClass M] [MulOneClass N] (f : M →* N) : f 1 = 1 := f.map_one

-- 同构是 Equiv + 同态：symm、trans、apply 对称化
example [Group G] : G ≃* G := MulEquiv.refl G

-- 共轭是一种自同构
example [Group G] (a : G) : G ≃* G := MulAut.conj a
```

---

> 上一章：[11 · Mathlib4 概述](11-mathlib-overview.md) ｜ 下一章：[13 · 数论](13-number-theory.md) ｜ 返回：[README](../README.md)
