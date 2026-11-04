/-
! # 第 32 章 · 有限阿贝尔群

对应原书 §6.1。机器验证：
1. 8 阶三群互不同构（元素阶与 U₂ 计数两个不变量）；
2. CRT：ℤ/6 ≅ ℤ/2 × ℤ/3（ZMod.chineseRemainder）；
3. 指数与循环性（定理 6.11 基定理的数值面）。
-/

import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.NormNum

namespace Abstractalgebra.Ch31

/-! ## 8 阶阿贝尔群的区分（定理 6.15 的数值面） -/

-- ℤ/8 有 8 阶元（1 的阶恰为 8：4•1 ≠ 0 且 8•1 = 0）
example : (4 : ℕ) • (1 : ZMod 8) ≠ 0 := by decide
example : (8 : ℕ) • (1 : ZMod 8) = 0 := by decide

-- ℤ/2 × ℤ/2 × ℤ/2 的每个元素都是 2 阶以下（指数 2）
example : ∀ x : Fin 3 → ZMod 2, x + x = 0 := by decide

-- U₂ 计数（引理 6.12 的形状：被 pⁿ 零化的元素数是不变量）
example : (Finset.univ.filter (fun x : Fin 3 → ZMod 2 => (2 : ℕ) • x = 0)).card = 8 := by
  decide

example : (Finset.univ.filter (fun x : ZMod 8 => (2 : ℕ) • x = 0)).card = 2 := by
  decide

example : (Finset.univ.filter (fun x : ZMod 4 × ZMod 2 => (2 : ℕ) • x = 0)).card = 4 := by
  decide

/-! ## CRT：两两互素 ⟹ 直积即循环 -/

-- ℤ/6 ≅ ℤ/2 × ℤ/3（环同构层面的 CRT）
example : ∃ e : ZMod 6 ≃+* ZMod 2 × ZMod 3, Function.Bijective e :=
  ⟨ZMod.chineseRemainder (show Nat.Coprime 2 3 by decide), Equiv.bijective _⟩

-- 同一定理用于 ℤ/8 × ℤ/9 ≅ ℤ/72（72 阶群的循环代表）
example : ∃ e : ZMod 72 ≃+* ZMod 8 × ZMod 9, Function.Bijective e :=
  ⟨ZMod.chineseRemainder (show Nat.Coprime 8 9 by decide), Equiv.bijective _⟩

/-! ## 指数 -/

-- ℤ/6 的指数是 6：全部元素被 6 零化，而 5 不够
example : ∀ x : ZMod 6, (6 : ℕ) • x = 0 := by decide
example : (5 : ℕ) • (1 : ZMod 6) ≠ 0 := by decide

/-! ## 分类计数的算术面 -/

-- 72 = 2³·3²；阿贝尔群个数 = p(3)·p(2) = 3·2 = 6（分拆数乘积）
example : (72 : ℕ) = 2 ^ 3 * 3 ^ 2 := by norm_num
example : (3 : ℕ) * 2 = 6 := by norm_num

-- 360 = 2³·3²·5 ⟹ 3·2·1 = 6 个阿贝尔群
example : (360 : ℕ) = 2 ^ 3 * 3 ^ 2 * 5 := by norm_num

end Abstractalgebra.Ch31
