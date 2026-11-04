/-
! # 第 15 章 · 交换环的基本性质

对应原书 §3.1-3.2。机器验证：
1. 负号纪律：a·0 = 0、负负得正、分配律推论；
2. 命题 3.14：单位不是零因子；
3. ZMod 7 是域（非零元均可逆）而 ZMod 6 有零因子（命题 3.15 实例）。
-/

import Mathlib.Algebra.Ring.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch15

/-! ## 负号纪律 -/

-- a·0 = 0（mathlib 一行；"公理挤出"的完整手工版见 docs 15 章）
example {R : Type*} [CommRing R] (a : R) : a * 0 = 0 := by ring

-- 负负得正
example {R : Type*} [CommRing R] (a b : R) : (-a) * (-b) = a * b := by ring

-- (−a)b = −(ab)
example {R : Type*} [CommRing R] (a b : R) : (-a) * b = -(a * b) := by ring

-- 减法分配：(a − b)c = ac − bc
example {R : Type*} [CommRing R] (a b c : R) : (a - b) * c = a * c - b * c := by ring

/-! ## 命题 3.14：单位不是零因子 -/

example {R : Type*} [CommRing R] {a b : R} (ha : IsUnit a) (h : a * b = 0) :
    b = 0 := by
  obtain ⟨u, hu⟩ := ha
  have h1 : u.inv * u.val = 1 := u.inv_mul
  have h2 : u.val = a := hu
  rw [← h2] at h
  calc b = (u.inv * u.val) * b := by rw [h1]; ring
    _ = u.inv * (u.val * b) := by ring
    _ = u.inv * 0 := by rw [h]
    _ = 0 := by ring

/-! ## 命题 3.15 实例：ZMod 7 域 / ZMod 6 零因子 -/

-- ℤ₇ 的每个非零元都是单位（域）
example : ∀ a : ZMod 7, a ≠ 0 → IsUnit a := by decide

-- ℤ₆ 的零因子现场：3 · 4 = 0 (mod 6)
example : (3 : ZMod 6) * 4 = 0 := by decide

example : (3 : ZMod 6) ≠ 0 := by decide

example : (4 : ZMod 6) ≠ 0 := by decide

end Abstractalgebra.Ch15
