/-
文件: 09_mathlib_algebra/algebra.lean
描述: 第12章 代数结构（与教程同步，Mathlib4 master@2026-09 验证）
编译: lake build Lean4Tutorial.Examples.MathlibAlgebra.Algebra
-/

import Mathlib.Algebra.Group.Semigroup
import Mathlib.Algebra.Group.Basic
import Mathlib.Algebra.Ring.Basic
import Mathlib.Algebra.Field.Basic
import Mathlib.Basic.Real.Basic          -- ℝ 记法与 Field ℝ（2026-08 起新位置）
import Mathlib.Algebra.Group.Subgroup.Basic
import Mathlib.RingTheory.Ideal.Basic
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Algebra.Ring.Hom.Defs
import Mathlib.Tactic.Abel
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.GroupTheory.GroupAction.ConjAct

namespace Lean4Tutorial.Examples.MathlibAlgebra.Ch12

/-! # 12.1 代数层次 -/

#check (inferInstance : Semigroup Nat)
#check (inferInstance : AddSemigroup Int)
#check (inferInstance : Monoid Nat)
#check (inferInstance : AddMonoid Nat)

/-! # 12.2 群 -/

#check (inferInstance : AddGroup Int)
#check (inferInstance : Group ℝˣ)

example (a : G) [Group G] : a⁻¹ * a = 1 := inv_mul_cancel a
example (a : G) [Group G] : a * a⁻¹ = 1 := mul_inv_cancel a
example (a : G) [Group G] : (a⁻¹)⁻¹ = a := inv_inv a
example (a b : G) [Group G] : (a * b)⁻¹ = b⁻¹ * a⁻¹ := mul_inv_rev a b
example (a b : Int) : a - b = a + (-b) := sub_eq_add_neg a b
example (a b c : Int) (h : a + b = a + c) : b = c := add_left_cancel h

/-! # 12.3 交换群与 abel -/

#check (inferInstance : AddCommGroup Int)
example (a b c d : Int) : (a + b) + (c + d) = (a + c) + (b + d) := by abel
-- abel 操作的对象是加法结构：系数用 • (nsmul) 而非 Int 乘法 *
example (G : Type) [AddCommGroup G] (a b : G) : 2 • (a + b) - (b + a) = a + b := by abel

/-! # 12.4 半环与环 -/

#check (inferInstance : Semiring Nat)
example (a b c : Nat) : a * (b + c) = a * b + a * c := left_distrib a b c
example (a b c : Nat) : (a + b) * c = a * c + b * c := right_distrib a b c

#check (inferInstance : Ring Int)
example (a b : Int) : (a + b) * (a - b) = a^2 - b^2 := by ring
example (x y : Int) : (x + y)^2 = x^2 + 2*x*y + y^2 := by ring
example (R : Type) [CommSemiring R] (a b : R) :
    (a + b)^2 = a^2 + 2*a*b + b^2 := by ring

/-! # 12.5 域 -/

#check (inferInstance : Field ℚ)
#check (inferInstance : Field ℝ)

example (a : ℝ) (h : a ≠ 0) : a * a⁻¹ = 1 := mul_inv_cancel₀ h
example (a b : ℝ) : a / b = a * b⁻¹ := div_eq_mul_inv a b

example (a b c : ℝ) (hb : b ≠ 0) (hc : c ≠ 0) :
    (a / b) / c = a / (b * c) := by
  field_simp
  <;> ring

/-! # 12.6 子结构 -/

example [Group G] (H : Subgroup G) : (1 : G) ∈ H := H.one_mem'
example [Group G] (H : Subgroup G) {x y : G} (hx : x ∈ H) (hy : y ∈ H) :
    x * y ∈ H := H.mul_mem' hx hy
example [Group G] (H : Subgroup G) {x : G} (hx : x ∈ H) : x⁻¹ ∈ H := H.inv_mem' hx
example [Group G] (H K : Subgroup G) : Subgroup G := H ⊓ K

example [CommRing R] (I : Ideal R) (r : R) {x : R} (hx : x ∈ I) : r * x ∈ I :=
  I.mul_mem_left r hx

/-! # 12.7 同态与等价 -/

#check MonoidHom
#check AddMonoidHom
#check RingHom
#check MulEquiv

example [MulOneClass M] [MulOneClass N] (f : M →* N) (x y : M) :
    f (x * y) = f x * f y := f.map_mul x y

example [MulOneClass M] [MulOneClass N] (f : M →* N) : f 1 = 1 := f.map_one

example [Group G] : G ≃* G := MulEquiv.refl G
example [Group G] (a : G) : G ≃* G := MulAut.conj a

end Lean4Tutorial.Examples.MathlibAlgebra.Ch12
