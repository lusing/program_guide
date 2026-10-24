import Mathlib.SetTheory.Cardinal.Aleph
import Mathlib.SetTheory.Cardinal.Continuum
import Mathlib.SetTheory.Cardinal.Arithmetic
import Mathlib.Tactic

open scoped Cardinal
open Order

/-!
# 第 76 章 · 选择公理与无穷和积不等式（冯琦 §2.1–2.2）

mathlib 的类型宇宙默认采用经典逻辑与选择原理；这里不重复假设 AC，
而是把本章用到的无穷基数结论落到官方定理：不交并的基数和、
`Cardinal.power_eq_two_power`（定理 2.13(1)）、`Cardinal.cantor`
（König 不等式的单指标特例）与 beth 不动点的强极限性。
Coq/Agda/Julia/Python/Prolog 负责有限选择函数与 König 对角构造。
-/

namespace Settheory.Ch76

/-- 并集的基数至多等于各块基数之和；不要求各块不交。 -/
theorem mk_iUnion_le_sum_official {α ι : Type} (f : ι → Set α) :
    #(⋃ i, f i) ≤ Cardinal.sum fun i => #(f i) :=
  Cardinal.mk_iUnion_le_sum_mk

/-- 每块至多有 κ 个元素时，并集受 |I|·κ 控制。 -/
theorem mk_iUnion_le_official {α ι : Type} (f : ι → Set α) :
    #(⋃ i, f i) ≤ #ι * ⨆ i, #(f i) :=
  Cardinal.mk_iUnion_le f

/-- 定理 2.13(1)：2 ≤ κ ≤ λ 且 λ 无穷时，κ^λ = 2^λ。 -/
theorem power_eq_two_power_official (κ ν : Cardinal)
    (hν : ℵ₀ ≤ ν) (hκ : 2 ≤ κ) (hκν : κ ≤ ν) : κ ^ ν = 2 ^ ν :=
  Cardinal.power_eq_two_power hν hκ hκν

/-- 特例：ℵ₀^ℵ₀ = 2^ℵ₀，而不是另一个待定的基数。 -/
theorem aleph0_power_aleph0' : ℵ₀ ^ ℵ₀ = 2 ^ ℵ₀ := by
  rw [Cardinal.power_eq_two_power le_rfl (by norm_num) le_rfl]

/-- Cantor 定理：κ < 2^κ；它也是 König 不等式取 κᵢ=1、λᵢ=2 的形式。 -/
theorem cantor_power (κ : Cardinal) : κ < 2 ^ κ := Cardinal.cantor κ

/-- 连续统就是 2^ℵ₀。 -/
theorem continuum_eq_two_power : 2 ^ ℵ₀ = 𝔠 := Cardinal.two_power_aleph0

/-- beth 序列的极限项都是强极限基数：μ < ℶ_λ → 2^μ < ℶ_λ。 -/
theorem beth_strong_limit {o : Ordinal} (ho : IsSuccPrelimit o) :
    Cardinal.IsStrongLimit (ℶ_ o) :=
  Cardinal.isStrongLimit_beth.mpr ho

end Settheory.Ch76
