/-
! # 第 11 章 · 群同态

对应原书 §2.5。机器验证：
1. f(1) = 1、f(a⁻¹) = f(a)⁻¹（引理 2.89）；
2. det 的乘法性（Matrix.det_mul）；
3. ZMod 6 → ZMod 3 的自然投射同态：核 {[0],[3]}、|G| = |ker|·|im| 预告。
-/

import Mathlib.Algebra.Group.Hom.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch11

/-! ## 引理 2.89 -/

example {G H : Type*} [Group G] [Group H] (f : G →* H) : f 1 = 1 := f.map_one

example {G H : Type*} [Group G] [Group H] (f : G →* H) (a : G) :
    f a ⁻¹ = (f a) ⁻¹ := f.map_inv a

example {G H : Type*} [Group G] [Group H] (f : G →* H) (a b : G) :
    f (a * b) = f a * f b := f.map_mul a b

/-! ## det 同态（矩阵乘积行列式 = 行列式乘积） -/

example (A B : Matrix (Fin 2) (Fin 2) ℝ) :
    (A * B).det = A.det * B.det := Matrix.det_mul A B

/-! ## ZMod 6 → ZMod 3：核与像 -/

-- ZMod.castHom：m ∣ n 时的自然同态 ZMod n →+ ZMod m
noncomputable example : (ZMod 6) →+ (ZMod 3) :=
  ZMod.castHom (by decide : (3 : ℕ) ∣ 6) (ZMod 3)

-- 核 = {[0], [3]}：恰两个元素映到 0
example : Fintype.card {x : ZMod 6 // x.val % 3 = 0} = 2 := by decide

-- 该映射保持运算（模 3 是良定义的同态）
example (a b : ZMod 6) : (a + b).val % 3 = (a.val % 3 + b.val % 3) % 3 := by
  simp [ZMod.val_add]

-- |G| = |ker|·|im| 的数值投影：6 = 2 × 3
example : Fintype.card (ZMod 6) = 2 * 3 := by decide

end Abstractalgebra.Ch11
