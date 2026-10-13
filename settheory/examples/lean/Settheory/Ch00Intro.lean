import Mathlib.SetTheory.Ordinal.Basic
import Mathlib.SetTheory.Cardinal.Basic

/-!
# 第 00 章 · 导引：三个世界里的集合论

本文件对应 docs/00-intro.md 的机器通道演示。
-/

/-! ## Type 宇宙：Russell 悖论为何无法陈述 -/

/-- 在 Lean 的类型论里，"x ∈ x" 型的命题无法对任意 x 成型：
`Membership.mem` 要求左边是右边类型的**元素类型**。全类 `V = {x : x = x}`
不存在，因为每个类型 `Type u` 本身住在更大的 `Type (u+1)` 里——
这就是类型层级对悖论的免疫方式。 -/
def typeHierarchy : Type 1 := Type 0

/-- 类型归属是分层判断：`ℕ` 是 `Type 0` 的居民，而 `Type 0` 是 `Type 1`
的居民；"ℕ ∈ ℕ" 不是良型的命题。 -/
def natIsSmall : Type 0 := ℕ

/-! ## von Neumann 序数：`Ordinal` 一瞥 -/

/-- 序数的后继运算逐条命中自然数：succ 0 = 1，succ 1 = 2。
mathlib 中序数的后继由 `SuccOrder` 实例给出，`succ o = o + 1`。 -/
example : (1 : Ordinal) = (0 : Ordinal) + 1 := by simp

example : (1 : Ordinal) + 1 = 2 := one_add_one_eq_two

/-! ## 基数：`Cardinal` 一瞥 -/

/-- 有限集合的基数就是元素个数。 -/
example : Cardinal.mk (Fin 3) = 3 := by simp

/-- Cantor 定理：没有最大基数——本书反复使用的引擎。 -/
example (κ : Cardinal) : κ < 2 ^ κ := Cardinal.cantor κ
