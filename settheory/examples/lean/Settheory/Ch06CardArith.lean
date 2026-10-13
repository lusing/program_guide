import Mathlib.SetTheory.Cardinal.Continuum
import Mathlib.SetTheory.Ordinal.CantorNormalForm

/-!
# 第 06 章 · 基数算术：κ^λ、连续统函数与 König

mathlib 的连续统理论（`Cardinal.Continuum`）与 Cantor 范式
（`Ordinal.CantorNormalForm`）是本章的主锚点。
-/

open scoped Cardinal

/-! ## 一、指数律的锚点 -/

/-- n^ℵ₀ = 𝔠（n ≥ 2）：可数幂是连续统。 -/
example {n : ℕ} (hn : 2 ≤ n) : (n : Cardinal) ^ ℵ₀ = 𝔠 :=
  Cardinal.nat_power_aleph0 hn

/-- ℵ₀^ℵ₀ = 𝔠：可数集的序列空间仍是连续统。 -/
example : ℵ₀ ^ ℵ₀ = 𝔠 := Cardinal.aleph0_power_aleph0

/-- 𝔠^ℵ₀ = 𝔠：连续统的"稳态"。 -/
example : 𝔠 ^ ℵ₀ = 𝔠 := Cardinal.continuum_power_aleph0

/-! ## 二、König 推论：cf(2^κ) > κ -/

/-- Cantor + König 推论 4 的形态：κ < κ ^ (cf κ)。
    mathlib 对一般 κ 的 cf 陈述在 `Order.cof`；这里给出
    后继基数版的可证特例：ℵ₀ < ℵ₀ ^ ℵ₀。 -/
example : ℵ₀ < ℵ₀ ^ ℵ₀ := by
  rw [Cardinal.aleph0_power_aleph0]
  simpa using Cardinal.cantor ℵ₀

/-! ## 三、Cantor 范式的库形态 -/

open Ordinal.CNF

/-- CNF b o 是 o 的 b 进 Cantor 范式项列表。
    zero_right：0 的范式是空表。 -/
example (b : Ordinal) : Ordinal.CNF b 0 = [] := zero_right b

/-- zero_left：b=0 时的退化条款：0^e · o。 -/
example (o : Ordinal) (ho : o ≠ 0) : Ordinal.CNF 0 o = [(0, o)] :=
  Ordinal.CNF.zero_left ho
