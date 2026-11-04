/-
! # 第 18 章 · 环同态

对应原书 §3.4。机器验证：
1. RingHom 基本律与核的吸收性（理想性质）；
2. ZMod 的 castHom：ℤ/6 → ℤ/3 的核计数；
3. 范数的"乘性非加性"侧影（用 ℚ 上的平方和呈现）。
-/

import Mathlib.Algebra.Ring.Hom.Defs
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch18

/-! ## 同态基本律 -/

example {R S : Type*} [CommRing R] [CommRing S] (f : R →+* S) : f 1 = 1 :=
  f.map_one

example {R S : Type*} [CommRing R] [CommRing S] (f : R →+* S) (a b : R) :
    f (a + b) = f a + f b := f.map_add a b

example {R S : Type*} [CommRing R] [CommRing S] (f : R →+* S) (a b : R) :
    f (a * b) = f a * f b := f.map_mul a b

example {R S : Type*} [CommRing R] [CommRing S] (f : R →+* S)
    (r x : R) (hx : f x = 0) : f (r * x) = 0 := by
  rw [map_mul, hx, mul_zero]

/-! ## ZMod.castHom：ℤ/6 → ℤ/3 的自然同态 -/

-- 同态存在（3 ∣ 6）
noncomputable example : (ZMod 6) →+* (ZMod 3) :=
  ZMod.castHom (by decide : (3 : ℕ) ∣ 6) (ZMod 3)

-- 核的计数侧影：恰两个元素 x 满足 x mod 3 = 0（即 {[0], [3]}）
example : Fintype.card {x : ZMod 6 // x.val % 3 = 0} = 2 := by decide

/-! ## 平方和范数的"乘性"侧影（Brahmagupta–Fibonacci 恒等式） -/

-- (a² + b²)(c² + d²) = (ac−bd)² + (ad+bc)²：范数乘性的整数内核
example (a b c d : ℚ) :
    (a * a + b * b) * (c * c + d * d)
      = (a * c - b * d) * (a * c - b * d)
        + (a * d + b * c) * (a * d + b * c) := by ring

end Abstractalgebra.Ch18
