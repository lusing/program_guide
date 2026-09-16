/-
文件: 16_advanced_tactics/advanced_tactics.lean
描述: 第19章 常用高级战术（与教程同步，Mathlib4 master@2026-09 验证）
编译: lake build Lean4Tutorial.Examples.AdvancedTactics.AdvancedTactics
-/

import Mathlib.Tactic.Ring
import Mathlib.Tactic.NoncommRing
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Abel
import Mathlib.Tactic.FunProp
import Mathlib.Tactic.Common
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Topology.Continuous                 -- Continuous + fun_prop 规则
import Mathlib.Topology.Instances.Real.Lemmas      -- ℝ 的拓扑实例
import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic  -- ℝ 的 Borel MeasurableSpace
import Mathlib.MeasureTheory.MeasurableSpace.Basic -- Measurable
import Mathlib.Analysis.Calculus.FDeriv.Pow        -- Differentiable 的 fun_prop 规则
import Mathlib.Analysis.Calculus.FDeriv.Add

namespace Lean4Tutorial.Examples.AdvancedTactics.Ch19

/-! # 19.1 ring -/

example (a b : ℤ) : (a + b) * (a - b) = a^2 - b^2 := by ring
example (x y : ℝ) : (x + y)^3 = x^3 + 3*x^2*y + 3*x*y^2 + y^3 := by ring
example (R : Type) [CommSemiring R] (a b : R) :
    (a + b)^2 = a^2 + 2*a*b + b^2 := by ring

-- ring_nf：只化简不关闭目标（两边归一后若相同则 rfl 收尾）
example (a b : ℝ) : (a + b)^2 = a^2 + 2*a*b + b^2 + 0 := by ring_nf

example (R : Type) [Ring R] (a b : R) : (a + b) - (b + a) + a = a := by noncomm_ring

/-! # 19.2 linarith / nlinarith -/

example (x y : ℝ) (h1 : x ≤ y) (h2 : y ≤ x + 1) : x ≤ y + 2 := by linarith
example (a b c : ℤ) (h1 : a > b) (h2 : b > c) : a > c := by linarith
example (x : ℝ) (hx : 0 ≤ x^2) : 0 ≤ x^2 + 1 := by linarith

example (x y : ℝ) : x^2 + y^2 ≥ 2 * x * y := by
  nlinarith [sq_nonneg (x - y)]
example (x y : ℝ) (h : x^2 + y^2 ≤ 1) : -1 ≤ x := by
  nlinarith [sq_nonneg y]

/-! # 19.3 omega（Lean 核心战术，无需 import Mathlib） -/

example (a b c : ℤ) (h1 : a + b > 0) (h2 : b + c > 0) (h3 : a + c > 0) :
    a + b + c > 0 := by omega

example (x y : ℤ) (h : 2 * x + 3 * y = 7) (h' : x ≥ 0) (h'' : y ≥ 0) :
    x = 2 ∧ y = 1 := by omega

example (n m : ℕ) (h : n ≥ 2 * m) : n - m ≥ m := by omega
example (n : ℕ) : n % 5 < 5 := by omega

/-! # 19.4 norm_num -/

example : 2 + 3 * 4 = 14 := by norm_num
example : 2^10 = 1024 := by norm_num
example : (123 : ℤ) * 456 = 56088 := by norm_num
example : Nat.choose 10 3 = 120 := by decide
example : Nat.Prime 97 := by norm_num          -- 素性扩展在 Mathlib.Tactic.NormNum.Prime
example : (6 : ℚ) / 4 = 3 / 2 := by norm_num
example (x : ℝ) (h : x = 2) : x^2 + 1 = 5 := by norm_num [h]

/-! # 19.5 positivity -/

example (x y : ℝ) (hx : 0 < x) (hy : 0 < y) : 0 < x * y := by positivity
example (n : ℕ) : 0 ≤ (n : ℝ) := by positivity
example (x : ℝ) : 0 ≤ x^2 := by positivity
example (x : ℝ) (hx : 0 < x) : 0 < x + |x| := by positivity

/-! # 19.6 field_simp -/

-- field_simp 通分后能自己收尾（旧教程的 field_simp <;> ring 写法中 ring 已无活可干）
example (a b c : ℝ) (hb : b ≠ 0) (hc : c ≠ 0) :
    (a / b) * (b / c) = a / c := by
  field_simp

example (x y : ℝ) (hy : y ≠ 0) :
    x / y + y / x = (x^2 + y^2) / (x * y) := by
  field_simp

/-! # 19.7 abel -/

example (a b c d : ℤ) : (a + b) + (c + d) = (a + d) + (b + c) := by abel
example (G : Type) [AddCommGroup G] (x y z : G) : x + y + z = z + y + x := by abel

/-! # 19.8 simp 家族 -/

example (n : ℕ) (h : 0 + n = n + 1) : n = n + 1 := by simpa using h
example (l : List ℕ) (h : l ++ [] = [1, 2]) : l = [1, 2] := by simpa using h
-- simp_arith 已废弃（现等价于 simp +arith）；算术收尾用 omega 更稳
example (n m : ℕ) (h : n ≤ m) : n + 1 ≤ m + 1 := by omega

/-! # 19.9 aesop -/

example (P Q R : Prop) (h1 : P → Q) (h2 : Q → R) (h3 : P) : R := by aesop

example {α : Type} {P Q : α → Prop} (h : ∀ x, P x → Q x) :
    (∀ x, P x) → (∀ x, Q x) := by aesop

/-! # 19.10 fun_prop -/

example : Continuous (fun x : ℝ => x^2 + 2*x + 1) := by fun_prop
example : Measurable (fun x : ℝ => x * x) := by fun_prop
example : Differentiable ℝ (fun x : ℝ => x^3 + 2 * x) := by fun_prop

/-! # 19.11 grind（Lean 4 核心） -/

example (l : List ℕ) : (l ++ []).length = l.length := by grind
example {α : Type} (a b : α) (h : a = b) (l : List α) : a :: l = b :: l := by grind

end Lean4Tutorial.Examples.AdvancedTactics.Ch19
