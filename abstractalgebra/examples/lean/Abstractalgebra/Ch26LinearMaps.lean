/-
! # 第 26 章 · 线性变换

对应原书 §4.3。机器验证：
1. LinearMap 基本律与"单 ⟺ 核平凡"；
2. 秩-零化度（mathlib 正式化）；
3. 2×2 迹的相似不变性引擎 trace(AB) = trace(BA)。
-/

import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch26

/-! ## 线性变换基本律 -/

example {F V W : Type*} [Field F] [AddCommGroup V] [Module F V]
    [AddCommGroup W] [Module F W] (T : V →ₗ[F] W) (v u : V) :
    T (v + u) = T v + T u := T.map_add v u

example {F V W : Type*} [Field F] [AddCommGroup V] [Module F V]
    [AddCommGroup W] [Module F W] (T : V →ₗ[F] W) (a : F) (v : V) :
    T (a • v) = a • T v := T.map_smul a v

-- 单 ⟺ 核平凡（与群/环论平行；mathlib 版：ker = ⊥ ↔ Injective）
example {F V W : Type*} [Field F] [AddCommGroup V] [Module F V]
    [AddCommGroup W] [Module F W] (T : V →ₗ[F] W) :
    LinearMap.ker T = ⊥ ↔ Function.Injective T :=
  LinearMap.ker_eq_bot

/-! ## 秩-零化度 -/

example {F V W : Type*} [Field F] [AddCommGroup V] [Module F V]
    [AddCommGroup W] [Module F W] [FiniteDimensional F V]
    (T : V →ₗ[F] W) :
    Module.finrank F ↥(LinearMap.range T) + Module.finrank F (LinearMap.ker T)
      = Module.finrank F V :=
  T.finrank_range_add_finrank_ker

/-! ## 迹的循环性（相似不变性的引擎） -/

-- 2×2 情形：trace(AB) = trace(BA) 的显式代数验证
-- A = [[a,b],[c,d]]、B = [[e,f],[g,h]]：
-- trace(AB) = (ae+bg) + (cf+dh)；trace(BA) = (ea+fc) + (gb+hd)
example (a b c d e f g h : ℚ) :
    (a * e + b * g) + (c * f + d * h)
      = (e * a + f * c) + (g * b + h * d) := by
  ring_nf

end Abstractalgebra.Ch26
