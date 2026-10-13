import Mathlib.SetTheory.Cardinal.SchroederBernstein
import Mathlib.SetTheory.Cardinal.Aleph
import Mathlib.SetTheory.Cardinal.Cofinality.Basic

open scoped Cardinal

/-!
# 第 03 章 · 基数：Hartogs、Cantor、Schröder-Bernstein

mathlib 的 `Cardinal` 理论是本章主战场：双向包含推出等势、
aleph 阶梯、共尾性与正则性。
-/

/-! ## 一、Cantor 与 Schröder-Bernstein -/

/-- Cantor 定理（第 00 章预告，这里正式入册）：κ < 2^κ。 -/
example (κ : Cardinal) : κ < 2 ^ κ := Cardinal.cantor κ

/-- **Schröder-Bernstein**（Jech 定理 7）：双向单射推出双射。 -/
example {α β : Type} (f : α → β) (g : β → α)
    (hf : Function.Injective f) (hg : Function.Injective g) : Nonempty (α ≃ β) :=
  Function.Embedding.antisymm ⟨f, hf⟩ ⟨g, hg⟩

/-! ## 二、aleph 阶梯（Jech 引理 3.2 + 定义） -/

/-- aleph 严格递增：ℵ 的下标即序数。 -/
example {o₁ o₂ : Ordinal} : ℵ_ o₁ < ℵ_ o₂ ↔ o₁ < o₂ :=
  Cardinal.aleph_lt_aleph

/-- 后继 aleph：(ℵ_α)⁺ = ℵ_{α+1}（最小更大基数）。 -/
example (o : Ordinal) : Order.succ (ℵ_ o) = ℵ_ (o + 1) :=
  Cardinal.succ_aleph o

/-- ℵ₀ 之上全是无穷：aleph0 ≤ ℵ_ o。 -/
example (o : Ordinal) : ℵ₀ ≤ ℵ_ o := Cardinal.aleph0_le_aleph o

/-! ## 三、共尾性（Jech 引理 3.3-3.5 的入口） -/

/-- 本版 mathlib 的共尾性 API 是 `Order.cof`（预序的共尾集基数
    下确界）。ℕ（序型 ω）的共尾数是 ℵ₀——"ℵ₀ 正则"的库形态。 -/
example : Order.cof ℕ = ℵ₀ :=
  Order.cof_nat
