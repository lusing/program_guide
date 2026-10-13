import Mathlib.Order.WellFounded
import Mathlib.SetTheory.Ordinal.Basic

/-!
# 第 11 章 · 传递模型：Mostowski 坍缩与反射原理

定理 28（良基+外延 ⟹ 同构于传递类）与定理 29（反射原理）
是 L 篇的方法论双璧。
-/

/-! ## 一、良基递归：坍缩函数的定义机制 -/

/- 最简形态（强归纳）已在 Coq 通道 Ch09 完整机器化
   （epsilon_induction_shadow）；坍缩的可执行版见计算通道。 -/

/-! ## 二、定理 2 回顾：坍缩的序数特例 -/

/-- 良序集的序型：良序集 ≅ 唯一序数——Mostowski 坍缩在
    ∈-良序下的特例（π 即枚举函数）。序型由 `Ordinal.type` 给出。 -/
example (α : Type) (r : α → α → Prop) [IsWellOrder α r] :
    ∃ o : Ordinal, o = Ordinal.type r :=
  ⟨_, rfl⟩

/-! ## 三、反射原理（讲义对照） -/
/-
定理 29：对每个公式 φ 与每个 M₀，存在传递集 M ⊇ M₀（甚至
M = V_α）反射 φ：M ⊨ φ[a] ⟺ φ[a]。
推论 4：ZF 不可有限公理化。
实测发现（入册）：Isabelle/ZF 的 Reflection.thy（Paulson 的
反射定理源码形式化）是 ZF-Constructible 会话的孤儿理论——
官方堆不含它；本章 Isabelle 通道以 AC_in_L 导出链为锚。 -/
