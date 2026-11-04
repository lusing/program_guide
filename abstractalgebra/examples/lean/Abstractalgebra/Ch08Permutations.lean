/-
! # 第 08 章 · 置换

对应原书 §2.2。机器验证：
1. sign 的乘法性（定理 2.39）与对换符号（引理 2.38）；
2. 完全分解的具体算例：α = (0 1 2)(3 4) ∈ S₅，阶 = lcm(3,2) = 6
   （命题 2.55）；
3. A₅ 的元素个数 = 60 = 5!/2。
-/

import Mathlib.GroupTheory.Perm.Sign
import Mathlib.GroupTheory.Perm.List
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch08

/-! ## 定理 2.39：sign 是乘法同态 -/

-- mathlib 正式化：sign (f * g) = sign f * sign g
example {α : Type*} [Fintype α] [DecidableEq α] (f g : Equiv.Perm α) :
    Equiv.Perm.sign (f * g) = Equiv.Perm.sign f * Equiv.Perm.sign g :=
  Equiv.Perm.sign_mul f g

/-! ## 引理 2.38：对换的符号 = −1 -/

example {α : Type*} [Fintype α] [DecidableEq α] (x y : α) (h : x ≠ y) :
    Equiv.Perm.sign (Equiv.swap x y) = -1 :=
  Equiv.Perm.sign_swap h

/-! ## 完全分解与阶（命题 2.24/2.55 的具体算例） -/

-- α = (0 1 2)(3 4) ∈ S₅：用循环字构造
def alpha5 : Equiv.Perm (Fin 5) :=
  (List.formPerm [0, 1, 2] * List.formPerm [3, 4] : Equiv.Perm (Fin 5))

-- 命题 2.55（阶 = lcm(3,2) = 6）的幂轨迹版：α⁶ = 1 且更小幂 ≠ 1
set_option maxRecDepth 20000 in
example : alpha5 ^ 6 = 1 := by decide

example : alpha5 ^ 3 ≠ 1 := by decide

example : alpha5 ^ 2 ≠ 1 := by decide

-- α 的符号 = −1：3-循环（偶）× 对换（奇）= 奇（推论 2.41）
example : Equiv.Perm.sign alpha5 = -1 := by decide

/-! ## A₅ 的元素个数 -/

-- |A₅| = 5!/2 = 60：sign 同态把 S₅ 均分为两半
example : Fintype.card {p : Equiv.Perm (Fin 5) // Equiv.Perm.sign p = 1} = 60 := by
  decide

end Abstractalgebra.Ch08
